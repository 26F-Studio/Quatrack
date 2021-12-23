local scene={}

function scene.sceneInit()
    BG.set()
end
function scene.sceneBack()
    saveSettings()
end

function scene.draw()
    setFont(80)
    posterizedText('SETTING',640,25)
end

local function sliderShow_time(S)
    return("%.0f"):format(S.disp()-260).." ms"
end
local function sliderShow_exp(S)
    return S.disp()-8
end
local function sliderShow_thick(S)
    return S.disp()*2+10
end
local function sliderShow_fps(S)
    return(S.disp()*30+60).." FPS"
end
local function sliderShow_mul(S)
    return(S.disp()*10+20).."%"
end

-- scene.widgetScrollHeight=720
scene.widgetList={
    WIDGET.newSlider{name='musicDelay', x=200, y=170,w=420,lim=160,unit=520,smooth=true,disp=SETval('musicDelay'),show=sliderShow_time,code=SETsto('musicDelay')},
    WIDGET.newSlider{name='dropSpeed',  x=200, y=230,w=420,lim=160,unit=16,disp=SETval('dropSpeed'),show=sliderShow_exp,code=SETsto('dropSpeed')},
    WIDGET.newSlider{name='noteThick',  x=200, y=290,w=420,lim=160,unit=20,disp=function()return(SETTING.noteThick-10)/2 end,show=sliderShow_thick,code=function(v)SETTING.noteThick=v*2+10 end},
    WIDGET.newSlider{name='holdAlpha',  x=200, y=350,w=420,lim=160,unit=1,disp=SETval('holdAlpha'),code=SETsto('holdAlpha')},
    WIDGET.newSlider{name='holdWidth',  x=200, y=410,w=420,lim=160,unit=1,disp=SETval('holdWidth'),code=SETsto('holdWidth')},

    WIDGET.newSlider{name='mainVol',    x=200, y=470,w=420,lim=160,disp=SETval('mainVol'), code=function(v)SETTING.mainVol=v love.audio.setVolume(SETTING.mainVol)end},
    WIDGET.newSlider{name='bgm',        x=200, y=530,w=420,lim=160,disp=SETval('bgm'),     code=function(v)SETTING.bgm=v BGM.setVol(SETTING.bgm)end},
    WIDGET.newSlider{name='sfx',        x=200, y=590,w=420,lim=160,disp=SETval('sfx'),     code=function(v)SETTING.sfx=v SFX.setVol(SETTING.sfx)end},
    WIDGET.newSlider{name='stereo',     x=200, y=650,w=420,lim=160,disp=SETval('stereo'),  code=function(v)SETTING.stereo=v SFX.setStereo(SETTING.stereo)end,hideF=function()return SETTING.sfx==0 end},

    WIDGET.newSwitch{name='sysCursor',  x=1100,y=140,lim=360,disp=SETval('sysCursor'),     code=function()SETTING.sysCursor=not SETTING.sysCursor applySettings()end},
    WIDGET.newSwitch{name='clickFX',    x=1100,y=200,lim=360,disp=SETval('clickFX'),       code=function()SETTING.clickFX=not SETTING.clickFX applySettings()end},
    WIDGET.newSwitch{name='power',      x=1100,y=260,lim=360,disp=SETval('powerInfo'),     code=function()SETTING.powerInfo=not SETTING.powerInfo applySettings()end},
    WIDGET.newSwitch{name='clean',      x=1100,y=320,lim=360,disp=SETval('cleanCanvas'),   code=function()SETTING.cleanCanvas=not SETTING.cleanCanvas applySettings()end},
    WIDGET.newSwitch{name='fullscreen', x=1100,y=380,lim=360,disp=SETval('fullscreen'),    code=function()SETTING.fullscreen=not SETTING.fullscreen applySettings()end},
    WIDGET.newSwitch{name='slowUnfocus',x=1100,y=440,lim=360,disp=SETval('slowUnfocus'),   code=SETrev('slowUnfocus')},

    WIDGET.newSlider{name='maxFPS',     x=860,y=500,w=360,lim=180,unit=10,disp=function()return(SETTING.maxFPS-60)/30 end, show=sliderShow_fps,code=function(v)SETTING.maxFPS=v*30+60 applyFPS(false)end},
    WIDGET.newSlider{name='frameMul',   x=860,y=560,w=360,lim=180,unit=8,disp=function()return(SETTING.frameMul-20)/10 end,show=sliderShow_mul,code=function(v)SETTING.frameMul=v*10+20 applyFPS(false)end},

    WIDGET.newButton{name='back',x=1140,y=640,w=170,h=80,sound='back',font=60,fText=CHAR.icon.back,code=backScene},
}

return scene
