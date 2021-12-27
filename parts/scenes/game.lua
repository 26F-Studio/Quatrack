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

local hitColors=hitColors
local hitTexts=hitTexts
local hitAccList=hitAccList
local hitLVOffsets=hitLVOffsets
local chainColors=chainColors
local trackNames=trackNames

local needSaveDropSpeed

local function _getHitLV(div)
    div=abs(div)
    return
    div<=hitLVOffsets[5]and 5 or
    div<=hitLVOffsets[4]and 4 or
    div<=hitLVOffsets[3]and 3 or
    div<=hitLVOffsets[2]and 2 or
    div<=hitLVOffsets[1]and 1 or
    0
end

local autoPlay
local playSongTime,songLength
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
    for i=1,#tracks do
        if #tracks[i].notes>0 then return end
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
    autoPlay=false

    map=SCN.args[1]

    playSongTime=map.songOffset+SETTING.musicDelay/1000
    songLength=map.songLength

    texts={
        mapName=gc.newText(getFont(80),map.mapName),
        musicAuth=gc.newText(getFont(40),'Music: '..map.musicAuth),
        mapAuth=gc.newText(getFont(40),'Map: '..map.mapAuth),
    }

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

    needSaveDropSpeed=false

    touches={}

    tracks={}
    for id=1,map.tracks do
        tracks[id]=require'parts.track'.new(id)
        tracks[id]:setDefaultPosition(70*(2*id-map.tracks-1),320)
        tracks[id]:setPosition(nil,nil,true)
        tracks[id]:rename(defaultTrackNames[map.tracks][id])
    end

    applyFPS(true)
end

function scene.sceneBack()
    BGM.stop()
    applyFPS(false)
end

local function _trigNote(deviateTime,track,noTailHold)
    hitTextTime=TIME()
    fullAcc=fullAcc+100
    hitLV=_getHitLV(deviateTime)
    if hitLV>0 and noTailHold then hitLV=5 end
    bestChain=min(bestChain,hitLV)
    hits[hitLV]=hits[hitLV]+1
    if hitLV>0 then
        curAcc=curAcc+hitAccList[hitLV]
        score0=score0+int(hitLV*(10000+combo)^.5)
        if needSaveDropSpeed then
            saveSettings()
            needSaveDropSpeed=false
        end
        combo=combo+1
        if combo>maxCombo then maxCombo=combo end
        if not noTailHold then
            if track then
                SFX.play('hit',1,track.state.x/420)
            end
            if abs(deviateTime)>.16 then deviateTime=deviateTime>0 and .16 or -.16 end
            ins(hitOffests,1,deviateTime)
            hitCount=hitCount+1
            totalDeviateTime=totalDeviateTime+deviateTime
            hitOffests[27]=nil
        end
    else
        if combo>=10 then SFX.play('combobreak')end
        combo=0
        bestChain=0
    end
    _updateAcc()
end
local function _trackPress(k)
    for i=1,#tracks do
        if tracks[i].state.available and tracks[i].name==k then
            local deviateTime=tracks[i]:press()
            if deviateTime then _trigNote(deviateTime,tracks[i])end
        end
    end
end
local function _trackRelease(k)
    for i=1,#tracks do
        if tracks[i].state.available and tracks[i].name==k then
            local deviateTime,noTailHold=tracks[i]:release()
            if deviateTime then _trigNote(deviateTime,tracks[i],noTailHold)end
        end
    end
end
function scene.keyDown(key,isRep)
    if isRep then return end
    local k=KEY_MAP[key]or key
    if trackNames[k]then
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
            SETTING.dropSpeed=max(SETTING.dropSpeed-1,-8)
            MES.new('info',text.dropSpeedChanged:repD(SETTING.dropSpeed),0)
            needSaveDropSpeed=true
        else
            MES.new('warn',text.cannotAdjustDropSpeed,0)
        end
    elseif k=='dropFaster'then
        if score0==0 then
            SETTING.dropSpeed=min(SETTING.dropSpeed+1,8)
            MES.new('info',text.dropSpeedChanged:repD(SETTING.dropSpeed),0)
            needSaveDropSpeed=true
        else
            MES.new('warn',text.cannotAdjustDropSpeed,0)
        end
    elseif k=='escape'then
        SCN.back()
    elseif k=='auto'then
        autoPlay=not autoPlay
        if autoPlay then
            curAcc=-1e99
            fullAcc=1e99
        end
    end
end
function scene.keyUp(key)
    local k=KEY_MAP[key]
    if trackNames[k]then
        _trackRelease(k)
    end
end

function scene.touchDown(x,y,id)
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
        _trackPress(tracks[closestTrackID].name)
    end
end
function scene.touchUp(_,_,id)
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
                _trackRelease(tracks[touches[i][2]].name)
            end
            rem(touches,i)
            return
        end
    end
end
function scene.mouseDown(x,y,k)scene.touchDown(x,y,k)end
function scene.mouseUp(_,_,k)scene.touchUp(_,_,k)end

function scene.update(dt)
    --Speed up with special keys
    if kbIsDown'lctrl'and kbIsDown('o','p','[',']')then
        dt=dt*(kbIsDown'o'and .4 or kbIsDown'p'and .75 or kbIsDown'['and 6 or 128)
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
        tracks[n.track]:addItem(n)
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
        if autoPlay then
            local _,note=tracks[i]:pollNote('note')
            if note then
                if note.type=='tap'then
                    if time>=note.time then
                        _trackPress(tracks[i].name)
                        _trackRelease(tracks[i].name)
                    end
                end
            end
            note=tracks[i].notes[1]
            if note and note.type=='hold'then
                if note.head then
                    if time>=note.time then _trackPress(tracks[i].name)end
                else
                    if time>=note.etime then _trackRelease(tracks[i].name)end
                end
            end
        end
        tracks[i]:update(dt)
        local missCount,marvCount=tracks[i]:updateLogic(time)
        if marvCount>0 then
            for _=1,marvCount do
                _trigNote(0,tracks[i],true)
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

    --Draw deviate times
    for i=1,#hitOffests do
        local c=hitColors[_getHitLV(hitOffests[i])]
        gc_setColor(c[1],c[2],c[3],.4)
        gc_rectangle('fill',640+hitOffests[i]*688-1,350-8,3,20)
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
