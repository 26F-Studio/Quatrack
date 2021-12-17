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
        noteQueue={},
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

            local stamp=STRING.split(str:sub(2),":")
            if #stamp==1 then ins(stamp,1,"0")end
            for i=1,2 do
                stamp[i]=tonumber(stamp[i])
                _syntaxCheck(type(stamp[i])=='number'and stamp[i]>=0,"Invalid time mark")
            end
            stamp=stamp[1]*60+stamp[2]
            _syntaxCheck(stamp>curTime,"Cannot warp to past")

            curTime=stamp
        elseif str:sub(1,1)=='['then--Animation: move track (WIP)
            local id=str:find(':')
            _syntaxCheck(id,"Syntax error (need ':')")
            id=tonumber(str:sub(2,id-1))
            _syntaxCheck(id,"Wrong track ID")
            local pos=STRING.split(str:sub(str:find(':')+1),",")
            _syntaxCheck(#pos==5,"Invalid track position")
            for i=1,5 do
                pos[i]=tonumber(pos[i])
                _syntaxCheck(type(pos[i])=='number',"Invalid track position")
            end
            ins(o.eventQueue,{
                type="moveTrack",
                time=curTime,
                track=id,
                pos={
                    x=pos[1],
                    y=pos[2],
                    ang=pos[3],
                    kx=pos[4],
                    ky=pos[5],
                },
            })
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
                            ins(o.noteQueue,{
                                type='hit',
                                time=curTime,
                                track=curTrack,
                            })
                        elseif c=='U'then--Long bar start
                            _syntaxCheck(not longBarState[curTrack],"Cannot start a long bar in a long bar")
                            local b={
                                type='bar',
                                track=curTrack,
                                stime=curTime,
                                etime=false,
                                tail=false,
                            }
                            ins(o.noteQueue,b)
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
                    ins(o.noteQueue,{
                        type='hit',
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

    --Reset two pointers
    o.notePtr,o.animePtr=1,1

    return setmetatable(o,{__index=Map})
end

function Map:updateTime(time)
    self.time=time
end

function Map:poll(type)
    if type=='note'then
        local n=self.noteQueue[self.notePtr]
        if n then
            if self.time>n.time-2.6 then
                local queue=self.noteQueue
                self.notePtr=self.notePtr+1
                if not queue[self.notePtr]then self.finished=true end
                return n
            end
        end
    elseif type=='event'then
        local n=self.eventQueue[self.animePtr]
        if n then
            if self.time>n.time-2.6 then
                self.animePtr=self.animePtr+1
                return n
            end
        end
    end
end

return Map