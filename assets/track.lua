local gc_push,gc_pop=GC.push,GC.pop
local gc_translate,gc_rotate,gc_scale=GC.translate,GC.rotate,GC.scale
local gc_setColor=GC.setColor
local gc_rectangle=GC.rectangle

local ins,rem=table.insert,table.remove
local max,min,abs=math.max,math.min,math.abs
local clamp=MATH.clamp

local SET=SETTINGS

local Track={}

local function _insert(t,v)
    for i=#t,1,-1 do
        if t[i].paramSet==v.paramSet then
            rem(t,i)
            break
        end
    end
    ins(t,1,v)
end
function Track.new(id)
    local track={
        id=id,
        _gameData=nil,
        name='',
        showname=false,
        nameList=false,
        chordColor=defaultChordColor,
        pressed=false,
        lastPressTime=-1e99,
        lastReleaseTime=-1e99,
        time=0,
        notes={},
        animQueue={insert=_insert},-- Current animation data
        state={
            x=0,y=0,
            ang=0,
            kx=1,ky=1,
            dropSpeed=1000,
            r=1,g=1,b=1,alpha=100,
            available=true,
            nameAlpha=0,
            drawSideMode='normal',
            drawBaseline=true,
        },
        defaultState=false,
        targetState=false,
    }
    track.defaultState=TABLE.copy(track.state)
    track.startState=TABLE.copy(track.state)
    track.targetState=TABLE.copy(track.state)
    return setmetatable(track,{__index=Track})
end

function Track:_setGameData(t)
    self._gameData=t
end

function Track:rename(name)
    self.name=name
    if name=='x' then name='' end
    self.nameList=name:split(' ')
    self.showName=TABLE.shift(self.nameList)
    for i=1,#self.showName do
        self.showName[i]=(KEY_MAP_inv[self.showName[i]] or '[X]'):upper()
    end
end

function Track:setChordColor(chordColor)
    self.chordColor=chordColor
end

function Track:setDefaultPosition(x,y) self.defaultState.x,self.defaultState.y=x,y end
function Track:setDefaultAngle(ang) self.defaultState.ang=ang end
function Track:setDefaultSize(kx,ky) self.defaultState.kx,self.defaultState.ky=kx,ky end
function Track:setDefaultDropSpeed(speed) self.defaultState.dropSpeed=speed end
function Track:setDefaultAlpha(alpha) self.defaultState.alpha=clamp(alpha,0,100) end
function Track:setDefaultAvailable(bool) self.defaultState.available=bool end
function Track:setDefaultColor(r,g,b) self.defaultState.r,self.defaultState.g,self.defaultState.b=clamp(r,0,1),clamp(g,0,1),clamp(b,0,1) end
function Track:setDefaultDrawSide(mode) self.defaultState.drawSideMode=mode end
function Track:setDefaultDrawBaseline(bool) self.defaultState.drawBaseline=bool end

function Track:movePosition(animData,dx,dy)
    self:setPosition(animData,self.targetState.x+(dx or 0),self.targetState.y+(dy or 0))
end
function Track:moveAngle(animData,da)
    self:setAngle(animData,self.targetState.ang+(da or 0))
end
function Track:moveSize(animData,dkx,dky)
    self:setSize(animData,self.targetState.kx+(dkx or 0),self.targetState.ky+(dky or 0))
end
function Track:moveDropSpeed(animData,dds)
    self:setDropSpeed(animData,self.targetState.dropSpeed+(dds or 0))
end
function Track:moveAlpha(animData,da)
    self:setAlpha(animData,self.targetState.alpha+(da or 0))
end
function Track:moveAvailable()
    self:setAvailable(not self.state.available)
end
function Track:moveColor(animData,dr,dg,db)
    self:setColor(animData,
        clamp(self.targetState.r+(dr or 0),0,1),
        clamp(self.targetState.g+(dg or 0),0,1),
        clamp(self.targetState.b+(db or 0),0,1)
    )
