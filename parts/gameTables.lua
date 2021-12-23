--Static data tables
mapMetaKeys={
    "version",
    "mapName",
    "musicAuth",
    "mapAuth",
    "mapDifficulty",

    "songFile",
    "songOffset",
    "tracks",
    "freeSpeed",
}
mapMetaKeyMap={}for i=1,#mapMetaKeys do mapMetaKeyMap[mapMetaKeys[i]]=true end
hitColors={
    [-1]=COLOR.dRed,
    [0]=COLOR.dRed,
    COLOR.lViolet,
    COLOR.lSea,
    COLOR.lOrange,
    COLOR.lGray,
    COLOR.white,
}
hitTexts={
    [-1]="MISS",
    [0]="BAD",
    'OK',
    'GOOD',
    'GREAT',
    'PERF',
    'MARV'
}
hitAccList={
    -100,--OK
    -26, --GOOD
    62,  --GREAT
    100,  --PERF
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
do--Userdata tables
    KEY_MAP={
        {space=1},
        {d=1,f=1,j=2,k=2},
        {d=1,f=1,v=2,n=2,j=3,k=3},
        {d=1,f=2,j=3,k=4},
        {d=1,f=2,v=3,n=3,j=4,k=5},
        {s=1,d=2,f=3,j=4,k=5,l=6},
        {s=1,d=2,f=3,space=4,j=5,k=6,l=7},
        {a=1,s=2,d=3,f=4,j=5,k=6,l=7,[';']=8},
        space='skip',
        ['`']='restart',
        ['-']='dropSlower',
        ['=']='dropFaster',
    }
    for i=1,#KEY_MAP do
        setmetatable(KEY_MAP[i],{__index=KEY_MAP})
    end
    SETTING={--Settings
        --Framework
        clickFX=true,
        powerInfo=true,
        cleanCanvas=false,
        fullscreen=true,
        maxFPS=180,
        frameMul=50,

        --System
        sysCursor=false,
        locale='zh',
        slowUnfocus=true,

        --Game
        musicDelay=260,
        dropSpeed=8,
        holdAlpha=.26,
        holdWidth=.8,

        --Sound
        autoMute=true,
        sfxPack='chiptune',
        vocPack='miya',
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
        run=0,game=0,time=0,frame=0,
        key=0,rotate=0,hold=0,
        extraPiece=0,finesseRate=0,
        piece=0,row=0,dig=0,
        atk=0,digatk=0,
        send=0,recv=0,pend=0,off=0,
        clear=(function()local L={}for i=1,29 do L[i]={0,0,0,0,0,0}end return L end)(),
        spin=(function()local L={}for i=1,29 do L[i]={0,0,0,0,0,0,0}end return L end)(),
        pc=0,hpc=0,b2b=0,b3b=0,score=0,
        lastPlay='sprint_10l',--Last played mode ID
        item=setmetatable({},{__index=function(self,k)
            self[k]=0
            return 0
        end}),
        date=false,
        todayTime=0,
    }
end
