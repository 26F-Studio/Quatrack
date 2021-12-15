local gc=love.graphics
local gc_push,gc_pop=gc.push,gc.pop
local gc_translate,gc_scale,gc_rotate=gc.translate,gc.scale,gc.rotate
local gc_setColor,gc_setLineWidth=gc.setColor,gc.setLineWidth
local gc_rectangle,gc_line=gc.rectangle,gc.line

local ins,rem=table.insert,table.remove

local Track={}

function Track.new()
    local track={
        pressed=false,
        glowTime=0,
        dropSpeed=1260,
        time=0,
        notes={},
        pos={x=0,y=0,ang=0,kx=1,ky=1},
        color={r=1,g=1,b=1,a=1},
    }
    return setmetatable(track,{__index=Track})
end

function Track:setPosition(d)
    if d.x then   self.pos.x=d.x end
    if d.y then   self.pos.y=d.y end
    if d.ang then self.pos.ang=d.ang end
    if d.kx then  self.pos.kx=d.kx end
    if d.ky then  self.pos.ky=d.ky end
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
function Track:update(dt)
    if self.glowTime>0 then
        self.glowTime=self.glowTime-dt
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
    gc_translate(self.pos.x,self.pos.y)
    gc_rotate(self.pos.ang)
    gc_scale(self.pos.kx,self.pos.ky)

    --Draw track line
    gc_setColor(1,1,1,1)
    gc_setLineWidth(4)
    gc_line(-50,0,50,0)
    for i=0,25 do
        gc_setColor(1,1,1,1-i/26)
        gc_line(-50,-i*26,-50,-i*26-26)
        gc_line(50,-i*26,50,-i*26-26)
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
        gc_rectangle('fill',-50,-(note.time-self.time)*self.dropSpeed-26,100,26)
    end

    gc_pop()
end

return Track