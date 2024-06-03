local lLerp=MATH.lLerp

local Note={}

function Note.new(d)
    d.active=true
    d.lostTime=.16
    d.trigTime=.2
    return setmetatable(d,{__index=Note})
end

function Note:getColor(t)
    return
    lLerp(self.color[1],t),
    lLerp(self.color[2],t),
    lLerp(self.color[3],t)
end

function Note:getAlpha(t)
    return lLerp(self.alpha,t)*.01
end

function Note:getOffset(t)
    return
    lLerp(self.xOffset,t),
    lLerp(self.yOffset,t)
end

return Note