local gc=love.graphics

local max,min=math.max,math.min
local int,abs=math.floor,math.abs
local sin,cos=math.sin,math.cos


local scene={}

function scene.sceneInit()
    BG.set()
end

function scene.draw()
    gc.push('transform')
    gc.translate(640+sin(2.6*TIME()),120+sin(3.6*TIME()))
    setFont(100)
    gc.setColor(COLOR.Z)
    gc.setColorMask(true,false,false,true)
    mStr('QUATRACK',sin(6*TIME()),sin(11*TIME()))
    gc.setColorMask(false,true,false,true)
    mStr('QUATRACK',sin(7*TIME()),sin(10*TIME()))
    gc.setColorMask(false,false,true,true)
    mStr('QUATRACK',sin(8*TIME()),sin(9*TIME()))
    gc.setColorMask()
    gc.pop()
end

scene.widgetList={
    WIDGET.newButton{name="play",   fText="Play",x=240,y=450,w=280,h=120,color="lR",font=45,code=goScene"game"},
    WIDGET.newButton{name="editor", fText="Editor",x=640,y=450,w=280,h=120,color="D",font=45,code=function()MES.new('warn',"Coming soon")end},
    WIDGET.newButton{name="setting",fText="Setting",x=1040,y=450,w=280,h=120,color="D",font=45,code=function()MES.new('warn',"Coming soon")end},
}

return scene
