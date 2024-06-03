--base
local objs={}
local events={}
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
    drawBack=nil,
    drawFront=nil,
    tag={},
}

--function
local math=math
local rnd=math.random
local ins,rem=table.insert,table.remove

--const
local offsetWater={50,0}

local function objCreate(obj)
    obj.timeSpawn=t
    ins(objs,obj)
end

local function objAnimBase(x,y,s)
    gc.line(x-49*s,y-2*s,x-49*s,y-11*s,x-40*s,y-11*s)
    gc.line(x+49*s,y-2*s,x+49*s,y-11*s,x+40*s,y-11*s)
    gc.line(x-49*s,y+2*s,x-49*s,y+11*s,x-40*s,y+11*s)
    gc.line(x+49*s,y+2*s,x+49*s,y+11*s,x+40*s,y+11*s)
end

local function objAnimDefault(obj)
    local x,y,_t=obj.x,obj.y,0.5-obj.life
    local s=1+0.8*_t
    gc.setColor(obj.color[1],obj.color[2],obj.color[3],obj.color[4]*(1-2*_t))
    objAnimBase(x,y,s)
end

local function objAnimWater(obj)
    local x,y,_t=obj.x,obj.y,0.5-obj.life
    local s=1+0.8*_t
    gc.setColor(98/255,130/255,209/255,1-2*_t)
    objAnimBase(x,y,s)
    gc.line(
        x+36*s,y-11*s,
        x-36*s,y-11*s,
        x-36*s,y-7*s,
        x-45*s,y-7*s,
        x-45*s,y+7*s,
        x-36*s,y+7*s,
        x-36*s,y+11*s,
        x+36*s,y+11*s,
        x+36*s,y+7*s,
        x+45*s,y+7*s,
        x+45*s,y-7*s,
        x+36*s,y-7*s
    )
end

local function objPartWater(obj)
    local x,y,l=obj.x,obj.y,obj.life
    gc.setColor(134/255,170/255,210/255)
    gc.circle('line',x,y,15*l)
    obj.xspeed=obj.xspeed-3+6*rnd()
    obj.x,obj.y=obj.x+obj.xspeed*ts,obj.y+obj.yspeed*ts
end