end
function Track:moveNameAlpha(animData,dna)
    self:setNameAlpha(animData,self.targetState.nameAlpha+(dna or 0))
end
function Track:moveDrawBaseline()
    self.state.drawBaseline=not self.defaultState.drawBaseline
end

function Track:setPosition(animData,x,y)
    self.state.x,self.state.y=self.targetState.x,self.targetState.y
    self.startState.x,self.startState.y=self.targetState.x,self.targetState.y
    self.targetState.x,self.targetState.y=x or self.defaultState.x,y or self.defaultState.y
    self.animQueue:insert{paramSet='position',data=animData}
end
function Track:setAngle(animData,ang)
    self.state.ang=self.targetState.ang
    self.startState.ang=self.targetState.ang
    self.targetState.ang=ang or self.defaultState.ang
    self.animQueue:insert{paramSet='angle',data=animData}
end
function Track:setSize(animData,kx,ky)
    self.state.kx,self.state.ky=self.targetState.kx,self.targetState.ky
    self.startState.kx,self.startState.ky=self.targetState.kx,self.targetState.ky
    self.targetState.kx,self.targetState.ky=kx or self.defaultState.kx,ky or self.defaultState.ky
    self.animQueue:insert{paramSet='size',data=animData}
end
function Track:setDropSpeed(animData,dropSpeed)
    self.state.dropSpeed=self.targetState.dropSpeed
    self.startState.dropSpeed=self.targetState.dropSpeed
    self.targetState.dropSpeed=dropSpeed or self.defaultState.dropSpeed
    self.animQueue:insert{paramSet='dropSpeed',data=animData}
end
function Track:setAlpha(animData,alpha)
    self.state.alpha=self.targetState.alpha
    self.startState.alpha=self.targetState.alpha
    self.targetState.alpha=clamp(alpha or self.defaultState.alpha,0,100)
    self.animQueue:insert{paramSet='alpha',data=animData}
end
function Track:setAvailable(bool)
    if bool==nil then bool=self.defaultState.available end
    self.state.available=bool
    if not self.state.available and self.pressed then
        self.pressed=false
        self.lastReleaseTime=self.time
    end
end
function Track:setColor(animData,r,g,b)
    self.state.r,self.state.g,self.state.b=self.targetState.r,self.targetState.g,self.targetState.b
    self.startState.r,self.startState.g,self.startState.b=self.targetState.r,self.targetState.g,self.targetState.b
    self.targetState.r,self.targetState.g,self.targetState.b=r or self.defaultState.r,g or self.defaultState.g,b or self.defaultState.b
    self.animQueue:insert{paramSet='color',data=animData}
end
function Track:setNameAlpha(animData,nameAlpha)
    self.state.nameAlpha=self.targetState.nameAlpha
    self.startState.nameAlpha=self.targetState.nameAlpha
    self.targetState.nameAlpha=clamp(nameAlpha or self.defaultState.nameAlpha,0,100)
    self.animQueue:insert{paramSet='nameAlpha',data=animData}
end
function Track:setDrawSideMode(mode)
    self.state.drawSideMode=mode
end
function Track:setDrawBaseline(bool)
    self.state.drawBaseline=bool
end

function Track:addItem(note)
    table.insert(self.notes,note)
end
function Track:pollNote(noteType)
    local l=self.notes
    if noteType=='note' then
        for i=1,#l do
            if
                l[i].type=='tap' or
                l[i].type=='hold' and l[i].active and l[i].head
            then
                return i,l[i]
            end
        end
    elseif noteType=='hold' then
        for i=1,#l do
            if
                l[i].type=='hold' and l[i].active
            then
                return i,l[i]
            end
        end
    end
end
function Track:pollPressTime()
    local l=self.notes
    for i=1,#l do
        if l[i].available and (l[i].type=='tap' or l[i].type=='hold' and l[i].active and l[i].head) then
            return l[i].time
        end
    end
    return 1e99
