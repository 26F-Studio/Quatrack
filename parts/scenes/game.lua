local Note=require'parts.note'

local gc=love.graphics
local gc_setColor=gc.setColor
local gc_rectangle=gc.rectangle
local gc_printf=gc.printf

local max=math.max
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
    'GOOD',
    'GREAT',
    'PERF',
    'MARV'
}
local hitAccList={
    -5, --OK
    2,  --GOOD
    6,  --GREAT
    10, --PERF
    10, --MARV
}

local function _getHitLV(div)
    return
    abs(div)<=.02 and 5 or
    abs(div)<=.04 and 4 or
    abs(div)<=.07 and 3 or
    abs(div)<=.10 and 2 or
    abs(div)<=.14 and 1 or
    0
end

local playSongTime

local map,tracks
local hitLV--Hit level (-1~5)
local hitTextTime--Time stamp, for hitText fading-out animation

local isSongPlaying
local time
local devTimes
local curAcc,fullAcc,accText
local combo,maxCombo,score,score0
local hits={}

local function _updateAcc()
    accText=("%.2f%%"):format(100*max(curAcc,0)/max(fullAcc,1))
end

local function _tryGoResult()
    for i=1,#tracks do
        if tracks[i].notes[1]then return end
    end
    SCN.swapTo('result',nil,{
        mapName=map.mapName,
        score=score0,
        maxCombo=maxCombo,
        accText=accText,
        hits={
            [-1]=hits[-1],
            [0]=hits[0],
            [1]=hits[1],
            [2]=hits[2],
            [3]=hits[3],
            [4]=hits[4],
            [5]=hits[5],
        }
    })
end

local scene={}

function scene.sceneInit()
    map=SCN.args[1]

    playSongTime=map.songOffset+(SETTING.musicDelay-260)/1000

    BGM.stop()
    BG.set('none')

    isSongPlaying=false
    time=-4
    devTimes={}
    curAcc,fullAcc=0,0
    _updateAcc()
    combo,maxCombo,score,score0=0,0,0,0
    for i=-1,5 do hits[i]=0 end

    hitLV,hitTextTime=false,1e-99

    tracks={}
    for i=1,map.tracks do
        tracks[i]=require'parts.track'.new()
        tracks[i]:setPosition{x=580-60*map.tracks+120*i,y=680}
    end
end

function scene.sceneBack()
    BGM.stop()
end

function scene.keyDown(key,isRep)
    if isRep then return end
    local k=KEY_MAP[map.tracks][key]
    if k then
        if type(k)=='number'then
            local deviateTime=tracks[k]:press()
            if deviateTime then
                hitTextTime=TIME()
                fullAcc=fullAcc+10
                hitLV=_getHitLV(deviateTime)
                hits[hitLV]=hits[hitLV]+1
                if hitLV>0 then
                    curAcc=curAcc+hitAccList[hitLV]
                    score0=score0+int(hitLV*(10000+combo)^.5)
                    combo=combo+1
                    if combo>maxCombo then
                        maxCombo=combo
                    end
                    SFX.play('hit')
                else
                    if combo>=10 then SFX.play('combobreak')end
                    combo=0
                end
                _updateAcc()
                ins(devTimes,1,deviateTime)
                devTimes[27]=nil
            end
        elseif k=='skip'then
            if map.finished then
                _tryGoResult()
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
            tracks[k]:release()
        end
    end
end

-- function scene.touchDown(x,y,id)
--     --?
-- end

function scene.update(dt)
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
    local n=map:poll('note')
    while n do
        tracks[n.track]:addNote(Note.new(n))
        n=map:poll('note')
    end
    n=map:poll('event')
    while n do
        if n.type=='moveTrack'then
            tracks[n.track]:setPosition(n.pos)
        end
        n=map:poll('event')
    end

    --Update tracks (check too-late miss)
    for i=1,map.tracks do
        tracks[i]:update(dt)
        local missCount=tracks[i]:updateLogic(time)
        if missCount then
            hitTextTime=TIME()
            hitLV=-1
            fullAcc=fullAcc+10*missCount
            _updateAcc()
            if combo>=10 then SFX.play('combobreak')end
            combo=0
            hits[-1]=hits[-1]+missCount
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
    for i=1,map.tracks do
        tracks[i]:draw()
    end

    --Draw hit text
    if TIME()-hitTextTime<.2 then
        local a=2-(TIME()-hitTextTime)*10
        setFont(80,'mono')
        gc_setColor(hitColors[hitLV][1],hitColors[hitLV][2],hitColors[hitLV][3],a)
        mStr(hitTexts[hitLV],640,245)
    end

    --Draw deviate indicator
    gc_setColor(1,1,1)gc_rectangle('fill',640-1,350-15,3,34)
    gc_setColor(1,1,1,.4)gc_rectangle('fill',640-100,350,200,4)
    gc_setColor(1,1,1,.3)for i=1,#devTimes do gc_rectangle('fill',640-devTimes[i]*626-1,350-8,3,20)end

    --Draw combo
    if combo>1 then
        setFont(50,'mono')
        mStr(combo,640,355)
        GC.shadedPrint(combo,640,360,'center',2,comboTextColor1,comboTextColor2)
    end

    --Draw score and accuracy
    setFont(40)
    gc_setColor(1,1,1)
    gc_printf(score,0,5,1270,'right')
    setFont(30)
    gc_printf(accText,0,50,1270,'right')

    --Draw map info at start
    if time<0 then
        local a=4-2*abs(time+2)
        setFont(80)
        gc_setColor(1,1,1,a)
        mStr(map.mapName,640,100)
        gc_setColor(.7,.7,.7,a)
        setFont(40)
        mStr(map.musicAuth,640,200)
        mStr(map.mapAuth,640,240)
    end
end

scene.widgetList={
    WIDGET.newKey{name="pause", x=40,y=60,w=50,fText="| |",code=backScene},
}
return scene
