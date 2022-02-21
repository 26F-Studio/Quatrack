local gc=love.graphics

local min=math.min
local sin=math.sin

local rankColors=rankColors
local results

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
    results.mapName=gc.newText(FONT.get(80,'mono'),results.map.mapName)
    results.mapDifficulty=gc.newText(FONT.get(30,'mono'),results.map.mapDifficulty)

    --Rank
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
    results.rankText1=gc.newText(FONT.get(100,'mono'),rankStr:sub(1,1))
    results.rankText2=gc.newText(FONT.get(65,'mono'),rankStr:sub(2,2))

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
                MES.new('error',errmsg)
            end
        end
    elseif k=='escape' then
        SCN.back()
    end
end

local _stencilX
local function _marvStencil()
    gc.rectangle('fill',_stencilX,210,100,100)
end
function scene.draw()
    gc.setColor(COLOR.L)
    gc.push('transform')
        gc.translate(640,100)
        gc.scale(min(900/results.mapName:getWidth(),1))
        GC.simpX(results.mapName,0,0)
    gc.pop()
    GC.simpX(results.mapDifficulty,640,200)

    gc.push('transform')
    gc.translate(240,255)

    --Draw rank
    gc.push('transform')
    gc.scale(2.2)
    gc.setColor(results.rankClr)
    posterizedDraw(results.rankText1,25,45)
    gc.setColor(1,1,1,.8)
    posterizedDraw(results.rankText2,47,14)
    gc.pop()

    --Draw score & accuracy & combo
    gc.setColor(COLOR.L)
    FONT.set(60)
    gc.print(results.score,140,0)
    FONT.set(50)
    gc.print(results.accText,140,60)
    FONT.set(15)
    gc.print(results.averageDeviate,145,120)
    FONT.set(40)
    gc.print(results.maxCombo.."x",140,135)

    --Draw trophy
    if results.bestChain>0 then
        local t=love.timer.getTime()
        local c=results.bestChain
        local trophy=Text.chainTexts[c]
        FONT.set(80)
        local clr=chainColors[c]
        for i=0,420,10 do
            gc.setColor(clr[1],clr[2],clr[3],.45-(i/1000))
            gc.rectangle('fill',i-2,216,10,70)
        end
        gc.setColor(clr)
        if c==1 then
            gc.print(trophy,0,195)
            gc.setColor(1,1,1,.626)
            gc.print(trophy,0,195)
        elseif c==2 then
            gc.print(trophy,0,195)
            gc.setColor(1,1,1,.626+.0626*sin(t*62.6))
            gc.print(trophy,0,195)
        elseif c==3 then
            gc.print(trophy,0,195)
            gc.setColor(1,1,1,.85+.15*sin(t*62.6))
            gc.print(trophy,0,195)
        elseif c>=4 then
            for i=0,10 do
                _stencilX=100*i
                gc.stencil(_marvStencil,'replace',1)
                gc.setStencilTest('equal',1)
                gc.setColor(COLOR.rainbow(t*(c==4 and 2.6 or 6.26)-i))
                gc.print(trophy,sin(t*355)*((c==4 and 1 or 2.6)+.6*sin(t*.626)),195+1.6*sin(t*260))
                gc.setStencilTest()
            end
            gc.setColor(1,1,1,.9)
            gc.print(trophy,0,195)
        end
    end
    gc.pop()

    drawHits(results.hits,480,240)
end

scene.widgetList={
    WIDGET.new{type='button_fill',x=940,y=640,w=170,h=80,fontSize=60,text=CHAR.icon.retry_spin,code=WIDGET.c_pressKey'restart'},
    WIDGET.new{type='button_fill',x=1140,y=640,w=170,h=80,sound='back',fontSize=60,text=CHAR.icon.back,code=WIDGET.c_backScn},
}
return scene
