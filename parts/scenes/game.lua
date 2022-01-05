local gc=love.graphics
local gc_setColor=gc.setColor
local gc_rectangle=gc.rectangle
local gc_draw,gc_printf=gc.draw,gc.printf
local gc_replaceTransform,gc_translate=gc.replaceTransform,gc.translate

local kbIsDown=love.keyboard.isDown

local setFont=setFont
local mStr=mStr

local unpack=unpack
local max,min=math.max,math.min
local sin,cos=math.sin,math.cos

local int,ceil,abs=math.floor,math.ceil,math.abs
local ins,rem=table.insert,table.remove

local SETTING=SETTING

local hitColors=hitColors
local hitTexts=hitTexts
local hitAccList=hitAccList
local hitLVOffsets=hitLVOffsets
local chainColors=chainColors
local trackNames=trackNames
local getHitLV=getHitLV
local function _showVolMes(v)
    needSaveSetting=true
    MES.new('info',('$1%'):repD(('%d'):format(v*100)),0)
end

local needSaveSetting
local autoPlay,autoPlayTextObj
local playSongTime,songLength
local playSpeed
local texts={}

local map,tracks
local hitLV--Hit level (-1~5)
local hitTextTime--Time stamp, for hitText fading-out animation

local time,isSongPlaying
local hitOffests
local curAcc,fullAcc,accText
local combo,maxCombo,score,score0
local hitCount,totalDeviateTime
local bestChain
local hits={}
local touches

local function _updateAcc()
    local acc=int(10000*curAcc/max(fullAcc,1))/100
    accText=("%.2f%%"):format(acc)
end

