local gc=love.graphics
local gc_push,gc_pop=gc.push,gc.pop
local gc_translate,gc_scale,gc_rotate=gc.translate,gc.scale,gc.rotate
local gc_setColor=gc.setColor
local gc_rectangle=gc.rectangle

local max=math.max
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
            dropSpeed=1000,
            r=1,g=1,b=1,alpha=1,
        },
        defaultState=false,
        targetState=false,
    }
    track.defaultState=TABLE.copy(track.state)
    track.targetState=TABLE.copy(track.state)
    return setmetatable(track,{__index=Track})
end

function Track:setDefaultPosition(x,y)self.defaultState.x,self.defaultState.y=x,y end
function Track:setDefaultAngle(ang)self.defaultState.ang=ang end
function Track:setDefaultSize(kx,ky)self.defaultState.kx,self.defaultState.ky=kx,ky end
function Track:setDefaultDropSpeed(speed)self.defaultState.dropSpeed=speed end
function Track:setDefaultAlpha(alpha)self.defaultState.alpha=alpha end

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
function Track:moveAlpha(da)
    self.targetState.alpha=self.targetState.alpha+da
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
function Track:setAlpha(alpha,force)
    if not alpha then alpha=self.defaultState.alpha end
    if force then self.state.alpha=alpha end
    self.targetState.alpha=alpha
end

function Track:addNote(note)
    table.insert(self.notes,note)
end

function Track:press()
    --Animation
    self.pressed=true
    self.glowTime=.26

    --Check first note
    local note=self.notes[1]
    if note then
        if self.time>note.time-note.trigTime then
            if note.type=='tap'then--Press tap note
                rem(self.notes,1)
            elseif note.type=='hold'then--Press hold note
                note.pressed=true
            end
            return note.time-self.time
        end
    end
end

function Track:release()
    self.pressed=false
    local note=self.notes[1]
    if note and note.type=='hold'and note.pressed then--Release hold note
        rem(self.notes,1)
        return note.etime-self.time,not note.tail
    end
end

--For animation
local expAnimations={
    'x','y',
    'ang',
    'kx','ky',
    'dropSpeed',
    'r','g','b','alpha',
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
    local missCount,marvCount=0,0
    for i=#self.notes,1,-1 do
        local note=self.notes[i]
        if note.type=='tap'then
            if self.time>note.time+note.lostTime then
                rem(self.notes,i)
                missCount=missCount+1
            end
        elseif note.type=='hold'then
            if not note.pressed then--Hold not pressed, miss whole when head missed
                if self.time>note.time+note.lostTime then
                    rem(self.notes,i)
                    missCount=missCount+1
                end
            else--Pressed, miss tail when tail missed
                note.time=max(note.time,self.time)
                if note.tail then
                    if self.time>note.etime+note.lostTime then
                        rem(self.notes,i)
                        missCount=missCount+1
                    end
                else
                    if self.time>note.etime then
                        rem(self.notes,i)
                        marvCount=marvCount+1
                    end
                end
            end
        end
    end
    return missCount,marvCount
end

function Track:draw(map)
    local s=self.state
    gc_push('transform')

    --Set coordinate for single track
    gc_translate(s.x,s.y)
    gc_rotate(s.ang)
    gc_scale(s.kx,s.ky)

    --Draw track line
    gc_setColor(s.r,s.g,s.b,s.alpha)
    gc_rectangle('fill',-54,0,108,4)
    for i=0,25 do
        gc_setColor(s.r,s.g,s.b,s.alpha*(1-i/26))
        gc_rectangle('fill',-50,-i*26,-4,-26)
        gc_rectangle('fill',50,-i*26,4,-26)
        if self.pressed then
            gc_setColor(s.r,s.g,s.b,s.alpha*((1-i/26)/6))
            gc_rectangle('fill',-50,-i*26-26,100,26)
        end
    end

    --Draw press effect
    if self.glowTime>0 then
        gc_setColor(s.r,s.g,s.b,s.alpha*(self.glowTime/.26))
        gc_rectangle('fill',-50,10,100,10)
    end

    --Draw notes
    local dropSpeed=s.dropSpeed*(map.freeSpeed and 1.1^(SETTING.dropSpeed-8 or 1))
    for i=1,#self.notes do
        local note=self.notes[i]
        if note.type=='tap'then
            gc_setColor(note.color)
            gc_rectangle('fill',-50,-(note.time-self.time)*dropSpeed-26,100,26)
        elseif note.type=='hold'then
            --Body
            gc_setColor(note.color[1],note.color[2],note.color[3],note.color[4]*SETTING.holdAlpha)
            gc_rectangle('fill',-50*SETTING.holdWidth,-(note.etime-self.time)*dropSpeed,100*SETTING.holdWidth,(note.etime-note.time)*dropSpeed)

            --Head
            gc_setColor(note.color)
            if not note.pressed then
                gc_rectangle('fill',-50,-(note.time-self.time)*dropSpeed-26,100,26)
            end

            --Tail
            if note.tail then
                gc_rectangle('fill',-50,-(note.etime-self.time)*dropSpeed-10,100,10)
            end
        end
    end

    gc_pop()
end

return Track