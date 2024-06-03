local min=math.min
local sin=math.sin

local rankColors=rankColors
local results

---@type Zenitha.Scene
local scene={}

function scene.enter()
    applyFPS(false)
    results=SCN.args[1] or{
        fake=true,
        map=require'assets.map'.new(),
        score=62600,
        maxCombo=260,
        accText="96.20%",
        averageDeviate='26.26ms',
        hits={
            miss=4,
            bad=4,
            well=4,
            good=62,
            perf=62,
            prec=62,
            marv=62,
        },
        bestChain=math.random(5),
    }
    if results.accText:sub(1,1)=='-' then results.bestChain=0 end
    if results.averageDeviate:sub(1,1)~='-' then results.averageDeviate='+'..results.averageDeviate end
    results.mapName=GC.newText(FONT.get(80,'mono'),results.map.mapName)
    results.mapDifficulty=GC.newText(FONT.get(30,'mono'),results.map.mapDifficulty)

    -- Rank
    local acc=tonumber(results.accText:sub(1,-2))
    local rankClr,rankStr
    if     acc==101   then rankClr,rankStr=rankColors[1],'X '
    elseif acc>=100.5 then rankClr,rankStr=rankColors[2],'U+'
    elseif acc>=100   then rankClr,rankStr=rankColors[2],'U '
    elseif acc>=99.5  then rankClr,rankStr=rankColors[3],'S+'
    elseif acc>=99    then rankClr,rankStr=rankColors[3],'S '
    elseif acc>=98    then rankClr,rankStr=rankColors[4],'A+'
    elseif acc>=97    then rankClr,rankStr=rankColors[4],'A '
    elseif acc>=94    then rankClr,rankStr=rankColors[5],'B+'
    elseif acc>=90    then rankClr,rankStr=rankColors[5],'B '
    elseif acc>=85    then rankClr,rankStr=rankColors[6],'C+'
    elseif acc>=80    then rankClr,rankStr=rankColors[6],'C '
    elseif acc>=75    then rankClr,rankStr=rankColors[7],'D+'
    elseif acc>=70    then rankClr,rankStr=rankColors[7],'D '
    elseif acc>=65    then rankClr,rankStr=rankColors[8],'E+'
    elseif acc>=60    then rankClr,rankStr=rankColors[8],'E '
    else                   rankClr,rankStr=rankColors[8],'F '
    end
    results.rankClr=rankClr
    results.rankText1=GC.newText(FONT.get(100,'mono'),rankStr:sub(1,1))
    results.rankText2=GC.newText(FONT.get(65,'mono'),rankStr:sub(2,2))

    BGM.play('result')
    BG.set()
end

function scene.keyDown(key,isRep)
    if isRep then return end
    local k=KEY_MAP[key] or key
    if k=='restart' then
        if results.map.valid then
            local map,errmsg=loadBeatmap(results.map.qbpFilePath)
            if map then
                SCN.swapTo('game',nil,map)
            else
                MSG.new('error',errmsg)
            end
        end
    elseif k=='escape' then
        SCN.back()
    end
    return true
end

local _stencilX
local function _marvStencil()
    GC.rectangle('fill',_stencilX,210,100,100)
end
function scene.draw()
    GC.setColor(COLOR.L)
    GC.push('transform')
        GC.translate(640,100)
        GC.scale(min(900/results.mapName:getWidth(),1))
        GC.mDrawX(results.mapName,0,0)
    GC.pop()
    GC.mDrawX(results.mapDifficulty,640,200)

    GC.push('transform')
    GC.translate(240,255)

    -- Draw rank
    GC.push('transform')
    GC.scale(2.2)
    GC.setColor(results.rankClr)
    posterizedDraw(results.rankText1,25,45)
    GC.setColor(1,1,1,.8)
    posterizedDraw(results.rankText2,47,14)
    GC.pop()

    -- Draw score & accuracy & combo
    GC.setColor(COLOR.L)
    FONT.set(60)
    GC.print(results.score,140,0)
    FONT.set(50)
    GC.print(results.accText,140,60)
    FONT.set(15)
    GC.print(results.averageDeviate,145,120)
    FONT.set(40)
    GC.print(results.maxCombo.."x",140,135)

    -- Draw trophy
    if results.bestChain>0 then
        local t=love.timer.getTime()
        local c=results.bestChain
        local trophy=Text.chainTexts[c]
        FONT.set(80)
        local clr=chainColors[c]
        for i=0,420,10 do
            GC.setColor(clr[1],clr[2],clr[3],.45-(i/1000))
            GC.rectangle('fill',i-2,216,10,70)
        end
        GC.setColor(clr)
        if c==1 then
            GC.print(trophy,0,202)
            GC.setColor(1,1,1,.626)
            GC.print(trophy,0,202)
        elseif c==2 then
            GC.print(trophy,0,202)
            GC.setColor(1,1,1,.626+.0626*sin(t*62.6))
            GC.print(trophy,0,202)
        elseif c==3 then
            GC.print(trophy,0,202)
            GC.setColor(1,1,1,.85+.15*sin(t*62.6))
            GC.print(trophy,0,202)
        elseif c>=4 then
            for i=0,10 do
                _stencilX=100*i
                GC.stencil(_marvStencil,'replace',1)
                GC.setStencilTest('equal',1)
                GC.setColor(COLOR.rainbow(t*(c==4 and 2.6 or 6.26)-i))
                GC.print(trophy,sin(t*355)*((c==4 and 1 or 2.6)+.6*sin(t*.626)),202+1.6*sin(t*260))
                GC.setStencilTest()
            end
            GC.setColor(1,1,1,.9)
            GC.print(trophy,0,202)
        end
    end
    GC.pop()

    drawHits(results.hits,480,240)
end

scene.widgetList={
    WIDGET.new{type='button_fill',pos={1,1},x=-300,y=-80,w=160,h=80,fontSize=60,text=CHAR.icon.retry,code=WIDGET.c_pressKey'restart'},
    WIDGET.new{type='button_fill',pos={1,1},x=-120,y=-80,w=160,h=80,sound_press='back',fontSize=60,text=CHAR.icon.back,code=WIDGET.c_backScn()},
}
return scene
