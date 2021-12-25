local scene={}

function scene.sceneInit()
    BG.set()
end
function scene.sceneBack()
    saveSettings()
end

function scene.draw()
    setFont(80)
    posterizedText('SETTINGS',350,10)
end

local function sliderShow_time(S)
    return("%.0f"):format(S.disp()).." ms"
end
local function sliderShow_scale(S)
    return("x%.2f"):format(S.disp())
end
local function sliderShow_fps(S)
    return S.disp().." FPS"
end
local function sliderShow_mul(S)
    return S.disp().."%"
end

scene.widgetList={
    WIDGET.newSlider{name='musicDelay', x=200, y=150,w=420,lim=160,axis={-260,260,1},smooth=true,disp=SETval('musicDelay'),show=sliderShow_time,code=SETsto('musicDelay')},
    WIDGET.newSlider{name='dropSpeed',  x=200, y=200,w=420,lim=160,axis={-8,8,1},                disp=SETval('dropSpeed'),code=SETsto('dropSpeed')},
    WIDGET.newSlider{name='noteThick',  x=200, y=250,w=420,lim=160,axis={10,50,4},               disp=SETval('noteThick'),code=SETsto('noteThick')},
    WIDGET.newSlider{name='holdAlpha',  x=200, y=300,w=420,lim=160,axis={.2,.8},                 disp=SETval('holdAlpha'),code=SETsto('holdAlpha')},
    WIDGET.newSlider{name='holdWidth',  x=200, y=350,w=420,lim=160,axis={.2,.8},                 disp=SETval('holdWidth'),code=SETsto('holdWidth')},
    WIDGET.newSlider{name='scaleX',     x=200, y=400,w=420,lim=160,axis={.8,1.5},                disp=SETval('scaleX'),show=sliderShow_scale,code=SETsto('scaleX')},
    WIDGET.newSlider{name='trackW',     x=200, y=450,w=420,lim=160,axis={.8,1.5},                disp=SETval('trackW'),show=sliderShow_scale,code=SETsto('trackW')},

    WIDGET.newSlider{name='mainVol',    x=200, y=520,w=420,lim=160,disp=SETval('mainVol'),       code=function(v)SETTING.mainVol=v love.audio.setVolume(SETTING.mainVol)end},
    WIDGET.newSlider{name='bgm',        x=200, y=570,w=420,lim=160,disp=SETval('bgm'),           code=function(v)SETTING.bgm=v BGM.setVol(SETTING.bgm)end},
    WIDGET.newSlider{name='sfx',        x=200, y=620,w=420,lim=160,disp=SETval('sfx'),           code=function(v)SETTING.sfx=v SFX.setVol(SETTING.sfx)end},
    WIDGET.newSlider{name='stereo',     x=200, y=670,w=420,lim=160,disp=SETval('stereo'),        code=function(v)SETTING.stereo=v SFX.setStereo(SETTING.stereo)end,hideF=function()return SETTING.sfx==0 end},

    WIDGET.newSwitch{name='sysCursor',  x=1160,y=70, lim=360,disp=SETval('sysCursor'),           code=function()SETTING.sysCursor=not SETTING.sysCursor applySettings()end},
    WIDGET.newSwitch{name='clickFX',    x=1160,y=130,lim=360,disp=SETval('clickFX'),             code=function()SETTING.clickFX=not SETTING.clickFX applySettings()end},
    WIDGET.newSwitch{name='power',      x=1160,y=190,lim=360,disp=SETval('powerInfo'),           code=function()SETTING.powerInfo=not SETTING.powerInfo applySettings()end},
    WIDGET.newSwitch{name='clean',      x=1160,y=250,lim=360,disp=SETval('cleanCanvas'),         code=function()SETTING.cleanCanvas=not SETTING.cleanCanvas applySettings()end},
    WIDGET.newSwitch{name='fullscreen', x=1160,y=310,lim=360,disp=SETval('fullscreen'),          code=function()SETTING.fullscreen=not SETTING.fullscreen applySettings()end},
    WIDGET.newSwitch{name='autoMute',   x=1160,y=370,lim=360,disp=SETval('autoMute'),            code=SETrev('autoMute')},
    WIDGET.newSwitch{name='slowUnfocus',x=1160,y=430,lim=360,disp=SETval('slowUnfocus'),         code=SETrev('slowUnfocus')},

    WIDGET.newSlider{name='maxFPS',     x=860,y=500,w=360,lim=180,axis={60,360,10},smooth=true,  disp=SETval('maxFPS'),show=sliderShow_fps,code=SETsto('maxFPS')},
    WIDGET.newSlider{name='frameMul',   x=860,y=560,w=360,lim=180,axis={20,100,10},              disp=SETval('frameMul'),show=sliderShow_mul,code=SETsto('frameMul')},

    WIDGET.newButton{name='back',x=1140,y=640,w=170,h=80,sound='back',font=60,fText=CHAR.icon.back,code=backScene},
}

return scene
