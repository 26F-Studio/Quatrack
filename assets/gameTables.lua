-- Static data tables
mapMetaKeys={
    "version",
    "mapName",
    "musicAuth",
    "mapAuth",
    "mapAuth2",
    "scriptAuth",
    "mapDifficulty",

    "songFile",
    "songImage",
    "songOffset",
    "tracks",
    "realTracks",
    "freeSpeed",
    "script",
}
mapMetaKeyMap={} for i=1,#mapMetaKeys do mapMetaKeyMap[mapMetaKeys[i]]=true end
defaultChordColor={
    {COLOR.hex("FFFF00")},
    {COLOR.hex("FFC000")},
    {COLOR.hex("FF6000")},
    {COLOR.hex("FF0000")},
}setmetatable(defaultChordColor,{__index=function(self,k)
    local l=#self
    for i=l+1,k do
        self[i]=self[l]
    end
    return self[l]
end})

mapTemplate={
    version="1.0",
    mapName='[mapName]',
    musicAuth='[musicAuth]',
    mapAuth='[mapAuth]',
    scriptAuth='[scriptAuth]',
    mapDifficulty='[mapDifficulty]',

    songFile="[songFile]",
    songImage=false,
    songOffset=0,
    tracks=4,
    realTracks=false,
    freeSpeed=true,
    script=false,
}
do
    local GC=GC
    mapScriptEnv={
        print=print,
        assert=assert,error=error,
        tonumber=tonumber,tostring=tostring,
        select=select,next=next,
        ipairs=ipairs,pairs=pairs,
        type=type,
        pcall=pcall,xpcall=xpcall,
        rawget=rawget,rawset=rawset,rawlen=rawlen,rawequal=rawequal,
        setfenv=setfenv,setmetatable=setmetatable,
        math={},string={},table={},bit={},coroutine={},
        debug={},package={},io={},os={},

        MATH={},STRING={},TABLE={},
        gc={
            setColor=function(r,g,b,a) GC.setColor(r,g,b,a) end,
            setLineWidth=function(w) GC.setLineWidth(w) end,
            setFont=function(f) FONT.set(f) end,

            line=function(...) GC.line(...) end,
            rectangle=function(mode,x,y,w,h) GC.rectangle(mode,x,y,w,h) end,
            circle=function(mode,x,y,r) GC.circle(mode,x,y,r) end,
            regPolygon=function(mode,x,y,r,sides,phase) GC.regPolygon(mode,x,y,r,sides,phase) end,
            polygon=function(mode,...)GC.polygon(mode,...) end,
            print=function(text,x,y,mode)
                if not mode or mode=='center' then
                    GC.printf(text,x-2600,y,5200,'center')
                elseif mode=='left' then
                    GC.printf(text,x,y,5200,'left')
                elseif mode=='right' then
                    GC.printf(text,x-5200,y,5200,'right')
                else
                    error("Print mode must be center/left/right")
                end
            end,
        },

        message=function(mes,time) MES.new('info',mes,time or 3) end,
        -- sfx=function(name,vol,pos,pitch) SFX.play(name,vol,pos,pitch) end,
    }
    for _,v in next,{
        'math','string','table',
        'bit','coroutine',
        'MATH','STRING','TABLE',
    } do TABLE.complete(_G[v],mapScriptEnv[v]) end
    mapScriptEnv.string.dump=nil
    local dangerousLibMeta={__index=function() error("No way.") end}
    for _,v in next,{
        'debug','package','io','os'
    } do setmetatable(mapScriptEnv[v],dangerousLibMeta) end
end

