local gc=love.graphics

local Note=require'parts.note'

local int,abs=math.floor,math.abs
local ins=table.insert

local hitColors={
    [-1]=COLOR.dRed,
    [0]=COLOR.dRed,
    COLOR.lWine,
    COLOR.lBlue,
    COLOR.lGreen,
    COLOR.lOrange,
    COLOR.lH,
}
local hitTexts={
    [-1]="MISS",
    [0]="BAD",
    'OK',
    'GREAT',
    'GOOD',
    'PERF',
    'MARV'
}
local hitAccList={
    -5,
    2,
    6,
    10,
    10,
}

local function _getHitLV(div)
    return
    abs(div)<=.02 and 5 or
    abs(div)<=.04 and 4 or
    abs(div)<=.07 and 3 or
    abs(div)<=.10 and 2 or
    abs(div)<=.15 and 1 or
    0
end

local map,tracks

local isSongPlaying
local time
local devTimes
local curAcc,fullAcc,accText
local combo,score,score0
local hitLV--Hit level (-1~5)
local hitTextTime--Time stamp, for hitText fading-out animation

local function _updateAcc()
    accText=("%.2f%%"):format(100*curAcc/(fullAcc>0 and fullAcc or 1))
end

local scene={}

function scene.sceneInit()
    local mapName=SCN.args[1]

    BGM.stop()
    BG.set('none')

    isSongPlaying=false
    time=-4
    devTimes={}
    curAcc,fullAcc=0,0
    _updateAcc()
    combo,score,score0=0,0,0

    hitLV,hitTextTime=false,1e-99

    map=require'parts.map'.new(('parts/levels/$1.qmp'):repD(mapName))

    tracks={}
    for i=1,4 do
        tracks[i]=require'parts.track'.new()
        tracks[i]:setPosition{x=340+120*i,y=680}
    end
end

function scene.sceneBack()
    BGM.stop()
end

function scene.keyDown(key,isRep)
    if isRep then return end
    if KEY_MAP[key]then
        local deviateTime=tracks[KEY_MAP[key]]:press()
        if deviateTime then
            hitTextTime=TIME()
            fullAcc=fullAcc+10
            hitLV=_getHitLV(deviateTime)
            if hitLV>0 then
                curAcc=curAcc+hitAccList[hitLV]
                score0=score0+int(hitLV*(100+combo)^.5)
                combo=combo+1
                SFX.play('hit')
            else
                if combo>=10 then SFX.play('break')end
                combo=0
            end
            _updateAcc()
            ins(devTimes,1,deviateTime)
            devTimes[27]=nil
        end
    elseif key=='escape'then
        SCN.back()
    end
end
function scene.keyUp(key)
    if KEY_MAP[key]then
        tracks[KEY_MAP[key]]:release()
    end
end

-- function scene.touchDown(x,y,id)
--     --?
-- end

function scene.update(dt)
    if not isSongPlaying and time<=map.songOffset and time+dt>map.songOffset then
        BGM.play(map.songFile,'-si')
        BGM.seek(time+dt-map.songOffset)
    end

    time=time+dt
    map:updateTime(time)
    local n=map:pollNote()
    while n do
        tracks[n.track]:addNote(Note.new(n))
        n=map:pollNote()
    end

    --Update tracks (check too-late miss)
    for i=1,4 do
        tracks[i]:update(dt)
        local missCount=tracks[i]:updateLogic(time)
        if missCount then
            hitTextTime=TIME()
            hitLV=-1
            fullAcc=fullAcc+10*missCount
            _updateAcc()
            if combo>=10 then SFX.play('break')end
            combo=0
        end
    end

    --Update score animation
    if score<score0 then
        score=int(score*.7+score0*.3)
        if score<score0 then score=score+1 end
    end
end

local comboTextColor1={.1,.05,0,.8}
local comboTextColor2={.86,.92,1,.8}
function scene.draw()
    --Draw tracks
    for i=1,4 do
        tracks[i]:draw()
    end

    --Draw hit text
    if TIME()-hitTextTime<.2 then
        local a=2-(TIME()-hitTextTime)*10
        setFont(80,'mono')
        gc.setColor(hitColors[hitLV][1],hitColors[hitLV][2],hitColors[hitLV][3],a)
        mStr(hitTexts[hitLV],640,245)
    end

    --Draw deviate indicator
    gc.setColor(1,1,1)gc.rectangle('fill',640-1,350-15,3,34)
    gc.setColor(1,1,1,.4)gc.rectangle('fill',640-100,350,200,4)
    gc.setColor(1,1,1,.3)for i=1,#devTimes do gc.rectangle('fill',640-devTimes[i]*626-1,350-8,3,20)end

    --Draw combo
    if combo>1 then
        setFont(50,'mono')
        mStr(combo,640,355)
        GC.shadedPrint(combo,640,360,'center',2,comboTextColor1,comboTextColor2)
    end

    --Draw score and accuracy
    setFont(40)
    gc.setColor(1,1,1)
    gc.printf(score,0,5,1270,'right')
    setFont(30)
    gc.printf(accText,0,50,1270,'right')

    --Draw map info at start
    if time<0 then
        local a=4-2*abs(time+2)
        setFont(80)
        gc.setColor(1,1,1,a)
        mStr(map.mapName,640,100)
        gc.setColor(.7,.7,.7,a)
        setFont(40)
        mStr(map.musicAuth,640,200)
        mStr(map.mapAuth,640,240)
    end
end

scene.widgetList={
    WIDGET.newKey{name="pause", x=40,y=60,w=50,fText="| |",code=backScene},
}
return scene
