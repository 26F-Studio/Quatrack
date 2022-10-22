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
    GC.replaceTransform(SCR.xOy_ul)
    FONT.set(80)
    posterizedText('SETTINGS',350,10-SCN.curScroll)

    if boundaryDispTime>0 then
        GC.origin()
        drawSafeArea(SETTINGS.safeX,SETTINGS.safeY,boundaryDispTime,2.6)
    end
end

local function _updateSFXvol()
    if math.abs(SETTINGS.musicDelay)>50 then
        SETTINGS.sfxVol=0
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

scene.scrollHeight=626
scene.widgetList={
    WIDGET.new{type='slider_fill',pos={0,0},x=260, y=150,w=420,h=35,text=LANG'setting_mainVol',     widthLimit=200,disp=TABLE.func_getVal(SETTINGS,'mainVol'), code=TABLE.func_setVal(SETTINGS,'mainVol')},
    WIDGET.new{type='slider_fill',pos={0,0},x=260, y=200,w=420,h=35,text=LANG'setting_bgm',         widthLimit=200,disp=TABLE.func_getVal(SETTINGS,'bgmVol'),  code=TABLE.func_setVal(SETTINGS,'bgmVol')},
    WIDGET.new{type='slider_fill',pos={0,0},x=260, y=250,w=420,h=35,text=LANG'setting_sfx',         widthLimit=200,disp=TABLE.func_getVal(SETTINGS,'sfxVol'),  code=TABLE.func_setVal(SETTINGS,'sfxVol')},
    WIDGET.new{type='slider_fill',pos={0,0},x=260, y=300,w=420,h=35,text=LANG'setting_stereo',      widthLimit=200,disp=TABLE.func_getVal(SETTINGS,'stereo'),  code=TABLE.func_setVal(SETTINGS,'stereo'),visibleFunc=function() return SETTINGS.sfxVol>0 end},
    WIDGET.new{type='slider_fill',pos={0,0},x=260, y=350,w=420,h=35,text=LANG'setting_bgAlpha',     widthLimit=200,disp=TABLE.func_getVal(SETTINGS,'bgAlpha'), code=TABLE.func_setVal(SETTINGS,'bgAlpha')},

    WIDGET.new{type='slider',     pos={0,0},x=260, y=450,w=420,     text=LANG'setting_musicDelay',  widthLimit=200,axis={-260,260,1},smooth=true,disp=TABLE.func_getVal(SETTINGS,'musicDelay'), valueShow=sliderShow_time,code=function(v) SETTINGS.musicDelay=v;_updateSFXvol() end},
    WIDGET.new{type='slider',     pos={0,0},x=260, y=500,w=420,     text=LANG'setting_dropSpeed',   widthLimit=200,axis={-8,8,1},                disp=TABLE.func_getVal(SETTINGS,'dropSpeed'),  code=TABLE.func_setVal(SETTINGS,'dropSpeed')},
    WIDGET.new{type='slider',     pos={0,0},x=260, y=600,w=420,     text=LANG'setting_noteThick',   widthLimit=200,axis={10,50,4},               disp=TABLE.func_getVal(SETTINGS,'noteThick'),  code=TABLE.func_setVal(SETTINGS,'noteThick')},
    WIDGET.new{type='slider',     pos={0,0},x=260, y=650,w=420,     text=LANG'setting_chordAlpha',  widthLimit=200,axis={0,1,.01},smooth=true,   disp=TABLE.func_getVal(SETTINGS,'chordAlpha'), code=TABLE.func_setVal(SETTINGS,'chordAlpha')},
    WIDGET.new{type='slider',     pos={0,0},x=260, y=700,w=420,     text=LANG'setting_holdAlpha',   widthLimit=200,axis={.2,.8},                 disp=TABLE.func_getVal(SETTINGS,'holdAlpha'),  code=TABLE.func_setVal(SETTINGS,'holdAlpha')},
    WIDGET.new{type='slider',     pos={0,0},x=260, y=750,w=420,     text=LANG'setting_holdWidth',   widthLimit=200,axis={.2,.8},                 disp=TABLE.func_getVal(SETTINGS,'holdWidth'),  code=TABLE.func_setVal(SETTINGS,'holdWidth')},
    WIDGET.new{type='slider',     pos={0,0},x=260, y=800,w=420,     text=LANG'setting_scaleX',      widthLimit=200,axis={.8,1.5,.01},smooth=true,disp=TABLE.func_getVal(SETTINGS,'scaleX'),     valueShow=sliderShow_scale,code=TABLE.func_setVal(SETTINGS,'scaleX')},
    WIDGET.new{type='slider',     pos={0,0},x=260, y=850,w=420,     text=LANG'setting_trackW',      widthLimit=200,axis={.8,1.5,.01},smooth=true,disp=TABLE.func_getVal(SETTINGS,'trackW'),     valueShow=sliderShow_scale,code=TABLE.func_setVal(SETTINGS,'trackW')},
    WIDGET.new{type='slider',     pos={0,0},x=260, y=950,w=420,     text=LANG'setting_safeX',       widthLimit=200,axis={0,120,10},              disp=TABLE.func_getVal(SETTINGS,'safeX'),      code=function(v) SETTINGS.safeX=v boundaryDispTime=2.6 end},
    WIDGET.new{type='slider',     pos={0,0},x=260, y=1000,w=210,    text=LANG'setting_safeY',       widthLimit=200,axis={0,60,10},               disp=TABLE.func_getVal(SETTINGS,'safeY'),      code=function(v) SETTINGS.safeY=v boundaryDispTime=2.6 end},
    WIDGET.new{type='slider',     pos={0,0},x=260, y=1050,w=260,    text=LANG'setting_showHitLV',   widthLimit=200,axis={0,5,1},                 disp=TABLE.func_getVal(SETTINGS,'showHitLV'),  valueShow=sliderShow_hitLV,code=TABLE.func_setVal(SETTINGS,'showHitLV')},
    WIDGET.new{type='slider',     pos={0,0},x=260, y=1100,w=420,    text=LANG'setting_dvtCount',    widthLimit=200,axis={5,50,5},                disp=TABLE.func_getVal(SETTINGS,'dvtCount'),   code=TABLE.func_setVal(SETTINGS,'dvtCount')},

    WIDGET.new{type='slider',     pos={0,0},x=260,y=1200,w=420,     text=LANG'setting_maxFPS',      widthLimit=200,axis={60,360,10},smooth=true, disp=TABLE.func_getVal(SETTINGS,'maxFPS'),     valueShow=sliderShow_fps,code=TABLE.func_setVal(SETTINGS,'maxFPS')},
    WIDGET.new{type='slider',     pos={0,0},x=260,y=1250,w=420,     text=LANG'setting_updRate',     widthLimit=200,axis={20,100,10},             disp=TABLE.func_getVal(SETTINGS,'updRate'),    valueShow=sliderShow_mul,code=TABLE.func_setVal(SETTINGS,'updRate')},
    WIDGET.new{type='slider',     pos={0,0},x=260,y=1300,w=420,     text=LANG'setting_drawRate',    widthLimit=200,axis={20,100,10},             disp=TABLE.func_getVal(SETTINGS,'drawRate'),   valueShow=sliderShow_mul,code=TABLE.func_setVal(SETTINGS,'drawRate')},

    WIDGET.new{type='switch',     pos={1,0},x=-100,y=70,            text=LANG'setting_sysCursor',   widthLimit=360,disp=TABLE.func_getVal(SETTINGS,'sysCursor'),     code=TABLE.func_revVal(SETTINGS,'sysCursor')},
    WIDGET.new{type='switch',     pos={1,0},x=-100,y=130,           text=LANG'setting_clickFX',     widthLimit=360,disp=TABLE.func_getVal(SETTINGS,'clickFX'),       code=TABLE.func_revVal(SETTINGS,'clickFX')},
    WIDGET.new{type='switch',     pos={1,0},x=-100,y=190,           text=LANG'setting_power',       widthLimit=360,disp=TABLE.func_getVal(SETTINGS,'powerInfo'),     code=TABLE.func_revVal(SETTINGS,'powerInfo')},
    WIDGET.new{type='switch',     pos={1,0},x=-100,y=250,           text=LANG'setting_clean',       widthLimit=360,disp=TABLE.func_getVal(SETTINGS,'cleanCanvas'),   code=TABLE.func_revVal(SETTINGS,'cleanCanvas')},
    WIDGET.new{type='switch',     pos={1,0},x=-100,y=310,           text=LANG'setting_fullscreen',  widthLimit=360,disp=TABLE.func_getVal(SETTINGS,'fullscreen'),    code=TABLE.func_revVal(SETTINGS,'fullscreen')},
    WIDGET.new{type='switch',     pos={1,0},x=-100,y=370,           text=LANG'setting_autoMute',    widthLimit=360,disp=TABLE.func_getVal(SETTINGS,'autoMute'),      code=TABLE.func_revVal(SETTINGS,'autoMute')},
    WIDGET.new{type='switch',     pos={1,0},x=-100,y=430,           text=LANG'setting_slowUnfocus', widthLimit=360,disp=TABLE.func_getVal(SETTINGS,'slowUnfocus'),   code=TABLE.func_revVal(SETTINGS,'slowUnfocus')},

    WIDGET.new{type='switch',     pos={1,0},x=-100,y=520,           text=LANG'setting_showTouch',   widthLimit=360,disp=TABLE.func_getVal(SETTINGS,'showTouch'),     code=TABLE.func_revVal(SETTINGS,'showTouch')},

    WIDGET.new{type='button_fill',pos={1,1},x=-320,y=-80,w=160,h=80,fontSize=60,text=CHAR.icon.keyboard,code=WIDGET.c_goScn'setting_key'},

    WIDGET.new{type='button_fill',pos={1,1},x=-120,y=-80,w=160,h=80,sound='back',fontSize=60,text=CHAR.icon.back,code=WIDGET.c_backScn},
}

return scene