hitColors={
    [-1]=COLOR.dR,
    [0]=COLOR.dR,
    COLOR.lV,
    COLOR.lS,
    COLOR.lO,
    COLOR.dL,
    COLOR.dL,
}
hitTexts={
    [-1]="MISS",
    [0]="BAD",
    'WELL',
    'GOOD',
    'PERF',
    'PREC',
    'MARV'
}
chainColors={
    [0]=COLOR.lD,
    COLOR.lS,
    COLOR.lS,
    COLOR.lF,
    COLOR.lY,
    COLOR.lY,
}
rankColors={
    COLOR.lM,
    COLOR.lF,
    COLOR.lY,
    COLOR.lG,
    COLOR.lB,
    COLOR.dV,
    COLOR.dW,
    COLOR.lD,
} for i=1,#rankColors do rankColors[i]={.3+rankColors[i][1]*.7,.3+rankColors[i][2]*.7,.3+rankColors[i][3]*.7} end
defaultTrackNames={
    {'C'},
    {'L1','R1'},
    {'L1','C','R1'},
    {'L2','L1','R1','R2'},
    {'L2','L1','C','R1','R2'},
    {'L3','L2','L1','R1','R2','R3'},
    {'L3','L2','L1','C','R1','R2','R3'},
    {'L4','L3','L2','L1','R1','R2','R3','R4'},
    {'L4','L3','L2','L1','C','R1','R2','R3','R4'},
    {'L5','L4','L3','L2','L1','R1','R2','R3','R4','R5'},
    {'L5','L4','L3','L2','L1','C','R1','R2','R3','R4','R5'},
}
trackNames={
    L1=true,L2=true,L3=true,L4=true,L5=true,
    R1=true,R2=true,R3=true,R4=true,R5=true,
    C=true,
}
actionNames={
    'L5','L4','L3','L2','L1',
    'C',
    'R1','R2','R3','R4','R5',
    'restart',
    'skip',
    'auto',
    'sfxVolDn',
    'sfxVolUp',
    'musicVolDn',
    'musicVolUp',
    'dropSpdDn',
    'dropSpdUp',
}
do-- Userdata tables
    KEY_MAP={-- Keys-Function map, for convert direct key input
        f='L1',d='L2',s='L3',a='L4',lshift='L5',
        space='C',
        j='R1',k='R2',l='R3',[';']='R4',['/']='R5',
        ['`']='restart',
        ['return']='skip',
        f5='auto',
        f1='sfxVolDn',
        f2='sfxVolUp',
        f3='musicVolDn',
        f4='musicVolUp',
        ['-']='dropSpdDn',
        ['=']='dropSpdUp',
    }
    KEY_MAP_inv={-- Function-Keys map, for show key name
        _update=function(self)
            local _f=self._update
            TABLE.clear(self)
            self._update=_f
            for k,v in next,KEY_MAP do
                self[v]=k
            end
        end,
    }
    STAT={
        version=VERSION.code,
        run=0,game=0,time=0,
        score=0,
        hits={
            miss=0,
            bad=0,
            well=0,
            good=0,
            perf=0,
            prec=0,
            marv=0,
        },
        item=setmetatable({},{__index=function(self,k)
            self[k]=0
            return 0
        end}),
        date=false,
        todayTime=0,
    }
    local settings={-- Settings
        __data={
            -- Framework
            clickFX=true,
            powerInfo=true,
            cleanCanvas=false,
            fullscreen=true,
            maxFPS=300,
            updRate=100,
            drawRate=30,

            -- System
            sysCursor=false,
            locale='zh',
            slowUnfocus=true,

            -- Game
            bgAlpha=.26,
            musicDelay=0,
            dropSpeed=0,
            noteThick=22,
            chordAlpha=.8,
            holdAlpha=.26,
            holdWidth=.8,
            scaleX=1,
            trackW=1,
            safeX=10,
            safeY=10,
            showHitLV=5,
            dvtCount=20,
            showTouch=true,

            -- Sound
            autoMute=false,
            mainVol=1,
            sfxVol=1,
            bgmVol=.7,
            stereo=.7,
            vib=0,
            voc=0,
        },
    }
    local settingTriggers={-- Changing values in SETTINGS.system will trigger these functions (if exist).
        -- Audio
        mainVol=        function(v) love.audio.setVolume(v) end,
        bgmVol=         function(v) BGM.setVol(v) end,
        sfxVol=         function(v) SFX.setVol(v) end,
        vocVol=         function(v) VOC.setVol(v) end,

        -- Video
        fullscreen=     function(v) love.window.setFullscreen(v) love.resize(love.graphics.getWidth(),love.graphics.getHeight()) end,
        maxFPS=         function(v) Zenitha.setMaxFPS(v) end,
        updRate=        function(v) Zenitha.setUpdateFreq(v) end,
        drawRate=       function(v) Zenitha.setDrawFreq(v) end,
        sysCursor=      function(v) love.mouse.setVisible(v) end,
        clickFX=        function(v) Zenitha.setClickFX(v) end,
        clean=          function(v) Zenitha.setCleanCanvas(v) end,

        -- Other
        locale=         function(v) Text=LANG.get(v) LANG.setTextFuncSrc(Text) end,
    }
    setmetatable(settings,{
        __index=settings.__data,
        __newindex=function(_,k,v)
            if settings.__data[k]~=v then
                settings.__data[k]=v
                if settingTriggers[k] then
                    settingTriggers[k](v)
                end
            end
        end,
        __metatable=true,
    })
    SETTINGS=settings
end
