local waveHeight,waveAngle={},{}

local function drawRectWave(t,n,sp)
    if not waveHeight[n]then
        for i=-n,n do
            waveHeight[i]=0.4+0.9*math.random()
            waveAngle[i]=90*math.random()
        end
    end
    for i=-n,n do
        local tr=t-math.abs(i)*sp/n
        if tr>0 and tr<1 then
            gc.setColor(1,1,1,1-tr)
            gc.polygon('line',640+i*640/n,360+tr*500*waveHeight[i],12,4,waveAngle[i])
            gc.polygon('line',640+i*640/n,360-tr*500*waveHeight[i],12,4,waveAngle[i])
        end
    end
end

function drawBack()
    local t=game.time
    if t>71.412 and t<76.412 then drawRectWave(t-71.412,32,0.3) end
    if t>115.297 and t<120.297 then drawRectWave(t-115.297,32,0.3) end
end