local ins,rem=table.insert,table.remove

local Map={}

local mapInfoKeys={
    "version",
    "mapName",
    "musicAuth",
    "mapAuth",
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
        tracks=4,

        time=0,
        eventQueue={},
        notePtr=0,
        animePtr=0,
    }

    _iter=love.filesystem.lines(file)

    local l=iterator()

    --Read metadata
    while true do
        if l:sub(1,1)=='$'then
            local k=l:sub(2,l:find("=")-1)
            if not TABLE.find(mapInfoKeys,k)then
                error("Invalid map info key: "..l)
            end
            o[k]=l:sub(assert(l:find("="),"Syntax error: need '='")+1)
            l=iterator()
        else
            break
        end
    end

    repeat
        ins(o.eventQueue,l)
        l=iterator()
    until not l

    --Parse notes & animations
    local curTime=2.6
    local curBPM=180
    for i=#o.eventQueue,1,-1 do
        local str=o.eventQueue[i]

        if str:sub(1,1)==':'then
            str=str:sub(2)
            local stamp=STRING.split(str,":")
            if #stamp==2 then
                curTime=tonumber(stamp[1])*60+tonumber(stamp[2])
            else
                error("Wrong Time stamp: "..str:sub(2))
            end
        elseif str:sub(1,1)=='!'then
            curBPM=tonumber(str:sub(2))
        else
            local step=1
            if str:sub(-1)=='|'then
                while str:sub(-1)=='|'do
                    str=str:sub(1,-2)
                    step=step*.5
                end
            elseif str:sub(-1)=='-'then
                while str:sub(-1)=='-'do
                    str=str:sub(1,-2)
                    step=step+1
                end
            end
            for j=1,o.tracks do
                local c=str:sub(j,j)
                if c=='.'or c==' 'then
                    --Do nothing
                elseif c=='X'or c=='O'then
                    ins(o.eventQueue,{
                        type="note",
                        time=curTime,
                        track=j,
                    })
                end
            end
            curTime=curTime+60/curBPM*step
        end
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
        if self.time>n.time-5 then
            repeat
                self.notePtr=self.notePtr+1
            until not self.eventQueue[self.notePtr] or self.eventQueue[self.notePtr].type=='note'
            return n
        end
    end
end

return Map