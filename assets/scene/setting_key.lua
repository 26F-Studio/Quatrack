---@type Zenitha.Scene
local scene={}

local selected-- if waiting for key

local keyNames={
    normal={
        a='A',b='B',c='C',d='D',e='E',f='F',g='G',
        h='H',i='I',j='J',k='K',l='L',m='M',n='N',
        o='O',p='P',q='Q',r='R',s='S',t='T',
        u='U',v='V',w='W',x='X',y='Y',z='Z',
        f1='F1',f2='F2',f3='F3',f4='F4',f5='F5',f6='F6',
        f7='F7',f8='F8',f9='F9',f10='F10',f11='F11',f12='F12',
        backspace=CHAR.key.backspace,
        ['return']=CHAR.key.returnKey,
        kpenter='kp'..CHAR.key.returnKey,
        tab=CHAR.key.tab,
        capslock=CHAR.key.capslock,
        lshift='L shift',
        rshift='R shift',
        lctrl='L ctrl',
        rctrl='R ctrl',
        lalt='L alt',
        ralt='R alt',
        lgui='L'..CHAR.key.windows,
        rgui='R'..CHAR.key.windows,
        space=CHAR.key.space,
        delete='Del',
        pageup='PgUp',
        pagedown='PgDn',
        home='Home',
        [' end']=' End',
        insert='Ins',
        numlock='Numlock',
        menu=CHAR.key.menu,
        up=CHAR.key.up,
        down=CHAR.key.down,
        left=CHAR.key.left,
        right=CHAR.key.right,
    },
    apple={
        kpenter=CHAR.key.mac_enter,
        tab=CHAR.key.mac_tab,
        lshift='L'..CHAR.key.shift,
        rshift='R'..CHAR.key.shift,
        lctrl='L'..CHAR.key.mac_control,
        rctrl='R'..CHAR.key.mac_control,
        lalt='L'..CHAR.key.mac_option,
        ralt='R'..CHAR.key.mac_option,
        lgui='L'..CHAR.key.mac_command,
        rgui='R'..CHAR.key.mac_command,
        space=CHAR.key.space,
        delete=CHAR.key.mac_fwdel,
        pageup=CHAR.key.mac_pgup,
        pagedown=CHAR.key.mac_pgdn,
        home=CHAR.key.mac_home,
        ['end']=CHAR.key.mac_end,
        numlock=CHAR.key.mac_clear,
    },
    controller={
        a=CHAR.key.ctrl_A,
        b=CHAR.key.ctrl_B,
        x=CHAR.key.ctrl_X,
        y=CHAR.key.ctrl_Y,
        dpup=CHAR.key.dpad_u,
        dpdown=CHAR.key.dpad_d,
        dpleft=CHAR.key.dpad_l,
        dpright=CHAR.key.dpad_r,
        triggerleft=CHAR.key.ctrl_lt,
        triggerright=CHAR.key.ctrl_rt,
        leftshoulder=CHAR.key.ctrl_lb,
        rightshoulder=CHAR.key.ctrl_rb,
        leftstick_up=CHAR.key.js_l_u,
        leftstick_down=CHAR.key.js_l_d,
        leftstick_left=CHAR.key.js_l_l,
        leftstick_right=CHAR.key.js_l_r,
        rightstick_up=CHAR.key.js_r_u,
        rightstick_down=CHAR.key.js_r_d,
        rightstick_left=CHAR.key.js_r_l,
        rightstick_right=CHAR.key.js_r_r,
    },
}setmetatable(keyNames.apple,{__index=keyNames.normal})

function scene.load()
    selected=false
    KEY_MAP_inv:_update()
    BG.set('none')
end
function scene.unload()
    saveFile(KEY_MAP,'conf/key')
end

local forbbidenKeys={
    ["\\"]=true,
    ["return"]=true,
}
function scene.keyDown(key,isRep)
    if isRep then return end
    if key=='escape' then
        if selected then
            selected=false
        else
            SCN.back()
        end
    elseif key=='backspace' then
        if selected then
            local binded=TABLE.findAll(KEY_MAP,selected)
            if binded then
                KEY_MAP[binded]=nil
            end
            KEY_MAP_inv:_update()
            selected=false
        end
    elseif selected then
        if not forbbidenKeys[key] then
            local oldKey=TABLE.findAll(KEY_MAP,selected)
            if oldKey then KEY_MAP[oldKey]=nil end
            KEY_MAP[key]=selected
            KEY_MAP_inv:_update()
            selected=false
        end
    else
        return
    end
    return true
end

