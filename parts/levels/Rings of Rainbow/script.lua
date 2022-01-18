local objs={}
local events={}
local colorRainbow={[0]={1,0.5,0.5,0.2},{1,0.75,0.5,0.2},{1,1,0.5,0.2},{0.5,1,0.5,0.2},{0.5,1,1,0.2},{0,0.5,1,0.2},{0.5,0,1,0.2},{1,0.5,1,0.2}}
local t,ts,pt=-2.6,0,-2.6
local objTemplate={
    x=0,
    y=0,
    speed=0,
    direction=0,
    gravity=0,
    scale=1,
    life=1e99,
    keep=nil,
    color={1,1,1,1},
    width=2,
    update=nil,
    draw=nil,
    tag={},
}

local rnd=math.random
local ins,rem=table.insert,table.remove

local function pointDirection(x1,y1,x2,y2)
    --local xs,ys=x2-x1,y2-y1
    --local d
    --历史遗留 太精彩了 跟他妈个弱智似的
    --[[
    if xs==0 then
        d=sign(ys)*180+90
    elseif ys==0 then
        d=sign(xs)*180
    elseif xs*ys>0 then
        d=math.deg(math.asin(math.abs(ys)/math.sqrt(xs^2+ys^2)))
        if xs<0 then d=d+180 end
    else
        d=math.deg(math.asin(math.abs(xs)/math.sqrt(xs^2+ys^2)))+90
        if xs>0 then d=d+180 end
    end
    ]]--

    --[[
    if xs==0 then
        d=sign(ys)*180+90
    else
        d=math.deg(math.atan(ys/xs))
        if xs<0 then d=d+180 end
    end
    ]]--

    return math.deg(math.atan2(y2-y1,x2-x1))
end

local function pointDistance(x1,y1,x2,y2)
    return math.sqrt((x2-x1)^2+(y2-y1)^2)
end

local function tableCopy(t)
    local copy={}
    for key,value in pairs(t) do
        if type(value)=="table" then
            copy[key]=tableCopy(value)
        else
            copy[key]=value
        end
    end
    return copy
end

local function tableFind(t,f)
    for key,value in pairs(t)do if f==value then return true end end
end

local function objCreate(arg)
    ins(objs,arg)
end

local function objChange(arg)
    for index,obj in pairs(objs) do
        if tableFind(obj.tag,arg.tag) then
            obj[arg.key]=arg.value
        end
    end
end

local function objExecute(arg)
    for index,obj in pairs(objs) do
        if tableFind(obj.tag,arg.tag) then
            arg.func(obj)
        end
    end
end

local function objDrawCircle(obj)
    local dx,dy=obj.x,obj.y
    if obj.keep then dx,dy=dx%1280,dy%720 end
    gc.setLineWidth(obj.width)
    gc.setColor(obj.color[1],obj.color[2],obj.color[3],obj.color[4])
    gc.circle("line",dx,dy,obj.scale)
end

local function objDrawRinger(obj)
    local dx,dy=obj.x,obj.y
    if obj.keep then dx,dy=dx%1280,dy%720 end
    gc.setLineWidth(obj.width)
    gc.setColor(obj.color[1],obj.color[2],obj.color[3],obj.color[4])
    gc.circle("fill",dx,dy,obj.scale)
    gc.circle("line",dx,dy,obj.scale+4)
end

local function objFadeout(obj)
    obj.scale=obj.scale+120/obj.life*ts
    obj.color[4]=obj.color[4]-0.4/obj.life*ts
end

local function objCircleSpin(obj)
    obj.direction=200*t%360+obj.tag.offsetAngle
    obj.x,obj.y=640+obj.tag.distance*math.cos(math.rad(obj.direction)),360-obj.tag.distance*math.sin(math.rad(obj.direction))
end

local function objCircleShrink(obj)
    obj.tag.distance=obj.tag.distance-40*ts
end

local function objStar(obj)
    local td=t-obj.tag.starT
    local theta,rho=45*td+obj.tag.starD,1600*obj.tag.starS*math.sin(td/8.8*math.pi)
    obj.x,obj.y=640+rho*math.cos(math.rad(theta)),360+rho*math.sin(math.rad(theta))
