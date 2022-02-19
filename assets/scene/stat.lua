local gc=love.graphics

local scene={}

local item

function scene.enter()
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
    FONT.set(30)
    for i=1,#item do
        gc.print(item[i],300,i*50)
        gc.print(Text.stat[i],100,i*50)
    end
end

scene.widgetList={
    WIDGET.new{type='button_fill',x=860,y=640,w=250,h=80,fontSize=25,text=LANG'stat_path',
        code=function()
            if SYSTEM=="Windows" or SYSTEM=="Linux" then
                love.system.openURL(love.filesystem.getSaveDirectory())
            else
                MES.new('info',love.filesystem.getSaveDirectory())
            end
        end
    },
    WIDGET.new{type='button_fill',x=1140,y=640,w=170,h=80,sound='back',fontSize=60,text=CHAR.icon.back,code=WIDGET.c_backScn},
}

return scene
