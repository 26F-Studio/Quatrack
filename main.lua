--System Global Vars Declaration
local fs=love.filesystem
VERSION=require"version"
TIME=love.timer.getTime
YIELD=coroutine.yield
SYSTEM=love.system.getOS()if SYSTEM=='OS X'then SYSTEM='macOS'end
FNNS=SYSTEM:find'\79\83'--What does FNSF stand for? IDK so don't ask me lol
MOBILE=SYSTEM=='Android'or SYSTEM=='iOS'
SAVEDIR=fs.getSaveDirectory()

--Global Vars & Settings
SFXPACKS={}
VOCPACKS={}
FIRSTLAUNCH=false
DAILYLAUNCH=false

--System setting
math.randomseed(os.time()*626)
love.setDeprecationOutput(false)
love.keyboard.setKeyRepeat(true)
love.keyboard.setTextInput(false)
if MOBILE then
    local w,h,f=love.window.getMode()
    f.resizable=false
    love.window.setMode(w,h,f)
end

local _LOADTIMELIST_={}
local _LOADTIME_=TIME()

--Load modules
Z=require'Zframework'
FONT.load{
    norm='parts/fonts/proportional.ttf',
    mono='parts/fonts/monospaced.ttf',
}
FONT.setDefault('norm')
FONT.setFallback('norm')

SCR.setSize(1280,720)--Initialize Screen size
BGM.setDefault('title')
BGM.setMaxSources(5)
VOC.setDiversion(.62)

table.insert(_LOADTIMELIST_,("Load Zframework: %.3fs"):format(TIME()-_LOADTIME_))

--Create shortcuts
setFont=FONT.set
getFont=FONT.get
mStr=GC.mStr
mText=GC.simpX
mDraw=GC.draw
Snd=SFX.playSample
string.repD=STRING.repD
string.sArg=STRING.sArg
string.split=STRING.split
string.trim=STRING.trim

--Delete all naked files (from too old version)
FILE.clear('')

--Create directories
for _,v in next,{'conf','record','replay','cache','lib','songs'}do
    local info=fs.getInfo(v)
    if not info then
        fs.createDirectory(v)
    elseif info.type~='directory'then
        fs.remove(v)
        fs.createDirectory(v)
    end
end

CHAR=require'parts.char'
require'parts.gameTables'
require'parts.gameFuncs'

--Load shader files from SOURCE ONLY
SHADER={}
for _,v in next,fs.getDirectoryItems('parts/shaders')do
    if isSafeFile('parts/shaders/'..v)then
        local name=v:sub(1,-6)
        SHADER[name]=love.graphics.newShader('parts/shaders/'..name..'.glsl')
    end
end

--Init Zframework
do--Z.setCursor
    local gc=love.graphics
    local sin,cos=math.sin,math.cos
    Z.setCursor(function(_,x,y)
        if not SETTING.sysCursor then
            gc.setColor(1,1,1)
            gc.circle('line',x,y,10)
            if love.mouse.isDown(1) then gc.circle('fill',x,y,6)end
            gc.setColor(1,1,1,.626)
            gc.setLineWidth(2)
            local angle=TIME()
            local s,c=sin(angle),cos(angle)
            gc.line(x-20*c,y-20*s,x+20*c,y+20*s)
            gc.line(x+20*s,y-20*c,x-20*s,y+20*c)
        end
    end)
end
Z.setOnFnKeys({
    function()MES.new('check',PROFILE.switch()and"profile start!"or"profile report copied!")end,
    function()MES.new('info',("System:%s[%s]\nluaVer:%s\njitVer:%s\njitVerNum:%s"):format(SYSTEM,jit.arch,_VERSION,jit.version,jit.version_num))end,
    function()MES.new('error',"挂了")end,
    function()end,
    function()print(WIDGET.getSelected()or"no widget selected")end,
    function()for k,v in next,_G do print(k,v)end end,
    function()if love["_openConsole"]then love["_openConsole"]()end end,
})

--Load settings and statistics
TABLE.update(loadFile('conf/settings','-canSkip')or{},SETTING)

--Initialize media modules
IMG.init{
    title='media/image/title.png',
}
SFX.init((function()
    local L={}
    for _,v in next,fs.getDirectoryItems('media/effect/chiptune/')do
        if isSafeFile('media/effect/chiptune/'..v,"Dangerous file : %SAVE%/media/effect/chiptune/"..v)then
            table.insert(L,v:sub(1,-5))
        end
    end
    return L
end)())
BGM.load((function()
    local L={}
    for _,v in next,fs.getDirectoryItems('media/music')do
        if isSafeFile('media/music/'..v,"Dangerous file : %SAVE%/media/music/"..v)then
            L[v:sub(1,-5)]='media/music/'..v
        end
    end
    return L
end)())
VOC.init{}

--Initialize language lib
LANG.init('zh',
    {
        zh=require'parts.language.lang_zh',
        en=require'parts.language.lang_en',
    }
)

table.insert(_LOADTIMELIST_,("Initialize Parts: %.3fs"):format(TIME()-_LOADTIME_))

--Load background files from SOURCE ONLY
for _,v in next,fs.getDirectoryItems('parts/backgrounds')do
    if isSafeFile('parts/backgrounds/'..v)and v:sub(-3)=='lua'then
        local name=v:sub(1,-5)
        BG.add(name,require('parts.backgrounds.'..name))
    end
end
BG.remList('none')BG.remList('gray')BG.remList('custom')
--Load scene files from SOURCE ONLY
for _,v in next,fs.getDirectoryItems('parts/scenes')do
    if isSafeFile('parts/scenes/'..v)then
        local sceneName=v:sub(1,-5)
        SCN.add(sceneName,require('parts.scenes.'..sceneName))
        LANG.addScene(sceneName)
    end
end

table.insert(_LOADTIMELIST_,("Load Files: %.3fs"):format(TIME()-_LOADTIME_))

--First start
FIRSTLAUNCH=STAT.run==0
if FIRSTLAUNCH and MOBILE then
    SETTING.cleanCanvas=true
end

--Apply system setting
applySettings()

table.insert(_LOADTIMELIST_,("Initialize Data: %.3fs"):format(TIME()-_LOADTIME_))

for i=1,#_LOADTIMELIST_ do LOG(_LOADTIMELIST_[i])end
