--Static data tables
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
mapMetaKeyMap={}for i=1,#mapMetaKeys do mapMetaKeyMap[mapMetaKeys[i]]=true end
defaultChordColor={
    {STRING.hexColor("FFFF00")},
    {STRING.hexColor("FFC000")},
    {STRING.hexColor("FF6000")},
    {STRING.hexColor("FF0000")},
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
    local gc=love.graphics
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
            setColor=function(r,g,b,a)gc.setColor(r,g,b,a)end,
            setLineWidth=function(w)gc.setLineWidth(w)end,
            setFont=function(f)setFont(f)end,

            line=function(x1,y1,x2,y2)gc.line(x1,y1,x2,y2)end,
            rect=function(mode,x,y,w,h)gc.rectangle(mode or'line',x,y,w,h)end,
            circle=function(mode,x,y,r)gc.circle(mode or'line',x,y,r)end,
            polygon=function(mode,x,y,r,sides,phase)GC.regPolygon(mode or'line',x,y,r,sides,phase)end,
            print=function(mode,text,x,y)gc.printf(text,x-2600,y,5200,mode or'center')end,
        },

        message=function(mes)MES.new('info',mes)end,
    }
    for _,v in next,{
        'math','string','table',
        'bit','coroutine',
        'MATH','STRING','TABLE',
    }do TABLE.complete(_G[v],mapScriptEnv[v])end
    mapScriptEnv.string.dump=nil
    local dangerousLibMeta={__index=function()error("No way.")end}
    for _,v in next,{
        'debug','package','io','os'
    }do setmetatable(mapScriptEnv[v],dangerousLibMeta)end
end

hitColors={
    [-1]=COLOR.dRed,
    [0]=COLOR.dRed,
    COLOR.lViolet,
    COLOR.lSea,
    COLOR.lOrange,
    COLOR.lGray,
    COLOR.lGray,
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
hitAccList={
    -100,--WELL
    0,   --GOOD
    75,  --PERF
    100, --PREC
    101, --MARV
}
hitLVOffsets={--Time judgement
    .16,
    .12,
    .08,
    .05,
    .03,
    0,
}
chainColors={
    [0]=COLOR.dH,
    COLOR.lSea,
    COLOR.lSea,
    COLOR.lFire,
    COLOR.lYellow,
    COLOR.lYellow,
}
rankColors={
    COLOR.lMagenta,
    COLOR.lFire,
    COLOR.lYellow,
    COLOR.lGreen,
    COLOR.lBlue,
    COLOR.dViolet,
    COLOR.dWine,
    COLOR.dGray,
}for i=1,#rankColors do rankColors[i]={.3+rankColors[i][1]*.7,.3+rankColors[i][2]*.7,.3+rankColors[i][3]*.7} end
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
do--Userdata tables
    KEY_MAP={--Keys-Function map, for convert direct key input
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
    KEY_MAP_inv={--Function-Keys map, for show key name
        _update=function(self)
            local _f=self._update
            TABLE.clear(self)
            self._update=_f
            for k,v in next,KEY_MAP do
                self[v]=k
            end
        end,
    }
    SETTING={--Settings
        --Framework
        clickFX=true,
        powerInfo=true,
        cleanCanvas=false,
        fullscreen=true,
        maxFPS=300,
        frameMul=30,

        --System
        sysCursor=false,
        locale='zh',
        slowUnfocus=true,

        --Game
        bgAlpha=.16,
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

        --Sound
        autoMute=false,
        mainVol=1,
        sfx=1,
        sfx_spawn=0,
        sfx_warn=.4,
        bgm=.7,
        stereo=.7,
        vib=0,
        voc=0,
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
end
