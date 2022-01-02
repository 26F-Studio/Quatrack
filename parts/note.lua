local hexColor=STRING.hexColor
local Note={}

function Note.new(d)
    d.active=true
    d.lostTime=.16
    d.trigTime=.2
    d.color={{hexColor(d.color[1])},{hexColor(d.color[2])}}
    return setmetatable(d,{__index=Note})
end

return Note