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
local function sign(n) if n==0 then return 0 else return math.abs(n)/n end end

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
    table.insert(objs,arg)
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
    if obj.keep then dx,dy=math.mod(dx,1280),math.mod(dy,720) end
    gc.setLineWidth(obj.width)
    gc.setColor(obj.color[1],obj.color[2],obj.color[3],obj.color[4])
    gc.circle("line",dx,dy,obj.scale)
end

local function objDrawRinger(obj)
    local dx,dy=obj.x,obj.y
    if obj.keep then dx,dy=math.mod(dx,1280),math.mod(dy,720) end
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
    obj.direction=math.mod(200*t,360)+obj.tag.offsetAngle
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
    local c=math.mod(math.floor((t+0.02)/0.279)+4,8)
    obj.color[1],obj.color[2],obj.color[3]=colorRainbow[c][1],colorRainbow[c][2],colorRainbow[c][3]
end

local function objSource1(obj)
    if obj.tag.delay then obj.tag.delay=math.mod(obj.tag.delay+ts,0.06) else obj.tag.delay=math.mod(ts,0.06) end
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
    local irho,itheta,itime
    local o=tableCopy(objTemplate)
    o.x,o.y,o.scale=640,360,8
    o.draw=objDrawRinger

    --CenterRed
    o.color=colorRainbow[0]
    o.speed=700
    for itheta=0,359,15 do
        o.direction=itheta
        table.insert(events,{time=1.370,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=3.602,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=5.835,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=7.509,func=objCreate,arg=tableCopy(o)})
    end

    --CenterOrange
    o.color=colorRainbow[1]
    for irho=500,1000,100 do
        for itheta=45,315,90 do
            o.speed=irho
            o.direction=itheta
            table.insert(events,{time=1.928,func=objCreate,arg=tableCopy(o)})
            table.insert(events,{time=4.160,func=objCreate,arg=tableCopy(o)})
        end
    end
    
    --CenterYellow
    o.color=colorRainbow[2]
    o.speed=700
    for itheta=0,359,18 do
        o.direction=itheta+9
        table.insert(events,{time=2.486,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=4.718,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=6.393,func=objCreate,arg=tableCopy(o)})
    end
    o.speed=900
    for itheta=0,359,18 do
        o.direction=itheta
        table.insert(events,{time=2.625,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=4.858,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=6.532,func=objCreate,arg=tableCopy(o)})
    end
    
    --CenterGreen
    o.color=colorRainbow[3]
    for itheta=0,359,9 do
        o.speed=500+400*math.random()
        o.direction=itheta+9
        table.insert(events,{time=3.044,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=5.277,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=6.951,func=objCreate,arg=tableCopy(o)})
    end

    --CenterAqua
    o.color=colorRainbow[4]
    o.gravity=400
    for itime=0,8 do
        for itheta=0,359,30 do
            o.speed=600
            o.direction=itheta+itime*3.75
            table.insert(events,{time=8.067+itime*0.07,func=objCreate,arg=tableCopy(o)})
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
        o.x,o.y=math.random()*640+320,math.random()*360+180
        o.color=colorRainbow[math.mod(itime,8)]
        table.insert(events,{time=10.021+itime*0.279,func=objCreate,arg=tableCopy(o)})
    end
    o.life=0.24
    for itime=0,23 do
        o.x,o.y=math.random()*640+320,math.random()*360+180
        o.color=colorRainbow[math.mod(itime,8)]
        table.insert(events,{time=14.486+itime*0.1395,func=objCreate,arg=tableCopy(o)})
    end
    o.life=0.18
    for itime=0,15 do
        o.x,o.y=math.random()*640+320,math.random()*360+180
        o.color=colorRainbow[math.mod(itime,8)]
        table.insert(events,{time=17.835+itime*0.07,func=objCreate,arg=tableCopy(o)})
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
            table.insert(o.tag,"insidecircle"..irho)
            o.speed=94.2*irho
            o.direction=itheta
            table.insert(events,{time=18.951,func=objCreate,arg=tableCopy(o)})
        end
    end

    --OutsideCircle
    o.speed=0
    for itime=0,59 do
        o.tag={"outsidecircle",offsetAngle=6*itime,distance=300}
        o.direction=o.tag.offsetAngle
        o.x,o.y=640+o.tag.distance*math.cos(math.rad(o.direction)),360-o.tag.distance*math.sin(math.rad(o.direction))
        table.insert(events,{time=18.951+itime*0.0186,func=objCreate,arg=tableCopy(o)})
    end

    --Animations
    table.insert(events,{time=19.788,func=objChange,arg={tag="insidecircle",key="speed",value=0}})
    table.insert(events,{time=20.067,func=objChange,arg={tag="insidecircle3",key="speed",value=1969}})
    table.insert(events,{time=20.346,func=objChange,arg={tag="insidecircle2",key="speed",value=1969}})
    table.insert(events,{time=20.625,func=objChange,arg={tag="insidecircle1",key="speed",value=1969}})
    table.insert(events,{time=20.904,func=objChange,arg={tag="outsidecircle",key="update",value=objCircleSpin}})

    table.insert(events,{time=21.184,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        if math.mod(obj.tag.offsetAngle,120)==0 then
            obj.update={objCircleSpin,objColorControl,objSource1}
        else
            obj.update={objCircleSpin,objColorControl}
        end
    end}})

    table.insert(events,{time=28.858,func=objExecute,arg={tag="sub",func=function(obj)obj.direction=pointDirection(640,360,obj.x,obj.y)end}})
    table.insert(events,{time=28.858,func=objChange,arg={tag="outsidecircle",key="update",value={objCircleSpin,objColorControl}}})

    --对 这里有他妈俩一样的东西 其中一个不可见 我也不知道为什么 但如果没有就不会正常工作 为什么呢 他妈的
    table.insert(events,{time=29.556,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        local o=tableCopy(obj)
        o.tag={}
        o.update=objColorControl
        o.direction=pointDirection(o.x,o.y,640,360)
        o.speed=1000
        o.color[4]=0
        objCreate(o)
    end}})
    table.insert(events,{time=29.556,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        local o=tableCopy(obj)
        o.tag={}
        o.update=objColorControl
        o.direction=pointDirection(o.x,o.y,640,360)
        o.speed=1000
        objCreate(o)
    end}})

    table.insert(events,{time=30.114,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        if math.mod(obj.tag.offsetAngle,90)==0 then
            obj.update={objCircleSpin,objColorControl,objSource1}
        else
            obj.update={objCircleSpin,objColorControl}
        end
    end}})

    table.insert(events,{time=37.788,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        table.insert(obj.update,objCircleShrink)
    end}})

    table.insert(events,{time=43.509,func=objExecute,arg={tag="sub",func=function(obj)
        obj.update=nil
        obj.speed=300
        obj.direction=pointDirection(640,360,obj.x,obj.y)
    end}})
    table.insert(events,{time=43.509,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        obj.update=nil
        obj.speed=300
        obj.direction=pointDirection(640,360,obj.x,obj.y)
    end}})

    o.tag={"sub"}
    o.speed=900
    for itime=0,31 do
        o.x,o.y=math.random()*640+320,math.random()*360+180
        o.color=colorRainbow[math.mod(itime,8)]
        local r=math.random()
        for itheta=0,359,72 do
            o.direction=itheta+72*r
            table.insert(events,{time=45.742+0.279*itime,func=objCreate,arg=tableCopy(o)})
        end
    end

    for itime=0,23 do
        o.x,o.y=math.random()*640+320,math.random()*360+180
        o.color=colorRainbow[math.mod(itime,8)]
        local r=math.random()
        for itheta=0,359,48 do
            o.direction=itheta+48*r
            table.insert(events,{time=54.672+0.279*itime,func=objCreate,arg=tableCopy(o)})
        end
    end

    for itime=0,7 do
        o.x,o.y=math.random()*640+320,math.random()*360+180
        o.color=colorRainbow[math.mod(itime,8)]
        local r=math.random()
        for itheta=0,359,48 do
            o.direction=itheta+48*r
            table.insert(events,{time=61.370+0.1395*itime,func=objCreate,arg=tableCopy(o)})
        end
    end

    for itime=0,15 do
        o.x,o.y=math.random()*640+320,math.random()*360+180
        o.color=colorRainbow[math.mod(itime,8)]
        local r=math.random()
        for itheta=0,359,48 do
            o.direction=itheta+48*r
            table.insert(events,{time=62.486+0.07*itime,func=objCreate,arg=tableCopy(o)})
        end
    end

    table.insert(events,{time=63.602,func=objExecute,arg={tag="sub",func=function(obj)obj.direction,obj.speed=pointDirection(640,360,obj.x,obj.y),150 end}})

    --CornerRed
    o.color=colorRainbow[0]
    o.speed=700
    o.x,o.y=0,0
    for itheta=15,75,30 do
        o.direction=itheta
        table.insert(events,{time=68.346,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=70.579,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=72.811,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=74.486,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,0
    for itheta=105,165,30 do
        o.direction=itheta
        table.insert(events,{time=68.346,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=70.579,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=72.811,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=74.486,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,720
    for itheta=195,255,30 do
        o.direction=itheta
        table.insert(events,{time=68.346,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=70.579,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=72.811,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=74.486,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=0,720
    for itheta=285,345,30 do
        o.direction=itheta
        table.insert(events,{time=68.346,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=70.579,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=72.811,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=74.486,func=objCreate,arg=tableCopy(o)})
    end

    --CornerOrange
    o.color=colorRainbow[1]
    o.x,o.y=0,0
    o.direction=pointDirection(o.x,o.y,640,360)
    for irho=500,1000,100 do
        o.speed=irho
        table.insert(events,{time=68.904,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=71.137,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=75.602,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,0
    o.direction=pointDirection(o.x,o.y,640,360)
    for irho=500,1000,100 do
        o.speed=irho
        table.insert(events,{time=68.904,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=71.137,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=75.602,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,720
    o.direction=pointDirection(o.x,o.y,640,360)
    for irho=500,1000,100 do
        o.speed=irho
        table.insert(events,{time=68.904,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=71.137,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=75.602,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=0,720
    o.direction=pointDirection(o.x,o.y,640,360)
    for irho=500,1000,100 do
        o.speed=irho
        table.insert(events,{time=68.904,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=71.137,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=75.602,func=objCreate,arg=tableCopy(o)})
    end

    --CornerYellow
    o.color=colorRainbow[2]
    o.speed=700
    o.x,o.y=0,0
    for itheta=9,81,36 do
        o.direction=itheta
        table.insert(events,{time=69.463,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=71.695,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=73.370,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=75.044,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,0
    for itheta=99,171,36 do
        o.direction=itheta
        table.insert(events,{time=69.463,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=71.695,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=73.370,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=75.044,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,720
    for itheta=189,261,36 do
        o.direction=itheta
        table.insert(events,{time=69.463,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=71.695,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=73.370,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=75.044,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=0,720
    for itheta=279,351,36 do
        o.direction=itheta
        table.insert(events,{time=69.463,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=71.695,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=73.370,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=75.044,func=objCreate,arg=tableCopy(o)})
    end
    o.speed=900
    o.x,o.y=0,0
    for itheta=27,63,36 do
        o.direction=itheta
        table.insert(events,{time=69.602,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=71.835,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=73.509,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=75.184,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,0
    for itheta=117,153,36 do
        o.direction=itheta
        table.insert(events,{time=69.602,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=71.835,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=73.509,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=75.184,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,720
    for itheta=207,243,36 do
        o.direction=itheta
        table.insert(events,{time=69.602,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=71.835,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=73.509,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=75.184,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=0,720
    for itheta=297,333,36 do
        o.direction=itheta
        table.insert(events,{time=69.602,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=71.835,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=73.509,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=75.184,func=objCreate,arg=tableCopy(o)})
    end

    --CornerGreen
    o.color=colorRainbow[3]
    o.x,o.y=0,0
    for itheta=0,4 do
        o.direction=itheta*22.5
        o.speed=225*pointDistance(0,0,itheta,4-itheta)
        table.insert(events,{time=70.021,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=72.253,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=73.928,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,0
    for itheta=0,4 do
        o.direction=itheta*22.5+90
        o.speed=225*pointDistance(0,0,itheta,4-itheta)
        table.insert(events,{time=70.021,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=72.253,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=73.928,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=1280,720
    for itheta=0,4 do
        o.direction=itheta*22.5+180
        o.speed=225*pointDistance(0,0,itheta,4-itheta)
        table.insert(events,{time=70.021,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=72.253,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=73.928,func=objCreate,arg=tableCopy(o)})
    end
    o.x,o.y=0,720
    for itheta=0,4 do
        o.direction=itheta*22.5+270
        o.speed=225*pointDistance(0,0,itheta,4-itheta)
        table.insert(events,{time=70.021,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=72.253,func=objCreate,arg=tableCopy(o)})
        table.insert(events,{time=73.928,func=objCreate,arg=tableCopy(o)})
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
        o.x,o.y=math.random()*640+320,math.random()*360+180
        o.color=colorRainbow[math.mod(itime,8)]
        table.insert(events,{time=76.997+itime*0.279,func=objCreate,arg=tableCopy(o)})
    end
    o.life=0.18
    for itime=0,63 do
        o.x,o.y=math.random()*640+320,math.random()*360+180
        o.color=colorRainbow[math.mod(itime,8)]
        table.insert(events,{time=81.463+itime*0.07,func=objCreate,arg=tableCopy(o)})
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
            table.insert(o.tag,"insidecircle"..irho)
            o.speed=94.2*irho
            o.direction=itheta
            table.insert(events,{time=85.928,func=objCreate,arg=tableCopy(o)})
        end
    end

    --OutsideCircle
    o.speed=0
    for itime=0,59 do
        o.tag={"outsidecircle",offsetAngle=6*itime,distance=300}
        o.direction=o.tag.offsetAngle
        o.x,o.y=640+o.tag.distance*math.cos(math.rad(o.direction)),360-o.tag.distance*math.sin(math.rad(o.direction))
        table.insert(events,{time=85.928+itime*0.0186,func=objCreate,arg=tableCopy(o)})
    end

    --Animations
    table.insert(events,{time=86.765,func=objChange,arg={tag="insidecircle",key="speed",value=0}})
    table.insert(events,{time=87.044,func=objChange,arg={tag="insidecircle3",key="speed",value=1969}})
    table.insert(events,{time=87.323,func=objChange,arg={tag="insidecircle2",key="speed",value=1969}})
    table.insert(events,{time=87.602,func=objChange,arg={tag="insidecircle1",key="speed",value=1969}})
    table.insert(events,{time=87.881,func=objChange,arg={tag="outsidecircle",key="update",value=objCircleSpin}})

    --Star
    o.x,o.y=640,360
    o.update={objColorControl,objStar}
    o.keep=1
    for itheta=0,4 do
        for irho=0,10 do
            local d=pointDirection(o.x,o.y,o.x+math.cos(math.rad(itheta*72))+(math.cos(math.rad((itheta+2)*72))-math.cos(math.rad(itheta*72)))*irho/11,o.y-math.sin(math.rad(itheta*72))-(math.sin(math.rad((itheta+2)*72))-math.sin(math.rad(itheta*72)))*irho/11);
            local s=pointDistance(o.x,o.y,o.x+math.cos(math.rad(itheta*72))+(math.cos(math.rad((itheta+2)*72))-math.cos(math.rad(itheta*72)))*irho/11,o.y-math.sin(math.rad(itheta*72))-(math.sin(math.rad((itheta+2)*72))-math.sin(math.rad(itheta*72)))*irho/11);
            o.tag={"star",starD=d,starS=s,starT=88.160}
            table.insert(events,{time=88.160,func=objCreate,arg=tableCopy(o)})
        end
    end

    table.insert(events,{time=88.160,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        obj.update={objCircleSpin,objColorControl}
    end}})

    table.insert(events,{time=96.811,func=objExecute,arg={tag="star",func=function(obj)
        obj.keep=nil
        obj.update={objColorControl}
        obj.direction=pointDirection(640,360,obj.x,obj.y)
        obj.speed=26*pointDistance(640,360,obj.x,obj.y)
    end}})

    table.insert(events,{time=97.090,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        if math.mod(obj.tag.offsetAngle,72)==0 then
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
        o.x,o.y=math.random()*640+320,math.random()*360+180
        local r=math.random()
        for itheta=0,359,36 do
            o.direction=itheta+36*r
            table.insert(events,{time=101.556+0.279*itime,func=objCreate,arg=tableCopy(o)})
        end
    end
    for itime=0,7 do
        o.x,o.y=math.random()*640+320,math.random()*360+180
        local r=math.random()
        for itheta=0,359,36 do
            o.direction=itheta+36*r
            table.insert(events,{time=101.556+0.279*itime,func=objCreate,arg=tableCopy(o)})
        end
    end
    for itime=0,7 do
        o.x,o.y=math.random()*640+320,math.random()*360+180
        local r=math.random()
        for itheta=0,359,36 do
            o.direction=itheta+36*r
            table.insert(events,{time=103.788+0.1395*itime,func=objCreate,arg=tableCopy(o)})
        end
    end

    table.insert(events,{time=104.765,func=objExecute,arg={tag="outsidecircle",func=function(obj)
        table.insert(obj.update,objCircleShrink)
    end}})

    for itime=0,15 do
        o.x,o.y=math.random()*640+320,math.random()*360+180
        local r=math.random()
        for itheta=0,359,36 do
            o.direction=itheta+36*r
            table.insert(events,{time=104.904+0.07*itime,func=objCreate,arg=tableCopy(o)})
        end
    end
    for itime=0,15 do
        o.x,o.y=math.random()*640+320,math.random()*360+180
        local r=math.random()
        for itheta=0,359,36 do
            o.direction=itheta+36*r
            table.insert(events,{time=106.021+0.1395*itime,func=objCreate,arg=tableCopy(o)})
        end
    end
    for itime=0,31 do
        o.x,o.y=math.random()*640+320,math.random()*360+180
        local r=math.random()
        for itheta=0,359,36 do
            o.direction=itheta+36*r
            table.insert(events,{time=108.253+0.07*itime,func=objCreate,arg=tableCopy(o)})
        end
    end

    table.insert(events,{time=110.486,func=objExecute,arg={tag="sub",func=function(obj)
        obj.update=nil
        obj.speed=300
        obj.direction=pointDirection(640,360,obj.x,obj.y)
        obj.gravity=283
    end}})
    table.insert(events,{time=110.486,func=objExecute,arg={tag="outsidecircle",func=function(obj)
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
            table.remove(objs,index)
        end
    end
    while(#events>0 and events[1].time<t)do
        events[1].func(events[1].arg)
        table.remove(events,1)
    end
    pt=t
end

function drawBack()
    for index,obj in pairs(objs) do
        if obj.draw then obj.draw(obj) end
    end
end