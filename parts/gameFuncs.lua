local gc=love.graphics
local sin=math.sin
local abs=math.abs

--System
do--function tryBack()
    local sureTime=-1e99
    function tryBack()
        if TIME()-sureTime<1 then
            sureTime=-1e99
            return true
        else
            sureTime=TIME()
            MES.new('warn',text.sureQuit)
        end
    end
end
do--function tryReset()
    local sureTime=-1e99
    function tryReset()
        if TIME()-sureTime<1 then
            sureTime=-1e99
            return true
        else
            sureTime=TIME()
            MES.new('warn',text.sureReset)
        end
    end
end
do--function tryDelete()
    local sureTime=-1e99
    function tryDelete()
        if TIME()-sureTime<1 then
            sureTime=-1e99
            return true
        else
            sureTime=TIME()
            MES.new('warn',text.sureDelete)
        end
    end
end
do--function loadFile(name,args), function saveFile(data,name,args)
    local t=setmetatable({},{__index=function()return"'$1' loading failed: $2"end})
    function loadFile(name,args)
        local text=text or t
        if not args then args=''end
        local res,mes=pcall(FILE.load,name,args)
        if res then
            return mes
        else
            if mes:find'open error'then
                MES.new('error',text.loadError_open:repD(name,""))
            elseif mes:find'unknown mode'then
                MES.new('error',text.loadError_errorMode:repD(name,args))
            elseif mes:find'no file'then
                if not args:sArg'-canSkip'then
                    MES.new('error',text.loadError_noFile:repD(name,""))
                end
            elseif mes then
                MES.new('error',text.loadError_other:repD(name,mes))
            else
                MES.new('error',text.loadError_unknown:repD(name,""))
            end
        end
    end
    function saveFile(data,name,args)
        local text=text or t
        local res,mes=pcall(FILE.save,data,name,args)
        if res then
            return mes
        else
            MES.new('error',
                mes:find'duplicate'and
                    text.saveError_duplicate:repD(name)or
                mes:find'encode error'and
                    text.saveError_encode:repD(name)or
                mes and
                    text.saveError_other:repD(name,mes)or
                text.saveError_unknown:repD(name)
            )
        end
    end
end
function isSafeFile(file,mes)
    if love.filesystem.getRealDirectory(file)~=SAVEDIR then
        return true
    elseif mes then
        MES.new('warn',mes)
    end
end
function saveStats()
    return saveFile(STAT,'conf/data')
end
function saveSettings()
    return saveFile(SETTING,'conf/settings')
end
do--function applySettings()
    function applySettings()
        --Apply language
        text=LANG.get(SETTING.locale)
        WIDGET.setLang(text.WidgetText)

        --Apply cursor
        love.mouse.setVisible(SETTING.sysCursor)

        --Apply fullscreen
        love.window.setFullscreen(SETTING.fullscreen)
        love.resize(gc.getWidth(),gc.getHeight())

        --Apply Zframework setting
        Z.setClickFX(SETTING.clickFX)
        Z.setPowerInfo(SETTING.powerInfo)
        Z.setCleanCanvas(SETTING.cleanCanvas)

        --Apply sound
        love.audio.setVolume(SETTING.mainVol)
        BGM.setVol(SETTING.bgm)
        SFX.setVol(SETTING.sfx)
        VOC.setVol(SETTING.voc)
    end
end
function applyFPS(inGame)
    if inGame then
        Z.setMaxFPS(SETTING.maxFPS)
        Z.setFrameMul(SETTING.frameMul)
    else
        Z.setMaxFPS(math.min(SETTING.maxFPS,90))
        Z.setFrameMul(100)
    end
end



--Game
function loadBeatmap(path)
    local success,res=pcall(require'parts.map'.new,path)
    if success then
        return res
    else
        return false,res
    end
