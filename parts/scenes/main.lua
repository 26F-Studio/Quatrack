local scene={}

function scene.sceneInit()
    BG.set()
    BGM.play()
end

function scene.keyDown(key)
    if key=='application'then
        SCN.go('result')
    end
end

function scene.draw()
    setFont(100)
    posterizedText('QUATRACK',640,120)
end

scene.widgetList={
    WIDGET.newButton{name="play",   x=240,y=450,w=280,h=120,color="lR",font=45,code=goScene"mapSelect"},
    WIDGET.newButton{name="setting",x=640,y=450,w=280,h=120,color="lB",font=45,code=goScene"setting"},
    WIDGET.newButton{name="editor", x=1040,y=450,w=280,h=120,color="D",font=45,code=function()MES.new('warn',"Coming soon")end},
}

return scene
