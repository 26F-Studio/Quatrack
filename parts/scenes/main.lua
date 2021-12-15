local gc=love.graphics

local scene={}

function scene.sceneInit()
    BG.set()
end

function scene.draw()
    --?
end

scene.widgetList={
    WIDGET.newButton{name="play",   fText="Play",x=240,y=450,w=280,h=120,color="lR",font=45,code=goScene"game"},
    WIDGET.newButton{name="editor", fText="Editor",x=640,y=450,w=280,h=120,color="D",font=45,code=goScene"editor"},
    WIDGET.newButton{name="setting",fText="Setting",x=1040,y=450,w=280,h=120,color="D",font=45,code=function()MES.new('warn',"Coming soon")end},
}

return scene
