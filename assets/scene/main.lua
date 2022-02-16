local scene={}

local title

function scene.enter()
    BG.set()
    BGM.play()
    title=MATH.roll(1e-6) and 'QUADTRACK' or 'QUATRACK'
end

function scene.keyDown(key)
    if key=='application' then
        SCN.go('result')
    else
        return true
    end
end

function scene.draw()
    FONT.set(100)
    posterizedText(title,640,120)
end

scene.widgetList={
    WIDGET.new{type='button_fill',x=240,y=80,w=100,        sound='button',color='lN',fontSize=70,text=CHAR.icon.language,           code=WIDGET.c_goScn'lang'},
    WIDGET.new{type='button_fill',x=240,y=450,w=280,h=120, sound='button',color="lR",fontSize=45,text=LANG'main_play',      code=WIDGET.c_goScn'mapSelect'},
    WIDGET.new{type='button_fill',x=640,y=450,w=280,h=120, sound='button',color="lB",fontSize=45,text=LANG'main_setting',   code=WIDGET.c_goScn'setting'},
    WIDGET.new{type='button_fill',x=240,y=600,w=95,        sound='button',color="lY",fontSize=70,text=CHAR.key.winMenu,             code=WIDGET.c_goScn'stat'},
    WIDGET.new{type='button_fill',x=1040,y=450,w=280,h=120,sound='button',color="D",fontSize=45,text=LANG'main_editor',     code=function() MES.new('info',"Coming soon") end},
    WIDGET.new{type='button_fill',x=1040,y=600,w=95,       sound='button',color="G",fontSize=70,text=CHAR.icon.zBook,               code=function() love.system.openURL("https://github.com/26F-Studio/Quatrack/wiki/beatmap") end},
}

return scene
