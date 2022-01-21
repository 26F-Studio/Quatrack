local gc=love.graphics
local gc_setColor,gc_setLineWidth=gc.setColor,gc.setLineWidth
local gc_rectangle=gc.rectangle
local gc_draw,gc_printf=gc.draw,gc.printf
local gc_replaceTransform,gc_translate=gc.replaceTransform,gc.translate

local kbIsDown=love.keyboard.isDown

local setFont=setFont
local mStr=mStr

local unpack,rawset=unpack,rawset
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

local safeAreaTimer
local time,isSongPlaying
local hitOffests
local curAcc,fullAcc,accText
local combo,maxCombo,score,score0
local hitCount,totalDeviateTime
local bestChain
local hits={}
local touches={}

local functionsGamePlay={}

local function _updateStat()
    if fullAcc<=0 then return end
    mergeStat(STAT,{
        game=1,
        time=songLength,
        score=score0,
        hits={
            miss=hits[-1],
            bad=hits[0],
            well=hits[1],
            good=hits[2],
            perf=hits[3],
            prec=hits[4],
            marv=hits[5],
        },
    })
    saveStats()
end

local function _updateAcc()
    local acc=int(10000*curAcc/max(fullAcc,1))/100
    accText=("%.2f%%"):format(acc)
end

local function _tryGoResult()
    if SCN.swapping or not map.finished then return true end
    for i=1,#tracks do if #tracks[i].notes>0 then return true end end
    if needSaveSetting then saveSettings()end
    if fullAcc>0 and curAcc/fullAcc>=.6 then
        _updateStat()
        MES.new('check',text.validScore:repD(os.date('%Y-%m-%d %H:%M')),6.26)
    else
        MES.new('info',text.invalidScore)
    end
    SCN.swapTo('result',nil,{
        map=map,
        score=score0,
        maxCombo=maxCombo,
        accText=accText,
        averageDeviate=("%.2fms"):format(hitCount>0 and totalDeviateTime/hitCount*1000 or 0),
        hits={
            miss=hits[-1],
            bad=hits[0],
            well=hits[1],
            good=hits[2],
            perf=hits[3],
            prec=hits[4],
            marv=hits[5],
        },
        bestChain=bestChain,
    })
end


local mapEnv
local gameArgs=setmetatable({},{__newindex=function()error("game.xxx is read only")end})
local function freshScriptArgs()
    rawset(gameArgs,'time',time)
    rawset(gameArgs,'combo',combo)
    rawset(gameArgs,'maxCombo',maxCombo)
    rawset(gameArgs,'score',score0)
    rawset(gameArgs,'fullAcc',fullAcc)
    rawset(gameArgs,'curAcc',curAcc)
    rawset(gameArgs,'hitCount',hitCount)
    rawset(gameArgs,'totalDeviateTime',totalDeviateTime)
    rawset(gameArgs,'bestChain',bestChain)
    rawset(gameArgs,'hits',hits)
    rawset(gameArgs,'map',map)
