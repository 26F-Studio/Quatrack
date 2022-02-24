local gc=love.graphics

local scene={}

local boundaryDispTime

function scene.enter()
    boundaryDispTime=0
    BG.set()
end
function scene.leave()
    saveSettings()
end

function scene.update(dt)
    if boundaryDispTime>0 then
        boundaryDispTime=math.max(boundaryDispTime-dt,0)
    end
end

function scene.draw()
    FONT.set(80)
    posterizedText('SETTINGS',350,10)

    if boundaryDispTime>0 then
        gc.push('transform')
        gc.origin()
        drawSafeArea(SETTING.safeX,SETTING.safeY,boundaryDispTime,2.6)
        gc.pop()
    end
end

local function _updateSFXvol()
    if math.abs(SETTING.musicDelay)>50 then
        SETTING.sfx=0
        SFX.setVol(0)
    end
end
local function sliderShow_time(S)
    local t=S.disp()
    return (t<0 and Text.music_early or t>0 and Text.music_late or Text.music_nodelay):repD(("%.0f"):format(math.abs(t)).." ms")
end
local function sliderShow_scale(S)
    return ("x%.2f"):format(S.disp())
end
local function sliderShow_fps(S)
    return S.disp().." FPS"
end
local function sliderShow_mul(S)
    return S.disp().."%"
end
local function sliderShow_hitLV(S)
    return hitTexts[S.disp()] or "?"
end

