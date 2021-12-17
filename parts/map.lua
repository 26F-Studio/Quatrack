local int,rnd=math.floor,math.random
local ins,rem=table.insert,table.remove
local assert=assert

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

local _iter
local function iterator()
    while true do
        local l=_iter()
        if l then
            l=STRING.trim(l)
            if #l>0 then
                return l
            end
        else
            return
        end
    end
end

function Map.new(file)
    local o={
        version="0.1",
        mapName='[mapName]',
        musicAuth='[musicAuth]',
        mapAuth='[mapAuth]',

        songFile="[songFile]",
        songOffset=0,
        tracks=4,

        time=0,
        eventQueue={},
        notePtr=0,
        animePtr=0,
        finished=false,
    }

    _iter=love.filesystem.lines(file)

    local l=iterator()

    --Read metadata
    while true do
        if l:sub(1,1)=='$'then
            local k=l:sub(2,l:find("=")-1)
            assert(TABLE.find(mapInfoKeys,k),"Invalid map info key:7 "..l)
            o[k]=l:sub(assert(l:find("="),"Syntax error: need '='")+1)
            l=iterator()
        else
            break
        end
    end

    if type(o.tracks)=='string'then o.tracks=tonumber(o.tracks)end
    if type(o.songOffset)=='string'then o.songOffset=tonumber(o.songOffset)end

    repeat
        ins(o.eventQueue,l)
        l=iterator()
    until not l

    --Parse notes & animations
    local curTime,curBPM=0,180
    local loopMark,loopEnd,loopCountDown
    local trackState=TABLE.new(0,o.tracks)
    local lastLineState=TABLE.new(false,o.tracks)
    local line=#o.eventQueue
    while line>0 do
        local str=o.eventQueue[line]
        local str0=str--Original string, for error message

        if str:sub(1,1)=='#'then--Annotation
            --Do nothing
        elseif str:sub(1,1)=='!'then--BPM mark
            local bpm=tonumber(str:sub(2))
            assert(type(bpm)=='number'and bpm>0,"[Invalid BPM mark] "..str0)
            curBPM=bpm
        elseif str:sub(1,1)==':'then--Time mark
            assert(not loopMark,"[Cannot set time in loop] "..str0)

            str=str:sub(2)
            local stamp=STRING.split(str,":")

            assert(#stamp==2 and type(stamp[1])=='number'and type(stamp[2])=='number',"[Wrong Time stamp] "..str0)

            stamp=tonumber(stamp[1])*60+tonumber(stamp[2])
            assert(stamp>curTime,"[Cannot warp to past] "..str0)

            curTime=stamp
        elseif str:sub(1,1)=='='then--Repeat mark
            local len=0
            repeat
                len=len+1
                str=str:sub(2)
            until str:sub(1,1)~='='
            assert(len>=4 and len<=10,"[Invalid repeat mark length] "..str0)

            if str:sub(1,1)=='S'then
                assert(not loopMark,"[Cannot start another loop in a loop] "..str0)
                loopMark=line
                if str:sub(2)==''then
                    loopCountDown=1
                else
                    loopCountDown=tonumber(str:sub(2))
                    assert(loopCountDown>=2 and int(loopCountDown)==loopCountDown,"[Invalid loop count] "..str0)
                    loopCountDown=loopCountDown-1
                end
            elseif str=='E'then
                assert(loopMark,"[Cannot end a loop without a start] "..str0)
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
                error("[Invalid repeat mark] "..str0)
            end
        else--Notes
            local readState='note'
            local curLineState=TABLE.new(false,o.tracks)
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
                        --?
                    elseif c=='A'then--Long bar stop
                        --?
                    elseif c=='H'then--Long bar end
                        --?
                    else
                        assert(curTrack==o.tracks+1,"[Bad line: too few notes in one line] "..str0)
                        readState='rnd'
                        goto CONTINUE_nextState
                    end
                    curLineState[curTrack]=true
                    end
                    assert(curTrack<=o.tracks,"[Bad line: too many notes in one line] "..str0)
                    curTrack=curTrack+1
                    str=str:sub(2)
                elseif readState=='rnd'then
                    c=str:sub(1,1)
                    local available={}
                    for i=1,o.tracks do available[i]=i end
                    for i=#available,1,-1 do
                        if curLineState[available[i]]then
                            rem(available,i)
                        end
                    end
                    local ifJack=c==c:upper()
                    for i=#available,1,-1 do if ifJack==lastLineState[available[i]]then rem(available,i)end end
                    c=c:upper()
                    if c=='L'then--Random left
                        for i=#available,1,-1 do
                            if available[i]>=o.tracks*.5 then
                                rem(available,i)
                            end
                        end
                    elseif c=='R'then--Random right
                        for i=#available,1,-1 do
                            if available[i]<=o.tracks*.5 then
                                rem(available,i)
                            end
                        end
                    elseif c=='X'then--Random anywhere
                        --Do nothing
                    else
                        readState='time'
                        goto CONTINUE_nextState
                    end
                    if #available>0 then
                        curTrack=available[rnd(#available)]
                        ins(o.eventQueue,{
                            type="note",
                            time=curTime,
                            track=curTrack,
                        })
                        curLineState[curTrack]=true
                    else
                        error('[Bad line: no available position to place notes] '..str0)
                    end
                    str=str:sub(2)
                elseif readState=='time'then
                    if str:sub(1,1)=='|'then--Shorten 1/2 for each
                        while true do
                            step=step*.5
                            str=str:sub(2)
                            if str==""then
                                break
                            elseif str:sub(1,1)~='|'then
                                error("[Bad line: mixed mark] "..str0)
                            end
                        end
                    elseif str:sub(1,1)=='~'then--Add 1 beat for each
                        while true do
                            step=step+1
                            str=str:sub(2)
                            if str==""then
                                break
                            elseif str:sub(1,1)~='~'then
                                error("[Bad line: mixed mark] "..str0)
                            end
                        end
                    elseif str:sub(1,1)=='*'then--Multiply time by any number
                        local mul=tonumber(str:sub(2))
                        assert(type(mul)=='number',"[Bad line: wrong num] "..str0)
                        step=step*mul
                        break
                    elseif str:sub(1,1)=='/'then--Divide time by any number
                        local div=tonumber(str:sub(2))
                        assert(type(div)=='number',"[Bad line: wrong num] "..str0)
                        step=step/div
                        break
                    elseif str==""then
                        break
                    else
                        error("[Bad line: invalid time mark] "..str0)
                    end
                end
                ::CONTINUE_nextState::
            end
            lastLineState=curLineState
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