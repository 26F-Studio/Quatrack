local gc=love.graphics

local listBox=WIDGET.newListBox{name='sel',x=100,y=80,w=1080,h=480,lineH=40,drawF=function(v,k,sel)
    if sel then
        gc.setColor(COLOR.X)
        gc.rectangle('fill',0,0,1080,40)
    end
    setFont(30)
    gc.setColor(COLOR.Z)
    gc.print(k,8,-1)
    gc.print(v,80,-1)
end}

local mapList={
    'GOODRAGE',
}

local scene={}

function scene.sceneInit()
    listBox:setList(mapList)
end

function scene.keyDown(key,isRep)
    if isRep then return end
    if key=='return'then
        local rep=listBox:getSel()
        if rep then
            SCN.go('game',nil,rep)
        end
    elseif key=='escape'then
        SCN.back()
    end
end

scene.widgetList={
    listBox,
    WIDGET.newButton{name="back", x=1140,y=640,w=170,h=80,font=60,fText=CHAR.icon.back,code=backScene},
}
return scene
