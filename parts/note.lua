local Note={}

function Note.new(d)
    local o={
        time=d.time,
        missTime=.26,
        badTime=.26,
    }
    return setmetatable(o,{__index=Note})
end

return Note