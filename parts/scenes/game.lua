local gc=love.graphics

local Note=require'parts.note'

local int,abs=math.floor,math.abs

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

local time
local curAcc,fullAcc
local combo,score,score0
local hitLV--Hit level (-1~5)
local hitTextTime--Time stamp, for hitText fading-out animation

local scene={}

function scene.sceneInit()
    BGM.stop()
    BG.set('none')

    time=0
    curAcc,fullAcc=0,0
    combo,score,score0=0,0,0

    hitLV,hitTextTime=false,1e-99

    map=require'parts.map'.new('parts/levels/goodrage.qmp')

    tracks={}
    for i=1,4 do
        tracks[i]=require'parts.track'.new()
        tracks[i]:setPosition{x=140+200*i,y=680}
    end
end

function scene.keyDown(key,isRep)
    if isRep then return end
    if KEY_MAP[key]then
        local divTime=tracks[KEY_MAP[key]]:press()
        if divTime then
            hitTextTime=TIME()
            fullAcc=fullAcc+10
            hitLV=_getHitLV(divTime)
            if hitLV>0 then
                curAcc=curAcc+hitAccList[hitLV]
                score0=score0+int(hitLV*(100+combo)^.5)
                combo=combo+1
                SFX.play('hit')
            else
                if combo>=10 then SFX.play('break')end
                combo=0
            end
        end
    elseif key=='escape'then
        SCN.back()
    end
end
function scene.keyUp(key)
    if key=='d'then
        tracks[1]:release()
    elseif key=='f'then
        tracks[2]:release()
    elseif key=='j'then
        tracks[3]:release()
    elseif key=='k'then
        tracks[4]:release()
    end
end

-- function scene.touchDown(x,y,id)
--     --?
-- end

function scene.update(dt)
    if time<=4.5 and time+dt>4.5 then
        BGM.play('goodrage','-si')
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

function scene.draw()
    for i=1,4 do
        tracks[i]:draw()
    end

    if TIME()-hitTextTime<.2 then
        local a=2-(TIME()-hitTextTime)*10
        setFont(80,'mono')
        gc.setColor(hitColors[hitLV][1],hitColors[hitLV][2],hitColors[hitLV][3],a)
        mStr(hitTexts[hitLV],640,270)
        if combo>2 then
            gc.setColor(1,1,1,a)
            setFont(50,'mono')
            mStr(combo,640,350)
        end
    end

    setFont(40)
    gc.setColor(1,1,1)
    gc.printf(score,0,10,1270,'right')
    setFont(30)
    gc.printf(("%.2f%%"):format(100*curAcc/fullAcc),0,60,1270,'right')

    if time<4 then
        setFont(80)
        gc.setColor(1,1,1,2-2*abs(2-time))
        mStr(map.mapName,640,100)
        gc.setColor(.7,.7,.7,2-2*abs(2-time))
        setFont(40)
        mStr(map.musicAuth,640,200)
        mStr(map.mapAuth,640,240)
    end
end

scene.widgetList={
    WIDGET.newKey{name="pause", x=30,y=30,w=50,fText="| |",code=backScene},
}
return scene
