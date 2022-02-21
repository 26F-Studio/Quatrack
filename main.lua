-- #    ____              __                  __   #
-- #   / __ \__  ______ _/ /__________ ______/ /__ #
-- #  / / / / / / / __ `/ __/ ___/ __ `/ ___/ //_/ #
-- # / /_/ / /_/ / /_/ / /_/ /  / /_/ / /__/ ,<    #
-- # \___\_\__,_/\__,_/\__/_/   \__,_/\___/_/|_|   #
-- #                                               #
-- Quatrack is a music game
-- Creating issue on github is welcomed

-- Some coding style:
-- 1. I made a framework called Zenitha, *most* code in Zenitha are not directly relevant to game;
-- 2. "xxx" are texts for reading by player, 'xxx' are string values just used in program;
-- 3. Some goto statement are used for better performance. All goto-labes have detailed names so don't be afraid;
-- 4. Except "gcinfo" function of lua itself, other "gc" are short for "graphics";

-------------------------------------------------------------
-- Load Zenitha
require("Zenitha")
DEBUG.checkLoadTime("Load Zenitha")
--------------------------------------------------------------
-- Global Vars Declaration
VERSION=require"version"
FNNS=SYSTEM:find'\79\83'-- What does FNSF stand for? IDK so don't ask me lol
SFXPACKS={}
VOCPACKS={}
FIRSTLAUNCH=false
--------------------------------------------------------------
-- System setting
math.randomseed(os.time()*626)
love.setDeprecationOutput(false)
love.keyboard.setKeyRepeat(true)
love.keyboard.setTextInput(false)
if MOBILE then
    local w,h,f=love.window.getMode()
    f.resizable=false
    love.window.setMode(w,h,f)
end
--------------------------------------------------------------
-- Create directories
for _,v in next,{'conf','record','replay','cache','lib','songs'} do
    local info=love.filesystem.getInfo(v)
    if not info then
        love.filesystem.createDirectory(v)
    elseif info.type~='directory' then
        love.filesystem.remove(v)
        love.filesystem.createDirectory(v)
    end
end
--------------------------------------------------------------
-- Load modules
CHAR=require'assets.char'
require'assets.gameTables'
require'assets.gameFuncs'
DEBUG.checkLoadTime("Load Assets")
--------------------------------------------------------------
-- Config Zenitha
STRING.install()
Zenitha.setVersionText(VERSION.string)
Zenitha.setFirstScene('load')
do--Zenitha.setDrawCursor
    local gc=love.graphics
    local sin,cos=math.sin,math.cos
    Zenitha.setDrawCursor(function(_,x,y)
        if not SETTING.sysCursor then
            gc.setColor(1,1,1)
            gc.setLineWidth(2)
            gc.circle('line',x,y,10)
            if love.mouse.isDown(1) then gc.circle('fill',x,y,6) end
            gc.setColor(1,1,1,.626)
            local angle=love.timer.getTime()
            local s,c=sin(angle),cos(angle)
            gc.line(x-20*c,y-20*s,x+20*c,y+20*s)
            gc.line(x+20*s,y-20*c,x-20*s,y+20*c)
        end
    end)
end
Zenitha.setOnGlobalKey('f11',function() SETTING.fullscreen=not SETTING.fullscreen applySettings() end)
Zenitha.setOnFnKeys({
    function() MES.new('check',PROFILE.switch() and "profile start!" or "profile report copied!") end,
    function() MES.new('info',("System:%s[%s]\nluaVer:%s\njitVer:%s\njitVerNum:%s"):format(SYSTEM,jit.arch,_VERSION,jit.version,jit.version_num)) end,
    function() MES.new('error',"挂了") end,
    function() end,
    function() print(WIDGET.getSelected() or "no widget selected") end,
    function() for k,v in next,_G do print(k,v) end end,
    function() if love["_openConsole"] then love["_openConsole"]() end end,
})
Zenitha.setDebugInfo{
    {"Cache",gcinfo},
    {"Tasks",TASK.getCount},
    {"Audios",love.audio.getSourceCount},
}
do--Zenitha.setOnFocus
    local function task_autoSoundOff()
        while true do
            coroutine.yield()
            local v=love.audio.getVolume()
            love.audio.setVolume(math.max(v-.05,0))
            if v==0 then return end
        end
    end
    local function task_autoSoundOn()
        while true do
            coroutine.yield()
            local v=love.audio.getVolume()
            if v<SETTING.mainVol then
                love.audio.setVolume(math.min(v+.05,SETTING.mainVol,1))
            else
                return
            end
        end
    end
    Zenitha.setOnFocus(function(f)
        if f then
            applyFPS(SCN.cur=='game')
            love.timer.step()
            if SETTING.autoMute then
                TASK.removeTask_code(task_autoSoundOff)
                TASK.new(task_autoSoundOn)
            end
        else
            if SETTING.slowUnfocus then
                Zenitha.setMaxFPS(20)
                Zenitha.setDrawFreq(100)
            end
            if SETTING.autoMute then
                TASK.removeTask_code(task_autoSoundOn)
                TASK.new(task_autoSoundOff)
            end
        end
    end)