function init()
    for _,note in next,game.map.noteQueue do
        if type(note)=='table' and note.track>=1 and note.track<=4 then
            local oAnim=TABLE.copyAll(objTemplate)
            local oAnimTime=note.time
            oAnim.life=0.5
            oAnim.x=290+140*note.track
            if note.time>75.290 and (note.track==1 or note.track==2) then oAnim.x=oAnim.x-70 end
            if note.time>75.290 and (note.track==3 or note.track==4) then oAnim.x=oAnim.x+70 end
            oAnim.y=668
            oAnim.drawFront=objAnimDefault
            oAnim.color={note.color[1][1],note.color[2][1],note.color[3][1],1}
            ins(events,{time=oAnimTime,func=objCreate,arg=TABLE.copyAll(oAnim)})
        end
        if type(note)=='table' and note.track==5 and note.time>100 then
            local oAnim=TABLE.copyAll(objTemplate)
            local oAnimTime=note.time
            oAnim.life=0.5
            oAnim.x=640
            oAnim.y=668
            oAnim.drawFront=objAnimDefault
            oAnim.color={note.color[1][1],note.color[2][1],note.color[3][1],1}
            ins(events,{time=oAnimTime,func=objCreate,arg=TABLE.copyAll(oAnim)})
        end
        if type(note)=='table' and note.track==5 and note.time<100 then
            note.yOffset=offsetWater
            local oAnim=TABLE.copyAll(objTemplate)
            local oAnimTime=note.time
            oAnim.life=0.5
            oAnim.x=640
            oAnim.y=668
            oAnim.drawFront=objAnimWater
            oAnim.color={note.color[1][1],note.color[2][1],note.color[3][1],1}
            ins(events,{time=oAnimTime,func=objCreate,arg=TABLE.copyAll(oAnim)})
            for _=1,math.floor(6+8*rnd()) do
                oAnim.life=0.1+0.4*rnd()
                oAnim.x=640-55+rnd()*110
                oAnim.y=668-12+rnd()*24
                oAnim.drawFront=objPartWater
                oAnim.xspeed=-8+rnd()*16
                oAnim.yspeed=-36-rnd()*24
                ins(events,{time=oAnimTime,func=objCreate,arg=TABLE.copyAll(oAnim)})
            end
        end
    end

    local oCreator=TABLE.copyAll(objTemplate)
    oCreator.x=640
    oCreator.y=320
    oCreator.life=25.6
    oCreator.t=0
    oCreator.update=function (obj)
        obj.t=obj.t+ts
        if obj.t>0.02 then
            local o=TABLE.copyAll(objTemplate)
            o.x=obj.x
            o.y=obj.y
            o.life=1+0.5*math.random()
            o.speed=942+196*math.random()
            o.direction=2*math.pi*math.random()
            if game.time<62.490 then
                o.update=function (obj)
                    obj.direction=obj.direction+0.012
                end
            else
                o.update=function (obj)
                    obj.direction=obj.direction-0.012
                end
            end
            o.drawBack=function (obj)
                gc.setColor(64/255,255/255,255/255,3.2-3*obj.life)
                gc.circle("line",obj.x,obj.y,15*obj.life)
            end
            objCreate(o)
            obj.t=obj.t-0.02
        end
    end

    ins(events,{time=49.69,func=objCreate,arg=TABLE.copyAll(oCreator)})
    local oCreator=TABLE.copyAll(objTemplate)
    oCreator.x=640
    oCreator.y=320
    oCreator.life=12.8
    oCreator.t=0
    oCreator.update=function (obj)
        obj.t=obj.t+ts
        if obj.t>0.01 then
            local o=TABLE.copyAll(objTemplate)
            o.x=obj.x
            o.y=obj.y
            o.life=1+0.5*math.random()
            o.speed=942+196*math.random()
            o.direction=2*math.pi*math.random()
            if game.time<120.090 then
                o.update=function (obj)
                    obj.direction=obj.direction+0.012
                end
            else
                o.update=function (obj)
                    obj.direction=obj.direction-0.012
                end
            end
            o.drawBack=function (obj)
                gc.setColor(255/255,128/255,64/255,3.2-3*obj.life)
                gc.circle("line",obj.x,obj.y,15*obj.life)
            end
            objCreate(o)
            obj.t=obj.t-0.01
        end
    end
    ins(events,{time=113.69,func=objCreate,arg=TABLE.copyAll(oCreator)})
    --SORT IT
    table.sort(events,function(a,b) return a.time<b.time end)
end

function update()
    t=game.time
    ts=t-pt

    for index,obj in next,objs do
        if type(obj.update)=='function' then
            obj.update(obj)
        elseif type(obj.update)=='table' then
            for _,v in next,obj.update do
                v(obj)
            end
        end

        local xs=obj.speed*math.cos(obj.direction)
        local ys=obj.speed*math.sin(obj.direction)
        if obj.gravity~=0 then
            ys=ys+obj.gravity*ts
            obj.direction=math.atan2(ys,xs)
        end
        obj.speed=math.sqrt(xs^2+ys^2)

        obj.x,obj.y=obj.x+xs*ts,obj.y+ys*ts

        obj.life=obj.life-ts
        if (obj.x+obj.scale<0 or obj.x-obj.scale>1280 or obj.y+obj.scale<0 or obj.y-obj.scale>720) and not obj.keep or obj.life<0 then
            rem(objs,index)
        end
    end
    while (#events>0 and events[1].time<t) do
        events[1].func(events[1].arg)
        rem(events,1)
    end
    pt=t
end

function drawBack()
    for _,obj in next,objs do
        if obj.drawBack then obj.drawBack(obj) end
    end
end

function drawFront()
    for _,obj in next,objs do
        if obj.drawFront then obj.drawFront(obj) end
    end
end