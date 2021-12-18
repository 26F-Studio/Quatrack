local gc=love.graphics
local gc_push,gc_pop=gc.push,gc.pop
local gc_translate,gc_scale,gc_rotate=gc.translate,gc.scale,gc.rotate
local gc_setColor=gc.setColor
local gc_rectangle=gc.rectangle

local rem=table.remove

local Track={}

function Track.new(id)
    local track={
        id=id,
        pressed=false,
        glowTime=0,
        time=0,
        notes={},
        state={
            x=0,y=0,
            ang=0,
            kx=1,ky=1,
            dropSpeed=1260,
        },
        defaultState=false,
        targetState=false,
        color={r=1,g=1,b=1,a=1},
    }
    track.defaultState=TABLE.copy(track.state)
    track.targetState=TABLE.copy(track.state)
    return setmetatable(track,{__index=Track})
end

function Track:setDefaultPosition(x,y)self.defaultState.x,self.defaultState.y=x,y end
function Track:setDefaultAngle(ang)self.defaultState.ang=ang end
function Track:setDefaultSize(kx,ky)self.defaultState.kx,self.defaultState.ky=kx,ky end
function Track:setDefaultDropSpeed(speed)self.defaultState.dropSpeed=speed end

function Track:movePosition(dx,dy)
    if not dx then dx=0 end if not dy then dy=0 end
    self.targetState.x=self.targetState.x+dx
    self.targetState.y=self.targetState.y+dy
end
function Track:moveAngle(da)
    self.targetState.ang=self.targetState.ang+da/57.29577951308232
end
function Track:moveSize(kx,ky)
    if not kx then kx=1 end if not ky then ky=1 end
    self.targetState.kx=self.targetState.kx*kx
    self.targetState.ky=self.targetState.ky*ky
end
function Track:moveDropSpeed(dds)
    self.targetState.dropSpeed=self.targetState.dropSpeed+dds
end

function Track:setPosition(x,y,force)
    if not x then x=self.defaultState.x end
    if not y then y=self.defaultState.y end
    if force then self.state.x,self.state.y=x,y end
    self.targetState.x,self.targetState.y=x,y
end
function Track:setAngle(ang,force)
    if not ang then ang=self.defaultState.ang end
    if force then self.state.ang=ang/57.29577951308232 end
    self.targetState.ang=ang/57.29577951308232
end
function Track:setSize(kx,ky,force)
    if not kx then kx=self.defaultState.kx end
    if not ky then ky=self.defaultState.ky end
    if force then self.state.kx,self.state.ky=kx,ky end
    self.targetState.kx,self.targetState.ky=kx,ky
end
function Track:setDropSpeed(dropSpeed,force)
    if not dropSpeed then dropSpeed=self.defaultState.dropSpeed end
    if force then self.state.dropSpeed=dropSpeed end
    self.targetState.dropSpeed=dropSpeed
end

function Track:addNote(noteObj)
    table.insert(self.notes,noteObj)
end

function Track:press()
    --Animation
    self.pressed=true
    self.glowTime=.26

    --Check first note
    local note=self.notes[1]
    if note then
        if self.time>note.time-note.badTime then
            rem(self.notes,1)
            return note.time-self.time
        end
    end
end

function Track:release()
    self.pressed=false
end

--For animation
local expAnimations={
    'x','y',
    'ang',
    'kx','ky',
    'dropSpeed',
}
function Track:update(dt)
    if self.glowTime>0 then
        self.glowTime=self.glowTime-dt
    end
    local s=self.state
    for i=1,#expAnimations do
        local k=expAnimations[i]
        s[k]=s[k]+(self.targetState[k]-s[k])*dt^.5
    end
end

--Logics
function Track:updateLogic(time)
    self.time=time
    local bad=0
    for i=#self.notes,1,-1 do
        local note=self.notes[i]
        if self.time>note.time+note.missTime then
            rem(self.notes,i)
            bad=bad+1
        end
    end
    return bad>0 and bad
end

function Track:draw()
    gc_push('transform')

    --Set coordinate for single track
    gc_translate(self.state.x,self.state.y)
    gc_rotate(self.state.ang)
    gc_scale(self.state.kx,self.state.ky)

    --Draw track line
    gc_setColor(1,1,1,1)
    gc_rectangle('fill',-54,0,108,4)
    for i=0,25 do
        gc_setColor(1,1,1,1-i/26)
        gc_rectangle('fill',-50,-i*26,-4,-26)
        gc_rectangle('fill',50,-i*26,4,-26)
        if self.pressed then
            gc_setColor(1,1,1,(1-i/26)/6)
            gc_rectangle('fill',-50,-i*26-26,100,26)
        end
    end

    --Draw press effect
    if self.glowTime>0 then
        gc_setColor(1,1,1,self.glowTime/.26)
        gc_rectangle('fill',-50,10,100,10)
    end

    --Draw notes
    gc_setColor(1,1,1,.8)
    for i=1,#self.notes do
        local note=self.notes[i]
        gc_rectangle('fill',-50,-(note.time-self.time)*self.state.dropSpeed-26,100,26)
    end

    gc_pop()
end

return Track