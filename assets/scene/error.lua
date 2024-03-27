local rnd=math.random

local BGcolor
local sysAndScn,errorText
local errorShot,errorInfo

local scene={}

function scene.enter()
    BGcolor=rnd()>.026 and{.3,.5,.9} or{.62,.3,.926}
    sysAndScn=SYSTEM.."-"..VERSION.string.."       scene:"..Zenitha.getErr('#').scene
    errorText=LOADED and Text.errorMsg or "An error has occurred while the game was loading.\nAn error log has been created so you can send it to the author."
    errorShot,errorInfo=Zenitha.getErr('#').shot,Zenitha.getErr('#').msg
    if SETTINGS then
        SFX.play('error',SETTINGS.sfxVol or 0)
    end
end

function scene.draw()
    GC.clear(BGcolor)
    if errorShot then
        GC.setColor(1,1,1)
        GC.draw(errorShot,100,326,nil,512/errorShot:getWidth(),288/errorShot:getHeight())
    end
    GC.setColor(COLOR.L)
    FONT.set(100)GC.print(":(",100,0,0,1.2)
    FONT.set(40)GC.printf(errorText,100,160,SCR.w0-100)
    FONT.set(20,'mono')
    GC.print(sysAndScn,100,630)
    FONT.set(15,'mono')
    GC.printf(errorInfo[1],626,326,1260-626)
    GC.print("TRACEBACK",626,390)
    for i=4,#errorInfo do
        GC.print(errorInfo[i],626,340+20*i)
    end
end

scene.widgetList={
    WIDGET.new{type='button',x=940,y=640,w=170,h=80,sound_press='key',fontSize=65,text=CHAR.icon.console,code=WIDGET.c_goScn'_console'},
    WIDGET.new{type='button',x=1140,y=640,w=170,h=80,sound_press='key',fontSize=40,text=CHAR.icon.cross_big,code=love.event.quit},
}

return scene
