---@type Zenitha.Scene
local scene={}

function scene.load()
    if SYSTEM~="iOS" then
        if math.random()>.0000626 then
            love.timer.sleep(.26)
            love.event.quit()
        else
            error("So lucky! 0.00626% to get this!!   You can quit the game now.")
        end
    else
        MSG.update(1e99)
        ZENITHA.globalEvent.setPowerInfo=NULL
        ZENITHA.globalEvent.clickFX=NULL
        VERSION.string=""
        MSG('error',"Please quit with HOME button on iOS",1e99)
    end
end

function scene.draw()
    love.graphics.clear()
end

return scene
