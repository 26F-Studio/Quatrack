local listMix=MATH.listMix

local Note={}

function Note.new(d)
    d.active=true
    d.lostTime=.16
    d.trigTime=.2
    return setmetatable(d,{__index=Note})
end

function Note:getColor(t)
    return
    listMix(self.color[1],t),
    listMix(self.color[2],t),
    listMix(self.color[3],t)
end

function Note:getAlpha(t)
    return listMix(self.alpha,t)*.01
end

function Note:getOffset(t)
    return
    listMix(self.xOffset,t),
    listMix(self.yOffset,t)
end

return Note