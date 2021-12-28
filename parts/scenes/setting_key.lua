local gc=love.graphics
local mStr=GC.mStr

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
        ['end']='End',
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
        ['end']=CHAR.key.macEnd,
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

function scene.sceneInit()
    selected=false
    KEY_MAP_inv:_update()
    BG.set('none')
end
function scene.sceneBack()
    saveFile(KEY_MAP,'conf/key')
end

local forbbidenKeys={
    ["\\"]=true,
    ["return"]=true,
}
function scene.keyDown(key,isRep)
    if isRep then return true end
    if key=='escape'then
        if selected then
            selected=false
        else
            SCN.back()
        end
    elseif key=='backspace'then
        if selected then
            KEY_MAP[TABLE.search(KEY_MAP,selected)]=nil
            KEY_MAP_inv:_update()
            selected=false
        end
    elseif selected then
        if not forbbidenKeys[key]then
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
    setFont(20)
    gc.setColor(COLOR.Z)
    gc.printf(text.keySettingInstruction,526,600,500,'right')

    setFont(30)
    for i=1,20 do
        gc.setColor(
            selected==actionNames[i]and(
                TIME()%.26>.13 and COLOR.R or
                COLOR.Y
            )or
            COLOR.Z
        )
        local W=scene.widgetList[i]
        local x,y=W:getCenter()
        if i<=11 then
            mStr(KEY_MAP_inv[actionNames[i]],x,y-90)
        else
            mStr(KEY_MAP_inv[actionNames[i]],x+140,y-25)
        end
    end
end

local function _setSel(i)
    if selected==i then
        selected=false
    else
        selected=actionNames[i]
    end
end
scene.widgetList={
    WIDGET.newKey{name='L5',        x=90,  y=260,w=100,h=60,fText='L5',color='dH',code=function()_setSel(01)end},
    WIDGET.newKey{name='L4',        x=200, y=260,w=100,h=60,fText='L4',color='dH',code=function()_setSel(02)end},
    WIDGET.newKey{name='L3',        x=310, y=260,w=100,h=60,fText='L3',color='Z' ,code=function()_setSel(03)end},
    WIDGET.newKey{name='L2',        x=420, y=260,w=100,h=60,fText='L2',color='lB',code=function()_setSel(04)end},
    WIDGET.newKey{name='L1',        x=530, y=260,w=100,h=60,fText='L1',color='lB',code=function()_setSel(05)end},
    WIDGET.newKey{name='C',         x=640, y=260,w=100,h=60,fText='C', color='Z' ,code=function()_setSel(06)end},
    WIDGET.newKey{name='R1',        x=750, y=260,w=100,h=60,fText='R1',color='lB',code=function()_setSel(07)end},
    WIDGET.newKey{name='R2',        x=860, y=260,w=100,h=60,fText='R2',color='lB',code=function()_setSel(08)end},
    WIDGET.newKey{name='R3',        x=970, y=260,w=100,h=60,fText='R3',color='Z' ,code=function()_setSel(09)end},
    WIDGET.newKey{name='R4',        x=1080,y=260,w=100,h=60,fText='R4',color='dH',code=function()_setSel(10)end},
    WIDGET.newKey{name='R5',        x=1190,y=260,w=100,h=60,fText='R5',color='dH',code=function()_setSel(11)end},

    WIDGET.newKey{name='restart',   x=130, y=400,w=120,h=60,font=25,color='lR',code=function()_setSel(12)end},
    WIDGET.newKey{name='skip',      x=130, y=480,w=120,h=60,font=25,color='lG',code=function()_setSel(13)end},
    WIDGET.newKey{name='auto',      x=130, y=560,w=120,h=60,font=25,color='lO',code=function()_setSel(14)end},
    WIDGET.newKey{name='sfxVolDn',  x=430, y=400,w=120,h=60,font=25,color='lL',code=function()_setSel(15)end},
    WIDGET.newKey{name='sfxVolUp',  x=430, y=480,w=120,h=60,font=25,color='lL',code=function()_setSel(16)end},
    WIDGET.newKey{name='musicVolDn',x=730, y=400,w=120,h=60,font=25,color='lL',code=function()_setSel(17)end},
    WIDGET.newKey{name='musicVolUp',x=730, y=480,w=120,h=60,font=25,color='lL',code=function()_setSel(18)end},
    WIDGET.newKey{name='dropSpdDn', x=1030,y=400,w=120,h=60,font=25,color='lL',code=function()_setSel(19)end},
    WIDGET.newKey{name='dropSpdUp', x=1030,y=480,w=120,h=60,font=25,color='lL',code=function()_setSel(20)end},

    WIDGET.newButton{name='back',x=1140,y=640,w=170,h=80,sound='back',font=60,fText=CHAR.icon.back,code=backScene},
}

return scene
