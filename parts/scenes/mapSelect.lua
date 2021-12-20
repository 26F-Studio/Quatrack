local gc=love.graphics

local max,min=math.max,math.min
local ins=table.insert

local listBox=WIDGET.newListBox{name='sel',x=60,y=80,w=1160,h=480,lineH=40,drawF=function(v,_,sel)
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
    gc.draw(v.mapName,10,-1,nil,min(800/v.mapName:getWidth(),1),1)
    gc.setColor(COLOR.Z)
    gc.printf(v.mapAuth,0,0,1000,'right')
    gc.draw(v.difficulty,1105-v.difficulty:getWidth(),0)
    gc.setColor(COLOR.lS)
    gc.printf(v.tracks,0,0,1150,'right')
end}

local lastFreshTime=0

local mapList
local function _freshSongList()
    lastFreshTime=TIME()
    mapList={}
    for source,path in next,{game='parts/levels',outside='songs'}do
        for _,fileName in next,love.filesystem.getDirectoryItems(path)do
            if fileName:sub(-4)=='.qbp'then
                local fullPath=path..'/'..fileName
                local iterator=love.filesystem.newFile(fullPath):lines()
                local metaData={
                    mapName="*"..fileName,
                    musicAuth="?",
                    mapAuth="?",
                    mapDifficulty="LV.?",
                    tracks="?",
                }
                while true do
                    local line=iterator()
                    if not line then break end
                    line=line:trim()
                    if line~=''and line:sub(1,1)~='#'then
                        if line:sub(1,1)~='$'then break end
                        local key,value=line:match('^%$(.-)=(.+)')
                        if key and value and mapMetaKeyMap[key]then
                            metaData[key]=value
                        end
                    end
                end
                ins(mapList,{
                    path=path..'/'..fileName,
                    source=source,
                    mapName=gc.newText(getFont(30),metaData.mapName.." - "..metaData.musicAuth),
                    mapAuth=metaData.mapAuth,
                    difficulty=gc.newText(getFont(30),metaData.mapDifficulty),
                    tracks=metaData.tracks,
                })
            end
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
    WIDGET.newButton{name="fresh",x=320,y=640,w=80,fText=CHAR.icon.retry_spin,color='lB',font=50,code=_freshSongList,hideF=function()return TIME()-lastFreshTime<1 end},
    WIDGET.newButton{name="play",x=640,y=640,w=140,h=80,fText=CHAR.icon.play,color='lG',font=60,code=pressKey'return'},
    WIDGET.newButton{name="back", x=1140,y=640,w=170,h=80,sound='back',font=60,fText=CHAR.icon.back,code=backScene},
}
return scene
