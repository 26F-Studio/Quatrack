local int=math.floor
local ins=table.insert
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
    local curTime=0
    local curBPM=180
    local loopMark
    local loopEnd
    local loopCountDown
    local line=#o.eventQueue
    while line>0 do
        local str=o.eventQueue[line]

        if str:sub(1,1)=='#'then--Annotation
            --Do nothing
        elseif str:sub(1,1)=='!'then--BPM mark
            local bpm=tonumber(str:sub(2))
            assert(type(bpm)=='number'and bpm>0,"Invalid BPM: "..str)
            curBPM=bpm
        elseif str:sub(1,1)==':'then--Time mark
            assert(not loopMark,"Cannot set time in loop")

            str=str:sub(2)
            local stamp=STRING.split(str,":")

            assert(#stamp==2 and type(stamp[1])=='number'and type(stamp[2])=='number',"Wrong Time stamp: "..str:sub(2))

            stamp=tonumber(stamp[1])*60+tonumber(stamp[2])
            assert(stamp>curTime,"Cannot warp to past")

            curTime=stamp
        elseif str:sub(1,1)=='='then--Repeat mark
            local len=0
            repeat
                len=len+1
                str=str:sub(2)
            until str:sub(1,1)~='='
            assert(len>=4 and len<=10,"Invalid repeat mark length: "..len)

            if str:sub(1,1)=='S'then
                assert(not loopMark,"Cannot start another loop in a loop")
                loopMark=line
                if str:sub(2)==''then
                    loopCountDown=1
                else
                    loopCountDown=tonumber(str:sub(2))
                    assert(loopCountDown>=2 and int(loopCountDown)==loopCountDown,"Invalid loop count: "..str:sub(2))
                    loopCountDown=loopCountDown-1
                end
            elseif str=='E'then
                assert(loopMark,"Cannot end a loop without a start")
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
                error("Invalid repeat mark: "..str)
            end
        else--Notes
            local step=1
            if str:sub(-1)=='|'then--Shorten 1/2 for each
                while str:sub(-1)=='|'do
                    str=str:sub(1,-2)
                    step=step*.5
                end
            elseif str:sub(-1)=='~'then--Add 1 for each
                while str:sub(-1)=='~'do
                    str=str:sub(1,-2)
                    step=step+1
                end
            elseif str:find('*')then
                local mul=tonumber(str:sub(str:find('*')+1))
                assert(type(mul)=='number',"Invalid time multiplier: "..str:sub(2))
                str=str:sub(1,str:find('*')-1)
                step=step*mul
            elseif str:find('/')then
                local div=tonumber(str:sub(str:find('/')+1))
                assert(type(div)=='number',"Invalid time divider: "..str:sub(2))
                str=str:sub(1,str:find('/')-1)
                step=step/div
            end
            for n=1,o.tracks do
                local c=str:sub(n,n)
                if c=='-'then
                    --Do nothing
                elseif c=='X'or c=='O'then
                    ins(o.eventQueue,{
                        type="note",
                        time=curTime,
                        track=n,
                    })
                elseif c=='U'then
                    --?
                elseif c=='A'then
                    --?
                elseif c=='H'then
                    --?
                else
                    error("Invalid note character: "..c)
                end
            end
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