end

local function objColorControl(obj)
    local c=math.floor(t/0.279)%8
    obj.color[1],obj.color[2],obj.color[3]=colorRainbow[c][1],colorRainbow[c][2],colorRainbow[c][3]
end

local function objSource1(obj)
    if obj.tag.delay then obj.tag.delay=obj.tag.delay+ts%0.06 else obj.tag.delay=ts%0.06 end
    if obj.tag.delay>0.03 then
        obj.tag.delay=obj.tag.delay-0.03
        local o=tableCopy(obj)
        o.tag={"sub"}
        o.update=objColorControl
        o.direction=pointDirection(o.x,o.y,640,360)
        o.speed=666
        objCreate(o)
    end
end

function init()
    local o=tableCopy(objTemplate)
    o.x,o.y,o.scale=640,360,8
    o.draw=objDrawRinger

    --CenterRed
    o.color=colorRainbow[0]
    o.speed=700
    for itheta=0,359,15 do
        o.direction=itheta
        ins(events,{time=0.279,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=2.511,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=4.744,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=6.418,func=objCreate,arg=tableCopy(o)})
    end

    --CenterOrange
    o.color=colorRainbow[1]
    for irho=500,1000,100 do
        for itheta=45,315,90 do
            o.speed=irho
            o.direction=itheta
            ins(events,{time=0.837,func=objCreate,arg=tableCopy(o)})
            ins(events,{time=3.069,func=objCreate,arg=tableCopy(o)})
        end
    end

    --CenterYellow
    o.color=colorRainbow[2]
    o.speed=700
    for itheta=0,359,18 do
        o.direction=itheta+9
        ins(events,{time=1.395,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=3.627,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=5.302,func=objCreate,arg=tableCopy(o)})
    end
    o.speed=900
    for itheta=0,359,18 do
        o.direction=itheta
        ins(events,{time=1.534,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=3.767,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=5.441,func=objCreate,arg=tableCopy(o)})
    end

    --CenterGreen
    o.color=colorRainbow[3]
    for itheta=0,359,9 do
        o.speed=500+400*rnd()
        o.direction=itheta+9
        ins(events,{time=1.953,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=4.186,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=5.86,func=objCreate,arg=tableCopy(o)})
    end

    --CenterAqua
    o.color=colorRainbow[4]
    o.gravity=400
    for itime=0,8 do
        for itheta=0,359,30 do
            o.speed=600
            o.direction=itheta+itime*3.75
            ins(events,{time=6.976+itime*0.07,func=objCreate,arg=tableCopy(o)})
        end
    end

    --Bubbles
    o.scale=80
    o.width=18
    o.speed=0
    o.gravity=0
    o.update=objFadeout
    o.draw=objDrawCircle
    o.life=0.3
    for itime=0,15 do
        o.x,o.y=rnd()*640+320,rnd()*360+180
        o.color=colorRainbow[itime%8]
        ins(events,{time=8.93+itime*0.279,func=objCreate,arg=tableCopy(o)})
    end
    o.life=0.24
    for itime=0,23 do
        o.x,o.y=rnd()*640+320,rnd()*360+180
        o.color=colorRainbow[itime%8]
        ins(events,{time=13.395+itime*0.1395,func=objCreate,arg=tableCopy(o)})
    end
    o.life=0.18
    for itime=0,15 do
        o.x,o.y=rnd()*640+320,rnd()*360+180
        o.color=colorRainbow[itime%8]
        ins(events,{time=16.744+itime*0.07,func=objCreate,arg=tableCopy(o)})
    end

    --InsideCircle
    o.x,o.y,o.scale=640,360,8
    o.width=2
    o.color=colorRainbow[0]
    o.update,o.draw=nil,objDrawRinger
    o.life=1e99
    o.tag={"insidecircle"}
    for irho=1,3 do
        for itheta=0,359,15 do
            ins(o.tag,"insidecircle"..irho)
            o.speed=94.2*irho
            o.direction=itheta
            ins(events,{time=17.86,func=objCreate,arg=tableCopy(o)})
        end
    end

    --OutsideCircle
    o.speed=0
    for itime=0,59 do
        o.tag={"outsidecircle",offsetAngle=6*itime,distance=300}
        o.direction=o.tag.offsetAngle
        o.x,o.y=640+o.tag.distance*math.cos(math.rad(o.direction)),360-o.tag.distance*math.sin(math.rad(o.direction))
        ins(events,{time=17.86+itime*0.0186,func=objCreate,arg=tableCopy(o)})
    end

    --Animations
    ins(events,{time=18.697,func=objChange,arg={tag="insidecircle",key="speed",value=0}})
    ins(events,{time=18.976,func=objChange,arg={tag="insidecircle3",key="speed",value=1969}})
    ins(events,{time=19.255,func=objChange,arg={tag="insidecircle2",key="speed",value=1969}})
    ins(events,{time=19.534,func=objChange,arg={tag="insidecircle1",key="speed",value=1969}})
    ins(events,{time=19.813,func=objChange,arg={tag="outsidecircle",key="update",value=objCircleSpin}})

    ins(events,{time=20.093,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        if obj.tag.offsetAngle%120==0 then
            obj.update={objCircleSpin,objColorControl,objSource1}
        else
            obj.update={objCircleSpin,objColorControl}
        end
    end}})

    ins(events,{time=27.767,func=objExecute,arg={tag="sub",func=function(obj)obj.direction=pointDirection(640,360,obj.x,obj.y)end}})
    ins(events,{time=27.767,func=objChange,arg={tag="outsidecircle",key="update",value={objCircleSpin,objColorControl}}})

    --对 这里有他妈俩一样的东西 其中一个不可见 我也不知道为什么 但如果没有就不会正常工作 为什么呢 他妈的
    ins(events,{time=28.465,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        local o=tableCopy(obj)
        o.tag={}
        o.update=objColorControl
        o.direction=pointDirection(o.x,o.y,640,360)
        o.speed=1000
        o.color[4]=0
        objCreate(o)
    end}})
    ins(events,{time=28.465,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        local o=tableCopy(obj)
        o.tag={}
        o.update=objColorControl
        o.direction=pointDirection(o.x,o.y,640,360)
        o.speed=1000
        objCreate(o)
    end}})

    ins(events,{time=29.023,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        if obj.tag.offsetAngle%90==0 then
            obj.update={objCircleSpin,objColorControl,objSource1}
        else
            obj.update={objCircleSpin,objColorControl}
        end
    end}})

    ins(events,{time=36.697,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        ins(obj.update,objCircleShrink)
    end}})

    ins(events,{time=42.418,func=objExecute,arg={tag="sub",func=function(obj)
        obj.update=nil
        obj.speed=300
        obj.direction=pointDirection(640,360,obj.x,obj.y)
    end}})
    ins(events,{time=42.418,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        obj.update=nil
        obj.speed=300
        obj.direction=pointDirection(640,360,obj.x,obj.y)
    end}})

    o.tag={"sub"}
    o.speed=900
    for itime=0,31 do
        o.x,o.y=rnd()*640+320,rnd()*360+180
        o.color=colorRainbow[itime%8]
        local r=rnd()
        for itheta=0,359,72 do
            o.direction=itheta+72*r
            ins(events,{time=44.651+0.279*itime,func=objCreate,arg=tableCopy(o)})
        end
    end

    for itime=0,23 do
        o.x,o.y=rnd()*640+320,rnd()*360+180
        o.color=colorRainbow[itime%8]
        local r=rnd()
        for itheta=0,359,48 do
            o.direction=itheta+48*r
            ins(events,{time=53.581+0.279*itime,func=objCreate,arg=tableCopy(o)})
        end
    end

    for itime=0,7 do
        o.x,o.y=rnd()*640+320,rnd()*360+180
        o.color=colorRainbow[itime%8]
        local r=rnd()
        for itheta=0,359,48 do
            o.direction=itheta+48*r
            ins(events,{time=60.279+0.1395*itime,func=objCreate,arg=tableCopy(o)})
        end
    end

    for itime=0,15 do
        o.x,o.y=rnd()*640+320,rnd()*360+180
        o.color=colorRainbow[itime%8]
        local r=rnd()
        for itheta=0,359,48 do
            o.direction=itheta+48*r
            ins(events,{time=61.395+0.07*itime,func=objCreate,arg=tableCopy(o)})
        end
    end

    ins(events,{time=62.511,func=objExecute,arg={tag="sub",func=function(obj)obj.direction,obj.speed=pointDirection(640,360,obj.x,obj.y),150 end}})

    --CornerRed
    o.color=colorRainbow[0]
    o.speed=700
    o.x,o.y=0,0
    for itheta=15,75,30 do
        o.direction=itheta
        ins(events,{time=67.255,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=69.488,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=71.72,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=73.395,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,0
    for itheta=105,165,30 do
        o.direction=itheta
        ins(events,{time=67.255,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=69.488,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=71.72,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=73.395,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,720
    for itheta=195,255,30 do
        o.direction=itheta
        ins(events,{time=67.255,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=69.488,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=71.72,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=73.395,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=0,720
    for itheta=285,345,30 do
        o.direction=itheta
        ins(events,{time=67.255,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=69.488,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=71.72,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=73.395,func=objCreate,arg=tableCopy(o)})
    end

    --CornerOrange
    o.color=colorRainbow[1]
    o.x,o.y=0,0
    o.direction=pointDirection(o.x,o.y,640,360)
    for irho=500,1000,100 do
        o.speed=irho
        ins(events,{time=67.813,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=70.046,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=74.511,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,0
    o.direction=pointDirection(o.x,o.y,640,360)
    for irho=500,1000,100 do
        o.speed=irho
        ins(events,{time=67.813,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=70.046,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=74.511,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,720
    o.direction=pointDirection(o.x,o.y,640,360)
    for irho=500,1000,100 do
        o.speed=irho
        ins(events,{time=67.813,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=70.046,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=74.511,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=0,720
    o.direction=pointDirection(o.x,o.y,640,360)
    for irho=500,1000,100 do
        o.speed=irho
        ins(events,{time=67.813,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=70.046,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=74.511,func=objCreate,arg=tableCopy(o)})
    end

    --CornerYellow
    o.color=colorRainbow[2]
    o.speed=700
    o.x,o.y=0,0
    for itheta=9,81,36 do
        o.direction=itheta
        ins(events,{time=68.372,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=70.604,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=72.279,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=73.953,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,0
    for itheta=99,171,36 do
        o.direction=itheta
        ins(events,{time=68.372,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=70.604,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=72.279,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=73.953,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,720
    for itheta=189,261,36 do
        o.direction=itheta
        ins(events,{time=68.372,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=70.604,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=72.279,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=73.953,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=0,720
    for itheta=279,351,36 do
        o.direction=itheta
        ins(events,{time=68.372,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=70.604,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=72.279,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=73.953,func=objCreate,arg=tableCopy(o)})
    end
    o.speed=900
    o.x,o.y=0,0
    for itheta=27,63,36 do
        o.direction=itheta
        ins(events,{time=68.511,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=70.744,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=72.418,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=74.093,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,0
    for itheta=117,153,36 do
        o.direction=itheta
        ins(events,{time=68.511,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=70.744,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=72.418,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=74.093,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,720
    for itheta=207,243,36 do
        o.direction=itheta
        ins(events,{time=68.511,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=70.744,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=72.418,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=74.093,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=0,720
    for itheta=297,333,36 do
        o.direction=itheta
        ins(events,{time=68.511,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=70.744,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=72.418,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=74.093,func=objCreate,arg=tableCopy(o)})
    end

    --CornerGreen
    o.color=colorRainbow[3]
    o.x,o.y=0,0
    for itheta=0,4 do
        o.direction=itheta*22.5
        o.speed=225*pointDistance(0,0,itheta,4-itheta)
        ins(events,{time=68.93,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=71.162,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=72.837,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,0
    for itheta=0,4 do
        o.direction=itheta*22.5+90
        o.speed=225*pointDistance(0,0,itheta,4-itheta)
        ins(events,{time=68.93,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=71.162,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=72.837,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,720
    for itheta=0,4 do
        o.direction=itheta*22.5+180
        o.speed=225*pointDistance(0,0,itheta,4-itheta)
        ins(events,{time=68.93,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=71.162,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=72.837,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=0,720
    for itheta=0,4 do
        o.direction=itheta*22.5+270
        o.speed=225*pointDistance(0,0,itheta,4-itheta)
        ins(events,{time=68.93,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=71.162,func=objCreate,arg=tableCopy(o)})
        ins(events,{time=72.837,func=objCreate,arg=tableCopy(o)})
    end

    --Bubbles
    o.scale=80
    o.width=18
    o.speed=0
    o.gravity=0
    o.update=objFadeout
    o.draw=objDrawCircle
    o.life=0.3
    for itime=0,15 do
        o.x,o.y=rnd()*640+320,rnd()*360+180
        o.color=colorRainbow[itime%8]
        ins(events,{time=75.906+itime*0.279,func=objCreate,arg=tableCopy(o)})
    end
    o.life=0.18
    for itime=0,63 do
        o.x,o.y=rnd()*640+320,rnd()*360+180
        o.color=colorRainbow[itime%8]
        ins(events,{time=80.372+itime*0.07,func=objCreate,arg=tableCopy(o)})
    end

    --InsideCircle
    o.x,o.y,o.scale=640,360,8
    o.width=2
    o.color=colorRainbow[0]
    o.update,o.draw=nil,objDrawRinger
    o.life=1e99
    o.tag={"insidecircle"}
    for irho=1,3 do
        for itheta=0,359,15 do
            ins(o.tag,"insidecircle"..irho)
            o.speed=94.2*irho
            o.direction=itheta
            ins(events,{time=84.837,func=objCreate,arg=tableCopy(o)})
        end
    end

    --OutsideCircle
    o.speed=0
    for itime=0,59 do
        o.tag={"outsidecircle",offsetAngle=6*itime,distance=300}
        o.direction=o.tag.offsetAngle
        o.x,o.y=640+o.tag.distance*math.cos(math.rad(o.direction)),360-o.tag.distance*math.sin(math.rad(o.direction))
        ins(events,{time=84.837+itime*0.0186,func=objCreate,arg=tableCopy(o)})
    end

    --Animations
    ins(events,{time=85.674,func=objChange,arg={tag="insidecircle",key="speed",value=0}})
    ins(events,{time=85.953,func=objChange,arg={tag="insidecircle3",key="speed",value=1969}})
    ins(events,{time=86.232,func=objChange,arg={tag="insidecircle2",key="speed",value=1969}})
    ins(events,{time=86.511,func=objChange,arg={tag="insidecircle1",key="speed",value=1969}})
    ins(events,{time=86.79,func=objChange,arg={tag="outsidecircle",key="update",value=objCircleSpin}})

    --Star
    o.x,o.y=640,360
    o.update={objColorControl,objStar}
    o.keep=1
    for itheta=0,4 do
        for irho=0,10 do
            local d=pointDirection(o.x,o.y,o.x+math.cos(math.rad(itheta*72))+(math.cos(math.rad((itheta+2)*72))-math.cos(math.rad(itheta*72)))*irho/11,o.y-math.sin(math.rad(itheta*72))-(math.sin(math.rad((itheta+2)*72))-math.sin(math.rad(itheta*72)))*irho/11);
            local s=pointDistance(o.x,o.y,o.x+math.cos(math.rad(itheta*72))+(math.cos(math.rad((itheta+2)*72))-math.cos(math.rad(itheta*72)))*irho/11,o.y-math.sin(math.rad(itheta*72))-(math.sin(math.rad((itheta+2)*72))-math.sin(math.rad(itheta*72)))*irho/11);
            o.tag={"star",starD=d,starS=s,starT=87.069}
            ins(events,{time=87.069,func=objCreate,arg=tableCopy(o)})
        end
    end

    ins(events,{time=87.069,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        obj.update={objCircleSpin,objColorControl}
    end}})

    ins(events,{time=95.72,func=objExecute,arg={tag="star",func=function(obj)
        obj.keep=nil
        obj.update={objColorControl}
        obj.direction=pointDirection(640,360,obj.x,obj.y)
        obj.speed=26*pointDistance(640,360,obj.x,obj.y)
    end}})

    ins(events,{time=95.999,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        if obj.tag.offsetAngle%72==0 then
            obj.update={objCircleSpin,objColorControl,objSource1}
        else
            obj.update={objCircleSpin,objColorControl}
        end
    end}})

    o.keep=nil
    o.tag={"sub"}
    o.speed=900
    o.update=objColorControl
    for itime=0,7 do
        o.x,o.y=rnd()*640+320,rnd()*360+180
        local r=rnd()
        for itheta=0,359,36 do
            o.direction=itheta+36*r
            ins(events,{time=100.465+0.279*itime,func=objCreate,arg=tableCopy(o)})
        end
    end
    for itime=0,7 do
        o.x,o.y=rnd()*640+320,rnd()*360+180
        local r=rnd()
        for itheta=0,359,36 do
            o.direction=itheta+36*r
            ins(events,{time=100.465+0.279*itime,func=objCreate,arg=tableCopy(o)})
        end
    end
    for itime=0,7 do
        o.x,o.y=rnd()*640+320,rnd()*360+180
        local r=rnd()
        for itheta=0,359,36 do
            o.direction=itheta+36*r
            ins(events,{time=102.697+0.1395*itime,func=objCreate,arg=tableCopy(o)})
        end
    end

    ins(events,{time=103.674,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        ins(obj.update,objCircleShrink)
    end}})

    for itime=0,15 do
        o.x,o.y=rnd()*640+320,rnd()*360+180
        local r=rnd()
        for itheta=0,359,36 do
            o.direction=itheta+36*r
            ins(events,{time=103.813+0.07*itime,func=objCreate,arg=tableCopy(o)})
        end
    end
    for itime=0,15 do
        o.x,o.y=rnd()*640+320,rnd()*360+180
        local r=rnd()
        for itheta=0,359,36 do
            o.direction=itheta+36*r
            ins(events,{time=104.93+0.1395*itime,func=objCreate,arg=tableCopy(o)})
        end
    end
    for itime=0,31 do
        o.x,o.y=rnd()*640+320,rnd()*360+180
        local r=rnd()
        for itheta=0,359,36 do
            o.direction=itheta+36*r
            ins(events,{time=107.162+0.07*itime,func=objCreate,arg=tableCopy(o)})
        end
    end

    ins(events,{time=109.395,func=objExecute,arg={tag="sub",func=function(obj)
        obj.update=nil
        obj.speed=300
        obj.direction=pointDirection(640,360,obj.x,obj.y)
        obj.gravity=283
    end}})
    ins(events,{time=109.395,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        obj.update=nil
        obj.speed=300
        obj.direction=pointDirection(640,360,obj.x,obj.y)
        obj.gravity=283
    end}})

    --SORT IT
    table.sort(events,function(a,b)return a.time<b.time end)
end

function update()
    t=game.time
    ts=t-pt

    for index,obj in pairs(objs) do
        if type(obj.update)=="function" then obj.update(obj) elseif type(obj.update)=="table" then for key,value in pairs(obj.update) do value(obj) end end

        local xs=obj.speed*math.cos(math.rad(obj.direction))
        local ys=obj.speed*math.sin(math.rad(obj.direction))
        if obj.gravity~=0 then
            ys=ys+obj.gravity*ts
            obj.direction=pointDirection(0,0,xs,ys)

        end
        --obj.speed=math.sqrt(xs^2+ys^2)
        obj.speed=pointDistance(0,0,xs,ys)

        obj.x=obj.x+xs*ts
        obj.y=obj.y+ys*ts

        obj.life=obj.life-ts
        if (obj.x+obj.scale<0 or obj.x-obj.scale>1280 or obj.y+obj.scale<0 or obj.y-obj.scale>720) and not obj.keep or obj.life<0 then
            rem(objs,index)
        end
    end
    while(#events>0 and events[1].time<t)do
        events[1].func(events[1].arg)
        rem(events,1)
    end
    pt=t
end

function drawBack()
    for _,obj in next,objs do
        if obj.draw then obj.draw(obj) end
    end
end