local function _tryGoResult()
    if not map.finished then return true end
    for i=1,#tracks do if #tracks[i].notes>0 then return true end end
    if needSaveSetting then saveSettings()end
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
    KEY_MAP_inv:_update()
    autoPlay=false
    playSpeed=1
    autoPlayTextObj=autoPlayTextObj or gc.newText(getFont(100),'AUTO')

    map=SCN.args[1]

    playSongTime=map.songOffset+SETTING.musicDelay/1000
    songLength=map.songLength

    texts={
        mapName=gc.newText(getFont(80),map.mapName),
        musicAuth=gc.newText(getFont(40),'Music: '..map.musicAuth),
        mapAuth=gc.newText(getFont(40),'Map: '..map.mapAuth),
    }

    local dirPath=map.qbpFilePath:sub(1,#map.qbpFilePath-map.qbpFilePath:reverse():find("/")+1)
    if love.filesystem.getInfo(dirPath..map.songFile..'.ogg')then
        BGM.load(map.songFile,dirPath..map.songFile..'.ogg')
    end
    BGM.play(map.songFile,'-preLoad')

    BGM.stop()
    if map.songImage then
        local image
        if love.filesystem.getInfo('parts/levels')or love.filesystem.getInfo('songs/'..map.songImage)then
            image=gc.newImage(dirPath..map.songImage)
        end
        if image then
            BG.set('custom')
            BG.send(.1626,image)
        else
            BG.set('none')
        end
    else
        BG.set('none')
    end

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

    needSaveSetting=false

    touches={}

    tracks={}
    for id=1,map.tracks do
        tracks[id]=require'parts.track'.new(id)
        tracks[id]:setDefaultPosition(70*(2*id-map.tracks-1),320)
        tracks[id]:setPosition(nil,nil,true)
        tracks[id]:rename(defaultTrackNames[map.tracks][id])
        tracks[id]:setChordColor(defaultChordColor)
        tracks[id]:setNameTime(2)
    end

    applyFPS(true)
end

function scene.sceneBack()
    BGM.stop()
    applyFPS(false)
    if needSaveSetting then saveSettings()end
end

local function _trigNote(deviateTime,noTailHold)
    hitTextTime=TIME()
    fullAcc=fullAcc+100
    hitLV=getHitLV(deviateTime)
    if hitLV>0 and noTailHold then hitLV=5 end
    bestChain=min(bestChain,hitLV)
    hits[hitLV]=hits[hitLV]+1
    if hitLV>0 then
        curAcc=curAcc+hitAccList[hitLV]
        score0=score0+int(hitLV*(10000+combo)^.5)
        combo=combo+1
        if combo>maxCombo then maxCombo=combo end
        if not noTailHold then
            if abs(deviateTime)>.16 then deviateTime=deviateTime>0 and .16 or -.16 end
            ins(hitOffests,1,deviateTime)
            hitCount=hitCount+1
            totalDeviateTime=totalDeviateTime+deviateTime
            hitOffests[SETTING.dvtCount+1]=nil
        end
    else
        if combo>=10 then SFX.play('combobreak')end
        combo=0
        bestChain=0
    end
    _updateAcc()
end
local function _trackPress(id,auto)
    local deviateTime=tracks[id]:press(auto)
    if not auto and deviateTime then
        _trigNote(deviateTime)
    end
end
local function _trackRelease(id,auto)
    local deviateTime,noTailHold=tracks[id]:release(auto)
    if not auto and deviateTime then
        _trigNote(deviateTime,noTailHold)
    end
end
function scene.keyDown(key,isRep)
    if isRep then return end
    local k=KEY_MAP[key]or key
    if trackNames[k]then
        if autoPlay then return end
        for id=1,map.tracks do
            if tracks[id].name:find(k)then
                _trackPress(id)
            end
        end
    elseif k=='skip'then
        if not isSongPlaying and time<-.8 then
            time=-.8
        else
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
    elseif k=='sfxVolDn'then SETTING.sfx=max(SETTING.sfx-.1,0)SFX.setVol(SETTING.sfx)_showVolMes(SETTING.sfx)
    elseif k=='sfxVolUp'then SETTING.sfx=min(SETTING.sfx+.1,1)SFX.setVol(SETTING.sfx)_showVolMes(SETTING.sfx)
    elseif k=='musicVolDn'then SETTING.bgm=max(SETTING.bgm-.1,0)BGM.setVol(SETTING.bgm)_showVolMes(SETTING.bgm)
    elseif k=='musicVolUp'then SETTING.bgm=min(SETTING.bgm+.1,1)BGM.setVol(SETTING.bgm)_showVolMes(SETTING.bgm)
    elseif k=='dropSpdDn'then
        if score0==0 or curAcc==-1e99 then
            SETTING.dropSpeed=max(SETTING.dropSpeed-1,-8)
            MES.new('info',text.dropSpeedChanged:repD(SETTING.dropSpeed),0)
            needSaveSetting=true
        else
            MES.new('warn',text.cannotAdjustDropSpeed,0)
        end
    elseif k=='dropSpdUp'then
        if score0==0 or curAcc==-1e99 then
            SETTING.dropSpeed=min(SETTING.dropSpeed+1,8)
            MES.new('info',text.dropSpeedChanged:repD(SETTING.dropSpeed),0)
            needSaveSetting=true
        else
            MES.new('warn',text.cannotAdjustDropSpeed,0)
        end
    elseif k=='escape'then
        if _tryGoResult()then
            SCN.back()
        end
    elseif k=='auto'then
        autoPlay=not autoPlay
        if autoPlay then
            curAcc=-1e99
            fullAcc=1e99
            _updateAcc()
        end
    elseif('12345'):find(key,1,true)and kbIsDown('lctrl','rctrl')and kbIsDown('lalt','ralt')then
        playSpeed=
            key=='1'and .25 or
            key=='2'and .5 or
            key=='3'and 1 or
            key=='4'and 8 or
            key=='5'and 32
        if playSpeed<1 then
            curAcc=-1e99
            fullAcc=1e99
            _updateAcc()
        end
        BGM.setPitch(playSpeed)
        BGM.seek(time-playSongTime)
    end
end
function scene.keyUp(key)
    local k=KEY_MAP[key]
    if trackNames[k]then
        if autoPlay then return end
        for id=1,map.tracks do
            if tracks[id].name:find(k)then
                _trackRelease(id)
            end
        end
    end
end

function scene.touchDown(x,y,id)
    local _x,_y=SCR.xOy:transformPoint(x,y)
    if _x<SETTING.safeX*SCR.k or _x>SCR.w-SETTING.safeX*SCR.k or _y<SETTING.safeY*SCR.k or _y>SCR.h-SETTING.safeY*SCR.k then return end

    if autoPlay then return end
    x,y=SCR.xOy_m:inverseTransformPoint(SCR.xOy:transformPoint(x,y))
    local minD2,closestTrackID=1e99,false
    x=x/SETTING.scaleX
    for i=1,#tracks do
        local t=tracks[i]
        if t.state.available then
            local D2=abs(cos(t.state.ang)*(t.state.x-x)-sin(t.state.ang)*(t.state.y-y))
            if D2<minD2 then minD2,closestTrackID=D2,i end
        end
    end
    if closestTrackID then
        ins(touches,{id,closestTrackID})
        _trackPress(closestTrackID)
    end
end
function scene.touchUp(_,_,id)
    if autoPlay then return end
    for i=1,#touches do
        if touches[i][1]==id then
            local allReleased=true
            for j=1,#touches do
                if i~=j and touches[j][2]==touches[i][2]then
                    allReleased=false
                    break
                end
            end
            if allReleased then
                _trackRelease(touches[i][2])
            end
            rem(touches,i)
            return
        end
    end
end
function scene.mouseDown(x,y,k)scene.touchDown(x,y,k)end
function scene.mouseUp(_,_,k)scene.touchUp(_,_,k)end

function scene.update(dt)
    dt=dt*playSpeed

    --Try play bgm
    if not isSongPlaying then
        if time<=playSongTime and time+dt>playSongTime then
            BGM.play(map.songFile,'-sdin -noloop')
            BGM.setPitch(playSpeed)
            BGM.seek(time+dt-playSongTime)
            isSongPlaying=true
        end
    else
        if not BGM.isPlaying()then
            _tryGoResult()
        end
    end

    --Update notes
    time=time+dt
    map:updateTime(time)
    while true do
        local n=map:poll('note')
        if not n then break end
        tracks[n.track]:addItem(n)
    end
    while true do
        local n=map:poll('event')
        if not n then break end
        if n.type=='setTrack'then
            local t=tracks[n.track]
            t[n.operation](t,unpack(n.args))
        elseif n.type=='setChordColor'then
            for i=1,#tracks do
                tracks[i]:setChordColor(n.color)
            end
        end
    end

    --Update tracks (check too-late miss)
    for id=1,map.tracks do
        local t=tracks[id]
        do--Auto play and invalid notes' auto hitting
            local _,note=t:pollNote('note')
            if note and(not note.available or autoPlay)and note.type=='tap'then
                if time>=note.time then
                    _trackPress(id,true)
                    _trackRelease(id,true)
                end
            end
            note=t.notes[1]
            if note and(not note.available or autoPlay)and note.type=='hold'then
                if note.head then
                    if time>=note.time then _trackPress(id,true)end
                else
                    if time>=note.etime then _trackRelease(id,true)end
                end
            end
        end
        t:update(dt)
        local missCount,marvCount=t:updateLogic(time)
        if marvCount>0 then
            for _=1,marvCount do
                _trigNote(0,true)
            end
        end
        if missCount>0 then
            hitTextTime=TIME()
            hitLV=-1
            fullAcc=fullAcc+100*missCount
            _updateAcc()
            if combo>=10 then SFX.play('combobreak')end
            combo=0
            bestChain=0
            hits[-1]=hits[-1]+missCount
        end
    end

    --Update displaying score
    if score<score0 then
        score=score+(score0-score)*dt^.26
    end
end

local SCC={1,1,1}--Super chain color
function scene.draw()
    gc_replaceTransform(SCR.xOy_m)

    --Draw auto mark
    if autoPlay then
        gc_setColor(1,1,1,.126)
        mDraw(autoPlayTextObj,nil,nil,nil,3.55)
    end

    --Draw tracks
    for i=1,map.tracks do
        tracks[i]:draw(map)
    end

    gc_replaceTransform(SCR.xOy)

    --Draw hit text
    if TIME()-hitTextTime<.26 and hitLV<=SETTING.showHitLV then
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
    gc_setColor(1,1,1)gc_rectangle('fill',640-2,350-13,4,30)
    for i=1,5 do
        local c=hitColors[i]
        local d1=hitLVOffsets[i]
        local d2=hitLVOffsets[i+1]
        gc_setColor(c[1]*.8+.3,c[2]*.8+.3,c[3]*.8+.3,.626)
        gc_rectangle('fill',640-d1*688,350,(d1-d2)*688,4)
        gc_rectangle('fill',640+d1*688,350,(d2-d1)*688,4)
    end

    --Draw time
    if time>0 then
        setFont(10)
        gc_setColor(1,1,1)
        gc_rectangle('fill',530,369,220*MATH.interval(time/songLength,0,1),3)
    end

    --Draw deviate times\
    local l=#hitOffests
    for i=1,l do
        local c=hitColors[getHitLV(hitOffests[i])]
        local r=1+(1-i/l)^1.626
        gc_setColor(c[1],c[2],c[3],.2*r)
        gc_rectangle('fill',640+hitOffests[i]*688-1,350-6*r,3,4+12*r)
    end

    --Draw map info at start
    if time<0 then
        local a=3.6-2*abs(time+1.8)
        gc_setColor(1,1,1,a)
        gc_draw(texts.mapName,640,100,nil,min(1200/texts.mapName:getWidth(),1),1,texts.mapName:getWidth()*.5)
        gc_setColor(.7,.7,.7,a)
        mText(texts.musicAuth,640,200)
        mText(texts.mapAuth,640,240)
    end

    gc_setColor(1,1,1)

    gc_replaceTransform(SCR.xOy_ur)
    gc_translate(-SCR.safeX/SCR.k,0)
    --Draw score & accuracy
    setFont(60)gc_printf(ceil(score),-1010,-10,1000,'right')
    setFont(40)gc_printf(accText,-1010,50,1000,'right')

    gc_replaceTransform(SCR.xOy_dr)
    gc_translate(-SCR.safeX/SCR.k,0)
    --Draw map info
    setFont(30)gc_printf(map.mapName,-1010,-45,1000,'right')
    setFont(25)gc_printf(map.mapDifficulty,-1010,-75,1000,'right')

    gc_replaceTransform(SCR.xOy)
end

scene.widgetList={
    WIDGET.newKey{name="restart", x=100,y=60,w=50,fText=CHAR.icon.retry_spin,code=pressKey'restart'},
    WIDGET.newKey{name="pause", x=40,y=60,w=50,fText=CHAR.icon.back,code=backScene},
}
return scene
