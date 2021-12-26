local Note=require'parts.note'

local rnd=math.random
local ins,rem=table.insert,table.remove

local Map={}

local mapMetaKeys=mapMetaKeys

local SCline,SCstr
local function _syntaxCheck(cond,msg)
    if not cond then
        error(("[$1] $2: $3"):repD(SCline,SCstr,msg))
    end
end

function Map.new(file)
    local o={
        version="1.0",
        mapName='[mapName]',
        musicAuth='[musicAuth]',
        mapAuth='[mapAuth]',
        mapDifficulty='[mapDifficulty]',

        songFile="[songFile]",
        songOffset=0,
        tracks=4,
        freeSpeed=true,

        valid=nil,
        qbpFilePath=file,
        songLength=nil,

        time=0,
        noteQueue={},
        eventQueue={},
        notePtr=0,
        animePtr=0,
        finished=false,
    }
    if file then
        o.valid=true
    else
        o.valid=false
        return setmetatable(o,{__index=Map})
    end

    --Read file
    local fileData={}do
        local lineNum=1
        for l in love.filesystem.lines(file)do
            l=l:trim()
            if l:find(';')then
                l=l:split(';')
                for i=1,#l do
                    l[i]=l[i]:trim()
                    if l[i]~=''and l[i]:sub(1,1)~='#'then
                        ins(fileData,{lineNum,l[i]})
                    end
                end
            else
                l=l:trim()
                if l~=''and l:sub(1,1)~='#'then
                    ins(fileData,{lineNum,l})
                end
            end
            lineNum=lineNum+1
        end
    end

    --Load metadata
    while true do
        local str=fileData[1][2]
        SCline,SCstr=fileData[1][1],str
        if str:sub(1,1)=='$'then
            local k=str:sub(2,str:find('=')-1)
            _syntaxCheck(TABLE.find(mapMetaKeys,k),"Invalid map info key '"..k.."'")
            _syntaxCheck(str:find('='),"Syntax error (need '=')")
            o[k]=str:sub(str:find('=')+1)
            rem(fileData,1)
        else
            break
        end
    end

    --Parse non-string metadata
    if type(o.tracks)=='string'then o.tracks=tonumber(o.tracks)end
    if type(o.songOffset)=='string'then o.songOffset=tonumber(o.songOffset)end
    if type(o.freeSpeed)=='string'then o.freeSpeed=o.freeSpeed=='true'end

    --Parse notes & animations
    local curTime,curBPM=0,180
    local loopStack={}
    local longBarState=TABLE.new(false,o.tracks)
    local lastLineState=TABLE.new(false,o.tracks)
    local trackDir={}for i=1,o.tracks do trackDir[i]=i end
    local line=#fileData
    while line>0 do
        local str=fileData[line][2]

        SCline,SCstr=fileData[line][1],str--For assertion

        if str:sub(1,1)=='!'then--BPM mark
            if str:sub(2,2)=='+'or str:sub(2,2)=='-'then
                local bpm_add=str:sub(3)
                _syntaxCheck(type(bpm_add)=='number',"Invalid BPM mark")
                curBPM=curBPM+bpm_add
            elseif str:sub(2,2)=='-'then
                local bpm_sub=str:sub(3)
                _syntaxCheck(type(bpm_sub)=='number',"Invalid BPM mark")
                _syntaxCheck(bpm_sub<curBPM,"Decrease BPM too much")
                curBPM=curBPM-bpm_sub
            else
                local bpm=tonumber(str:sub(2))
                _syntaxCheck(type(bpm)=='number'and bpm>0,"Invalid BPM mark")
                curBPM=bpm
            end
        elseif str:sub(1,1)=='@'then--Random seed mark
            if str:sub(2)==''then
                math.randomseed(love.timer.getTime())
            else
                local seedList=str:sub(2):split(',')
                for i=1,#seedList do
                    _syntaxCheck(tonumber(seedList[i]),"Invalid seed number")
                end
                math.randomseed(love.timer.getTime())
                math.randomseed(260000+seedList[rnd(#seedList)])--Too small number make randomizer not that random
            end
        elseif str:sub(1,1)==':'then--Time mark
            _syntaxCheck(not loopStack[1],"Cannot set time in loop")

            local stamp=str:sub(2):split(":")
            if #stamp==1 then ins(stamp,1,"0")end
            for i=1,2 do
                stamp[i]=tonumber(stamp[i])
                _syntaxCheck(type(stamp[i])=='number'and stamp[i]>=0,"Invalid time mark")
            end
            stamp=stamp[1]*60+stamp[2]
            _syntaxCheck(stamp>curTime,"Cannot warp to past")

            curTime=stamp
        elseif str:sub(1,1)=='['then--Animation: set track states
            local t=str:find(']')
            _syntaxCheck(t,"Syntax error (need ']')")

            id=str:sub(2,t-1)
            if not(id=='A'or id=='L'or id=='R')then
                id=tonumber(id)
                _syntaxCheck(id and id%1==0 and id>=1 and id<=o.tracks,"Wrong track ID")
            end

            local data=str:sub(t+1):split(",")
            local op=data[1]:upper()
            local opType=data[1]==data[1]:upper()and'set'or'move'

            local event
            if op=='P'then--Position
                _syntaxCheck(#data<=3,"Too many arguments")
                data[2]=tonumber(data[2])
                data[3]=tonumber(data[3])
                event={
                    type="setTrack",
                    time=curTime,
                    track=id,
                    operation=opType.."Position",
                    args={data[2],data[3],false},
                }
            elseif op=='R'then--Rotate
                _syntaxCheck(#data<=2,"Too many arguments")
                data[2]=tonumber(data[2])
                event={
                    type="setTrack",
                    time=curTime,
                    track=id,
                    operation=opType.."Angle",
                    args={data[2],false},
                }
            elseif op=='S'then--Size
                _syntaxCheck(#data<=3,"Too many arguments")
                data[2]=tonumber(data[2])
                data[3]=tonumber(data[3])
                event={
                    type="setTrack",
                    time=curTime,
                    track=id,
                    operation=opType.."Size",
                    args={data[2],data[3],false},
                }
            elseif op=='D'then--Drop speed
                _syntaxCheck(#data<=2,"Too many arguments")
                data[2]=tonumber(data[2])
                event={
                    type="setTrack",
                    time=curTime,
                    track=id,
                    operation=opType.."DropSpeed",
                    args={data[2],false},
                }
            elseif op=='T'then--Transparent
                _syntaxCheck(#data<=2,"Too many arguments")
                data[2]=tonumber(data[2])
                event={
                    type="setTrack",
                    time=curTime,
                    track=id,
                    operation=opType.."Alpha",
                    args={data[2],false},
                }
            elseif op=='C'then--Color
                _syntaxCheck(#data<=2,"Too many arguments")
                local r,g,b
                if data[2]==''then
                    r,g,b=1,1,1
                else
                    local neg
                    if data[2]:sub(1,1)=='-'then
                        neg=true
                        data[2]=data[2]:sub(2)
                    end
                    _syntaxCheck(not data[2]:find("[^0-9a-fA-F]")and #data[2]<=6,"Wrong color code")
                    r,g,b=STRING.hexColor(data[2])
                    if neg then
                        r,g,b=-r,-g,-b
                    end
                end
                event={
                    type="setTrack",
                    time=curTime,
                    track=id,
                    operation=opType.."Color",
                    args={r,g,b,false},
                }
            elseif op=='A'then--Available
                _syntaxCheck(opType=='set'and #data<=2 or opType=='move'and #data<=2,"Too many arguments")
                _syntaxCheck(data[2]=='true'or data[2]=='false',"Invalid option (need true/false)")
                data[2]=data[2]=='true'
                event={
                    type="setTrack",
                    time=curTime,
                    track=id,
                    operation=opType.."Available",
                    args={data[2],false},
                }
            else
                _syntaxCheck(false,"Invalid track operation")
            end
            if id=='A'or id=='L'or id=='R'then
                local i,j
                if id=='A'then
                    i,j=1,o.tracks
                elseif id=='L'then
                    i,j=1,(o.tracks+1)*.5
                elseif id=='R'then
                    i,j=o.tracks*.5+1,o.tracks
                end
                for k=i,j do
                    local E=TABLE.copy(event)
                    E.track=k
                    ins(o.eventQueue,E)
                end
            else
                ins(o.eventQueue,event)
            end
        elseif str:sub(1,1)=='='then--Repeat mark
            local len=0
            repeat
                len=len+1
                str=str:sub(2)
            until str:sub(1,1)~='='
            _syntaxCheck(len>=4 and len<=10,"Invalid repeat mark length")

            if str:sub(1,1)=='S'then
                local cd=1
                if str:sub(2)~=''then
                    cd=tonumber(str:sub(2))
                    _syntaxCheck(cd>=2 and cd%1==0,"Invalid loop count")
                    cd=cd-1
                end
                ins(loopStack,{
                    countDown=cd,
                    startMark=line,
                    endMark=false,
                })
            elseif str=='E'then
                _syntaxCheck(loopStack[1],"No loop to end")
                local curState=loopStack[#loopStack]
                if curState.countDown>0 then
                    curState.endMark=line
                    curState.countDown=curState.countDown-1
                    line=curState.startMark
                else
                    rem(loopStack)
                end
            elseif str=='M'then
                _syntaxCheck(loopStack[1],"No loop to break")
                if loopStack[#loopStack].countDown==0 then
                    line=loopStack[#loopStack].endMark
                    rem(loopStack)
                end
            else
                _syntaxCheck(false,"Invalid repeat mark")
            end
        elseif str:sub(1,1)=='&'then--Redirect notes to different track
            if str:sub(2)==''then--Reset
                for i=1,o.tracks do trackDir[i]=i end
            elseif str:sub(2)=='A'then--Random shuffle (won't reset to 1~N!)
                local l={}
                for i=1,o.tracks do l[i]=trackDir[i]end
                for i=1,o.tracks do trackDir[i]=rem(l,rnd(#l))end
            else--Redirect tracks from presets
                local argList=str:sub(2):split(',')
                for i=1,#argList do
                    _syntaxCheck(#argList[i]==o.tracks,"Illegal redirection (track count)")
                    _syntaxCheck(not argList[i]:find('[^1-9a-zA-Z]'),"Illegal redirection (track number)")
                end
                local reDirMethod=argList[rnd(#argList)]
                local l=TABLE.shift(trackDir)
                for i=1,o.tracks do
                    local id=tonumber(reDirMethod:sub(i,i),36)
                    _syntaxCheck(id<=o.tracks,"Illegal redirection (too large track number)")
                    trackDir[i]=l[id]
                end
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
                        if c=='O'then--Tap note
                            ins(o.noteQueue,{
                                type='tap',
                                time=curTime,
                                track=trackDir[curTrack],
                            })
                        elseif c=='U'then--Hold note start
                            _syntaxCheck(not longBarState[curTrack],"Cannot start a long bar in a long bar")
                            local b={
                                type='hold',
                                track=trackDir[curTrack],
                                time=curTime,
                                etime=false,
                                head=true,
                                tail=false,
                            }
                            ins(o.noteQueue,b)
                            longBarState[curTrack]=b
                        elseif c=='A'or c=='H'then--Long bar stop
                            _syntaxCheck(longBarState[curTrack],"No long bar to stop")
                            longBarState[curTrack].etime=curTime
                            longBarState[curTrack].tail=c=='A'
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
                        type='tap',
                        time=curTime,
                        track=trackDir[curTrack],
                    })
                    trackUsed[curTrack]=true
                    str=str:sub(2)
                elseif readState=='time'then
                    if str:sub(1,1)=='|'then--Shorten 1/2 for each
                        while true do
                            step=step*.5
                            str=str:sub(2)
                            if str==''then
                                break
                            else
                                _syntaxCheck(str:sub(1,1)=='|',"Mixed mark")
                            end
                        end
                    elseif str:sub(1,1)=='~'then--Add 1 beat for each
                        while true do
                            step=step+1
                            str=str:sub(2)
                            if str==''then
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
                    elseif str==''then
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

    for i=1,#longBarState do
        _syntaxCheck(not longBarState[i],("Long bar not ended (Track $1)"):repD(i))
    end

    --Reset two pointers
    o.notePtr,o.animePtr=1,1

    local lastNote=o.noteQueue[#o.noteQueue]
    if lastNote.type=='tap'then
        o.songLength=lastNote.time
    elseif lastNote.type=='hold'then
        o.songLength=lastNote.etime
    end

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
                return Note.new(n)
            end
        end
    elseif type=='event'then
        local n=self.eventQueue[self.animePtr]
        if n then
            if self.time>n.time then
                self.animePtr=self.animePtr+1
                return n
            end
        end
    end
end

return Map