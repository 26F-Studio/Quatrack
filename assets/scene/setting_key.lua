local scene={}

local selected--if waiting for key

local keyNames={
    normal={
        a='A',b='B',c='C',d='D',e='E',f='F',g='G',
        h='H',i='I',j='J',k='K',l='L',m='M',n='N',
        o='O',p='P',q='Q',r='R',s='S',t='T',
        u='U',v='V',w='W',x='X',y='Y',z='Z',
        f1='F1',f2='F2',f3='F3',f4='F4',f5='F5',f6='F6',
        f7='F7',f8='F8',f9='F9',f10='F10',f11='F11',f12='F12',
        backspace=CHAR.key.backspace,
        ['return']=CHAR.key.enter_or_return,
        kpenter='kp'..CHAR.key.enter_or_return,
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
        menu=CHAR.key.winMenu,
        up=CHAR.key.up,
        down=CHAR.key.down,
        left=CHAR.key.left,
        right=CHAR.key.right,
    },
    apple={
        kpenter=CHAR.key.macEnter,
        tab=CHAR.key.mactab,
        lshift='L'..CHAR.key.shift,
        rshift='R'..CHAR.key.shift,
        lctrl='L'..CHAR.key.macCtrl,
        rctrl='R'..CHAR.key.macCtrl,
        lalt='L'..CHAR.key.macOpt,
        ralt='R'..CHAR.key.macOpt,
        lgui='L'..CHAR.key.macCmd,
        rgui='R'..CHAR.key.macCmd,
        space=CHAR.key.space,
        delete=CHAR.key.macFowardDel,
        pageup=CHAR.key.macPgup,
        pagedown=CHAR.key.macPgdn,
        home=CHAR.key.macHome,
        [' end']=CHAR.key.macEnd,
        numlock=CHAR.key.clear,
    },
    controller={
        x=CHAR.controller.xboxX,
        y=CHAR.controller.xboxY,
        a=CHAR.controller.xboxA,
        b=CHAR.controller.xboxB,
        dpup=CHAR.controller.dpadU,
        dpdown=CHAR.controller.dpadD,
        dpleft=CHAR.controller.dpadL,
        dpright=CHAR.controller.dpadR,
        triggerleft=CHAR.controller.lt,
        triggerright=CHAR.controller.rt,
        leftshoulder=CHAR.controller.lb,
        rightshoulder=CHAR.controller.rb,
        leftstick_up=CHAR.controller.jsLU,
        leftstick_down=CHAR.controller.jsLD,
        leftstick_left=CHAR.controller.jsLL,
        leftstick_right=CHAR.controller.jsLR,
        rightstick_up=CHAR.controller.jsRU,
        rightstick_down=CHAR.controller.jsRD,
        rightstick_left=CHAR.controller.jsRL,
        rightstick_right=CHAR.controller.jsRR,
    },
}setmetatable(keyNames.apple,{__index=keyNames.normal})

function scene.enter()
    selected=false
    KEY_MAP_inv:_update()
    BG.set('none')
end
function scene.leave()
    saveFile(KEY_MAP,'conf/key')
end

local forbbidenKeys={
    ["\\"]=true,
    ["return"]=true,
}
function scene.keyDown(key,isRep)
    if isRep then return true end
    if key=='escape' then
        if selected then
            selected=false
        else
            SCN.back()
        end
    elseif key=='backspace' then
        if selected then
            local binded=TABLE.search(KEY_MAP,selected)
            if binded then
                KEY_MAP[binded]=nil
            end
            KEY_MAP_inv:_update()
            selected=false
        end
    elseif selected then
        if not forbbidenKeys[key] then
            local oldKey=TABLE.search(KEY_MAP,selected)
            if oldKey then KEY_MAP[oldKey]=nil end
            KEY_MAP[key]=selected
            KEY_MAP_inv:_update()
            selected=false
        end
    else
        return true
    end
end