scene.scrollHeight=450
scene.widgetList={
    WIDGET.new{type='slider',     x=200, y=150,w=420, text=LANG'setting_mainVol',     widthLimit=160,disp=SETval('mainVol'),       code=function(v) SETTING.mainVol=v love.audio.setVolume(SETTING.mainVol) end},
    WIDGET.new{type='slider',     x=200, y=200,w=420, text=LANG'setting_bgm',         widthLimit=160,disp=SETval('bgm'),           code=function(v) SETTING.bgm=v BGM.setVol(SETTING.bgm) end},
    WIDGET.new{type='slider',     x=200, y=250,w=420, text=LANG'setting_sfx',         widthLimit=160,disp=SETval('sfx'),           code=function(v) SETTING.sfx=v SFX.setVol(SETTING.sfx) end},
    WIDGET.new{type='slider',     x=200, y=300,w=420, text=LANG'setting_stereo',      widthLimit=160,disp=SETval('stereo'),        code=function(v) SETTING.stereo=v SFX.setStereo(SETTING.stereo) end,visibleFunc=function() return SETTING.sfx>0 end},

    WIDGET.new{type='slider',     x=200, y=350,w=420, text=LANG'setting_bgAlpha',     widthLimit=160,axis={0,.6,.01},smooth=true,  disp=SETval('bgAlpha'),code=SETsto('bgAlpha')},

    WIDGET.new{type='slider',     x=200, y=450,w=420, text=LANG'setting_musicDelay',  widthLimit=160,axis={-260,260,1},smooth=true,disp=SETval('musicDelay'),valueShow=sliderShow_time,code=function(v) SETTING.musicDelay=v;_updateSFXvol() end},
    WIDGET.new{type='slider',     x=200, y=500,w=420, text=LANG'setting_dropSpeed',   widthLimit=160,axis={-8,8,1},                disp=SETval('dropSpeed'),code=SETsto('dropSpeed')},
    WIDGET.new{type='slider',     x=200, y=600,w=420, text=LANG'setting_noteThick',   widthLimit=160,axis={10,50,4},               disp=SETval('noteThick'),code=SETsto('noteThick')},
    WIDGET.new{type='slider',     x=200, y=650,w=420, text=LANG'setting_chordAlpha',  widthLimit=160,axis={0,1,.01},smooth=true,   disp=SETval('chordAlpha'),code=SETsto('chordAlpha')},
    WIDGET.new{type='slider',     x=200, y=700,w=420, text=LANG'setting_holdAlpha',   widthLimit=160,axis={.2,.8},                 disp=SETval('holdAlpha'),code=SETsto('holdAlpha')},
    WIDGET.new{type='slider',     x=200, y=750,w=420, text=LANG'setting_holdWidth',   widthLimit=160,axis={.2,.8},                 disp=SETval('holdWidth'),code=SETsto('holdWidth')},
    WIDGET.new{type='slider',     x=200, y=800,w=420, text=LANG'setting_scaleX',      widthLimit=160,axis={.8,1.5},                disp=SETval('scaleX'),valueShow=sliderShow_scale,code=SETsto('scaleX')},
    WIDGET.new{type='slider',     x=200, y=850,w=420, text=LANG'setting_trackW',      widthLimit=160,axis={.8,1.5},                disp=SETval('trackW'),valueShow=sliderShow_scale,code=SETsto('trackW')},
    WIDGET.new{type='slider',     x=200, y=950,w=420, text=LANG'setting_safeX',       widthLimit=160,axis={0,120,10},              disp=SETval('safeX'),code=function(v) SETTING.safeX=v boundaryDispTime=2.6 end},
    WIDGET.new{type='slider',     x=200, y=1000,w=210,text=LANG'setting_safeY',       widthLimit=160,axis={0,60,10},               disp=SETval('safeY'),code=function(v) SETTING.safeY=v boundaryDispTime=2.6 end},
    WIDGET.new{type='slider',     x=200, y=1050,w=260,text=LANG'setting_showHitLV',   widthLimit=160,axis={0,5,1},                 disp=SETval('showHitLV'),valueShow=sliderShow_hitLV,code=SETsto('showHitLV')},
    WIDGET.new{type='slider',     x=200, y=1100,w=420,text=LANG'setting_dvtCount',    widthLimit=160,axis={5,50,5},                disp=SETval('dvtCount'),code=SETsto('dvtCount')},

    WIDGET.new{type='checkBox',   x=1160,y=70,        text=LANG'setting_sysCursor',   widthLimit=360,disp=SETval('sysCursor'),     code=function() SETTING.sysCursor=not SETTING.sysCursor applySettings() end},
    WIDGET.new{type='checkBox',   x=1160,y=130,       text=LANG'setting_clickFX',     widthLimit=360,disp=SETval('clickFX'),       code=function() SETTING.clickFX=not SETTING.clickFX applySettings() end},
    WIDGET.new{type='checkBox',   x=1160,y=190,       text=LANG'setting_power',       widthLimit=360,disp=SETval('powerInfo'),     code=function() SETTING.powerInfo=not SETTING.powerInfo applySettings() end},
    WIDGET.new{type='checkBox',   x=1160,y=250,       text=LANG'setting_clean',       widthLimit=360,disp=SETval('cleanCanvas'),   code=function() SETTING.cleanCanvas=not SETTING.cleanCanvas applySettings() end},
    WIDGET.new{type='checkBox',   x=1160,y=310,       text=LANG'setting_fullscreen',  widthLimit=360,disp=SETval('fullscreen'),    code=function() SETTING.fullscreen=not SETTING.fullscreen applySettings() end},
    WIDGET.new{type='checkBox',   x=1160,y=370,       text=LANG'setting_autoMute',    widthLimit=360,disp=SETval('autoMute'),      code=SETrev('autoMute')},
    WIDGET.new{type='checkBox',   x=1160,y=430,       text=LANG'setting_slowUnfocus', widthLimit=360,disp=SETval('slowUnfocus'),   code=SETrev('slowUnfocus')},

    WIDGET.new{type='slider',     x=860,y=750,w=360,  text=LANG'setting_maxFPS',      widthLimit=180,axis={60,360,10},smooth=true, disp=SETval('maxFPS'),valueShow=sliderShow_fps,code=SETsto('maxFPS')},
    WIDGET.new{type='slider',     x=860,y=800,w=360,  text=LANG'setting_updRate',     widthLimit=180,axis={20,100,10},             disp=SETval('updRate'),valueShow=sliderShow_mul,code=SETsto('updRate')},
    WIDGET.new{type='slider',     x=860,y=850,w=360,  text=LANG'setting_drawRate',    widthLimit=180,axis={20,100,10},             disp=SETval('drawRate'),valueShow=sliderShow_mul,code=SETsto('drawRate')},

    WIDGET.new{type='button_fill',x=900,y=640,w=170,h=80,fontSize=60,text=CHAR.key.keyboard,code=WIDGET.c_goScn'setting_key'},

    WIDGET.new{type='button_fill',x=1140,y=640,w=170,h=80,sound='back',fontSize=60,text=CHAR.icon.back,code=WIDGET.c_backScn},
}

return scene
