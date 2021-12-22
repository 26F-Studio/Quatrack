local gc=love.graphics
local sin=math.sin

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

        --Apply language
        text=LANG.get(SETTING.locale)
        WIDGET.setLang(text.WidgetText)

        --Apply cursor
        love.mouse.setVisible(SETTING.sysCursor)

        --Apply BG
        if SETTING.bg=='on'then
            BG.unlock()
            BG.set()
        elseif SETTING.bg=='off'then
            BG.unlock()
            BG.set('gray')
            BG.send(SETTING.bgAlpha)
            BG.lock()
        elseif SETTING.bg=='custom'then
            if love.filesystem.getInfo('conf/customBG')then
                local res,image=pcall(gc.newImage,love.filesystem.newFile('conf/customBG'))
                if res then
                    BG.unlock()
                    BG.set('custom')
                    gc.setDefaultFilter('linear','linear')
                    BG.send(SETTING.bgAlpha,image)
                    gc.setDefaultFilter('nearest','nearest')
                    BG.lock()
                else
                    MES.new('error',text.customBGloadFailed)
                end
            else--Switch off when custom BG not found
                SETTING.bg='off'
                BG.unlock()
                BG.set('gray')
                BG.send(SETTING.bgAlpha)
                BG.lock()
            end
        end
    end
end
function applyFPS()
    if SCN.cur=='game'then
        Z.setMaxFPS(SETTING.maxFPS)
        Z.setFrameMul(SETTING.frameMul)
    else
        Z.setMaxFPS(math.min(SETTING.maxFPS,90))
        Z.setFrameMul(SETTING.frameMul)
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



--GC
do--function posterizedText(str,x,y)
    local TIME=TIME
    local gc_setColorMask=gc.setColorMask
    function posterizedText(str,x,y)
        gc.push('transform')
        gc.translate(x+sin(2.6*TIME()),y+sin(3.6*TIME()))
        gc.setColor(1,1,1)
        gc_setColorMask(true,false,false,true)
        mStr(str,sin(6*TIME()),sin(11*TIME()))
        gc_setColorMask(false,true,false,true)
        mStr(str,sin(7*TIME()),sin(10*TIME()))
        gc_setColorMask(false,false,true,true)
        mStr(str,sin(8*TIME()),sin(9*TIME()))
        gc_setColorMask()
        gc.pop()
    end
    function posterizedDraw(obj,x,y)
        gc.push('transform')
        gc.translate(x+sin(2.6*TIME()),y+sin(3.6*TIME()))
        gc.setColor(1,1,1)
        gc_setColorMask(true,false,false,true)
        mDraw(obj,sin(6*TIME()),sin(11*TIME()))
        gc_setColorMask(false,true,false,true)
        mDraw(obj,sin(7*TIME()),sin(10*TIME()))
        gc_setColorMask(false,false,true,true)
        mDraw(obj,sin(8*TIME()),sin(9*TIME()))
        gc_setColorMask()
        gc.pop()
    end
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
