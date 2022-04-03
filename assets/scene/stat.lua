local gc=love.graphics

local scene={}

local item

function scene.enter()
    BG.set('none')
    item={
        STAT.run,
        STAT.game,
        STRING.time(STAT.time),
        STAT.score,
    }
end

function scene.draw()
    local t=love.timer.getTime()

    -- Infomation
    gc.push('transform')
    gc.translate(120,100+4*math.sin(t))
    gc.setColor(COLOR.lC)
    gc.setLineWidth(4)
    gc.rectangle('line',0,0,626,326)
    FONT.set(30)
    for i=1,#item do
        gc.print(item[i],220,i*50-30)
        gc.print(Text.stat[i],20,i*50-30)
    end
    gc.pop()

    -- Character
    gc.translate(962,300)
    gc.setColor(1,1,1)
    gc.scale(.626)
    GC.draw(IMG.z.character)
    GC.draw(IMG.z.screen1, -91, -157+16*math.sin(t))
    GC.draw(IMG.z.screen2, 120, -166+16*math.sin(t+1))
    gc.setColor(1,1,1,.7+.3*math.sin(.6*t)) GC.draw(IMG.z.particle1, -50,                    42+6*math.sin(t*0.36))
    gc.setColor(1,1,1,.7+.3*math.sin(.7*t)) GC.draw(IMG.z.particle2, 110+6*math.sin(t*0.92), 55)
    gc.setColor(1,1,1,.7+.3*math.sin(.8*t)) GC.draw(IMG.z.particle3, -54+6*math.sin(t*0.48), -248)
    gc.setColor(1,1,1,.7+.3*math.sin(.9*t)) GC.draw(IMG.z.particle4, 133,                    -305+6*math.sin(t*0.40))
end

scene.widgetList={
    WIDGET.new{type='button_fill',pos={1,1},x=-320,y=-80,w=200,h=80,fontSize=25,text=LANG'stat_path',
        code=function()
            if not MOBILE then
                love.system.openURL(love.filesystem.getSaveDirectory())
            else
                MES.new('info',love.filesystem.getSaveDirectory())
            end
        end
    },
    WIDGET.new{type='button_fill',pos={1,1},x=-120,y=-80,w=160,h=80,sound='back',fontSize=60,text=CHAR.icon.back,code=WIDGET.c_backScn},
}

return scene
