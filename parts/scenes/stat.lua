local gc=love.graphics

local scene={}

local item

function scene.sceneInit()
    BG.set()
    item={
        STAT.run,
        STAT.game,
        STRING.time(STAT.time),
        STAT.score,
    }
end

function scene.draw()
    gc.setColor(COLOR.Z)
    setFont(30)
    for i=1,#item do
        gc.print(item[i],300,i*50)
        gc.print(text.stat[i],100,i*50)
    end

    drawHits(STAT.hits,0,260)
end

scene.widgetList={
    WIDGET.newButton{name='path',x=860,y=640,w=250,h=80,font=25,
        code=function()
            if SYSTEM=="Windows"or SYSTEM=="Linux"then
                love.system.openURL(SAVEDIR)
            else
                MES.new('info',SAVEDIR)
            end
        end
    },
    WIDGET.newButton{name='back',x=1140,y=640,w=170,h=80,sound='back',font=60,fText=CHAR.icon.back,code=backScene},
}

return scene
