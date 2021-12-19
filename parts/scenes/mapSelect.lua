local gc=love.graphics

local ins=table.insert

local listBox=WIDGET.newListBox{name='sel',x=60,y=80,w=1160,h=480,lineH=40,drawF=function(v,k,sel)
    if sel then
        gc.setColor(COLOR.X)
        gc.rectangle('fill',0,0,1160,40)
    end
    setFont(30)
    gc.setColor(
        v.source=='game'and COLOR.Z or
        v.source=='outside'and COLOR.lY or
        COLOR.D
    )
    gc.print(k,8,-1)
    gc.print(v.name,80,-1)
end}

local mapList
local function _freshSongList()
    mapList={}
    for _,fileName in next,love.filesystem.getDirectoryItems('parts/levels')do
        ins(mapList,{
            path='parts/levels/'..fileName,
            name=fileName:sub(1,-5),
            source='game',
        })
    end
    for _,fileName in next,love.filesystem.getDirectoryItems('songs')do
        if fileName:sub(-4)=='.qbp'then
            ins(mapList,{
                path='songs/'..fileName,
                name=fileName:sub(1,-5),
                source='outside',
            })
        end
    end
    table.sort(mapList,function(a,b) return a.path<b.path end)
end

local scene={}

function scene.sceneInit()
    _freshSongList()
    BGM.play()
    listBox:setList(mapList)
end

function scene.keyDown(key,isRep)
    if isRep then return end
    if key=='return'then
        local map,errmsg=loadBeatmap(listBox:getSel().path)
        if map then
            SFX.play('enter')
            SCN.go('game',nil,map)
        else
            MES.new('error',errmsg)
        end
    elseif key=='up'or key=='down'then
        listBox:arrowKey(key)
    elseif key=='escape'then
        SCN.back()
    end
end

scene.widgetList={
    listBox,
    WIDGET.newButton{name="openDir",x=160,y=640,w=200,h=80,fText=CHAR.icon.import,color='lV',font=60,
        code=function()
            if SYSTEM=="Windows"or SYSTEM=="Linux"then
                love.system.openURL(SAVEDIR..'/songs')
            else
                MES.new('info',SAVEDIR)
            end
        end
    },
    WIDGET.newButton{name="play",x=640,y=640,w=140,h=80,fText=CHAR.icon.play,color='lG',font=60,code=pressKey'return'},
    WIDGET.newButton{name="back", x=1140,y=640,w=170,h=80,sound='back',font=60,fText=CHAR.icon.back,code=backScene},
}
return scene
