local gc=love.graphics

local min=math.min
local sin=math.sin


local hitColors=hitColors
local hitTexts=hitTexts
local rankColors=rankColors
local results

local scene={}

function scene.sceneInit()
    results=SCN.args[1]or{
        fake=true,
        map=require'parts.map'.new(),
        score=62600,
        maxCombo=260,
        accText="96.20%",
        averageDeviate='26.26ms',
        hits={
            [-1]=4,
            [0]=4,
            [1]=4,
            [2]=62,
            [3]=62,
            [4]=62,
            [5]=62,
        },
        bestChain=math.random(5),
    }
    results.mapName=gc.newText(getFont(80,'mono'),results.map.mapName)
    results.mapDifficulty=gc.newText(getFont(30,'mono'),results.map.mapDifficulty)
    local acc=tonumber(results.accText:sub(1,-2))
    results.rank=gc.newText(getFont(100,'mono'),
        acc==101 and{rankColors[1],'X'}or
        acc>=100 and{rankColors[2],'U'}or
        acc>=97 and{rankColors[3],'S'}or
        acc>=94 and{rankColors[4],'A'}or
        acc>=90 and{rankColors[5],'B'}or
        acc>=85 and{rankColors[6],'C'}or
        acc>=80 and{rankColors[7],'D'}or
        acc>=70 and{rankColors[8],'E'}or
        {rankColors[9],'F'}
    )

    BGM.play('result')
    BG.set()
end

function scene.keyDown(key,isRep)
    if isRep then return end
    local k=KEY_MAP[key]or key
    if k=='restart'then
        if results.map.valid then
            local map,errmsg=loadBeatmap(results.map.qbpFilePath)
            if map then
                SCN.swapTo('game',nil,map)
            else
                MES.new('error',errmsg)
            end
        end
    elseif k=='escape'then
        SCN.back()
    end
end

local _stencilX
local function _marvStencil()
    gc.rectangle('fill',_stencilX,210,100,100)
end
function scene.draw()
    gc.setColor(COLOR.Z)
    gc.push('transform')
        gc.translate(640,100)
        gc.scale(min(900/results.mapName:getWidth(),1))
        mText(results.mapName,0,0)
    gc.pop()
    mText(results.mapDifficulty,640,200)

    gc.push('transform')
    gc.translate(240,255)

    --Draw score & accuracy & combo
    gc.setColor(COLOR.Z)
    gc.push('transform')
    gc.scale(2.2)
    posterizedDraw(results.rank,28,45)
    gc.pop()
    setFont(60)
    gc.print(results.score,140,0)
    setFont(50)
    gc.print(results.accText,140,60)
    setFont(15)
    gc.print(results.averageDeviate,145,120)
    setFont(40)
    gc.print(results.maxCombo.."x",140,135)

    --Draw trophy
    if results.bestChain>0 then
        local t=TIME()
        local c=results.bestChain
        local trophy=text.chainTexts[c]
        setFont(80)
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

    --Draw hits
    setFont(40)
    for i=-1,5 do
        gc.setColor(hitColors[i])
        gc.printf(hitTexts[i],725,460-40*i,200,'right')
        gc.print(results.hits[i],960,460-40*i)
        gc.setColor(1,1,1,.626)
        gc.print(results.hits[i],960,460-40*i)
    end
end

scene.widgetList={
    WIDGET.newButton{name="again",x=940,y=640,w=170,h=80,font=60,fText=CHAR.icon.retry_spin,code=pressKey'restart'},
    WIDGET.newButton{name="back", x=1140,y=640,w=170,h=80,sound='back',font=60,fText=CHAR.icon.back,code=backScene},
}
return scene
