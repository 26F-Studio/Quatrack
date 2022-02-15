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
local chainColors=chainColors
local trackNames=trackNames
local getHitLV=getHitLV
local function _showVolMes(v)
    needSaveSetting=true
    MES.new('info',('$1%'):repD(('%d'):format(v*100)),0)
end

local game={
    needSaveSetting=false,
    autoPlay=false,
    autoPlayTextObj=false,
    playSongTime=false,
    songLength=false,
    playSpeed=false,
    texts={"","",""},
    judgeTimes=nil,-- judgeTimeList, copied from _G.judgeTimes
    mapEnv=nil,-- Enviroment of script, copied from _G.mapTemplate

    map=nil,-- Map object
    tracks=nil,-- track object list
    hitLV=nil,-- Hit level (-1~5)
    hitTextTime=nil,-- Time stamp, for hitText fading-out animation

    safeAreaTimer=nil,
    time=nil,
    isSongPlaying=nil,
    hitOffests=nil,
    curAcc=nil,
    fullAcc=nil,
    accText=nil,
    combo=nil,
    maxCombo=nil,
    score=nil,
    score0=nil,
    hitCount=nil,
    totalDeviateTime=nil,
    bestChain=nil,
    hits={},
    touches={},
}

local function _updateStat()
    if game.fullAcc<=0 then return end
    mergeStat(STAT,{
        game=1,
        time=game.songLength,
        score=game.score0,
    })
    saveStats()
end

local function _updateAcc()
    local acc=int(10000*game.curAcc/max(game.fullAcc,1))/100
    game.accText=("%.2f%%"):format(acc)
end

local function _tryGoResult()
    if SCN.swapping or not game.map.finished then return true end
    for i=1,#game.tracks do if #game.tracks[i].notes>0 then return true end end
    if game.needSaveSetting then saveSettings() end
    if game.fullAcc>0 and game.curAcc/game.fullAcc>=.6 then
        _updateStat()
        MES.new('check',text.validScore:repD(os.date('%Y-%m-%d %H:%M')),6.26)
    else
        MES.new('info',text.invalidScore)
    end
    SCN.swapTo('result',nil,{
        map=game.map,
        score=game.score0,
        maxCombo=game.maxCombo,
        accText=game.accText,
        averageDeviate=("%.2fms"):format(game.hitCount>0 and game.totalDeviateTime/game.hitCount*1000 or 0),
        hits={
            miss=game.hits[-1],
            bad=game.hits[0],
            well=game.hits[1],
            good=game.hits[2],
            perf=game.hits[3],
            prec=game.hits[4],
            marv=game.hits[5],
        },
        bestChain=game.bestChain,
    })
end

local gameArgs=setmetatable({},{__newindex=function() error("game.xxx is read only") end})
local function _freshScriptArgs()
    for k,v in next,game do
        if type(v)=='number' or type(v)=='string' or type(v)=='boolean' then
            rawset(gameArgs,k,v)
        end
    end

    --Special, will remove in the future
    rawset(gameArgs,'map',game.map)
end
local lastErrorTime=setmetatable({},{__index=function(self,k) self[k]=-1e99 return -1e99 end})
local function callScriptEvent(event,...)
    if game.map.script[event] then
        local ok,err=pcall(game.map.script[event],...)
        if not ok then
            game.errorCount=game.errorCount+1
            if TIME()-lastErrorTime[event]>=0.626 then
                lastErrorTime[event]=TIME()
                err=err:gsub('%b[]:','')
                -- MES.new('error',("<$1>$2:$3"):repD(event,err:match('^%d+'),err:sub(err:find(':')+1)))
                MES.new('error',err)
            end
        end
    end
end

local scene={}

