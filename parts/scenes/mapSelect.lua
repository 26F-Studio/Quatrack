local gc=love.graphics

local listBox=WIDGET.newListBox{name='sel',x=100,y=80,w=1080,h=480,lineH=40,drawF=function(v,k,sel)
    if sel then
        gc.setColor(COLOR.X)
        gc.rectangle('fill',0,0,1080,40)
    end
    setFont(30)
    gc.setColor(COLOR.Z)
    gc.print(k,8,-1)
    gc.print(v.name,80,-1)
end}

local mapList=love.filesystem.getDirectoryItems('parts/levels')
for i=1,#mapList do
    mapList[i]={
        fileName=mapList[i],
        name=mapList[i]:gsub("%.qmp",""),
    }
end

local scene={}

function scene.sceneInit()
    BGM.play()
    listBox:setList(mapList)
end

function scene.keyDown(key,isRep)
    if isRep then return true end
    if key=='return'then
        local mapName=listBox:getSel().fileName
        if mapName then
            local success,res=pcall(require'parts.map'.new,('parts/levels/$1'):repD(mapName))
            if success then
                SFX.play('enter')
                SCN.go('game',nil,res)
            else
                MES.new('error',res)
            end
        end
    elseif key=='escape'then
        SCN.back()
    else
        return true
    end
end

scene.widgetList={
    listBox,
    WIDGET.newButton{name="back", x=1140,y=640,w=170,h=80,sound='back',font=60,fText=CHAR.icon.back,code=backScene},
}
return scene
