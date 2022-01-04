local listLerp=MATH.listLerp

local Note={}

function Note.new(d)
    d.active=true
    d.lostTime=.16
    d.trigTime=.2
    return setmetatable(d,{__index=Note})
end

function Note:getColor(t)
    return
    listLerp(self.color[1],t),
    listLerp(self.color[2],t),
    listLerp(self.color[3],t)
end

function Note:getAlpha(t)
    return listLerp(self.alpha,t)*.01
end

return Note