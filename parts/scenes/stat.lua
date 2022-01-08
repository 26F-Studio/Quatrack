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

    --Draw hits
    local hits=STAT.hits
    gc.translate(0,260)
    setFont(100)
    gc.setColor(.92,.82,.65)
    gc.printf(hits.perf+hits.prec+hits.marv,-140,0,600,'right')

    setFont(80)
    gc.setColor(.58,.65,.96)
    gc.printf(hits.well+hits.good,-140,100,600,'right')

    gc.setColor(.6,.1,.1)
    gc.printf(hits.miss+hits.bad,-140,180,600,'right')

    setFont(25)
    gc.setColor(hitColors[5])
    gc.printf(hitTexts[5],-55,27,600,'right')
    gc.print(hits.marv,555,27)
    gc.setColor(hitColors[4])
    gc.printf(hitTexts[4],-55,52,600,'right')
    gc.print(hits.prec,555,52)
    gc.setColor(hitColors[3])
    gc.printf(hitTexts[3],-55,77,600,'right')
    gc.print(hits.perf,555,77)

    gc.setColor(hitColors[2])
    gc.printf(hitTexts[2],-55,123,600,'right')
    gc.print(hits.good,555,123)
    gc.setColor(hitColors[1])
    gc.printf(hitTexts[1],-55,153,600,'right')
    gc.print(hits.well,555,153)

    gc.setColor(hitColors[0])
    gc.printf(hitTexts[0],-55,203,600,'right')
    gc.print(hits.bad,555,203)
    gc.setColor(hitColors[-1])
    gc.printf(hitTexts[-1],-55,233,600,'right')
    gc.print(hits.miss,555,233)
    gc.translate(0,-260)
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
