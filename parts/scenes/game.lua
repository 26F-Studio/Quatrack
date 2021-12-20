local gc=love.graphics
local gc_setColor=gc.setColor
local gc_rectangle=gc.rectangle
local gc_printf=gc.printf
local gc_replaceTransform=gc.replaceTransform

local kbIsDown=love.keyboard.isDown

local setFont=setFont
local mStr=mStr

local unpack=unpack
local max,min=math.max,math.min
local sin,cos=math.sin,math.cos

local int,abs=math.floor,math.abs
local ins,rem=table.insert,table.remove

local hitColors=hitColors
local hitTexts=hitTexts
local hitAccList=hitAccList
local hitLVOffsets=hitLVOffsets
local chainColors=chainColors

local function _getHitLV(div)
    div=abs(div)
    return
    div<=.02 and 5 or
    div<=.04 and 4 or
    div<=.07 and 3 or
    div<=.10 and 2 or
    div<=.14 and 1 or
    0
end

local playSongTime

local map,tracks
local hitLV--Hit level (-1~5)
local hitTextTime--Time stamp, for hitText fading-out animation

local isSongPlaying
local time,songLength
local hitOffests
local curAcc,fullAcc,accText
local combo,maxCombo,score,score0
local hitCount,totalDeviateTime
local bestChain
local hits={}
local touches

local function _updateAcc()
    accText=("%.2f%%"):format(100*max(curAcc,0)/max(fullAcc,1))
end

local function _tryGoResult()
    for i=1,#tracks do
        if tracks[i].notes[1]then return end
    end
    SCN.swapTo('result',nil,{
        map=map,
        score=score0,
        maxCombo=maxCombo,
        accText=accText,
        averageDeviate=("%.2fms"):format(hitCount>0 and totalDeviateTime/hitCount*1000 or 0),
        hits={
            [-1]=hits[-1],
            [0]=hits[0],
            [1]=hits[1],
            [2]=hits[2],
            [3]=hits[3],
            [4]=hits[4],
            [5]=hits[5],
        },
        bestChain=bestChain,
    })
end

local scene={}

function scene.sceneInit()
    map=SCN.args[1]

    playSongTime=map.songOffset+(SETTING.musicDelay-260)/1000
    songLength=map.songLength
    if love.filesystem.getInfo('parts/levels/'..map.songFile..'.ogg')then
        BGM.load(map.songFile,'parts/levels/'..map.songFile..'.ogg')
    elseif love.filesystem.getInfo('songs/'..map.songFile..'.ogg')then
        BGM.load(map.songFile,'songs/'..map.songFile..'.ogg')
    end
    BGM.play(map.songFile,'-preLoad')

    BGM.stop()
    BG.set('none')

    isSongPlaying=false
    time=-3.6
    hitOffests={}
    curAcc,fullAcc=0,0
    _updateAcc()
    combo,maxCombo,score,score0=0,0,0,0
    hitCount,totalDeviateTime=0,0
    bestChain=5
    for i=-1,5 do hits[i]=0 end

    hitLV,hitTextTime=false,1e-99

    touches={}

    tracks={}
    for id=1,map.tracks do
        tracks[id]=require'parts.track'.new(id)
        tracks[id]:setDefaultPosition(70*(2*id-map.tracks-1),320)
        tracks[id]:setPosition(nil,nil,true)
    end
end

function scene.sceneBack()
    BGM.stop()
end

local function _trigNote(deviateTime,noTailHold)
    hitTextTime=TIME()
    fullAcc=fullAcc+10
    hitLV=_getHitLV(deviateTime)
    if hitLV>0 and noTailHold then hitLV=5 end
    bestChain=min(bestChain,hitLV)
    hits[hitLV]=hits[hitLV]+1
    if hitLV>0 then
        curAcc=curAcc+hitAccList[hitLV]
        score0=score0+int(hitLV*(10000+combo)^.5)
        combo=combo+1
        if combo>maxCombo then
            maxCombo=combo
        end
        if not noTailHold then
            SFX.play('hit')
        end
    else
        if combo>=10 then SFX.play('combobreak')end
        combo=0
        bestChain=0
    end
    _updateAcc()
    if not noTailHold then
        if abs(deviateTime)>.14 then deviateTime=deviateTime>0 and .14 or -.14 end
        ins(hitOffests,1,deviateTime)
        hitCount=hitCount+1
        totalDeviateTime=totalDeviateTime+deviateTime
        hitOffests[27]=nil
    end
