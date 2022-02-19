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

local scene={}

function scene.leave()
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
    SETTING.locale=lid
    applySettings()
    TEXT.clear()
    TEXT.show(langList[lid],640,360,100,'appear',.626)
    collectgarbage()
    WIDGET.resize()
    if FIRSTLAUNCH then SCN.back() end
end

scene.widgetList={
    WIDGET.new{type='button_fill',x=271,y=210,w=346,h=100,sound='check',fontSize=40, text=langList.en,      color='R',code=function() _setLang('en') end},
    -- WIDGET.new{type='button_fill',x=271,y=329,w=346,h=100,fontSize=40, text=langList.fr,      color='F',sound='check',code=function() _setLang('fr') end},
    -- WIDGET.new{type='button_fill',x=271,y=449,w=346,h=100,fontSize=35, text=langList.es,      color='O',sound='check',code=function() _setLang('es') end},
    -- WIDGET.new{type='button_fill',x=271,y=568,w=346,h=100,fontSize=35, text=langList.id,      color='Y',sound='check',code=function() _setLang('id') end},

    -- WIDGET.new{type='button_fill',x=637,y=210,w=346,h=100,fontSize=40, text=langList.pt,      color='A',sound='check',code=function() _setLang('pt') end},
    -- WIDGET.new{type='button_fill',x=637,y=329,w=346,h=100,fontSize=40, text=langList.symbol,  color='G',sound='check',code=function() _setLang('symbol') end},
    -- WIDGET.new{type='button_fill',x=637,y=449,w=346,h=100,fontSize=40, text=langList.ja,      color='J',sound='check',code=function() _setLang('ja') end},
    -- WIDGET.new{type='button_fill',x=637,y=568,w=346,h=100,fontSize=40, text=langList.zh_grass,color='L',sound='check',code=function() _setLang('zh_grass') end},

    WIDGET.new{type='button_fill',x=1003,y=210,w=346,h=100,sound='check',fontSize=40,text=langList.zh,      color='C',code=function() _setLang('zh') end},
    -- WIDGET.new{type='button_fill',x=1003,y=329,w=346,h=100,fontSize=40,text=langList.zh_full, color='N',sound='check',code=function() _setLang('zh_full') end},
    -- WIDGET.new{type='button_fill',x=1003,y=449,w=346,h=100,fontSize=40,text=langList.zh_trad, color='S',sound='check',code=function() _setLang('zh_trad') end},

    WIDGET.new{type='button_fill',x=1003,y=568,w=346,h=100,sound='back',fontSize=60,text=CHAR.icon.back,code=WIDGET.c_backScn},
}

return scene
