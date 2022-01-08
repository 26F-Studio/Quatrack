local Note=require'parts.note'

local int,rnd=math.floor,math.random
local ins,rem=table.insert,table.remove

local Map={}

local mapMetaKeys=mapMetaKeys

local SCline,SCstr
local function _syntaxCheck(cond,msg)
    if not cond then
        error(("[$1] $2: $3"):repD(SCline,SCstr,msg))
    end
end
local function _insert(list,obj)
    local pos=#list
    while pos>0 and list[pos].time>obj.time do
        pos=pos-1
    end
    ins(list,pos+1,obj)
end

function Map.new(file)
    local o=TABLE.copy(mapTemplate)

    o.qbpFilePath=file

    o.time=0
    o.noteQueue={insert=_insert}
    o.eventQueue={insert=_insert}
    o.notePtr=0
    o.animePtr=0
    o.finished=false

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

    --Parse metadata
    SCline=0
    SCstr='[metadata]'
    _syntaxCheck(o.version=='1.0',"Invalid map version")
    if o.songFile then o.songFile=o.songFile:trim()end
    _syntaxCheck(#o.songFile>0,"Invalid $songFile")
    if o.songImage then
        o.songImage=o.songImage:trim()
        _syntaxCheck(#o.songImage>0,"Invalid $songImage")
    end

    if type(o.tracks)=='string'then o.tracks=tonumber(o.tracks)end
    _syntaxCheck(o.tracks,"Invalid $tracks value (need number)")
    if o.realTracks then
        if type(o.realTracks)=='string'then o.realTracks=tonumber(o.realTracks)end
        _syntaxCheck(o.realTracks,"Invalid $realTracks value (need number)")
    end

    if type(o.songOffset)=='string'then
        local unit=1
        if o.songOffset:sub(-2)=='ms'then
            o.songOffset=tonumber(o.songOffset:sub(1,-3))
            unit=0.001
        elseif o.songOffset:sub(-1)=='s'then
            o.songOffset=tonumber(o.songOffset:sub(1,-2))
        elseif o.songOffset:sub(-1)=='m'then
            o.songOffset=tonumber(o.songOffset:sub(1,-2))
            unit=60
        elseif o.songOffset:sub(-1)=='h'then
            o.songOffset=tonumber(o.songOffset:sub(1,-2))
            unit=3600
        else
            o.songOffset=tonumber(o.songOffset)
            _syntaxCheck(o.songOffset==0 or math.abs(o.songOffset)>=1,("Use $songOffset=$1ms is you sure"):repD(o.songOffset))
            unit=0.001
        end
        _syntaxCheck(o.songOffset,"Invalid songOffset")
        o.songOffset=o.songOffset*unit
    end
    if type(o.freeSpeed)=='string'then o.freeSpeed=o.freeSpeed=='true'end

    --Parse notes & animations
    local curTime,curBPM=0,180
    local curBeat,signature=false,false
    local loopStack={}
    local trackDir={}for i=1,o.tracks do trackDir[i]=i end
    local trackAvailable={}for i=1,o.tracks do trackAvailable[i]=true end
    local lastLongBar=TABLE.new(false,o.tracks)
    local lastLineState=TABLE.new(false,o.tracks)
    local noteState={
        color=TABLE.new({{.9},{.9},{.9}},o.tracks),
        alpha=TABLE.new({100},o.tracks),
        xOffset=TABLE.new({0},o.tracks),
        yOffset=TABLE.new({0},o.tracks),
    }
    local line=#fileData
    while line>0 do
        local str=fileData[line][2]

        SCline,SCstr=fileData[line][1],str--For assertion

        if str:sub(1,1)=='!'then--BPM mark
            local data=str:sub(2):split(',')
            _syntaxCheck(data[1],"Need BPM mark")
            _syntaxCheck(#data<=2,"Too many arguments")
            local bpmStr,signStr=data[1],data[2]
            if bpmStr=='+'then
                local bpm_add=tonumber(bpmStr:sub(2))
                _syntaxCheck(type(bpm_add)=='number',"Invalid BPM mark")
                curBPM=curBPM+bpm_add
            elseif bpmStr=='-'then
                local bpm_sub=tonumber(bpmStr:sub(2))
                _syntaxCheck(type(bpm_sub)=='number',"Invalid BPM mark")
                _syntaxCheck(bpm_sub<curBPM,"Decrease BPM too much")
                curBPM=curBPM-bpm_sub
            else
                local bpm=tonumber(bpmStr)
                _syntaxCheck(type(bpm)=='number'and bpm>0,"Invalid BPM mark")
                curBPM=bpm
            end
            if signStr then
                local sign=tonumber(signStr)
                _syntaxCheck(type(sign)=='number'and sign>0 and sign%1==0,"Invalid time signature")
                curBeat,signature=0,sign
            else
                curBeat=false
                signature=false
            end
        elseif str:sub(1,1)=='+'then--Bar separator
            local len=0
            repeat
                len=len+1
                str=str:sub(2)
            until str:sub(1,1)~='+'
            _syntaxCheck(len>=4 and len<=10,"Invalid bar mark length")
            if curBeat then
                _syntaxCheck(int(curBeat*2048+.5)/2048%signature==0,"Unfinished bar")
            else
                _syntaxCheck(signature,"No signature to check")
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
        elseif str:sub(1,1)=='>'then--Time mark
            _syntaxCheck(not loopStack[1],"Cannot set time in loop")
            if str:sub(2)=='start'then
                curTime=-3.6
            else
                str=str:sub(2)

                local sign
                if str:sub(1,1)=='+'then
                    sign='+'
                    str=str:sub(2)
                elseif str:sub(1,1)=='-'then
                    sign='-'
                    str=str:sub(2)
                else
                    sign=''
                end

                local dt
                if str:find(':')then
                    local time=str:split(':')
                    time[1]=tonumber(time[1])
                    time[2]=tonumber(time[2])
                    _syntaxCheck(time[1]and time[2],"Invalid time mark")
                    dt=time[1]*60+time[2]
                else
                    local unit
                    if str:sub(-1)=='s'then
                        str,unit=str:sub(1,-2),1
                    elseif str:sub(-2)=='ms'then
                        str,unit=str:sub(1,-3),0.001
                    elseif str:sub(-4)=='beat'then
                        str,unit=str:sub(1,-5),60/curBPM
                    elseif str:sub(-3)=='bar'then
                        _syntaxCheck(signature,"No signature to calculate bar length")
                        str,unit=str:sub(1,-4),60/curBPM*signature
                    else--Unit default to beat
                        unit=60/curBPM
                    end
                    dt=tonumber(str)
                    _syntaxCheck(dt,"Invalid time mark")
                    dt=dt*unit
                end

                if sign==''then
                    curTime=dt
                elseif sign=='+'then
                    curTime=curTime+dt
                elseif sign=='-'then
                    curTime=curTime-dt
                end
            end
        elseif str:sub(1,1)=='['then--Animation: set track states
            local t=str:find(']')
            _syntaxCheck(t,"Syntax error (need ']')")

            local trackList={}

            local trackStr=str:sub(2,t-1)
            if trackStr=='A'or trackStr=='L'or trackStr=='R'then
                local i,j
                if trackStr=='A'then
                    i,j=1,o.tracks
                elseif trackStr=='L'then
                    i,j=1,(o.tracks+1)*.5
                elseif trackStr=='R'then
                    i,j=o.tracks*.5+1,o.tracks
                end
                for n=0,j-i do
                    trackList[n+1]=i+n
                end
            else
                trackList=trackStr:split(',')
                for i=1,#trackList do
                    local id=tonumber(trackList[i])
                    _syntaxCheck(id and id>0 and id<=o.tracks,"Invalid track id")
                    trackList[i]=id
                end
            end
            str=str:sub(t+1)

            local animData
            if str:sub(1,1)=='<'then
                local t2=str:find('>')
                _syntaxCheck(t2,"Syntax error (need '>')")
                local animList=str:sub(2,t2-1):split(',')

                str=str:sub(t2+1)

                local animType=rem(animList,1)
                _syntaxCheck(animType,"Need animation type (S/L/E/C)")
                if animType=='S'then
                    _syntaxCheck(#animList==0,"Invalid animation data")
                    animData={type='S'}
                elseif animType=='L'then
                    _syntaxCheck(#animList==1,"Invalid animation data (need time)")
                    local s=animList[1]
                    local unit
                    if s:sub(-1)=='s'then
                        s,unit=s:sub(1,-2),1
                    elseif s:sub(-2)=='ms'then
                        s,unit=s:sub(1,-3),0.001
                    elseif s:sub(-4)=='beat'then
                        s,unit=s:sub(1,-5),60/curBPM
                    elseif s:sub(-3)=='bar'then
                        _syntaxCheck(signature,"No signature to calculate bar length")
                        s,unit=s:sub(1,-4),60/curBPM*signature
                    else--Unit default to beat
                        unit=60/curBPM
                    end
                    s=tonumber(s)
                    _syntaxCheck(s and s>0,"Invalid animation time ([number]ms/s/beat)")
                    s=s*unit
                    animData={type='L',start=curTime,duration=s}
                elseif animType=='E'then
                    _syntaxCheck(#animList==1,"Invalid animation data (need speed)")
                    local s=tonumber(animList[1])
                    _syntaxCheck(s and s>0,"Invalid expontial param")
                    animData={type='E',start=curTime,speed=s}
                elseif animType=='C'then
                    _syntaxCheck(false,"Coming soon")
                    animData={type='C'}
                else
                    _syntaxCheck(false,"Invalid animation type (need S/L/E/C)")
                end
            else
                animData={type='E',start=curTime,speed=12}
            end

            local data=str:split(',')
            local op=data[1]:upper()
            local opType=data[1]==data[1]:upper()and'set'or'move'

            local event
            if op=='P'then--Position
                _syntaxCheck(#data<=3,"Too many arguments")
                data[2]=tonumber(data[2])or false
                data[3]=tonumber(data[3])or false
                event={
                    type='setTrack',
                    time=curTime,
                    operation=opType..'Position',
                    args={animData,data[2],data[3]},
                }
            elseif op=='R'then--Rotate
                _syntaxCheck(#data<=2,"Too many arguments")
                data[2]=tonumber(data[2])or false
                event={
                    type='setTrack',
                    time=curTime,
                    operation=opType..'Angle',
                    args={animData,data[2]},
                }
            elseif op=='S'then--Size
                _syntaxCheck(#data<=3,"Too many arguments")
                data[2]=tonumber(data[2])or false
                data[3]=tonumber(data[3])or false
                event={
                    type='setTrack',
                    time=curTime,
                    operation=opType..'Size',
                    args={animData,data[2],data[3]},
                }
            elseif op=='D'then--Drop speed
                _syntaxCheck(#data<=2,"Too many arguments")
                data[2]=tonumber(data[2])or false
                event={
                    type='setTrack',
                    time=curTime,
                    operation=opType..'DropSpeed',
                    args={animData,data[2]},
                }
            elseif op=='T'then--Transparent
                _syntaxCheck(#data<=2,"Too many arguments")
                data[2]=tonumber(data[2])or false
                event={
                    type='setTrack',
                    time=curTime,
                    operation=opType..'Alpha',
                    args={animData,data[2]},
                }
            elseif op=='C'then--Color
                _syntaxCheck(#data<=2,"Too many arguments")
                local r,g,b
                if not data[2]then
                    _syntaxCheck(#data==2,"Invalid color")
                    r,g,b=1,1,1
                else
                    local neg
                    if data[2]:sub(1,1)=='-'then
                        neg=true
                        data[2]=data[2]:sub(2)
                    end
                    _syntaxCheck(not data[2]:find("[^0-9a-fA-F]")and #data[2]<=6,"Invalid color code")
                    r,g,b=STRING.hexColor(data[2])
                    if neg then
                        r,g,b=-r,-g,-b
                    end
                end
                event={
                    type='setTrack',
                    time=curTime,
                    operation=opType..'Color',
                    args={animData,r,g,b},
                }
            elseif op=='A'then--Available
                if data[2]=='true'then
                    data[2]=true
                elseif data[2]=='false'then
                    data[2]=false
                end
                if opType=='set'then
                    if data[2]==nil then data[2]=true end
                    _syntaxCheck(#data<=2,"Too many arguments")
                    _syntaxCheck(data[2]==true or data[2]==false,"Invalid option (need true/false)")
                    for i=1,#trackList do
                        trackAvailable[trackList[i]]=data[2]
                    end
                elseif opType=='move'then
                    _syntaxCheck(#data<=1,"Too many arguments")
                    for i=1,#trackList do
                        trackAvailable[trackList[i]]=not trackAvailable[trackList[i]]
                    end
                end
                event={
                    type='setTrack',
                    time=curTime,
                    operation=opType..'Available',
                    args={data[2]},
                }
            elseif op=='N'then--Show track name
                local time=tonumber(data[2])
                _syntaxCheck(time and time>0,"Invalid time")
                event={
                    type='setTrack',
                    time=curTime,
                    operation='setNameTime',
                    args={time},
                }
            else
                _syntaxCheck(false,"Invalid track operation")
            end
            for i=1,#trackList do
                local E=TABLE.copy(event)
                E.track=trackList[i]
                o.eventQueue:insert(E)
            end
        elseif str:sub(1,1)=='('then--Note state: color & alpha
            local t=str:find(')')
            _syntaxCheck(t,"Syntax error (need ')')")

            local trackList={}

            local trackStr=str:sub(2,t-1)
            if trackStr=='A'or trackStr=='L'or trackStr=='R'then
                local i,j
                if trackStr=='A'then
                    i,j=1,o.tracks
                elseif trackStr=='L'then
                    i,j=1,(o.tracks+1)*.5
                elseif trackStr=='R'then
                    i,j=o.tracks*.5+1,o.tracks
                end
                for n=0,j-i do
                    trackList[n+1]=i+n
                end
            else
                trackList=trackStr:split(',')
                for i=1,#trackList do
                    local id=tonumber(trackList[i])
                    _syntaxCheck(id and id>0 and id<=o.tracks,"Invalid track id")
                    trackList[i]=id
                end
            end

            local data=str:sub(t+1):split(',')
            local op=data[1]:upper()
            if op=='T'then--Transparent
                local a={}
                if data[2]then
                    for i=2,#data do
                        local alpha=tonumber(data[i])
                        _syntaxCheck(alpha and alpha>=0 and alpha<=100,"Invalid alpha value")
                        a[i-1]=alpha
                    end
                else
                    a[1]=80
                end
                for i=1,#trackList do
                    noteState.alpha[trackList[i]]=a
                end
            elseif op=='C'then--Color
                local codes={}
                if not data[2]then
                    codes[1]='E6E6E6'
                else
                    for i=2,#data do
                        local code=data[i]
                        _syntaxCheck(not code:find("[^0-9a-fA-F]")and #code<=6,"Invalid color code")
                        codes[i-1]=code
                    end
                end
                local color={{},{},{}}
                for i=1,#codes do
                    color[1][i],color[2][i],color[3][i]=STRING.hexColor(codes[i])
                end
                for i=1,#trackList do
                    noteState.color[trackList[i]]=color
                end
            elseif op=='X'or op=='Y'then--X/Y offset
                local offset={}
                if data[2]then
                    for i=2,#data do
                        data[i]=tonumber(data[i])
                        _syntaxCheck(data[i],"Invalid alpha value")
                        offset[i-1]=data[i]
                    end
                else
                    offset[1]=0
                end
                local state=op=='X'and noteState.xOffset or noteState.yOffset
                for i=1,#trackList do
                    state[trackList[i]]=offset
                end
            else
                _syntaxCheck(false,"Invalid note operation")
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
        elseif str:sub(1,1)=='^'then--Set chord color
            local c=str:sub(2):split(',')
            if #c==0 then
                c=defaultChordColor
            else
                for i=1,#c do
                    _syntaxCheck(not c[i]:find("[^0-9a-fA-F]")and #c[i]<=6,"Invalid color code")
                    c[i]={STRING.hexColor(c[i])}
                end
                if #c>o.tracks-1 then _syntaxCheck(false,"Too many colors")end
                setmetatable(c,getmetatable(defaultChordColor))
            end
            o.eventQueue:insert{
                type='setChordColor',
                time=curTime,
                color=c,
            }
        elseif str:sub(1,1)=='%'then--Rename tracks
            local nameList=str:sub(2):split(',')
            _syntaxCheck(#nameList==o.tracks,"Track names not match track count")
            for id=1,#nameList do
                local name=nameList[id]
                if name:find(' ')then
                    local multiNameList=name:split(' ')
                    for i=1,#multiNameList do
                        _syntaxCheck(trackNames[multiNameList[i]],"Invalid track name")
                    end
                else
                    _syntaxCheck(name=='x'or trackNames[name],"Invalid track name")
                end
                o.eventQueue:insert{
                    type='setTrack',
                    time=curTime,
                    track=id,
                    operation='rename',
                    args={name},
                }
                if name=='x'then
                    o.eventQueue:insert{
                        type='setTrack',
                        time=curTime,
                        track=id,
                        operation='setAvailable',
                        args={},
                    }
                    trackAvailable[id]=false
                end
            end
        else--Notes
            local readState='note'
            local lastNote=TABLE.new(false,o.tracks)
            local curTrack=1
            local step=1

            local c
            while true do
                if readState=='note'then
                    c=str:sub(1,1)
                    if c~='-'then--Space
                        if c=='O'then--Tap note
                            local b={
                                type='tap',
                                time=curTime,
                                track=trackDir[curTrack],
                                available=trackAvailable[trackDir[curTrack]],
                                color=noteState.color[curTrack],
                                alpha=noteState.alpha[curTrack],
                                xOffset=noteState.xOffset[curTrack],
                                yOffset=noteState.yOffset[curTrack],
                            }
                            o.noteQueue:insert(b)
                            lastNote[curTrack]=b
                        elseif c=='U'then--Hold note start
                            _syntaxCheck(not lastLongBar[curTrack],"Cannot start a long bar in a long bar")
                            local b={
                                type='hold',
                                track=trackDir[curTrack],
                                available=trackAvailable[trackDir[curTrack]],
                                time=curTime,
                                etime=false,
                                head=true,
                                tail=false,
                                color=noteState.color[curTrack],
                                alpha=noteState.alpha[curTrack],
                                xOffset=noteState.xOffset[curTrack],
                                yOffset=noteState.yOffset[curTrack],
                            }
                            o.noteQueue:insert(b)
                            lastLongBar[curTrack]=b
                            lastNote[curTrack]=b
                        elseif c=='A'or c=='H'then--Long bar stop
                            _syntaxCheck(lastLongBar[curTrack],"No long bar to stop")
                            if c=='A'then
                                lastNote[curTrack]=lastLongBar[curTrack]
                            end
                            lastLongBar[curTrack].etime=curTime
                            lastLongBar[curTrack].tail=c=='A'
                            lastLongBar[curTrack]=false
                        else
                            _syntaxCheck(curTrack==o.tracks+1,"Too few notes in one line")
                            readState='rnd'
                            goto CONTINUE_nextState
                        end
                    end
                    _syntaxCheck(curTrack<=o.tracks,"Too many notes in one line")
                    curTrack=curTrack+1
                    str=str:sub(2)
                elseif readState=='rnd'then
                    c=str:sub(1,1)
                    local noJack=c==c:upper()
                    c=c:upper()

                    if not(c=='L'or c=='R'or c=='X')then
                        readState='time'
                        goto CONTINUE_nextState
                    end

                    local available={}
                    for i=1,o.tracks do available[i]=i end
                    for i=#available,1,-1 do
                        if lastNote[available[i]]then
                            rem(available,i)
                        end
                    end

                    for i=#available,1,-1 do if not noJack==not lastLineState[available[i]]then rem(available,i)end end

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
                    end
                    _syntaxCheck(#available>0,"No space to place notes")
                    curTrack=available[rnd(#available)]

                    local b={
                        type='tap',
                        time=curTime,
                        track=trackDir[curTrack],
                        available=trackAvailable[trackDir[curTrack]],
                        color=noteState.color[curTrack],
                        alpha=noteState.alpha[curTrack],
                        xOffset=noteState.xOffset[curTrack],
                        yOffset=noteState.yOffset[curTrack],
                    }
                    o.noteQueue:insert(b)
                    lastNote[curTrack]=b
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
                        _syntaxCheck(type(mul)=='number',"Invalid scale num")
                        step=step*mul
                        break
                    elseif str:sub(1,1)=='/'then--Divide time by any number
                        local div=tonumber(str:sub(2))
                        _syntaxCheck(type(div)=='number',"Invalid scale num")
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

            local chordCount=0
            for i=1,o.tracks do
                if lastNote[i]and lastNote[i].available then
                    chordCount=chordCount+1
                end
            end
            for i=1,o.tracks do
                if lastNote[i]then
                    local n=lastNote[i]
                    if n.type=='tap'then
                        n.chordCount=chordCount
                    elseif n.type=='hold'then
                        if n.etime then
                            n.chordCount_tail=chordCount
                        else
                            n.chordCount_head=chordCount
                        end
                    end
                end
            end
            lastLineState=lastNote
            o.songLength=curTime
            curTime=curTime+60/curBPM*step
            if curBeat then
                curBeat=curBeat+step
            end
        end
        line=line-1
    end

    for i=1,#lastLongBar do
        _syntaxCheck(not lastLongBar[i],("Long bar not ended (Track $1)"):repD(i))
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