end
local function _trackPress(k)
    local deviateTime=tracks[k]:press()
    if deviateTime then _trigNote(deviateTime)end
end
local function _trackRelease(k)
    local deviateTime,noTailHold=tracks[k]:release()
    if deviateTime then _trigNote(deviateTime,noTailHold)end
end
function scene.keyDown(key,isRep)
    if isRep then return end
    local k=KEY_MAP[map.tracks][key]
    if k then
        if type(k)=='number'then
            _trackPress(k)
        elseif k=='skip'then
            if map.finished then
                _tryGoResult()
            end
        elseif k=='restart'then
            local m,errmsg=loadBeatmap(map.qbpFilePath)
            if m then
                SCN.args[1]=m
                BGM.stop('-s')
                scene.sceneInit()
            else
                MES.new('error',errmsg)
            end
        elseif k=='dropSlower'then
            if score0==0 then
                SETTING.dropSpeed=max(SETTING.dropSpeed-1,0)
                MES.new('info',text.dropSpeedChanged:repD(SETTING.dropSpeed-8),0)
            else
                MES.new('warn',text.cannotAdjustDropSpeed,0)
            end
        elseif k=='dropFaster'then
            if score0==0 then
                SETTING.dropSpeed=min(SETTING.dropSpeed+1,16)
                MES.new('info',text.dropSpeedChanged:repD(SETTING.dropSpeed-8),0)
            else
                MES.new('warn',text.cannotAdjustDropSpeed,0)
            end
        end
    elseif key=='escape'then
        SCN.back()
    end
end
function scene.keyUp(key)
    local k=KEY_MAP[map.tracks][key]
    if k then
        if type(k)=='number'then
            _trackRelease(k)
        end
    end
end

function scene.touchDown(x,y,id)
    x,y=SCR.xOy_m:inverseTransformPoint(SCR.xOy:transformPoint(x,y))
    local minD2,closestTrackID=1e99,false
    for i=1,#tracks do
        local D2=abs(cos(tracks[i].state.ang)*(tracks[i].state.x-x)-sin(tracks[i].state.ang)*(tracks[i].state.y-y))
        if D2<minD2 then minD2,closestTrackID=D2,i end
    end
    ins(touches,{id,closestTrackID})
    _trackPress(closestTrackID)
end
function scene.touchUp(_,_,id)
    for i=1,#touches do
        if touches[i][1]==id then
            _trackRelease(touches[i][2])
            rem(touches,i)
            return
        end
    end
end
function scene.mouseDown(x,y,k)scene.touchDown(x,y,k)end
function scene.mouseUp(_,_,k)scene.touchUp(_,_,k)end

function scene.update(dt)
    if kbIsDown'lctrl'and kbIsDown('o','p','[',']')then
        dt=dt*(kbIsDown'o'and .4 or kbIsDown'p'and .75 or kbIsDown'['and 6 or 32)
        if time-dt-playSongTime>0 then
            BGM.seek(time-dt-playSongTime)
        end
    end
    --Try play bgm
    if not isSongPlaying then
        if time<=playSongTime and time+dt>playSongTime then
            BGM.play(map.songFile,'-sdin -noloop')
            BGM.seek(time+dt-playSongTime)
            isSongPlaying=true
        end
    else
        if not BGM.isPlaying()and map.finished then
            _tryGoResult()
        end
    end

    --Update notes
    time=time+dt
    map:updateTime(time)
    while true do
        local n=map:poll('note')
        if not n then break end
        tracks[n.track]:addNote(n)
    end
    while true do
        local n=map:poll('event')
        if not n then break end
        if n.type=='setTrack'then
            local t=tracks[n.track]
            t[n.operation](t,unpack(n.args))
        end
    end

    --Update tracks (check too-late miss)
    for i=1,map.tracks do
        if kbIsDown('tab')then
            local n=tracks[i].notes[1]
            if n then
                if n.type=='tap'then
                    if time>=n.time then
                        _trackPress(i)
                        _trackRelease(i)
                    end
                elseif n.type=='hold'then
                    if not n.pressed then
                        if time>=n.time then _trackPress(i)end
                    else
                        if time>=n.etime then _trackRelease(i)end
                    end
                end
            end
        end
        tracks[i]:update(dt)
        local missCount,marvCount=tracks[i]:updateLogic(time)
        if marvCount>0 then
            for _=1,marvCount do
                _trigNote(0,true)
            end
        end
        if missCount>0 then
            hitTextTime=TIME()
            hitLV=-1
            fullAcc=fullAcc+10*missCount
            _updateAcc()
            if combo>=10 then SFX.play('combobreak')end
            combo=0
            bestChain=0
            hits[-1]=hits[-1]+missCount
        end
    end

    --Update score animation
    if score<score0 then
        score=int(score*.7+score0*.3)
        if score<score0 then score=score+1 end
    end