function scene.sceneInit()
    KEY_MAP_inv:_update()
    game.autoPlay=false
    game.playSpeed=1
    game.autoPlayTextObj=game.autoPlayTextObj or gc.newText(getFont(100),'AUTO')
    game.judgeTimes=TABLE.shift(judgeTimesTemplate)

    game.map=SCN.args[1]

    game.playSongTime=game.map.songOffset+SETTING.musicDelay/1000
    game.songLength=game.map.songLength

    game.texts={
        mapName=gc.newText(getFont(80),game.map.mapName),
        musicAuth=gc.newText(getFont(40),'Music: '..game.map.musicAuth),
        mapAuth=gc.newText(getFont(40),'Map: '..game.map.mapAuth),
    }

    game.safeAreaTimer=2
    game.isSongPlaying=false
    game.time=-3.6
    game.hitOffests={}
    game.curAcc,game.fullAcc=0,0
    _updateAcc()
    game.combo,game.maxCombo,game.score,game.score0=0,0,0,0
    game.hitCount,game.totalDeviateTime=0,0
    for i=-1,5 do game.hits[i]=0 end
    game.hitLV,game.hitTextTime=false,1e-99
    game.bestChain=5

    game.needSaveSetting=false
    TABLE.cut(game.touches)

    game.tracks={}
    local trackNameList=defaultTrackNames[game.map.tracks]
    for id=1,game.map.tracks do
        local t=require'parts.track'.new(id)
        t:_setGameData(game)
        t:rename(trackNameList and trackNameList[id] or '')
        t:setChordColor(defaultChordColor)
        t:setDefaultPosition(70*(2*id-game.map.tracks-1),320)
        t:setPosition({type='S'})
        t:setNameAlpha({type='S'},100)
        t:setNameAlpha({type='L',start=-3.6,duration=3},0)
        t:updateLogic(game.time)
        game.tracks[id]=t
    end

    local dirPath=game.map.qbpFilePath:sub(1,#game.map.qbpFilePath-game.map.qbpFilePath:reverse():find("/")+1)
    if love.filesystem.getInfo(dirPath..game.map.songFile..'.ogg') then
        BGM.load(game.map.qbpFilePath,dirPath..game.map.songFile..'.ogg')
    else
        MES.new('error',text.noFile)
    end
    BGM.play(game.map.qbpFilePath,'-preLoad')

    game.errorCount=0
    _freshScriptArgs()
    if game.map.script then
        if love.filesystem.getInfo(dirPath..game.map.script..'.lua') then
            local file=love.filesystem.read('string',dirPath..game.map.script..'.lua')
            local func,err=loadstring(file)
            game.map.script={}
            if func then
                game.mapEnv=TABLE.copy(mapScriptEnv)
                game.mapEnv.game=gameArgs
                game.mapEnv._G=game.mapEnv
                setfenv(func,game.mapEnv)
                local _
                _,err=pcall(func)
                if err then
                    MES.new('error',err)
                else
                    game.map.script=game.mapEnv
                end
            else
                err=err:gsub('%b[]:','')
                MES.new('error',("<$1>$2:$3"):repD('syntax',err:match('^%d+'),err:sub(err:find(':')+1)))
            end
        else
            MES.new('error',text.noFile)
        end
    else
        game.map.script={}
    end
    callScriptEvent('init')

    BGM.stop()
    if game.map.songImage then
        local image
        if love.filesystem.getInfo('parts/levels') or love.filesystem.getInfo('songs/'..game.map.songImage) then
            local success
            success,image=pcall(gc.newImage,dirPath..game.map.songImage)
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
    if game.needSaveSetting then saveSettings() end
end

local function _trigNote(deviateTime,noTailHold,weak)
    game.hitLV=getHitLV(deviateTime,game.judgeTimes)
    game.hitTextTime=TIME()
    game.fullAcc=game.fullAcc+100
    if noTailHold and(game.hitLV>0 or game.hitLV==0 and weak) then game.hitLV=5 end
    game.bestChain=min(game.bestChain,game.hitLV)
    game.hits[game.hitLV]=game.hits[game.hitLV]+1
    if game.hitLV>0 then
        game.curAcc=game.curAcc+hitAccList[game.hitLV]
        game.score0=game.score0+int(game.hitLV*(10000+game.combo)^.5)
        game.combo=game.combo+1
        if game.combo>game.maxCombo then game.maxCombo=game.combo end
        if not noTailHold then
            if abs(deviateTime)>.16 then deviateTime=deviateTime>0 and .16 or -.16 end
            ins(game.hitOffests,1,deviateTime)
            game.hitCount=game.hitCount+1
            game.totalDeviateTime=game.totalDeviateTime+deviateTime
            game.hitOffests[SETTING.dvtCount+1]=nil
        end
    else
        if game.combo>=10 then SFX.play('combobreak') end
        game.combo=0
        game.bestChain=0
    end
    _updateAcc()
end
local function _trackPress(id,weak,auto)
    callScriptEvent('trackPress',id)
    local deviateTime=game.tracks[id]:press(weak,auto)
    if not auto and deviateTime then
        _trigNote(deviateTime)
    end
end
local function _trackRelease(id,weak,auto)
    local deviateTime,noTailHold=game.tracks[id]:release(weak,auto)
    if not auto and deviateTime then
        _trigNote(deviateTime,noTailHold,weak)
    end
end
function scene.keyDown(key,isRep)
    if isRep then return end
    local k=KEY_MAP[key] or key
    if trackNames[k] then
        if game.autoPlay then return end
        local minTime=1e99
        for id=1,game.map.tracks do
            if game.tracks[id].name:find(k) then
                local t=game.tracks[id]:pollPressTime()
                if t<minTime then minTime=t end
            end
        end
        for id=1,game.map.tracks do
            if game.tracks[id].name:find(k) then
                _trackPress(id,minTime<game.tracks[id]:pollPressTime())
            end
        end
    elseif k=='skip' then
        if not game.isSongPlaying and game.time<-.8 then
            game.time=-.8
        else
            _tryGoResult()
        end
    elseif k=='restart' then
        local m,errmsg=loadBeatmap(game.map.qbpFilePath)
        if m then
            SCN.args[1]=m
            BGM.stop('-s')
            scene.sceneInit()
        else
            MES.new('error',errmsg)
        end
    elseif k=='sfxVolDn' then SETTING.sfx=max(SETTING.sfx-.1,0)SFX.setVol(SETTING.sfx)_showVolMes(SETTING.sfx)
    elseif k=='sfxVolUp' then SETTING.sfx=min(SETTING.sfx+.1,1)SFX.setVol(SETTING.sfx)_showVolMes(SETTING.sfx)
    elseif k=='musicVolDn' then SETTING.bgm=max(SETTING.bgm-.1,0)BGM.setVol(SETTING.bgm)_showVolMes(SETTING.bgm)
    elseif k=='musicVolUp' then SETTING.bgm=min(SETTING.bgm+.1,1)BGM.setVol(SETTING.bgm)_showVolMes(SETTING.bgm)
    elseif k=='dropSpdDn' then
        if game.score0==0 or game.curAcc==-1e99 then
            SETTING.dropSpeed=max(SETTING.dropSpeed-1,-8)
            MES.new('info',text.dropSpeedChanged:repD(SETTING.dropSpeed),0)
            game.needSaveSetting=true
        else
            MES.new('warn',text.cannotAdjustDropSpeed,0)
        end
    elseif k=='dropSpdUp' then
        if game.score0==0 or game.curAcc==-1e99 then
            SETTING.dropSpeed=min(SETTING.dropSpeed+1,8)
            MES.new('info',text.dropSpeedChanged:repD(SETTING.dropSpeed),0)
            game.needSaveSetting=true
        else
            MES.new('warn',text.cannotAdjustDropSpeed,0)
        end
    elseif k=='escape' then
        if _tryGoResult() then
            SCN.back()
        end
    elseif k=='auto' then
        game.autoPlay=not game.autoPlay
        if game.autoPlay then
            game.curAcc=-1e99
            game.fullAcc=1e99
            _updateAcc()
        end
    elseif('12345'):find(key,1,true) and kbIsDown('lctrl','rctrl') and kbIsDown('lalt','ralt') then
        game.playSpeed=
            key=='1' and .25 or
            key=='2' and .5 or
            key=='3' and 1 or
            key=='4' and 8 or
            key=='5' and 32
        if game.playSpeed<1 then
            game.curAcc=-1e99
            game.fullAcc=1e99
            _updateAcc()
        end
        BGM.setPitch(game.playSpeed)
        BGM.seek(game.time-game.playSongTime)
    end
end
function scene.keyUp(key)
    local k=KEY_MAP[key]
    if trackNames[k] then
        if game.autoPlay then return end

        local minTime=1e99
        for id=1,game.map.tracks do
            if game.tracks[id].name:find(k) then
                local t=game.tracks[id]:pollReleaseTime()
                if t<minTime then
                    minTime=t
                end
            end
        end
        for id=1,game.map.tracks do
            if game.tracks[id].name:find(k) then
                local s=game.tracks[id].nameList
                for j=1,#s do
                    local kbKey=KEY_MAP_inv[s[j]]
                    if kbKey and kbIsDown(kbKey) then
                        if minTime==game.tracks[id]:pollReleaseTime() then
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

    if game.autoPlay then return end
    x,y=SCR.xOy_m:inverseTransformPoint(SCR.xOy:transformPoint(x,y))
    local minD2,closestTrackID=1e99,false
    x=x/SETTING.scaleX
    for i=1,#game.tracks do
        local t=game.tracks[i]
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
        ins(game.touches,{id,closestTrackID})
        _trackPress(closestTrackID,false)
    end
end
function scene.touchUp(_,_,id)
    if game.autoPlay then return end
    for i=1,#game.touches do
        if game.touches[i][1]==id then
            local allReleased=true
            for j=1,#game.touches do
                if i~=j and game.touches[j][2]==game.touches[i][2] then
                    allReleased=false
                    break
                end
            end
            if allReleased then
                _trackRelease(game.touches[i][2])
            end
            rem(game.touches,i)
            return
        end
    end
end
function scene.mouseDown(x,y,k)scene.touchDown(x,y,k) end
function scene.mouseUp(_,_,k)scene.touchUp(_,_,k) end

function scene.update(dt)
    dt=dt*game.playSpeed

    -- Try play bgm
    if not game.isSongPlaying then
        if game.time<=game.playSongTime and game.time+dt>game.playSongTime then
            BGM.play(game.map.qbpFilePath,'-sdin -noloop')
            BGM.setPitch(game.playSpeed)
            BGM.seek(game.time+dt-game.playSongTime)
            game.isSongPlaying=true
        end
    else
        if not BGM.isPlaying() then
            _tryGoResult()
        end
    end

    -- Update timers
    game.time=game.time+dt
    if game.safeAreaTimer>0 then game.safeAreaTimer=max(0,game.safeAreaTimer-dt) end

    -- Update notes
    game.map:updateTime(game.time)
    while true do
        local n=game.map:poll('note')
        if not n then break end
        game.tracks[n.track]:addItem(n)
    end
    while true do
        local n=game.map:poll('event')
        if not n then break end
        if n.type=='setTrack' then
            local t=game.tracks[n.track]
            t[n.operation](t,unpack(n.args))
        elseif n.type=='setChordColor' then
            for i=1,#game.tracks do
                game.tracks[i]:setChordColor(n.color)
            end
        elseif n.type=='setJudge' then
            for i=1,5 do
                game.judgeTimes[i]=n.args[i]
            end
        end
    end

    -- Update tracks (check too-late miss)
    for id=1,game.map.tracks do
        local t=game.tracks[id]
        do-- Auto play and invalid notes' auto hitting
            local _,note=t:pollNote('note')
            if note and(not note.available or game.autoPlay) and note.type=='tap' then
                if game.time>=note.time then
                    _trackPress(id,false,true)
                    note=t.notes[1]
                    if not(note and note.type=='hold') then
                        _trackRelease(id)
                    end
                end
            end
            note=t.notes[1]
            if note and(not note.available or game.autoPlay) and note.type=='hold' then
                if note.head then
                    if game.time>=note.time then _trackPress(id,false,true) end
                else
                    if game.time>=note.etime then _trackRelease(id,false,true) end
                end
            end
        end
        t:update(dt)
        local missCount,marvCount=t:updateLogic(game.time)
        if marvCount>0 then
            for _=1,marvCount do
                _trigNote(0,true)
            end
        end
        if missCount>0 then
            game.hitTextTime=TIME()
            game.hitLV=-1
            game.fullAcc=game.fullAcc+100*missCount
            _updateAcc()
            if game.combo>=10 then SFX.play('combobreak') end
            game.combo=0
            game.bestChain=0
            game.hits[-1]=game.hits[-1]+missCount
        end
    end

    -- Update displaying score
    if game.score<game.score0 then
        game.score=game.score+(game.score0-game.score)*dt^.26
    end

    _freshScriptArgs()
    callScriptEvent('update')
end

local SCC={1,1,1}-- Super chain color
function scene.draw()
    gc_setColor(1,1,1)gc_setLineWidth(2)
    callScriptEvent('drawBack')

    if game.safeAreaTimer>0 then
        gc.origin()
        drawSafeArea(SETTING.safeX,SETTING.safeY,game.safeAreaTimer)
    end

    gc_replaceTransform(SCR.xOy_m)

    -- Draw auto mark
    if game.autoPlay then
        gc_setColor(1,1,1,.126)
        mDraw(game.autoPlayTextObj,nil,nil,nil,3.55)
    end

    -- Draw tracks
    for i=1,game.map.tracks do
        game.tracks[i]:draw(game.map)
    end

    gc_replaceTransform(SCR.xOy)

    -- Draw hit text
    if TIME()-game.hitTextTime<.26 and game.hitLV<=SETTING.showHitLV then
        local c=hitColors[game.hitLV]
        setFont(80,'mono')
        gc_setColor(c[1],c[2],c[3],2.6-(TIME()-game.hitTextTime)*10)
        mStr(hitTexts[game.hitLV],640,245)
    end

    -- Draw combo
    if game.combo>0 then
        setFont(50,'mono')
        if game.bestChain==5 then
            SCC[3]=(1-game.time/game.songLength)^.26
            GC.shadedPrint(game.combo,640,360,'center',1,chainColors[game.bestChain],SCC)
        else
            GC.shadedPrint(game.combo,640,360,'center',1,chainColors[game.bestChain],COLOR.Z)
        end
    end

    -- Draw deviate indicator
    gc_setColor(1,1,1)gc_rectangle('fill',640-2,350-13,4,30)
    for i=1,5 do
        local c=hitColors[i]
        local d1=game.judgeTimes[i]
        local d2=game.judgeTimes[i+1]
        gc_setColor(c[1]*.8+.3,c[2]*.8+.3,c[3]*.8+.3,.626)
        gc_rectangle('fill',640-d1*688,350,(d1-d2)*688,4)
        gc_rectangle('fill',640+d1*688,350,(d2-d1)*688,4)
    end

    -- Draw time
    if game.time>0 then
        setFont(10)
        gc_setColor(1,1,1)
        gc_rectangle('fill',530,369,220*MATH.interval(game.time/game.songLength,0,1),3)
    end

    -- Draw deviate times
    local l=#game.hitOffests
    for i=1,l do
        local c=hitColors[getHitLV(game.hitOffests[i],game.judgeTimes)]
        local r=1+(1-i/l)^1.626
        gc_setColor(c[1],c[2],c[3],.2*r)
        gc_rectangle('fill',640+game.hitOffests[i]*688-1,350-6*r,3,4+12*r)
    end

    -- Draw map info at start
    if game.time<0 then
        local a=3.6-2*abs(game.time+1.8)
        gc_setColor(1,1,1,a)
        gc_draw(game.texts.mapName,640,100,nil,min(1200/game.texts.mapName:getWidth(),1),1,game.texts.mapName:getWidth()*.5)
        gc_setColor(.7,.7,.7,a)
        mText(game.texts.musicAuth,640,200)
        mText(game.texts.mapAuth,640,240)
    end

    gc_setColor(1,1,1)

    gc_replaceTransform(SCR.xOy_ur)
    gc_translate(-SCR.safeX/SCR.k,0)
    -- Draw score & accuracy
    setFont(60)gc_printf(ceil(game.score),-1010,-10,1000,'right')
    setFont(40)gc_printf(game.accText,-1010,50,1000,'right')

    gc_replaceTransform(SCR.xOy_dr)
    gc_translate(-SCR.safeX/SCR.k,0)
    -- Draw map info
    setFont(30)gc_printf(game.map.mapName,-1010,-45,1000,'right')
    setFont(25)gc_printf(game.map.mapDifficulty,-1010,-75,1000,'right')
    if game.errorCount>0 then
        setFont(10)
        gc_setColor(1,.26,.26)
        gc_printf(game.errorCount..' error',-1010,-90,1000,'right')
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