end
local errorCount
local lastErrorTime=setmetatable({},{__index=function(self,k)self[k]=-1e99 return -1e99 end})
local function callScriptEvent(event)
    if map.script[event]then
        local ok,err=pcall(map.script[event],gameArgs)
        if not ok then
            errorCount=errorCount+1
            if TIME()-lastErrorTime[event]>=1 then
                lastErrorTime[event]=TIME()
                err=err:gsub('%b[]:','')
                --MES.new('error',("<$1>$2:$3"):repD(event,err:match('^%d+'),err:sub(err:find(':')+1)))
                MES.new('error',err)
            end
        end
    end
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

    safeAreaTimer=2
    isSongPlaying=false
    time=-3.6
    hitOffests={}
    curAcc,fullAcc=0,0
    _updateAcc()
    combo,maxCombo,score,score0=0,0,0,0
    hitCount,totalDeviateTime=0,0
    for i=-1,5 do hits[i]=0 end
    hitLV,hitTextTime=false,1e-99
    bestChain=5

    needSaveSetting=false
    TABLE.cut(touches)

    tracks={}
    local trackNameList=defaultTrackNames[map.tracks]
    for id=1,map.tracks do
        local t=require'parts.track'.new(id)
        t:setDefaultPosition(70*(2*id-map.tracks-1),320)
        t:setPosition({type='S'})
        t:rename(trackNameList and trackNameList[id]or'')
        t:setChordColor(defaultChordColor)
        t:setNameAlpha({type='S'},100)
        t:setNameAlpha({type='L',start=-3.6,duration=3},0)
        t:updateLogic(time)
        tracks[id]=t
    end

    local dirPath=map.qbpFilePath:sub(1,#map.qbpFilePath-map.qbpFilePath:reverse():find("/")+1)
    if love.filesystem.getInfo(dirPath..map.songFile..'.ogg')then
        BGM.load(map.qbpFilePath,dirPath..map.songFile..'.ogg')
    else
        MES.new('error',text.noFile)
    end
    BGM.play(map.qbpFilePath,'-preLoad')

    errorCount=0
    freshScriptArgs()
    if map.script then
        if love.filesystem.getInfo(dirPath..map.script..'.lua')then
            local file=love.filesystem.read('string',dirPath..map.script..'.lua')
            local func,err=loadstring(file)
            map.script={}
            if func then
                mapEnv=TABLE.copy(mapScriptEnv)
                mapEnv.game=gameArgs
                mapEnv._G=mapEnv
                setfenv(func,mapEnv)
                local _
                _,err=pcall(func)
                if err then
                    MES.new('error',err)
                else
                    map.script=mapEnv
                end
            else
                err=err:gsub('%b[]:','')
                MES.new('error',("<$1>$2:$3"):repD('syntax',err:match('^%d+'),err:sub(err:find(':')+1)))
            end
        else
            MES.new('error',text.noFile)
        end
    else
        map.script={}
    end
    callScriptEvent('init')

    BGM.stop()
    if map.songImage then
        local image
        if love.filesystem.getInfo('parts/levels')or love.filesystem.getInfo('songs/'..map.songImage)then
            local success
            success,image=pcall(gc.newImage,dirPath..map.songImage)
            if not success then
                MES.new('error',text.noFile)
                image=nil
            end
        end
        if image then
            BG.set('custom')
            BG.send(SETTING.bgAlpha,image)
        else
            BG.set('none')
        end
    else
        BG.set('none')
    end

    applyFPS(true)
end

function scene.sceneBack()
    BGM.stop()
    applyFPS(false)
    if needSaveSetting then saveSettings()end
end

local function _trigNote(deviateTime,noTailHold,weak)
    hitLV=getHitLV(deviateTime,map.hitLVOffsets)
    hitTextTime=TIME()
    fullAcc=fullAcc+100
    if noTailHold and(hitLV>0 or hitLV==0 and weak)then hitLV=5 end
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
local function _trackPress(id,weak,auto)
    local deviateTime=tracks[id]:press(weak,auto,hitLVOffsets)
    if not auto and deviateTime then
        _trigNote(deviateTime)
    end
end
local function _trackRelease(id,weak,auto)
    local deviateTime,noTailHold=tracks[id]:release(weak,auto,hitLVOffsets)
    if not auto and deviateTime then
        _trigNote(deviateTime,noTailHold,weak)
    end
end
function scene.keyDown(key,isRep)
    if isRep then return end
    local k=KEY_MAP[key]or key
    if trackNames[k]then
        if autoPlay then return end
        local minTime=1e99
        for id=1,map.tracks do
            if tracks[id].name:find(k)then
                local t=tracks[id]:pollPressTime()
                if t<minTime then minTime=t end
            end
        end
        for id=1,map.tracks do
            if tracks[id].name:find(k)then
                _trackPress(id,minTime<tracks[id]:pollPressTime())
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

        local minTime=1e99
        for id=1,map.tracks do
            if tracks[id].name:find(k)then
                local t=tracks[id]:pollReleaseTime()
                if t<minTime then
                    minTime=t
                end
            end
        end
        for id=1,map.tracks do
            if tracks[id].name:find(k)then
                local s=tracks[id].nameList
                for j=1,#s do
                    local kbKey=KEY_MAP_inv[s[j]]
                    if kbKey and kbIsDown(kbKey)then
                        if minTime==tracks[id]:pollReleaseTime()then
                            _trackRelease(id,true)
                            goto BREAK_weak
                        end
                    end
                end
                _trackRelease(id,false)
                ::BREAK_weak::
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
            local angle=math.atan2(y-t.state.y,x-t.state.x)
            if t.state.ky<0 then angle=angle+3.141592653589793 end
            angle=angle-t.state.ang/57.29577951308232
            angle=angle+1.5707963267948966
            angle=angle%6.283185307179586

            local D
            if abs(angle-3.141592653589793)>=1.5707963267948966 then
                if angle>3.141592653589793 then angle=6.283185307179586-angle end
                D=abs(cos(t.state.ang/57.29577951308232)*(x-t.state.x)+sin(t.state.ang/57.29577951308232)*(y-t.state.y))
            else
                D=((y-t.state.y)^2+(x-t.state.x)^2)^.5
            end
            if D<minD2 then minD2,closestTrackID=D,i end
        end
    end
    if closestTrackID then
        ins(touches,{id,closestTrackID})
        _trackPress(closestTrackID,false)
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

--我先随便写一个近的地方 回头再挪位置
functionsGamePlay.setJudges=function(...)
    local args={...}
    for i,v in pairs(args) do
        local n=7-i
        map.hitLVOffsets[n]=v
    end
end
functionsGamePlay.moveJudges=function(...)
    local args={...}
    for i,v in ipairs(args) do
        local n=7-i
        map.hitLVOffsets[n]=map.hitLVOffsets[n]+v
    end
end

function scene.update(dt)
    dt=dt*playSpeed

    --Try play bgm
    if not isSongPlaying then
        if time<=playSongTime and time+dt>playSongTime then
            BGM.play(map.qbpFilePath,'-sdin -noloop')
            BGM.setPitch(playSpeed)
            BGM.seek(time+dt-playSongTime)
            isSongPlaying=true
        end
    else
        if not BGM.isPlaying()then
            _tryGoResult()
        end
    end

    --Update timers
    time=time+dt
    if safeAreaTimer>0 then safeAreaTimer=max(0,safeAreaTimer-dt)end

    --Update notes
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
        elseif n.type=='setGamePlay' then
            functionsGamePlay[n.operation](t,unpack(n.args))
        end
    end

    --Update tracks (check too-late miss)
    for id=1,map.tracks do
        local t=tracks[id]
        do--Auto play and invalid notes' auto hitting
            local _,note=t:pollNote('note')
            if note and(not note.available or autoPlay)and note.type=='tap'then
                if time>=note.time then
                    _trackPress(id,false,true)
                    note=t.notes[1]
                    if not(note and note.type=='hold')then
                        _trackRelease(id)
                    end
                end
            end
            note=t.notes[1]
            if note and(not note.available or autoPlay)and note.type=='hold'then
                if note.head then
                    if time>=note.time then _trackPress(id,false,true)end
                else
                    if time>=note.etime then _trackRelease(id,false,true)end
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

    freshScriptArgs()
    --if map.script.update then map.script.update()end
    callScriptEvent('update')
end

local SCC={1,1,1}--Super chain color
function scene.draw()
    gc_setColor(1,1,1)gc_setLineWidth(2)
    callScriptEvent('drawBack')

    if safeAreaTimer>0 then
        gc.origin()
        drawSafeArea(SETTING.safeX,SETTING.safeY,safeAreaTimer)
    end

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
        local d1=map.hitLVOffsets[i]
        local d2=map.hitLVOffsets[i+1]
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
    local l=#hitOffests
    for i=1,l do
        local c=hitColors[getHitLV(hitOffests[i],map.hitLVOffsets)]
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
    if errorCount>0 then
        setFont(10)
        gc_setColor(1,.26,.26)
        gc_printf(errorCount..' error',-1010,-90,1000,'right')
    end
    gc_replaceTransform(SCR.xOy)
    gc_setColor(1,1,1)gc_setLineWidth(2)
    callScriptEvent('drawFront')
end

scene.widgetList={
    WIDGET.newKey{name="restart", x=100,y=60,w=50,fText=CHAR.icon.retry_spin,code=pressKey'restart'},
    WIDGET.newKey{name="pause", x=40,y=60,w=50,fText=CHAR.icon.back,code=backScene},
}
return scene
