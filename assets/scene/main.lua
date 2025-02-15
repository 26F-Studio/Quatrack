---@type Zenitha.Scene
local scene={}

local tryCounter=0
local fool=os.date("%m%d")=="0401"

function scene.load()
    BG.set()
    BGM.play('title')
end

function scene.keyDown(key)
    if key=='application' then
        SCN.go('result')
        return true
    end
end

function scene.draw()
    GC.setColor(1,1,1)
    GC.mDraw(IMG.logo_full,640,200,0,.3)
    GC.setColor(1,1,1,(1-math.abs(math.sin(love.timer.getTime())))^3/2)
    GC.mDraw(IMG.logo_color,640,200,0,.3)
    if fool then
        GC.setColor(1,.26,.26)
        GC.setLineWidth(26)
        GC.line(260,160,1010,260)
        GC.setColor(1,1,1)
        FONT.set(150,'_basic')
        GC.strokePrint('full',4,COLOR.D,COLOR.L,"Techmino",640,130,nil,'center')
        GC.translate(860,260)
        GC.rotate(-.0626)
        FONT.set(70,'_basic')
        GC.strokePrint('full',3,COLOR.D,COLOR.L,"Galaxy",0,0,nil,'center')
    end
end

scene.widgetList={
    WIDGET.new{type='button_fill',x=200,y=80,w=100,        color='lI',fontSize=70,text=CHAR.icon.language,   onClick=WIDGET.c_goScn'lang'},
    WIDGET.new{type='button_fill',x=240,y=450,w=280,h=120, color="lR",fontSize=45,text=LANG'main_play',      onClick=WIDGET.c_goScn'mapSelect'},
    WIDGET.new{type='button_fill',x=640,y=450,w=280,h=120, color="lB",fontSize=45,text=LANG'main_setting',   onClick=WIDGET.c_goScn'setting'},
    WIDGET.new{type='button_fill',x=240,y=600,w=95,        color="lY",fontSize=70,text=CHAR.icon.info_circ,  onClick=WIDGET.c_goScn'stat'},
    WIDGET.new{type='button_fill',x=1040,y=450,w=280,h=120,color="D",fontSize=45,text=LANG'main_editor',     onClick=function() MSG('info',"Coming soon",1.26) tryCounter=(tryCounter+1)%12 if tryCounter==0 then SCN.go('_console') end end},
    WIDGET.new{type='button_fill',x=1040,y=600,w=95,       color="G",fontSize=70,text=CHAR.icon.zictionary,  onClick=function() love.system.openURL("https://github.com/26F-Studio/Quatrack/wiki/beatmap") end},
}

return scene
