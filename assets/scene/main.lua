local scene={}

local tryCounter=0

function scene.enter()
    BG.set()
    BGM.play()
end

function scene.keyDown(key)
    if key=='application' then
        SCN.go('result')
    else
        return true
    end
end

function scene.draw()
    GC.setColor(1,1,1)
    GC.mDraw(IMG.logo_full,640,200,0,.3)
    GC.setColor(1,1,1,(1-math.abs(math.sin(love.timer.getTime())))^3/2)
    GC.mDraw(IMG.logo_color,640,200,0,.3)
end

scene.widgetList={
    WIDGET.new{type='button_fill',x=200,y=80,w=100,        color='lI',fontSize=70,text=CHAR.icon.language,   code=WIDGET.c_goScn'lang'},
    WIDGET.new{type='button_fill',x=240,y=450,w=280,h=120, color="lR",fontSize=45,text=LANG'main_play',      code=WIDGET.c_goScn'mapSelect'},
    WIDGET.new{type='button_fill',x=640,y=450,w=280,h=120, color="lB",fontSize=45,text=LANG'main_setting',   code=WIDGET.c_goScn'setting'},
    WIDGET.new{type='button_fill',x=240,y=600,w=95,        color="lY",fontSize=70,text=CHAR.icon.info_circ,  code=WIDGET.c_goScn'stat'},
    WIDGET.new{type='button_fill',x=1040,y=450,w=280,h=120,color="D",fontSize=45,text=LANG'main_editor',     code=function() MSG.new('info',"Coming soon",1.26) tryCounter=(tryCounter+1)%12 if tryCounter==0 then SCN.go('_console') end end},
    WIDGET.new{type='button_fill',x=1040,y=600,w=95,       color="G",fontSize=70,text=CHAR.icon.zictionary,  code=function() love.system.openURL("https://github.com/26F-Studio/Quatrack/wiki/beatmap") end},
}

return scene
