local gc=love.graphics

local min=math.min
local sin=math.sin


local hitColors=hitColors
local hitTexts=hitTexts

local results

local scene={}

function scene.sceneInit()
    results=SCN.args[1]or{
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
        bestChain=4,
    }
    results.mapName=gc.newText(getFont(80,'mono'),results.map.mapName)
    results.mapDifficulty=gc.newText(getFont(30,'mono'),results.map.mapDifficulty)

    BGM.play('result')
    BG.set()
end

function scene.keyDown(key,isRep)
    if isRep then return end
    local k=KEY_MAP[key]
    if k then
        if k=='restart'then
            local map,errmsg=loadBeatmap(results.map.qbpFilePath)
            if map then
                SCN.swapTo('game',nil,map)
            else
                MES.new('error',errmsg)
            end
        end
    elseif key=='escape'then
        SCN.back()
    end
end

local _stencilX
local function _marvStencil()
    gc.rectangle('fill',_stencilX,430,100,50)
end
function scene.draw()
    gc.setColor(COLOR.Z)
    gc.push('transform')
        gc.translate(640,150)
        gc.scale(min(900/results.mapName:getWidth(),1))
        posterizedDraw(results.mapName,0,0)
    gc.pop()
    posterizedDraw(results.mapDifficulty,640,200)

    setFont(40)
    for i=-1,5 do
        gc.setColor(hitColors[i])
        gc.printf(hitTexts[i],130,460-40*i,200,'right')
        gc.print(results.hits[i],365,460-40*i)
        gc.setColor(1,1,1,.26)
        gc.printf(hitTexts[i],130,460-40*i,200,'right')
    end

    gc.setColor(COLOR.Z)
    setFont(60)
    gc.print(results.score,800,255)
    setFont(50)
    gc.print(results.accText,800,315)
    setFont(30)
    gc.print(results.averageDeviate,800,365)

    setFont(40)
    gc.print(results.maxCombo.."x",800,500)

    if results.bestChain>0 then
        local t=TIME()
        local c=results.bestChain
        local trophy=text.chainTexts[c]
        setFont(55)
        if c==1 then
            gc.setColor(chainColors[c])
            gc.print(trophy,800,415)
            gc.setColor(1,1,1,.626)
            gc.print(trophy,800,415)
        elseif c==2 then
            gc.setColor(chainColors[c])
            gc.print(trophy,800,415)
            gc.setColor(1,1,1,.626+.0626*sin(t*62.6))
            gc.print(trophy,800,415)
        elseif c==3 then
            gc.setColor(chainColors[3])
            gc.print(trophy,800,415)
            gc.setColor(1,1,1,.9+.05*sin(t*62.6))
            gc.print(trophy,800,415)
        elseif c==4 then
            gc.setColor(chainColors[4])
            gc.print(trophy,800,415)
            gc.setColor(1,1,1,.8+.1*sin(t*62.6))
            gc.print(trophy,800,415)
        elseif c==5 then
            for i=0,2 do
                _stencilX=800+100*i
                gc.stencil(_marvStencil,'replace',1)
                gc.setStencilTest('equal',1)
                gc.setColor(COLOR.rainbow_light(t*6.26-i))
                gc.print(trophy,800+2*sin(t*626),415+2*sin(t*355))
                gc.setStencilTest()
            end
            gc.setColor(1,1,1,.9)
            gc.print(trophy,800,415)
        end
    end
end

scene.widgetList={
    WIDGET.newButton{name="back", x=1140,y=640,w=170,h=80,sound='back',font=60,fText=CHAR.icon.back,code=backScene},
}
return scene
