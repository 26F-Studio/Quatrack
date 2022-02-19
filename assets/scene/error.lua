local gc=love.graphics
local rnd=math.random

local BGcolor
local sysAndScn,errorText
local errorShot,errorInfo

local scene={}

function scene.enter()
    BGcolor=rnd()>.026 and{.3,.5,.9} or{.62,.3,.926}
    sysAndScn=SYSTEM.."-"..VERSION.string.."       scene:"..Zenitha.getErr('#').scene
    errorText=LOADED and Text.errorMsg or "An error has occurred while the game was loading.\nAn error log has been created so you can send it to the author."
    errorShot,errorInfo=Zenitha.getErr('#').shot,Zenitha.getErr('#').mes
end

function scene.draw()
    gc.clear(BGcolor)
    if errorShot then
        gc.setColor(1,1,1)
        gc.draw(errorShot,100,326,nil,512/errorShot:getWidth(),288/errorShot:getHeight())
    end
    gc.setColor(COLOR.Z)
    FONT.set(100)gc.print(":(",100,0,0,1.2)
    FONT.set(40)gc.printf(errorText,100,160,SCR.w0-100)
    FONT.set(20,'mono')
    gc.print(sysAndScn,100,630)
    FONT.set(15,'mono')
    gc.printf(errorInfo[1],626,326,1260-626)
    gc.print("TRACEBACK",626,390)
    for i=4,#errorInfo do
        gc.print(errorInfo[i],626,340+20*i)
    end
end

scene.widgetList={
    WIDGET.new{type='button',x=940,y=640,w=170,h=80,sound='key',fontSize=65,text=CHAR.icon.console,code=WIDGET.c_goScn'app_console'},
    WIDGET.new{type='button',x=1140,y=640,w=170,h=80,sound='key',fontSize=40,text=CHAR.icon.cross_thick,code=love.event.quit},
}

return scene
