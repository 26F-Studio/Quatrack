local gc=love.graphics

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

local Track=require'parts.track'
local Note=require'parts.note'

local time
local curAcc,fullAcc
local combo,score,score0
local hitLV,hitTextTime
local TRK={}

local scene={}

function scene.sceneInit()
    BG.set('none')

    time=0
    curAcc,fullAcc=0,0
    combo,score,score0=0,0,0

    hitLV,hitTextTime=false,1e-99

    for i=1,4 do
        TRK[i]=Track.new()
        TRK[i]:setPosition{x=140+200*i,y=680}
    end

    local r=math.random(1,4)
    for i=1,62 do
        TRK[r]:addNote(Note.new{time=1+.15*i})
        if i%4==1 then
            local r1=math.random(1,3)
            if r1>=r then r1=r1+1 end
            TRK[r1]:addNote(Note.new{time=1+.15*i})
        end
        r1=math.random(1,3)
        if r1>=r then r1=r1+1 end
        r=r1
    end
end

function scene.keyDown(key,isRep)
    if isRep then return end
    if KEY_MAP[key]then
        local divTime=TRK[KEY_MAP[key]]:press()
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
        TRK[1]:release()
    elseif key=='f'then
        TRK[2]:release()
    elseif key=='j'then
        TRK[3]:release()
    elseif key=='k'then
        TRK[4]:release()
    end
end

-- function scene.touchDown(x,y,id)
--     --?
-- end

function scene.update(dt)
    time=time+dt
    for i=1,4 do
        TRK[i]:update(dt)
        local missCount=TRK[i]:updateLogic(time)
        if missCount then
            hitTextTime=TIME()
            hitLV=-1
            fullAcc=fullAcc+10*missCount
            if combo>=10 then SFX.play('break')end
            combo=0
        end
    end
    if score<score0 then
        score=int(score*.7+score0*.3)
        if score<score0 then score=score+1 end
    end
end

function scene.draw()
    for i=1,4 do
        TRK[i]:draw()
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
end

scene.widgetList={
    WIDGET.newKey{name="pause", x=30,y=30,w=50,fText="| |",code=backScene},
}
return scene
