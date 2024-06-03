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
local elementA=MATH.roll()
local elementB=MATH.roll()
local colorFire={{1},{0.2},{0.2}}
local colorWater={{0.2},{0.2},{1}}
local colorThunder={{0.5},{0},{1}}
local colorIce={{0.75},{1},{1}}
local offsetFire={-50,0}
local offsetWater={50,0}
local offsetThunder={1.96e42}
local offsetIce={{140,140,140,140,140,140,140,140,140,140,140,140,140,140,140,140,140,140,140,140,140,140,140,140,0,0,0},{-140,-140,-140,-140,-140,-140,-140,-140,-140,-140,-140,-140,-140,-140,-140,-140,-140,-140,-140,-140,-140,-140,-140,-140,0,0,0}}

local function objCreate(arg)
    arg.timeSpawn=t
    ins(objs,arg)
end

local function objDrawText(obj)
    local alpha=math.min(t-obj.timeSpawn,obj.life,0.5)*2
    gc.setColor(0,0,0,alpha*0.4)
    gc.rectangle('fill',obj.x,obj.y,1280,36*#obj.text)
    for i,str in next,obj.text do
        gc.setColor(1,1,1,alpha)
        gc.print(str,640,obj.y+36*(i-1))
    end
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
    gc.setColor(255/255,255/255,128/255,1-2*_t)
    objAnimBase(x,y,s)
end

local function objAnimFire(obj)
    local x,y,_t=obj.x,obj.y,0.5-obj.life
    local s=1+0.8*_t
    gc.setColor(243/255,225/255,168/255,1-2*_t)
    objAnimBase(x,y,s)

    gc.setColor(243/255,180/255,142/255,1-2*_t)
    gc.line(x-49*s,y,x+49*s,y)
    gc.circle('fill',x,y,6*(1-2*_t))
end

local function objPartFire(obj)
    local x,y,l=obj.x,obj.y,obj.life
    gc.setColor(243/255,225/255,214/255)
    gc.circle('fill',x,y,15*l)
    obj.speed=obj.speed-360*ts
    if obj.speed<0 then obj.speed=0 end
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

local function objAnimThunderA(obj)
    local x,y=obj.x,obj.y
    gc.setColor(163/255,70/255,255/255)
    gc.line(x-49,y-2,x-49,y-11,x-40,y-11)
    gc.line(x+40,y-11,x+49,y-11,x+49,y-2)
    gc.line(x-49,y+2,x-49,y+11,x-40,y+11)
    gc.line(x+40,y+11,x+49,y+11,x+49,y+2)

    local t1=obj.life/0.441
    local t2=1-(1-t1)^2.5
    gc.circle('fill',x,y,t1*6)
    gc.setColor(163/255,70/255,255/255,t2)
    gc.circle('line',x,y,t2*80)
end

local function objAnimThunderB(obj)
    local x,y,_t=obj.x,obj.y,0.5-obj.life
    local s=1+0.8*_t
    gc.setColor(163/255,70/255,255/255,1-2*_t)
    objAnimBase(x,y,s)

    gc.setColor(163/255,70/255,255/255,1-2*_t)
    gc.circle('line',x,y,_t*200)
end

local function objPartThunder(obj)
    local x,y,xo,yo,l=obj.x,obj.y,obj.xOffset,obj.yOffset,obj.life
    gc.setColor(215/255,174/255,255/255,l*2)
    gc.line(x,y,x+xo,y+yo)
end

local function objAnimIce(obj)
    local x,y,_t=obj.x,obj.y,0.5-obj.life
    local s=1+0.8*_t
    gc.setColor(192/255,255/255,255/255,1-2*_t)
    objAnimBase(x,y,s)

    gc.line(x-49*s,y,x-20*s,y)
    gc.line(x+20*s,y,x+49*s,y)
    gc.line(x,y+11*s,x-20*s,y,x,y-11*s)
    gc.line(x,y-11*s,x+20*s,y,x,y+11*s)
end

local function objPartIce(obj)
    local x,y,l,s=obj.x,obj.y,obj.life,obj.scale
    gc.setColor(216/255,255/255,255/255,l*2)
    gc.circle('fill',x,y,s)
end

function init()
    for _,note in next,game.map.noteQueue do
        if type(note)=='table' and note.track>=1 and note.track<=4 then
            local oAnim=TABLE.copyAll(objTemplate)
            local oAnimTime=note.time
            oAnim.life=0.5
            oAnim.x=290+140*note.track
            oAnim.y=668
            oAnim.drawFront=objAnimDefault
            ins(events,{time=oAnimTime,func=objCreate,arg=TABLE.copyAll(oAnim)})
        end
        if elementB==true and type(note)=='table' and note.track>=17 and note.track<=20 then
            local oAnim=TABLE.copyAll(objTemplate)
            local oAnimTime=note.time
            oAnim.life=0.5
            oAnim.x=-1950+140*note.track
            oAnim.y=668
            oAnim.drawFront=objAnimDefault
            ins(events,{time=oAnimTime,func=objCreate,arg=TABLE.copyAll(oAnim)})
        end
        if elementB==false and type(note)=='table' and note.track>=9 and note.track<=12 then
            local oAnim=TABLE.copyAll(objTemplate)
            local oAnimTime=note.time
            oAnim.life=0.5
            oAnim.x=-830+140*note.track
            oAnim.y=668
            oAnim.drawFront=objAnimDefault
            ins(events,{time=oAnimTime,func=objCreate,arg=TABLE.copyAll(oAnim)})
        end
        if elementB==false and type(note)=='table' and note.track>=13 and note.track<=16 then
            local oAnim=TABLE.copyAll(objTemplate)
            local oAnimTime=note.time
            oAnim.life=0.5
            oAnim.x=-1390+140*note.track
            oAnim.y=668
            oAnim.drawFront=objAnimDefault
            ins(events,{time=oAnimTime,func=objCreate,arg=TABLE.copyAll(oAnim)})
        end
    end

    local o=TABLE.copyAll(objTemplate)
    o.drawFront=objDrawText
    o.x,o.y=0,150
    o.life=5.294
    if elementA then
        o.text={"若陀龙王即将汲取火元素的力量…","附着火元素的音符下落速度将会加快！"}
        for _,note in next,game.map.noteQueue do
            if type(note)=='table' and note.track>=5 and note.track<=8 then
                note.color=colorFire
                note.yOffset=offsetFire
                local oAnim=TABLE.copyAll(objTemplate)
                local oAnimTime=note.time
                oAnim.life=0.5
                oAnim.x=-270+140*note.track
                oAnim.y=668
                oAnim.drawFront=objAnimFire
                ins(events,{time=oAnimTime,func=objCreate,arg=TABLE.copyAll(oAnim)})
                for _=1,math.floor(6+8*rnd()) do
                    oAnim.life=0.1+0.4*rnd()
                    oAnim.x=-270+140*note.track-55+rnd()*110
                    oAnim.y=668-12+rnd()*24
                    oAnim.drawFront=objPartFire
                    oAnim.direction=math.atan2(oAnim.y-668,oAnim.x-(140*note.track-270))-30+60*rnd()
                    oAnim.speed=72+rnd()*48
                    ins(events,{time=oAnimTime,func=objCreate,arg=TABLE.copyAll(oAnim)})
                end
            end
        end
        for i=1,4 do
            game.map.eventQueue:insert{
                type='setTrack',
                time=79.760,
                track=i,
                operation='setColor',
                args={{type='E',start=79.760,speed=4},1,0.25,0.25},
            }
        end
    else
        o.text={"若陀龙王即将汲取水元素的力量…","附着水元素的音符下落速度将会减慢！"}
        for _,note in next,game.map.noteQueue do
            if type(note)=='table' and note.track>=5 and note.track<=8 then
                note.color=colorWater
                note.yOffset=offsetWater
                local oAnim=TABLE.copyAll(objTemplate)
                local oAnimTime=note.time
                oAnim.life=0.5
                oAnim.x=-270+140*note.track
                oAnim.y=668
                oAnim.drawFront=objAnimWater
                ins(events,{time=oAnimTime,func=objCreate,arg=TABLE.copyAll(oAnim)})
                for _=1,math.floor(6+8*rnd()) do
                    oAnim.life=0.1+0.4*rnd()
                    oAnim.x=-270+140*note.track-55+rnd()*110
                    oAnim.y=668-12+rnd()*24
                    oAnim.drawFront=objPartWater
                    oAnim.xspeed=-8+rnd()*16
                    oAnim.yspeed=-36-rnd()*24
                    ins(events,{time=oAnimTime,func=objCreate,arg=TABLE.copyAll(oAnim)})
                end
            end
        end
        for i=1,4 do
            game.map.eventQueue:insert{
                type='setTrack',
                time=79.760,
                track=i,
                operation='setColor',
                args={{type='E',start=79.760,speed=4},0.25,0.25,1},
            }
        end
    end
    ins(events,{time=72.701,func=objCreate,arg=TABLE.copyAll(o)})
    if elementB then
        o.text={"若陀龙王即将汲取雷元素的力量…","附着雷元素的音符需要在一拍后重复击打！"}
        for _,note in next,game.map.noteQueue do
            if type(note)=='table' and note.track>=9 and note.track<=12 then
                note.color=colorThunder
                local oAnim=TABLE.copyAll(objTemplate)
                local oAnimTime=note.time
                oAnim.life=0.441
                oAnim.x=-830+140*note.track
                oAnim.y=668
                oAnim.drawFront=objAnimThunderA
                ins(events,{time=oAnimTime,func=objCreate,arg=TABLE.copyAll(oAnim)})
                oAnim.drawFront=objAnimThunderB
                ins(events,{time=oAnimTime+0.441,func=objCreate,arg=TABLE.copyAll(oAnim)})
                for _=1,math.floor(6+8*rnd()) do
                    oAnim.life=0.1+0.4*rnd()
                    oAnim.x=-830+140*note.track-55+rnd()*110
                    oAnim.y=668-12+rnd()*24
                    oAnim.xOffset=-12+rnd()*24
                    oAnim.yOffset=-12+rnd()*24
                    oAnim.drawFront=objPartThunder
                    ins(events,{time=oAnimTime+0.441,func=objCreate,arg=TABLE.copyAll(oAnim)})
                end
            elseif type(note)=='table' and note.track>=13 and note.track<=16 then
                note.xOffset=offsetThunder
            end
        end
        for i=1,4 do
            game.map.eventQueue:insert{
                type='setTrack',
                time=122.113,
                track=i,
                operation='setColor',
                args={{type='E',start=122.113,speed=4},0.5,0,1},
            }
        end
    else
        o.text={"若陀龙王即将汲取冰元素的力量…","附着冰元素的音符将会移动到相邻的轨道！"}
        for _,note in next,game.map.noteQueue do
            if type(note)=='table' and note.track>=17 and note.track<=20 then
                note.color=colorIce
                note.xOffset=offsetIce[2-note.track%2]
                local oAnim=TABLE.copyAll(objTemplate)
                local oAnimTime=note.time
                oAnim.life=0.5
                oAnim.x=-1950+140*note.track
                oAnim.y=668
                oAnim.drawFront=objAnimIce
                ins(events,{time=oAnimTime,func=objCreate,arg=TABLE.copyAll(oAnim)})
                for _=1,math.floor(6+8*rnd()) do
                    oAnim.life=0.1+0.4*rnd()
                    oAnim.x=-1950+140*note.track-55+rnd()*110
                    oAnim.y=668-12+rnd()*24
                    oAnim.direction=math.pi/2
                    oAnim.speed=6+rnd()*15
                    oAnim.scale=1+rnd()*4
                    oAnim.drawFront=objPartIce
                    ins(events,{time=oAnimTime,func=objCreate,arg=TABLE.copyAll(oAnim)})
                end
            end
        end
        for i=1,4 do
            game.map.eventQueue:insert{
                type='setTrack',
                time=122.113,
                track=i,
                operation='setColor',
                args={{type='E',start=122.113,speed=4},0.75,1,1},
            }
        end
    end
    ins(events,{time=115.054,func=objCreate,arg=TABLE.copyAll(o)})
    for _,note in next,game.map.noteQueue do
        if type(note)=='table' then
            note.track=(note.track-1)%4+1
            note.available=true
        end
    end
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
