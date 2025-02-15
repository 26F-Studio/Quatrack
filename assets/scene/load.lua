---@type Zenitha.Scene
local scene={}

local loading,progress,maxProgress
local studioLogo-- Studio logo text object
local logoColor1,logoColor2

local loadingThread=coroutine.wrap(function()
    BG.setDefault(MOBILE and 'space' or 'galaxy')
    BG.set()
    BGM.play('title')
    coroutine.yield('loadVoice')VOC.load('assets/vocal/')
    coroutine.yield('loadFont') for i=1,17 do FONT.get(15+5*i) end

    STAT.run=STAT.run+1
    saveStats()
    LOADED=true
    return 'finish'
end)

function scene.load()
    local r=math.random()*6.2832
    logoColor1={COLOR.rainbow(r)}
    logoColor2={COLOR.rainbow_light(r)}
    studioLogo=GC.newText(FONT.get(90),"26F Studio")
    progress=0
    maxProgress=10
end

function scene.mouseDown()
    if LOADED then
        if FIRSTLAUNCH then
            SCN._pop()
            SCN._push('main')
            SCN.go('lang')
        else
            SCN.swapTo('main')
        end
    end
end
scene.touchDown=scene.mouseDown
function scene.keyDown(key)
    if key=="escape" then
        love.event.quit()
    elseif LOADED then
        scene.mouseDown()
    end
    return true
end

function scene.update()
    if not LOADED then
        loading=loadingThread() or loading
        progress=progress+1
    end
end

function scene.draw()
    GC.setColor(1,1,1)
    GC.mDraw(IMG.logo_full,640,200,0,.3)
    GC.setColor(1,1,1,(1-math.abs(math.sin(love.timer.getTime())))^3/2)
    GC.mDraw(IMG.logo_color,640,200,0,.3)

    GC.setColor(logoColor1[1],logoColor1[2],logoColor1[3],progress/maxProgress)
    GC.mDraw(studioLogo,640,400)
    GC.setColor(logoColor2[1],logoColor2[2],logoColor2[3],progress/maxProgress)
    for dx=-2,2,2 do for dy=-2,2,2 do GC.mDraw(studioLogo,640+dx,400+dy) end end
    GC.setColor(.2,.2,.2,progress/maxProgress)GC.mDraw(studioLogo,640,400)

    if loading then
        GC.setColor(1,1,1)
        FONT.set(30)
        GC.mStr(Text.loadText[loading],640,530)
    end
end

return scene