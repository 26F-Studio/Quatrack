local int,rnd=math.floor,math.random
local ins,rem=table.insert,table.remove

local Map={}

local mapInfoKeys={
    "version",
    "mapName",
    "musicAuth",
    "mapAuth",
    "songFile",
    "songOffset",
    "tracks",
}

local SCline,SCstr
local function _syntaxCheck(cond,msg)
    if not cond then
        error(("[$1] $2: $3"):repD(SCline,SCstr,msg))
    end
end

function Map.new(file)
    local o={
        version="0.1",
        mapName='[mapName]',
        musicAuth='[musicAuth]',
        mapAuth='[mapAuth]',

        songFile="songFile]",
        songOffset=0,
        tracks=4,

        time=0,
        eventQueue={},
        notePtr=0,
        animePtr=0,
        finished=false,
    }

    --Read file
    local fileData={}do
        local lineNum=1
        for l in love.filesystem.lines(file)do
            l=STRING.trim(l)
            if l~=""then
                ins(fileData,{lineNum,l})
            end
            lineNum=lineNum+1
        end
    end

    --Load metadata
    while true do
        local str=fileData[1][2]
        SCline,SCstr=fileData[1][1],str
        if str:sub(1,1)=='$'then
            local k=str:sub(2,str:find("=")-1)
            _syntaxCheck(TABLE.find(mapInfoKeys,k),"Invalid map info key '"..k.."'")
            _syntaxCheck(str:find("="),"Syntax error (need '=')")
            o[k]=str:sub(str:find("=")+1)
            rem(fileData,1)
        else
            break
        end
    end

    --Parse non-string metadata
    if type(o.tracks)=='string'then o.tracks=tonumber(o.tracks)end
    if type(o.songOffset)=='string'then o.songOffset=tonumber(o.songOffset)end

    --Parse notes & animations
    local curTime,curBPM=0,180
    local loopMark,loopEnd,loopCountDown
    local longBarState=TABLE.new(false,o.tracks)
    local lastLineState=TABLE.new(false,o.tracks)
    local line=#fileData
    while line>0 do
        local str=fileData[line][2]

        SCline,SCstr=fileData[line][1],str--For assertion

        if str:sub(1,1)=='#'then--Annotation
            --Do nothing
        elseif str:sub(1,1)=='!'then--BPM mark
            local bpm=tonumber(str:sub(2))
            _syntaxCheck(type(bpm)=='number'and bpm>0,"Invalid BPM mark")
            curBPM=bpm
        elseif str:sub(1,1)==':'then--Time mark
            _syntaxCheck(not loopMark,"Cannot set time in loop")

            str=str:sub(2)
            local stamp=STRING.split(str,":")

            _syntaxCheck(#stamp==2 and type(stamp[1])=='number'and type(stamp[2])=='number',"Wrong Time stamp")

            stamp=tonumber(stamp[1])*60+tonumber(stamp[2])
            _syntaxCheck(stamp>curTime,"Cannot warp to past")

            curTime=stamp
        elseif str:sub(1,1)=='='then--Repeat mark
            local len=0
            repeat
                len=len+1
                str=str:sub(2)
            until str:sub(1,1)~='='
            _syntaxCheck(len>=4 and len<=10,"Invalid repeat mark length")

            if str:sub(1,1)=='S'then
                _syntaxCheck(not loopMark,"Cannot start another loop in a loop")
                loopMark=line
                if str:sub(2)==''then
                    loopCountDown=1
                else
                    loopCountDown=tonumber(str:sub(2))
                    _syntaxCheck(loopCountDown>=2 and int(loopCountDown)==loopCountDown,"Invalid loop count")
                    loopCountDown=loopCountDown-1
                end
            elseif str=='E'then
                _syntaxCheck(loopMark,"Cannot end a loop without start one")
                if loopCountDown>0 then
                    loopEnd=line
                    loopCountDown=loopCountDown-1
                    line=loopMark
                else
                    loopMark=nil
                    loopCountDown=nil
                end
            elseif str=='M'then
                if loopCountDown==0 then
                    loopMark=nil
                    loopCountDown=nil
                    line=loopEnd
                end
            else
                _syntaxCheck(false,"Invalid repeat mark")
            end
        else--Notes
            local readState='note'
            local trackUsed=TABLE.new(false,o.tracks)
            local curTrack=1
            local step=1

            local c
            while true do
                if readState=='note'then
                    c=str:sub(1,1)
                    if c~='-'then--Space
                        if c=='O'then--Normal note
                            ins(o.eventQueue,{
                                type="note",
                                time=curTime,
                                track=curTrack,
                            })
                        elseif c=='U'then--Long bar start
                            _syntaxCheck(not longBarState[curTrack],"Cannot start a long bar in a long bar")
                            local b={
                                type="bar",
                                track=curTrack,
                                stime=curTime,
                                etime=false,
                                tail=false,
                            }
                            ins(o.eventQueue,b)
                            longBarState[curTrack]=b
                        elseif c=='A'then--Long bar stop
                            _syntaxCheck(longBarState[curTrack],"No long bar to stop")
                            longBarState[curTrack].etime=curTime
                            longBarState[curTrack].tail=true
                            longBarState[curTrack]=false
                        elseif c=='H'then--Long bar end
                            _syntaxCheck(longBarState[curTrack],"No long bar to end")
                            longBarState[curTrack].etime=curTime
                            longBarState[curTrack]=false
                        else
                            _syntaxCheck(curTrack==o.tracks+1,"Too few notes in one line")
                            readState='rnd'
                            goto CONTINUE_nextState
                        end
                        trackUsed[curTrack]=true
                    end
                    _syntaxCheck(curTrack<=o.tracks,"Too many notes in one line")
                    curTrack=curTrack+1
                    str=str:sub(2)
                elseif readState=='rnd'then
                    c=str:sub(1,1)
                    local available={}
                    for i=1,o.tracks do available[i]=i end
                    for i=#available,1,-1 do
                        if trackUsed[available[i]]then
                            rem(available,i)
                        end
                    end
                    local ifJack=c==c:upper()
                    for i=#available,1,-1 do if ifJack==lastLineState[available[i]]then rem(available,i)end end
                    c=c:upper()
                    if c=='L'then--Random left
                        for i=#available,1,-1 do
                            if available[i]>(o.tracks+1)*.5 then
                                rem(available,i)
                            end
                        end
                    elseif c=='R'then--Random right
                        for i=#available,1,-1 do
                            if available[i]<(o.tracks+1)*.5 then
                                rem(available,i)
                            end
                        end
                    elseif c=='X'then--Random anywhere
                        --Do nothing
                    else
                        readState='time'
                        goto CONTINUE_nextState
                    end
                    _syntaxCheck(#available>0,"No space to place notes")
                    curTrack=available[rnd(#available)]
                    ins(o.eventQueue,{
                        type="note",
                        time=curTime,
                        track=curTrack,
                    })
                    trackUsed[curTrack]=true
                    str=str:sub(2)
                elseif readState=='time'then
                    if str:sub(1,1)=='|'then--Shorten 1/2 for each
                        while true do
                            step=step*.5
                            str=str:sub(2)
                            if str==""then
                                break
                            else
                                _syntaxCheck(str:sub(1,1)=='|',"Mixed mark")
                            end
                        end
                    elseif str:sub(1,1)=='~'then--Add 1 beat for each
                        while true do
                            step=step+1
                            str=str:sub(2)
                            if str==""then
                                break
                            else
                                _syntaxCheck(str:sub(1,1)=='~',"Mixed mark")
                            end
                        end
                    elseif str:sub(1,1)=='*'then--Multiply time by any number
                        local mul=tonumber(str:sub(2))
                        _syntaxCheck(type(mul)=='number',"Wrong scale num")
                        step=step*mul
                        break
                    elseif str:sub(1,1)=='/'then--Divide time by any number
                        local div=tonumber(str:sub(2))
                        _syntaxCheck(type(div)=='number',"Wrong scale num")
                        step=step/div
                        break
                    elseif str==""then
                        break
                    else
                        _syntaxCheck(false,"Invalid time mark")
                    end
                end
                ::CONTINUE_nextState::
            end
            lastLineState=trackUsed
            curTime=curTime+60/curBPM*step
        end
        line=line-1
    end

    --Move two pointers to first [item]
    o.notePtr=1
    o.animePtr=1
    while o.eventQueue[o.notePtr]do
        if o.eventQueue[o.notePtr].type=='note'then break end
        o.notePtr=o.notePtr+1
    end
    while o.eventQueue[o.animePtr]do
        if o.eventQueue[o.animePtr].type=='event'then break end
        o.animePtr=o.animePtr+1
    end

    return setmetatable(o,{__index=Map})
end

function Map:updateTime(time)
    self.time=time
end

function Map:pollNote()
    local n=self.eventQueue[self.notePtr]
    if n then
        if self.time>n.time-2.6 then
            local queue=self.eventQueue
            while true do
                self.notePtr=self.notePtr+1
                if not queue[self.notePtr]then
                    self.finished=true
                    break
                elseif queue[self.notePtr].type=='note'then
                    break
                end
            end
            return n
        end
    end
end

return Map