end
function getHitLV(div,judgeTimes)
    div=abs(div)
    return
    div<=judgeTimes[5]and 5 or
    div<=judgeTimes[4]and 4 or
    div<=judgeTimes[3]and 3 or
    div<=judgeTimes[2]and 2 or
    div<=judgeTimes[1]and 1 or
    0
end
function mergeStat(stat,delta)--Merge delta stat. to global stat.
    for k,v in next,delta do
        if type(v)=='table'then
            if type(stat[k])=='table'then
                mergeStat(stat[k],v)
            end
        else
            if stat[k]then
                stat[k]=stat[k]+v
            end
        end
    end
end



--GC
do--function posterizedText(str,x,y)
    local TIME=TIME
    local gc_setColorMask=gc.setColorMask
    function posterizedText(str,x,y)
        local t=TIME()
        gc.push('transform')
        gc.translate(x+sin(2.6*t),y+sin(3.6*t))
        gc.setColor(1,1,1)
        gc_setColorMask(true,false,false,true)
        mStr(str,sin(6*t),sin(11*t))
        gc_setColorMask(false,true,false,true)
        mStr(str,sin(7*t),sin(10*t))
        gc_setColorMask(false,false,true,true)
        mStr(str,sin(8*t),sin(9*t))
        gc_setColorMask()
        gc.pop()
    end
    function posterizedDraw(obj,x,y)
        local t=TIME()
        gc.push('transform')
        gc.translate(x,y)
        gc_setColorMask(true,false,false,true)
        mDraw(obj,sin(6*t),sin(8*t))
        gc_setColorMask(false,true,false,true)
        mDraw(obj,sin(9.5*t),sin(5*t))
        gc_setColorMask(false,false,true,true)
        mDraw(obj,sin(6.5*t),sin(8.5*t))
        gc_setColorMask()
        gc.pop()
    end
end
function drawSafeArea(x,y,time,alpha)
    x,y=x*SCR.k-4,y*SCR.k-4
    gc.setColor(1,.626,.626,(alpha or 1)*math.min(.5,time)/5)
    gc.rectangle('fill',0,0,x,SCR.h)
    gc.rectangle('fill',SCR.w,0,-x,SCR.h)
    gc.rectangle('fill',x,0,SCR.w-2*x,y)
    gc.rectangle('fill',x,SCR.h,SCR.w-2*x,-y)
    gc.setColor(1,.1,.1,(alpha or 1)*math.min(.5,time)/2)
    gc.setLineWidth(4)
    x,y=x+1,y+1
    gc.line(0,0,x,y)
    gc.line(SCR.w,0,SCR.w-x,y)
    gc.line(0,SCR.h,x,SCR.h-y)
    gc.line(SCR.w,SCR.h,SCR.w-x,SCR.h-y)
    x,y=x+1,y+1
    gc.rectangle('line',x,y,SCR.w-2*x,SCR.h-2*y)
end
function drawHits(hits,x,y)
    gc.translate(x,y)
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
    gc.translate(-x,-y)
end



--Widget function shortcuts
function backScene()SCN.back()end
do--function goScene(name,style)
    local cache={}
    function goScene(name,style)
        local hash=style and name..style or name
        if not cache[hash]then
            cache[hash]=function()SCN.go(name,style)end
        end
        return cache[hash]
    end
end
do--function swapScene(name,style)
    local cache={}
    function swapScene(name,style)
        local hash=style and name..style or name
        if not cache[hash]then
            cache[hash]=function()SCN.swapTo(name,style)end
        end
        return cache[hash]
    end
end
do--function pressKey(k)
    local cache={}
    function pressKey(k)
        if not cache[k]then
            cache[k]=function()love.keypressed(k)end
        end
        return cache[k]
    end
end
do--CUS/SETXXX(k)
    function SETval(k)return function()return SETTING[k]end end
    function SETrev(k)return function()SETTING[k]=not SETTING[k]end end
    function SETsto(k)return function(i)SETTING[k]=i end end
end