end
function Track:pollReleaseTime()
    local l=self.notes
    for i=1,#l do
        local note=l[i]
        if note.type=='hold' and note.available and note.active and note.tail then
            return note.etime
        end
    end
    return 1e99
end

local holdHeadSFX={
    'hold4',
    'hold3',
    'hold2',
    'hold1',
    'hold1',
}
local holdTailSFX={
    'hit8',
    'hit7',
    'hit6',
    'hit5',
    'hit5',
}
function Track:press(weak,auto)
    -- Animation
    self.pressed=true
    self.lastPressTime=self.time
    if weak then return end

    -- Check first note
    local i,note=self:pollNote('note')
    if note and (auto or note.available) and self.time>note.time-note.trigTime then
        local deviateTime=self.time-note.time
        local hitLV=getHitLV(deviateTime,self._gameData.judgeTimes)
        local _a,_p,_d
        if hitLV>0 then
            _a,_p,_d=note:getAlpha(1),self.state.x/420,min(hitLV-SET.showHitLV+1,0)
        end
        if note.type=='tap' then-- Press tap note
            rem(self.notes,i)
            if _a then
                SFX.play('hit_tap',.3+.7*_a,_p,_d)
            end
        elseif note.type=='hold' then-- Press hold note
            if not note.head then return end
            note.head=false
            if _a then
                SFX.play('hit_tap',.3+.7*_a,_p,_d)
                SFX.play(holdHeadSFX[hitLV],.4+.6*_a,_p)
            end
        end
        return deviateTime
    end
end
function Track:release(weak,auto)
    if not weak then self.pressed=false end
    self.lastReleaseTime=self.time
    local i,note=self:pollNote('hold')
    if note and (auto or note.available) and note.type=='hold' and not note.head then-- Release hold note
        local deviateTime=note.etime-self.time
        local hitLV=getHitLV(deviateTime,self._gameData.judgeTimes)
        if self.time>note.etime-note.trigTime then
            if note.tail and hitLV>0 then
                SFX.play(holdTailSFX[hitLV],.4+.6*note:getAlpha(1),self.state.x/420)
            end
            rem(self.notes,i)
            return deviateTime,not note.tail
        elseif not weak then
            note.active=false
            return deviateTime,not note.tail
        end
    end
end

local approach,lerp=MATH.expApproach,MATH.lerp
local animManager={
    position={'x','y'},
    angle={'ang'},
    size={'kx','ky'},
    dropSpeed={'dropSpeed'},
    alpha={'alpha'},
    color={'r','g','b'},
    nameAlpha={'nameAlpha'},
}
function Track:update(dt)
    local C=self.state
    local S=self.startState
    local T=self.targetState

    for i=#self.animQueue,1,-1 do
        local a=self.animQueue[i]
        local animData=a.data
        local animKeys=animManager[a.paramSet]
        if animData.type=='S' then
            for j=1,#animKeys do
                C[animKeys[j]]=T[animKeys[j]]
            end
            rem(self.animQueue,i)
        elseif animData.type=='L' then
            for j=1,#animKeys do
                local k=animKeys[j]
                C[k]=lerp(S[k],T[k],(self.time-animData.start)/animData.duration)
            end
            if self.time>animData.start+animData.duration then
                for j=1,#animKeys do
                    C[animKeys[j]]=T[animKeys[j]]
                end
                rem(self.animQueue,i)
            end
        elseif animData.type=='T' then
            for j=1,#animKeys do
                local k=animKeys[j]
                C[k]=lerp(S[k],T[k],-math.cos((self.time-animData.start)/animData.duration*MATH.pi)*.5+.5)
            end
            if self.time>animData.start+animData.duration then
                for j=1,#animKeys do
                    C[animKeys[j]]=T[animKeys[j]]
                end
                rem(self.animQueue,i)
            end
        elseif animData.type=='E' then
            for j=1,#animKeys do
                local k=animKeys[j]
                C[k]=approach(C[k],T[k],animData.speed*dt)
            end
            if self.time>animData.start+10/animData.speed then
                for j=1,#animKeys do
                    C[animKeys[j]]=T[animKeys[j]]
                end
                rem(self.animQueue,i)
            end
        elseif animData.type=='P' then
            for j=1,#animKeys do
                local k=animKeys[j]
                C[k]=
                    animData.exp>0 and S[k]+(T[k]-S[k])*((self.time-animData.start)/animData.duration)^animData.exp or
                    S[k]+(T[k]-S[k])*(1-(1-(self.time-animData.start)/animData.duration)^-animData.exp)
            end
            if self.time>animData.start+animData.duration then
                for j=1,#animKeys do
                    C[animKeys[j]]=T[animKeys[j]]
                end
                rem(self.animQueue,i)
            end
        else
            rem(self.animQueue,i)
        end
    end