function scene.draw()
    FONT.set(30)
    for i=1,20 do
        GC.setColor(
            selected==actionNames[i] and(
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
    WIDGET.new{type='button',pos={0.10,false},x=0,y=260,w=100,h=60,sound='key',fontSize=30,text='L5',color='lD',code=function() _setSel(01) end},
    WIDGET.new{type='button',pos={0.18,false},x=0,y=260,w=100,h=60,sound='key',fontSize=30,text='L4',color='lD',code=function() _setSel(02) end},
    WIDGET.new{type='button',pos={0.26,false},x=0,y=260,w=100,h=60,sound='key',fontSize=30,text='L3',color='L' ,code=function() _setSel(03) end},
    WIDGET.new{type='button',pos={0.34,false},x=0,y=260,w=100,h=60,sound='key',fontSize=30,text='L2',color='lB',code=function() _setSel(04) end},
    WIDGET.new{type='button',pos={0.42,false},x=0,y=260,w=100,h=60,sound='key',fontSize=30,text='L1',color='lB',code=function() _setSel(05) end},
    WIDGET.new{type='button',pos={0.50,false},x=0,y=260,w=100,h=60,sound='key',fontSize=30,text='C', color='L' ,code=function() _setSel(06) end},
    WIDGET.new{type='button',pos={0.58,false},x=0,y=260,w=100,h=60,sound='key',fontSize=30,text='R1',color='lB',code=function() _setSel(07) end},
    WIDGET.new{type='button',pos={0.66,false},x=0,y=260,w=100,h=60,sound='key',fontSize=30,text='R2',color='lB',code=function() _setSel(08) end},
    WIDGET.new{type='button',pos={0.74,false},x=0,y=260,w=100,h=60,sound='key',fontSize=30,text='R3',color='L' ,code=function() _setSel(09) end},
    WIDGET.new{type='button',pos={0.82,false},x=0,y=260,w=100,h=60,sound='key',fontSize=30,text='R4',color='lD',code=function() _setSel(10) end},
    WIDGET.new{type='button',pos={0.90,false},x=0,y=260,w=100,h=60,sound='key',fontSize=30,text='R5',color='lD',code=function() _setSel(11) end},

    WIDGET.new{type='button',pos={0.1111,false},x=0,y=400,w=120,h=60,sound='key',fontSize=25,text=LANG'keySetting_restart',   color='lR',code=function() _setSel(12) end},
    WIDGET.new{type='button',pos={0.1111,false},x=0,y=480,w=120,h=60,sound='key',fontSize=25,text=LANG'keySetting_skip',      color='lG',code=function() _setSel(13) end},
    WIDGET.new{type='button',pos={0.1111,false},x=0,y=560,w=120,h=60,sound='key',fontSize=25,text=LANG'keySetting_auto',      color='lO',code=function() _setSel(14) end},
    WIDGET.new{type='button',pos={0.3333,false},x=0,y=400,w=120,h=60,sound='key',fontSize=25,text=LANG'keySetting_sfxVolDn',  color='lL',code=function() _setSel(15) end},
    WIDGET.new{type='button',pos={0.3333,false},x=0,y=480,w=120,h=60,sound='key',fontSize=25,text=LANG'keySetting_sfxVolUp',  color='lL',code=function() _setSel(16) end},
    WIDGET.new{type='button',pos={0.5555,false},x=0,y=400,w=120,h=60,sound='key',fontSize=25,text=LANG'keySetting_musicVolDn',color='lL',code=function() _setSel(17) end},
    WIDGET.new{type='button',pos={0.5555,false},x=0,y=480,w=120,h=60,sound='key',fontSize=25,text=LANG'keySetting_musicVolUp',color='lL',code=function() _setSel(18) end},
    WIDGET.new{type='button',pos={0.7777,false},x=0,y=400,w=120,h=60,sound='key',fontSize=25,text=LANG'keySetting_dropSpdDn', color='lL',code=function() _setSel(19) end},
    WIDGET.new{type='button',pos={0.7777,false},x=0,y=480,w=120,h=60,sound='key',fontSize=25,text=LANG'keySetting_dropSpdUp', color='lL',code=function() _setSel(20) end},

    WIDGET.new{type='button_fill',pos={1,1},x=-120,y=-80,w=160,h=80,sound='back',fontSize=60,text=CHAR.icon.back,code=WIDGET.c_backScn},
}

return scene
