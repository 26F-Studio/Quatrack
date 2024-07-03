---@type Zenitha.Scene
local scene={}

local item

function scene.load()
    BG.set('none')
    item={
        STAT.run,
        STAT.game,
        STRING.time(STAT.time),
        STAT.score,
    }
end

local function drawPannel()
    GC.setLineWidth(4)
    GC.rectangle('line',0,0,626,326)
    FONT.set(30)
    for i=1,#item do
        GC.print(item[i],220,i*50-30)
        GC.print(Text.stat[i],20,i*50-30)
    end
end

function scene.draw()
    local t=love.timer.getTime()

    -- Infomation
    GC.push('transform')
    GC.translate(120,100+4*math.sin(t))
    GC.setColor(.4,.97,.94)
    drawPannel()
    GC.translate(4*math.sin(t*.6),3*math.sin(t*.5))
    GC.setColor(.7,.97,.94,.4)
    drawPannel()
    GC.pop()

    -- Character
    GC.translate(962,300)
    GC.setColor(1,1,1)
    GC.scale(.626)
    GC.mDraw(IMG.z.character)
    GC.mDraw(IMG.z.screen1, -91, -157+16*math.sin(t))
    GC.mDraw(IMG.z.screen2, 120, -166+16*math.sin(t+1))
    GC.setColor(1,1,1,.7+.3*math.sin(.6*t)) GC.mDraw(IMG.z.particle1, -50,                    42+6*math.sin(t*0.36))
    GC.setColor(1,1,1,.7+.3*math.sin(.7*t)) GC.mDraw(IMG.z.particle2, 110+6*math.sin(t*0.92), 55)
    GC.setColor(1,1,1,.7+.3*math.sin(.8*t)) GC.mDraw(IMG.z.particle3, -54+6*math.sin(t*0.48), -248)
    GC.setColor(1,1,1,.7+.3*math.sin(.9*t)) GC.mDraw(IMG.z.particle4, 133,                    -305+6*math.sin(t*0.40))
end

scene.widgetList={
    WIDGET.new{type='button_fill',pos={1,1},x=-320,y=-80,w=200,h=80,fontSize=25,text=LANG'stat_path',
        code=function()
            if not MOBILE then
                love.system.openURL(love.filesystem.getSaveDirectory())
            else
                MSG.new('info',love.filesystem.getSaveDirectory())
            end
        end
    },
    WIDGET.new{type='button_fill',pos={1,1},x=-120,y=-80,w=160,h=80,sound_press='back',fontSize=60,text=CHAR.icon.back,code=WIDGET.c_backScn()},
}

return scene