end

-- Logics
function Track:updateLogic(time)
    self.time=time
    local missCount,marvCount=0,0
    for i=#self.notes,1,-1 do
        local note=self.notes[i]
        if note.type=='tap' then
            if self.time>note.time+note.lostTime then
                rem(self.notes,i)
                missCount=missCount+1
            end
        elseif note.type=='hold' then
            if note.head then-- Hold not pressed, miss whole when head missed
                if note.active and self.time>note.time+note.lostTime then
                    note.active=false
                    note.head=false
                    missCount=missCount+2
                end
            else-- Pressed, miss tail when tail missed
                note.time=max(note.time,self.time)
                if note.active then
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
                elseif self.time>note.etime then
                    rem(self.notes,i)
                end
            end
        end
    end
    return missCount,marvCount
end

local function _drawChordBox(c,a,trackW,H,thick)
    c[4]=a
    gc_setColor(c)
    gc_rectangle('fill',-trackW-5,-H-thick-6,2*trackW+10,6)
    gc_rectangle('fill',-trackW-5,-H-thick,5,thick)
    gc_rectangle('fill',trackW,-H-thick,5,thick)
end

-- TODO: implement bar line
function Track:draw(map)
    local s=self.state
    gc_push('transform')

    -- Set coordinate for single track
    gc_translate(s.x*SET.scaleX,s.y)
    gc_rotate(s.ang/57.29577951308232)
    local ky=abs(s.ky)
    local trackW=50*s.kx*SET.trackW

    do-- Draw track frame
        local r,g,b,a=s.r,s.g,s.b,s.alpha/100
        -- Draw track name
        if s.nameAlpha>0 then
            FONT.set(40)
            gc_setColor(r,g,b,s.nameAlpha/100)
            for i=1,#self.showName do
                GC.mStr(self.showName[i],0,MATH.sign(s.ky)*(-20-40*i))
            end
        end

        -- Use ky=abs(s,ky) instead of s.ky, flip all graphics except track name
        if s.ky<0 then gc_scale(1,-1) end

        if a>0 then
            if self.state.drawSideMode~='hide' then
                -- Draw sides
                local unitY=640*ky
                if self.state.drawSideMode=='normal' then
                    for i=0,99 do
                        gc_setColor(r,g,b,a*(1-abs(i)/100))
                        gc_rectangle('fill',-trackW,4-unitY*i/100,-4,-unitY*.01)
                        gc_rectangle('fill',trackW,4-unitY*i/100,4,-unitY*.01)
                    end
                elseif self.state.drawSideMode=='hard' then
                    for i=0,99 do
                        gc_setColor(r,g,b,a)
                        gc_rectangle('fill',-trackW,4-unitY*i/100,-4,-unitY*.01)
                        gc_rectangle('fill',trackW,4-unitY*i/100,4,-unitY*.01)
                    end
                elseif self.state.drawSideMode=='double' then
                    for i=-99,99 do
                        gc_setColor(r,g,b,a*(1-abs(i)/100))
                        gc_rectangle('fill',-trackW,4-unitY*i/100,-4,-unitY*.01)
                        gc_rectangle('fill',trackW,4-unitY*i/100,4,-unitY*.01)
                    end
                elseif self.state.drawSideMode=='harddouble' then
                    for i=-99,99 do
                        gc_setColor(r,g,b,a)
                        gc_rectangle('fill',-trackW,4-unitY*i/100,-4,-unitY*.01)
                        gc_rectangle('fill',trackW,4-unitY*i/100,4,-unitY*.01)
                    end
                end

                -- Draw filling light
                local pressA=
                    self.pressed and 1 or
                    self.time-self.lastReleaseTime<.1 and (.1-(self.time-self.lastReleaseTime))/.1
                if pressA then
                    for i=0,.99,.01 do
                        gc_setColor(r,g,b,a*(1-i)*pressA/6)
                        gc_rectangle('fill',-trackW*pressA,-unitY*i,2*trackW*pressA,-unitY*.01)
                    end
                end
            end

            if self.state.drawBaseline then
                -- Draw baseline
                gc_setColor(r,g,b,a*max(1-(self.pressed and 0 or self.time-self.lastReleaseTime)/.26,.26))
                gc_rectangle('fill',-trackW,0,2*trackW,4)
            end
        end
    end

    -- Prepare to draw notes
    local dropSpeed=s.dropSpeed*ky*(map.freeSpeed and 1.1^SET.dropSpeed or 1)
    local thick=SET.noteThick*ky

    local chordAlpha=SET.chordAlpha
    if chordAlpha==0 then chordAlpha=false end

    -- Draw notes
    for i=1,#self.notes do
        local note=self.notes[i]
        local timeRemain=note.time-self.time
        local headH=timeRemain*dropSpeed

        local r,g,b=note:getColor(1-timeRemain/2.6)
        local a=note:getAlpha(1-timeRemain/2.6)
        if note.type=='tap' and timeRemain<0 then
            a=a*(1+timeRemain/self._gameData.judgeTimes[1])
        end
        if a >0 then
            local dx,dy=note:getOffset(1-timeRemain/2.6)

            gc_translate(dx,dy)
            if note.type=='tap' then
                if chordAlpha and note.chordCount>1 then
                    _drawChordBox(self.chordColor[note.chordCount-1],chordAlpha*a,trackW,headH,thick)
                end
                gc_setColor(r,g,b,a)
                gc_rectangle('fill',-trackW,-headH,2*trackW,-thick)
            elseif note.type=='hold' then
                local tailH=(note.etime-self.time)*dropSpeed
                local a2=note.active and a or a*.5
                -- Body
                gc_setColor(r,g,b,a2*SET.holdAlpha)
                gc_rectangle('fill',-trackW*SET.holdWidth,-tailH,2*trackW*SET.holdWidth,tailH-headH+(note.head and -thick or 0))

                -- Head & Tail
                if note.head then
                    if chordAlpha and note.chordCount_head>1 then
                        _drawChordBox(self.chordColor[note.chordCount_head-1],chordAlpha*a,trackW,headH,thick)
                    end
                    gc_setColor(r,g,b,a)
                    gc_rectangle('fill',-trackW,-headH,2*trackW,-thick)
                end
                if note.tail then
                    if chordAlpha and note.chordCount_tail>1 then
                        _drawChordBox(self.chordColor[note.chordCount_tail-1],chordAlpha*a2,trackW,tailH,thick/2)
                    end
                    gc_setColor(r,g,b,a2)
                    gc_rectangle('fill',-trackW,-tailH,2*trackW,-thick/2)
                end
            end
            gc_translate(-dx,-dy)
        end
    end

    gc_pop()
end

return Track