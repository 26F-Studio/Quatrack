--Static data tables
RANK_CHARS={'B','A','S','U','X'}for i=1,#RANK_CHARS do RANK_CHARS[i]=CHAR.icon['rank'..RANK_CHARS[i]]end
RANK_BASE_COLORS={
    {.1,.2,.3},
    {.3,.42,.32},
    {.45,.44,.15},
    {.42,.25,.2},
    {.42,.15,.4},
}
RANK_COLORS={
    {.8,.86,.9},
    {.6,.9,.7},
    {.93,.93,.65},
    {1,.5,.4},
    {.95,.5,.95},
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
    }
    for i=1,#KEY_MAP do
        setmetatable(KEY_MAP[i],{__index=KEY_MAP})
    end
    SETTING={--Settings
        --System
        autoPause=true,
        menuPos='middle',
        fine=false,
        autoSave=false,
        autoLogin=true,
        simpMode=false,
        sysCursor=true,
        locale='zh',

        --Graphic
        frameMul=100,
        cleanCanvas=false,

        text=true,
        score=true,
        bufferWarn=true,
        showSpike=true,
        highCam=true,
        nextPos=true,
        fullscreen=true,
        bg='on',
        bgAlpha=.26,
        powerInfo=true,
        clickFX=true,
        warn=true,

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

        --Virtualkey
        VKSFX=.2,--SFX volume
        VKVIB=0,--VIB
        VKSwitch=false,--If disp
        VKSkin=1,--If disp
        VKTrack=false,--If tracked
        VKDodge=false,--If dodge
        VKTchW=.3,--Touch-Pos Weight
        VKCurW=.4,--Cur-Pos Weight
        VKIcon=true,--If disp icon
        VKAlpha=.3,
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
