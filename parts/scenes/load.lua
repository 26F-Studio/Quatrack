local gc=love.graphics

local scene={}

local loading,progress,maxProgress
local studioLogo--Studio logo text object
local logoColor1,logoColor2

local loadingThread=coroutine.wrap(function()
    BG.setDefault('space')
    BG.set()
    BGM.play()
    local r=math.random()*6.2832
    logoColor1={COLOR.rainbow(r)}
    logoColor2={COLOR.rainbow_light(r)}
    YIELD('loadSFX')SFX.load('media/effect/chiptune/')
    YIELD('loadVoice')VOC.load('media/vocal/')
    YIELD('loadFont')for i=1,17 do getFont(15+5*i)end

    STAT.run=STAT.run+1
    saveStats()
    LOADED=true
    return'finish'
end)

function scene.sceneInit()
    studioLogo=gc.newText(getFont(90),"26F Studio")
    progress=0
    maxProgress=10
end
function scene.sceneBack()
    love.event.quit()
end

function scene.mouseDown()
    if LOADED then
        if FIRSTLAUNCH then
            SCN.push('main')
            SCN.swapTo('lang')
        else
            SCN.swapTo('main')
        end
    end
end
scene.touchDown=scene.mouseDown
function scene.keyDown(key)
    if key=="escape"then
        love.event.quit()
    elseif LOADED then
        scene.mouseDown()
    end
end

function scene.update()
    if not LOADED then
        loading=loadingThread()or loading
        progress=progress+1
    end
end

function scene.draw()
    gc.setColor(1,1,1)
    mDraw(IMG.title,640,200,0,.3)

    gc.setColor(logoColor1[1],logoColor1[2],logoColor1[3],progress/maxProgress)mDraw(studioLogo,640,400)
    gc.setColor(logoColor2[1],logoColor2[2],logoColor2[3],progress/maxProgress)for dx=-2,2,2 do for dy=-2,2,2 do mDraw(studioLogo,640+dx,400+dy)end end
    gc.setColor(.2,.2,.2,progress/maxProgress)mDraw(studioLogo,640,400)

    gc.setColor(1,1,1)
    setFont(30)
    mStr(text.loadText[loading],640,530)
end

return scene