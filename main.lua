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
love.keyboard.setTextInput(false)
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
Zenitha.setAppName('Quatrack')
Zenitha.setVersionText(VERSION.string)
Zenitha.setFirstScene('load')
do-- Zenitha.setDrawCursor
    Zenitha.setDrawCursor(function(_,x,y)
        if not SETTINGS.sysCursor then
            GC.setColor(1,1,1)
            GC.setLineWidth(2)
            GC.translate(x,y)
            GC.rotate(love.timer.getTime()%6.283185307179586)
            GC.circle('line',0,0,10)
            if love.mouse.isDown(1) then GC.circle('line',0,0,6) end
            if love.mouse.isDown(2) then GC.circle('fill',0,0,4) end
            if love.mouse.isDown(3) then GC.line(-6,-6,6,6) GC.line(-6,6,6,-6) end
            GC.setColor(1,1,1,.626)
            GC.line(0,-20,0,20)
            GC.line(-20,0,20,0)
        end
    end)
end
Zenitha.setOnGlobalKey('f11',function() SETTINGS.fullscreen=not SETTINGS.fullscreen; saveSettings() end)
Zenitha.setOnFnKeys({
    function() MSG.new('check',PROFILE.switch() and "profile start!" or "profile report copied!") end,
    function() MSG.new('info',("System:%s[%s]\nluaVer:%s\njitVer:%s\njitVerNum:%s"):format(SYSTEM,jit.arch,_VERSION,jit.version,jit.version_num)) end,
    function() MSG.new('error',"挂了") end,
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
do-- Zenitha.setOnFocus
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
            if v<SETTINGS.mainVol then
                love.audio.setVolume(math.min(v+.05,SETTINGS.mainVol,1))
            else
                return
            end
        end
    end
    Zenitha.setOnFocus(function(f)
        if f then
            applyFPS(SCN.cur=='game')
            love.timer.step()
            if SETTINGS.autoMute then
                TASK.removeTask_code(task_autoSoundOff)
                TASK.new(task_autoSoundOn)
            end
        else
            if SETTINGS.slowUnfocus then
                Zenitha.setMaxFPS(math.min(SETTINGS.maxFPS,90))
                Zenitha.setDrawFreq(15)
            end
            if SETTINGS.autoMute then
                TASK.removeTask_code(task_autoSoundOn)
                TASK.new(task_autoSoundOff)
            end
        end
    end)
end
do-- Zenitha.setDrawSysInfo
    Zenitha.setDrawSysInfo(function()
        if not SETTINGS.powerInfo then return end
        GC.translate(SCR.safeX,0)
        GC.setColor(0,0,0,.26)
        GC.rectangle('fill',0,0,107,26)
        local state,pow=love.system.getPowerInfo()
        if state~='unknown' then
            GC.setLineWidth(2)
            if state=='nobattery' then
                GC.setColor(1,1,1)
                GC.line(74,5,100,22)
            elseif pow then
                if state=='charging' then GC.setColor(0,1,0)
                elseif pow>50 then        GC.setColor(1,1,1)
                elseif pow>26 then        GC.setColor(1,1,0)
                elseif pow==26 then       GC.setColor(.5,0,1)
                else                      GC.setColor(1,0,0)
                end
                GC.rectangle('fill',76,6,pow*.22,14)
                if pow<100 then
                    FONT.set(15,'_basic')
                    GC.shadedPrint(pow,88,5,'center',1,8)
                end
            end
            GC.rectangle('line',74,4,26,18)
            GC.rectangle('fill',102,6,2,14)
        end
        FONT.set(25,'_basic')
        GC.print(os.date("%H:%M"),3,0,nil,.9)
    end)
end
FONT.setDefaultFallback('symbols')
FONT.setDefaultFont('norm')
FONT.setFallback('mono','norm')
FONT.load{
    mono='assets/font/monospaced.ttf',
    bold='assets/font/Inter-ExtraBold.otf',
    norm='assets/font/Inter-Regular.otf',
    thin='assets/font/Inter-SemiBold.otf',
    symbols='assets/font/symbols.otf',
}
SCR.setSize(1280,720)
BGM.setDefault('title')
BGM.setMaxSources(5)
VOC.setDiversion(.62)
WIDGET._prototype.button.sound_press='button'
WIDGET._prototype.checkBox.sound_on='check'
WIDGET._prototype.checkBox.sound_off='uncheck'
WIDGET._prototype.selector.sound_press='selector'
WIDGET._prototype.listBox.sound_select='click'
WIDGET._prototype.inputBox.sound_input='hit5'
WIDGET._prototype.inputBox.sound_bksp='hit3'
WIDGET._prototype.inputBox.sound_bksp='hold1'
WIDGET._prototype.inputBox.sound_clear='hold4'
WIDGET._prototype.textBox.sound_clear='hold4'
WIDGET._prototype.slider.numFontType='norm'
WIDGET._prototype.slider_fill.lineWidth=2
WIDGET._prototype.switch.labelPos='left'
WIDGET._prototype.button.lineWidth=2
WIDGET._prototype.button_fill.textColor=TABLE.shift(COLOR.D)
LANG.add{
    zh='assets/language/lang_zh.lua',
    en='assets/language/lang_en.lua',
}
LANG.setDefault('zh')
--[Attention] Not loading IMG/SFX/BGM files here, just read file paths
IMG.init{
    logo_full='assets/image/logo_full.png',
    logo_color='assets/image/logo_color.png',
    z={
        character='assets/image/z_character.png',
        screen1='assets/image/z_screen1.png',
        screen2='assets/image/z_screen2.png',
        particle1='assets/image/z_particle1.png',
        particle2='assets/image/z_particle2.png',
        particle3='assets/image/z_particle3.png',
        particle4='assets/image/z_particle4.png',
    }
}
SFX.load((function()
    local path='assets/effect/chiptune/'
    local L={}
    for _,v in next,love.filesystem.getDirectoryItems(path) do
        if FILE.isSafe(path..v) then
            L[v:sub(1,-5)]=path..v
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
-- Load settings and statistics
local setting=FILE.load('conf/settings','-json -canskip')
if setting then
    for k,v in next,setting do SETTINGS.__data[k]=v end
end
for k,v in next,SETTINGS.__data do
    SETTINGS.__data[k]=nil
    SETTINGS[k]=v
end

TABLE.coverR(loadFile('conf/data','-canSkip') or {},STAT)
local savedKey=loadFile('conf/key','-canSkip')
if savedKey then
    KEY_MAP=savedKey
    KEY_MAP_inv:_update()
end
--------------------------------------------------------------
-- First start
FIRSTLAUNCH=STAT.run==0
if FIRSTLAUNCH and MOBILE then
    SETTINGS.cleanCanvas=true
    SETTINGS.scaleX=1.3
    SETTINGS.trackW=1.3
end
-- Update savedata
do
    SETTINGS.drawRate=SETTINGS.drawRate or SETTINGS.frameMul
    STAT.hits=nil
    SETTINGS.frameMul=nil
    love.filesystem.remove('progress')
    if STAT.version~=VERSION.code or not love.filesystem.getInfo('songs/readme.txt','file') then
        love.filesystem.write('songs/readme.txt',love.filesystem.read('assets/language/readme.txt'))
        STAT.version=VERSION.code
        saveStats()
    end
end
DEBUG.checkLoadTime("Load savedata")
--------------------------------------------------------------
DEBUG.logLoadTime()
--------------------------------------------------------------
-- Apply system setting
