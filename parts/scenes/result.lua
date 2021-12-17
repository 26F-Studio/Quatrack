local gc=love.graphics

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

local results

local scene={}

function scene.sceneInit()
    results=SCN.args[1]or{
        mapName="/",
        score=62600,
        maxCombo=260,
        accText="96.20%",
        hits={
            [-1]=4,
            [0]=4,
            [1]=4,
            [2]=62,
            [3]=62,
            [4]=62,
            [5]=62,
        }
    }
    BGM.play('result')
    BG.set()
end

function scene.keyDown(key,isRep)
    if isRep then return end
    if key=='escape' then
        SCN.back()
    end
end

function scene.draw()
    gc.setColor(COLOR.Z)
    setFont(100,'mono')
    posterizedText('Result',640,60)

    setFont(40)
    for i=-1,5 do
        gc.setColor(hitColors[i])
        gc.printf(hitTexts[i],130,460-40*i,200,'right')
        gc.print(results.hits[i],365,460-40*i)
        gc.setColor(1,1,1,.26)
        gc.printf(hitTexts[i],130,460-40*i,200,'right')
        gc.print(results.hits[i],365,460-40*i)
    end

    gc.setColor(COLOR.Z)
    setFont(60)
    gc.print(results.score,800,255)
    setFont(50)
    gc.print(results.accText,800,315)

    setFont(40)
    gc.print(results.maxCombo.."x",800,500)
end

scene.widgetList={
    WIDGET.newButton{name="back", x=1140,y=640,w=170,h=80,sound='back',font=60,fText=CHAR.icon.back,code=backScene},
}
return scene