function scene.draw()
    FONT.set(30)
    for i=1,20 do
        GC.setColor(
            selected==actionNames[i] and (
                love.timer.getTime()%.26>.13 and COLOR.R or
                COLOR.Y
            ) or
            COLOR.L
        )
        local W=scene.widgetList[i]
        local x,y=W._x,W._y
        if i<=11 then
            GC.mStr(KEY_MAP_inv[actionNames[i]] or '[X]',x,y-90)
        else
            GC.mStr(KEY_MAP_inv[actionNames[i]] or '[X]',x+140,y-25)
        end
    end

    GC.replaceTransform(SCR.xOy_dr)
    FONT.set(20)
    GC.setColor(COLOR.L)
    GC.printf(Text.keySettingInstruction,-710,-120,500,'right')
end

local function _setSel(i)
    if selected==i then
        selected=false
    else
        selected=actionNames[i]
    end
end
scene.widgetList={
    WIDGET.new{type='button',pos={0.10,false},x=0,y=260,w=100,h=60,sound_press='key',fontSize=30,text='L5',color='lD',code=function() _setSel(01) end},
    WIDGET.new{type='button',pos={0.18,false},x=0,y=260,w=100,h=60,sound_press='key',fontSize=30,text='L4',color='lD',code=function() _setSel(02) end},
    WIDGET.new{type='button',pos={0.26,false},x=0,y=260,w=100,h=60,sound_press='key',fontSize=30,text='L3',color='L' ,code=function() _setSel(03) end},
    WIDGET.new{type='button',pos={0.34,false},x=0,y=260,w=100,h=60,sound_press='key',fontSize=30,text='L2',color='lB',code=function() _setSel(04) end},
    WIDGET.new{type='button',pos={0.42,false},x=0,y=260,w=100,h=60,sound_press='key',fontSize=30,text='L1',color='lB',code=function() _setSel(05) end},
    WIDGET.new{type='button',pos={0.50,false},x=0,y=260,w=100,h=60,sound_press='key',fontSize=30,text='C', color='L' ,code=function() _setSel(06) end},
    WIDGET.new{type='button',pos={0.58,false},x=0,y=260,w=100,h=60,sound_press='key',fontSize=30,text='R1',color='lB',code=function() _setSel(07) end},
    WIDGET.new{type='button',pos={0.66,false},x=0,y=260,w=100,h=60,sound_press='key',fontSize=30,text='R2',color='lB',code=function() _setSel(08) end},
    WIDGET.new{type='button',pos={0.74,false},x=0,y=260,w=100,h=60,sound_press='key',fontSize=30,text='R3',color='L' ,code=function() _setSel(09) end},
    WIDGET.new{type='button',pos={0.82,false},x=0,y=260,w=100,h=60,sound_press='key',fontSize=30,text='R4',color='lD',code=function() _setSel(10) end},
    WIDGET.new{type='button',pos={0.90,false},x=0,y=260,w=100,h=60,sound_press='key',fontSize=30,text='R5',color='lD',code=function() _setSel(11) end},

    WIDGET.new{type='button',pos={0.1111,false},x=0,y=400,w=120,h=60,sound_press='key',fontSize=25,text=LANG'keySetting_restart',   color='lR',code=function() _setSel(12) end},
    WIDGET.new{type='button',pos={0.1111,false},x=0,y=480,w=120,h=60,sound_press='key',fontSize=25,text=LANG'keySetting_skip',      color='lG',code=function() _setSel(13) end},
    WIDGET.new{type='button',pos={0.1111,false},x=0,y=560,w=120,h=60,sound_press='key',fontSize=25,text=LANG'keySetting_auto',      color='lO',code=function() _setSel(14) end},
    WIDGET.new{type='button',pos={0.3333,false},x=0,y=400,w=120,h=60,sound_press='key',fontSize=25,text=LANG'keySetting_sfxVolDn',  color='lL',code=function() _setSel(15) end},
    WIDGET.new{type='button',pos={0.3333,false},x=0,y=480,w=120,h=60,sound_press='key',fontSize=25,text=LANG'keySetting_sfxVolUp',  color='lL',code=function() _setSel(16) end},
    WIDGET.new{type='button',pos={0.5555,false},x=0,y=400,w=120,h=60,sound_press='key',fontSize=25,text=LANG'keySetting_musicVolDn',color='lL',code=function() _setSel(17) end},
    WIDGET.new{type='button',pos={0.5555,false},x=0,y=480,w=120,h=60,sound_press='key',fontSize=25,text=LANG'keySetting_musicVolUp',color='lL',code=function() _setSel(18) end},
    WIDGET.new{type='button',pos={0.7777,false},x=0,y=400,w=120,h=60,sound_press='key',fontSize=25,text=LANG'keySetting_dropSpdDn', color='lL',code=function() _setSel(19) end},
    WIDGET.new{type='button',pos={0.7777,false},x=0,y=480,w=120,h=60,sound_press='key',fontSize=25,text=LANG'keySetting_dropSpdUp', color='lL',code=function() _setSel(20) end},

    WIDGET.new{type='button_fill',pos={1,1},x=-120,y=-80,w=160,h=80,sound_press='back',fontSize=60,text=CHAR.icon.back,code=WIDGET.c_backScn()},
}

return scene
