local gc=love.graphics

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
function applyLanguage()
    text=LANG.get(SETTING.locale)
    WIDGET.setLang(text.WidgetText)
end
function applyCursor()
    love.mouse.setVisible(SETTING.sysCursor)
end
function applyFullscreen()
    love.window.setFullscreen(SETTING.fullscreen)
    love.resize(gc.getWidth(),gc.getHeight())
end
function applyAllSettings()
    applyFullscreen()
    love.audio.setVolume(SETTING.mainVol)
    BGM.setVol(SETTING.bgm)
    SFX.setVol(SETTING.sfx)
    VOC.setVol(SETTING.voc)
    applyLanguage()
    applyCursor()
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
