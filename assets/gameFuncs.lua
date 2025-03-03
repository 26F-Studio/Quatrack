local sin=math.sin
local abs=math.abs

-- System
local lastTime=setmetatable({},{
    __index=function(self,k)
        self[k]=-1e99
        return self[k]
    end,
})
function sureCheck(event)
    if love.timer.getTime()-lastTime[event]<1 then
        return true
    else
        MSG('info',Text.sureText[event])
    end
    lastTime[event]=love.timer.getTime()
end
do-- function loadFile(name,args)
    local t=setmetatable({},{__index=function() return "'$1' loading failed: $2" end})
    function loadFile(name,args)
        local text=Text or t
        if not args then args='' end
        local res,mes=pcall(FILE.load,name,args)
        if res then
            return mes
        else
            if mes:find'open error' then
                MSG('error',text.loadError_open:repD(name,""))
            elseif mes:find'unknown mode' then
                MSG('error',text.loadError_errorMode:repD(name,args))
            elseif mes:find'no file' then
                if not args:sArg'-canSkip' then
                    MSG('error',text.loadError_noFile:repD(name,""))
                end
            elseif mes then
                MSG('error',text.loadError_other:repD(name,mes))
            else
                MSG('error',text.loadError_unknown:repD(name,""))
            end
        end
    end
end
do-- function saveFile(data,name,args)
    local t=setmetatable({},{__index=function() return "'$1' saving failed: $2" end})
    function saveFile(data,name,args)
        local text=Text or t
        local res,mes=pcall(FILE.save,data,name,args)
        if res then
            return mes
        else
            MSG('error',
                mes:find'duplicate' and
                    text.saveError_duplicate:repD(name) or
                mes:find'encode error' and
                    text.saveError_encode:repD(name) or
                mes and
                    text.saveError_other:repD(name,mes) or
                text.saveError_unknown:repD(name)
            )
        end
    end
end
function saveStats()
    return saveFile(STAT,'conf/data')
end
function saveSettings()
    return saveFile(SETTINGS.__data,'conf/settings')
end
function applyFPS(inGame)
    if inGame then
        ZENITHA.setMainLoopSpeed(SETTINGS.maxFPS)
        ZENITHA.setUpdateRate(SETTINGS.updRate)
        ZENITHA.setRenderRate(SETTINGS.drawRate)
    else
        ZENITHA.setMainLoopSpeed(math.min(SETTINGS.maxFPS,90))
        ZENITHA.setUpdateRate(100)
        ZENITHA.setRenderRate(100)
    end
end
function applyClickFX(flag)
    ZENITHA.globalEvent.clickFX=flag and function(x,y) SYSFX.tap(.26,x,y) end or NULL
end



-- Game
function loadBeatmap(path)
    local success,res=pcall(require'assets.map'.new,path)
    if success then
        return res
    else
        return false,res
    end
end
function getHitLV(div,judgeTimes)
    div=abs(div)
    return
    div<=judgeTimes[5] and 5 or
    div<=judgeTimes[4] and 4 or
    div<=judgeTimes[3] and 3 or
    div<=judgeTimes[2] and 2 or
    div<=judgeTimes[1] and 1 or
    0
end
function mergeStat(stat,delta)-- Merge delta stat. to global stat.
    for k,v in next,delta do
        if type(v)=='table' then
            if type(stat[k])=='table' then
                mergeStat(stat[k],v)
            end
        else
            if stat[k] then
                stat[k]=stat[k]+v
            end
        end
    end
end



-- GC
do-- function posterizedText(str,x,y)
    local timer=love.timer.getTime
    local gc_setColorMask=GC.setColorMask
    function posterizedText(str,x,y)
        local t=timer()
        GC.push('transform')
        GC.translate(x+sin(2.6*t),y+sin(3.6*t))
        GC.setColor(1,1,1)
        gc_setColorMask(true,false,false,true)
        GC.mStr(str,sin(6*t),sin(11*t))
        gc_setColorMask(false,true,false,true)
        GC.mStr(str,sin(7*t),sin(10*t))
        gc_setColorMask(false,false,true,true)
        GC.mStr(str,sin(8*t),sin(9*t))
        gc_setColorMask()
        GC.pop()
    end
    function posterizedDraw(obj,x,y)
        local t=timer()
        GC.push('transform')
        GC.translate(x,y)
        gc_setColorMask(true,false,false,true)
        GC.mDraw(obj,sin(6*t),sin(8*t))
        gc_setColorMask(false,true,false,true)
        GC.mDraw(obj,sin(9.5*t),sin(5*t))
        gc_setColorMask(false,false,true,true)
        GC.mDraw(obj,sin(6.5*t),sin(8.5*t))
        gc_setColorMask()
        GC.pop()
    end
end
function drawSafeArea(x,y,time,alpha)
    x,y=x*SCR.k-4,y*SCR.k-4
    GC.setColor(1,.626,.626,(alpha or 1)*math.min(.5,time)/5)
    GC.rectangle('fill',0,0,x,SCR.h)
    GC.rectangle('fill',SCR.w,0,-x,SCR.h)
    GC.rectangle('fill',x,0,SCR.w-2*x,y)
    GC.rectangle('fill',x,SCR.h,SCR.w-2*x,-y)
    GC.setColor(1,.1,.1,(alpha or 1)*math.min(.5,time)/2)
    GC.setLineWidth(4)
    x,y=x+1,y+1
    GC.line(0,0,x,y)
    GC.line(SCR.w,0,SCR.w-x,y)
    GC.line(0,SCR.h,x,SCR.h-y)
    GC.line(SCR.w,SCR.h,SCR.w-x,SCR.h-y)
    x,y=x+1,y+1
    GC.rectangle('line',x,y,SCR.w-2*x,SCR.h-2*y)
end
function drawHits(hits,x,y)
    GC.translate(x,y)
    FONT.set(100)
    GC.setColor(.92,.82,.65)
    GC.printf(hits.perf+hits.prec+hits.marv,-140,0,600,'right')

    FONT.set(80)
    GC.setColor(.58,.65,.96)
    GC.printf(hits.well+hits.good,-140,100,600,'right')

    GC.setColor(.6,.1,.1)
    GC.printf(hits.miss+hits.bad,-140,180,600,'right')

    FONT.set(25)
    GC.setColor(hitColors[5])
    GC.printf(hitTexts[5],-55,27,600,'right')
    GC.print(hits.marv,555,27)
    GC.setColor(hitColors[4])
    GC.printf(hitTexts[4],-55,52,600,'right')
    GC.print(hits.prec,555,52)
    GC.setColor(hitColors[3])
    GC.printf(hitTexts[3],-55,77,600,'right')
    GC.print(hits.perf,555,77)

    GC.setColor(hitColors[2])
    GC.printf(hitTexts[2],-55,123,600,'right')
    GC.print(hits.good,555,123)
    GC.setColor(hitColors[1])
    GC.printf(hitTexts[1],-55,153,600,'right')
    GC.print(hits.well,555,153)

    GC.setColor(hitColors[0])
    GC.printf(hitTexts[0],-55,203,600,'right')
    GC.print(hits.bad,555,203)
    GC.setColor(hitColors[-1])
    GC.printf(hitTexts[-1],-55,233,600,'right')
    GC.print(hits.miss,555,233)
    GC.translate(-x,-y)
end