end
do--Zenitha.setDrawSysInfo
    local gc=love.graphics
    Zenitha.setDrawSysInfo(function()
        if not SETTING.powerInfo then return end
        gc.translate(SCR.safeX,0)
        gc.setColor(0,0,0,.26)
        gc.rectangle('fill',0,0,107,26)
        local state,pow=love.system.getPowerInfo()
        if state~='unknown' then
            gc.setLineWidth(2)
            if state=='nobattery' then
                gc.setColor(1,1,1)
                gc.line(74,5,100,22)
            elseif pow then
                if state=='charging' then gc.setColor(0,1,0)
                elseif pow>50 then        gc.setColor(1,1,1)
                elseif pow>26 then        gc.setColor(1,1,0)
                elseif pow==26 then       gc.setColor(.5,0,1)
                else                      gc.setColor(1,0,0)
                end
                gc.rectangle('fill',76,6,pow*.22,14)
                if pow<100 then
                    FONT.set(10,'_basic')
                    GC.shadedPrint(pow,87,6,'center',1,8)
                end
            end
            gc.rectangle('line',74,4,26,18)
            gc.rectangle('fill',102,6,2,14)
        end
        FONT.set(25,'_basic')
        gc.print(os.date("%H:%M"),3,-5)
    end)
end
FONT.load{
    norm='assets/font/proportional.ttf',
    mono='assets/font/monospaced.ttf',
}
FONT.setDefaultFont('norm')
FONT.setDefaultFallback('norm')
SCR.setSize(1280,720)
BGM.setDefault('title')
BGM.setMaxSources(5)
VOC.setDiversion(.62)
WIDGET.setDefaultButtonSound('button')
WIDGET.setDefaultCheckBoxSound('check','uncheck')
WIDGET.setDefaultSelectorSound('selector')
WIDGET.setDefaultTypeSound('hit5','hit3')
WIDGET.setDefaultClearSound('hold4')
LANG.add{
    zh='assets/language/lang_zh.lua',
    en='assets/language/lang_en.lua',
}
LANG.setDefault('zh')
--[Attention] Not loading IMG/SFX/BGM files here, just read file paths
IMG.init{
    title='assets/image/title.png',
}
SFX.init((function()
    local L={}
    for _,v in next,love.filesystem.getDirectoryItems('assets/effect/chiptune/') do
        if FILE.isSafe('assets/effect/chiptune/'..v) then
            table.insert(L,v:sub(1,-5))
        end
    end
    return L
end)())
BGM.load((function()
    local L={}
    for _,v in next,love.filesystem.getDirectoryItems('assets/music') do
        if FILE.isSafe('assets/music/'..v) then
            L[v:sub(1,-5)]='assets/music/'..v
        end
    end
    return L
end)())
VOC.init{}
DEBUG.checkLoadTime("Configuring Zenitha")
--------------------------------------------------------------
-- Load SOURCE ONLY resources
SHADER={}
for _,v in next,love.filesystem.getDirectoryItems('assets/shader') do
    if FILE.isSafe('assets/shader/'..v) then
        local name=v:sub(1,-6)
        SHADER[name]=love.graphics.newShader('assets/shader/'..name..'.glsl')
    end
end
for _,v in next,love.filesystem.getDirectoryItems('assets/background') do
    if FILE.isSafe('assets/background/'..v) and v:sub(-3)=='lua' then
        local name=v:sub(1,-5)
        BG.add(name,require('assets/background/'..name))
    end
end
for _,v in next,love.filesystem.getDirectoryItems('assets/scene') do
    if FILE.isSafe('assets/scene/'..v) then
        local sceneName=v:sub(1,-5)
        SCN.add(sceneName,require('assets/scene/'..sceneName))
    end
end
DEBUG.checkLoadTime("Load SDs+BGs+SCNs")
--------------------------------------------------------------
--Load settings and statistics
TABLE.update(loadFile('conf/settings','-canSkip') or{},SETTING)
TABLE.coverR(loadFile('conf/data','-canSkip') or{},STAT)
local savedKey=loadFile('conf/key','-canSkip')
if savedKey then
    KEY_MAP=savedKey
    KEY_MAP_inv:_update()
end
--------------------------------------------------------------
--First start
FIRSTLAUNCH=STAT.run==0
if FIRSTLAUNCH and MOBILE then
    SETTING.cleanCanvas=true
    SETTING.scaleX=1.3
    SETTING.trackW=1.3
end
--Update savedata
do
    SETTING.drawRate=SETTING.drawRate or SETTING.frameMul
    STAT.hits=nil
    SETTING.frameMul=nil
    love.filesystem.remove('progress')
    if STAT.version~=VERSION.code then
        love.filesystem.write('songs/readme.txt',love.filesystem.read('assets/language/readme.txt'))
    end
end
DEBUG.checkLoadTime("Load savedata")
--------------------------------------------------------------
DEBUG.logLoadTime()
--------------------------------------------------------------
--Apply system setting
applySettings()
