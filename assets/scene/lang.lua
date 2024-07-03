local langList={
    zh="简体中文",
    zh_full="全简体中文",
    zh_trad="繁體中文",
    en="English",
    fr="Français",
    es="　Español\n(Castellano)",
    pt="Português",
    id="Bahasa Indonesia",
    ja="日本語",
    zh_grass="机翻",
    symbol="?????",
}
local languages={
    "Language  Langue  Lingua",
    "语言  言語  언어",
    "Idioma  Línguas  Sprache",
    "Язык  Γλώσσα  Bahasa",
}
local curLang=1

---@type Zenitha.Scene
local scene={}

function scene.unload()
    saveSettings()
end

function scene.update(dt)
    curLang=curLang+dt*1.26
    if curLang>=#languages+1 then
        curLang=1
    end
end

function scene.draw()
    FONT.set(80)
    love.graphics.setColor(1,1,1,1-curLang%1*2)
    GC.mStr(languages[curLang-curLang%1],640,20)
    love.graphics.setColor(1,1,1,curLang%1*2)
    GC.mStr(languages[curLang-curLang%1+1] or languages[1],640,20)
end

local function _setLang(lid)
    SETTINGS.locale=lid
    TEXT:clear()
    TEXT:add{
        text=langList[lid],
        x=640,
        y=360,
        fontSize=100,
        style='appear',
        duration=1.6,
    }
    collectgarbage()
    WIDGET._reset()
    if FIRSTLAUNCH then SCN.back() end
end

scene.widgetList={
    WIDGET.new{type='button_fill',x=270,y=210,w=330,h=100,fontSize=40, text=langList.en, color='R', sound_press='check',code=function() _setLang('en') end},
    WIDGET.new{type='button'     ,x=270,y=330,w=330,h=100,fontSize=40, text='',          color='F', sound_press='check'},
    WIDGET.new{type='button'     ,x=270,y=450,w=330,h=100,fontSize=35, text='',          color='O', sound_press='check'},
    WIDGET.new{type='button'     ,x=270,y=570,w=330,h=100,fontSize=35, text='',          color='Y', sound_press='check'},

    WIDGET.new{type='button'     ,x=640,y=210,w=330,h=100,fontSize=40, text='',          color='A', sound_press='check'},
    WIDGET.new{type='button'     ,x=640,y=330,w=330,h=100,fontSize=40, text='',          color='K', sound_press='check'},
    WIDGET.new{type='button'     ,x=640,y=450,w=330,h=100,fontSize=40, text='',          color='G', sound_press='check'},
    WIDGET.new{type='button'     ,x=640,y=570,w=330,h=100,fontSize=40, text='',          color='J', sound_press='check'},

    WIDGET.new{type='button_fill',x=1000,y=210,w=330,h=100,fontSize=40,text=langList.zh, color='I', sound_press='check',code=function() _setLang('zh') end},
    WIDGET.new{type='button'     ,x=1000,y=330,w=330,h=100,fontSize=40,text='',          color='B', sound_press='check'},
    WIDGET.new{type='button'     ,x=1000,y=450,w=330,h=100,fontSize=40,text='',          color='P', sound_press='check'},

    WIDGET.new{type='button_fill',x=1000,y=570,w=330,h=100,sound_press='back',fontSize=60,text=CHAR.icon.back,code=WIDGET.c_backScn()},
}

return scene