end

local SCC={1,1,1}
function scene.draw()
    --Draw tracks
    gc_replaceTransform(SCR.xOy_m)
    for i=1,map.tracks do
        tracks[i]:draw(map)
    end

    gc_replaceTransform(SCR.xOy)

    --Draw hit text
    if TIME()-hitTextTime<.26 then
        local c=hitColors[hitLV]
        setFont(80,'mono')
        gc_setColor(c[1],c[2],c[3],2.6-(TIME()-hitTextTime)*10)
        mStr(hitTexts[hitLV],640,245)
    end

    --Draw combo
    if combo>0 then
        setFont(50,'mono')
        if bestChain==5 then
            SCC[3]=(1-time/songLength)^.26
            GC.shadedPrint(combo,640,360,'center',1,chainColors[bestChain],SCC)
        else
            GC.shadedPrint(combo,640,360,'center',1,chainColors[bestChain],COLOR.Z)
        end
    end

    --Draw deviate indicator
    gc_setColor(1,1,1)gc_rectangle('fill',640-1,350-15,2,34)
    for i=1,5 do
        local c=hitColors[i]
        local d=hitLVOffsets[i]
        gc_setColor(c[1]*.8+.3,c[2]*.8+.3,c[3]*.8+.3,.626)
        gc_rectangle('fill',640-d[1]*700,350,(d[1]-d[2])*700,4)
        gc_rectangle('fill',640+d[1]*700,350,(d[2]-d[1])*700,4)
    end

    --Draw deviate times
    for i=1,#hitOffests do
        local c=hitColors[_getHitLV(hitOffests[i])]
        gc_setColor(c[1],c[2],c[3],.4)
        gc_rectangle('fill',640+hitOffests[i]*700-1,350-8,3,20)
    end

    --Draw map info at start
    if time<0 then
        local a=3.6-2*abs(time+1.8)
        setFont(80)
        gc_setColor(1,1,1,a)
        mStr(map.mapName,640,100)
        gc_setColor(.7,.7,.7,a)
        setFont(40)
        mStr(map.musicAuth,640,200)
        mStr(map.mapAuth,640,240)
    end

    --Draw score & accuracy
    gc_replaceTransform(SCR.xOy_ur)
    gc_setColor(1,1,1)
    setFont(60)gc_printf(score,-1010,-10,1000,'right')
    setFont(40)gc_printf(accText,-1010,50,1000,'right')

    --Draw map info
    gc_replaceTransform(SCR.xOy_dr)
    setFont(30)gc_printf(map.mapName,-1010,-55,1000,'right')
    setFont(25)gc_printf(map.mapDifficulty,-1010,-85,1000,'right')

    --Draw progress bar
    gc_replaceTransform(SCR.xOy_dl)
    if time>0 then
        gc_setColor(COLOR.rainbow_light(TIME()*12.6,.8))
        gc_rectangle('fill',0,-10,SCR.w*time/songLength,6)
        local d=time-songLength
        if d>0 then
            gc_setColor(.92,.86,0,min(d,1))
            gc_rectangle('fill',0,-10,SCR.w,6)
        end
    end

    gc_replaceTransform(SCR.xOy)
end

scene.widgetList={
    WIDGET.newKey{name="pause", x=40,y=60,w=50,fText="| |",code=backScene},
}
return scene
