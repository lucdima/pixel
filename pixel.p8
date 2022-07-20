pico-8 cartridge // http://www.pico-8.com
version 32
__lua__


function _init()
    config = makeConfig()

    game = makeGame()
    sounds = makeSounds()
    enemyGenerator = makeEnemyGenerator()
    showDeadCount = makeShowDeadCount()
    cls(config.backgroundColor)
end

function _update()
    if game.state==0 then
        if btn(0) or btn(1) or btn(2) or btn(3) or btn(4) then
            game.state=1
        end
        if  btn(5) then
            game.state=1
            game.time=600
        end
    elseif game.state==1 then
        enemyGenerator:generate()
        if (btn(0)) then game.player:moveLeft() end
        if (btn(1)) then game.player:moveRight() end
        if (btn(2)) then game.player:moveTop() end
        if (btn(3)) then game.player:moveDown() end

        if(btnp(4)) then
            sounds:playLaser()
            add(game.bullets, bulletFactory(game.player.x,game.player.y,game.player.direction))
        end
    elseif game.state==2 then
         endGame = makeEndgameTimeCounter(game.totalKills)
        -- if(btnp(4) or btnp(5)) and game.endtime+60 < game.time then
            if game.endtime+60 < game.time then
            cls(config.backgroundColor)
            game.state=3
        end
    elseif game.state==3 and endGame.playend == 1 then
        if(btnp(4) or btnp(5)) then
            _init()
        end
    end
end

function _draw()
    -- wating to begin
    if game.state==0 then
        cls(config.backgroundColor)
        game:drawPlayer()
    -- play
    elseif game.state==1 then
        cls(config.backgroundColor)
         game:drawPlayer()
         game:bulletCollitionCheck()
         game:bulletCleanUp()
         game:enemyCleanUp()
         game:moveBullets()
         game:moveEnemies()
         game:checkEnemyPlayerCollision()
         game:drawBullets()
         game:drawEnemies()
         showDeadCount:draw()
         game.time+=1
     -- endgame with enemies still heading for dead player
     elseif game.state==2 then
         cls(config.backgroundColor)
         game:bulletCollitionCheck()
         game:bulletCleanUp()
         game:enemyCleanUp()
         game:moveBullets()
         game:moveEnemies()
         game:drawBullets()
         game:drawEnemies()

         showDeadCount:draw()

         game.time+=1
     elseif game.state==3 then
         -- count enemimes
         endGame:draw()
     end
end

function makeConfig()
    local config = {
        backgroundColor = 0,
        playerColor = 7,
        playerStartingPositionX = 64,
        playerStartingPositionY = 64,
        playerSpeed = 2,

        bulletColor = 12,
        bulletSpeed = 5,
        bulletDuration  = 60, -- in frames (this is 2 seconds)

        enemyColor = 10,
        enemySpeed = 1,

        level0Frames = 300,
        level1Frames = 600, -- ten seconds
        level2Frames = 900,
        level3Frames = 1200,
    }

    return config
end

function makeSounds()
    local s = {
        playLaser=function()
            sfx(flr(rnd(3)))
        end,
        playEnemyDead=function()
            sfx(3)
        end,
        playPlayerDead=function()
            sfx(4)
        end,
        playCountEnemies=function()
            sfx(5)
        end,
        playEndChord=function()
            sfx(6)
        end,
    }

    return s
end

function makeShowDeadCount()
    local m = {
        draw=function(self)
            local x = 0
            local y = 0
            for i=1,game.totalKills do
                pset(x,y,config.enemyColor)
                x+=2
                if x>127 then
                    x=0
                    y+=2
                end
            end
        end,
    }

    return m
end

function makeEndgameTimeCounter(killCount)
    local m = {
        killCount=killCount,
        x=0,
        y=0,
        current=0,
        playend=0,
        draw=function(self)
            if self.current<self.killCount then
                pset(self.x,self.y,config.enemyColor)
                sounds:playCountEnemies()
                self.x+=2
                if self.x>127 then
                    self.x=0
                    self.y+=2
                end
                self.current+=1
            elseif self.playend==0 then
                sounds:playEndChord()
                self.playend=1
            end
        end,
    }

    return m
end

function makeEnemyGenerator()
    local eg = {
    level=0,
    generate=function(self)
        if game.time<config.level0Frames then self.level = 0
        elseif game.time<config.level1Frames then self.level = 1
        elseif game.time<config.level2Frames then self.level = 2
        elseif game.time<config.level3Frames then self.level = 3
        else self.level = 4
        end

        if self.level==0 then self:level0(self)
        elseif self.level==1 then self:level1(self)
        elseif self.level==2 then self:level2(self)
        elseif self.level==3 then self:level3(self)
        else self:level4(self)
        end
    end,
    level0=function(self)
        if (game.time - 60) % 360 == 0 then
            add(game.enemies, enemyFactory(127,64,config.enemyColor,game.player.x,game.player.y,config.enemySpeed))
        elseif (game.time - 150) % 360 == 0 then
            add(game.enemies, enemyFactory(64,127,config.enemyColor,game.player.x,game.player.y,config.enemySpeed))
        elseif (game.time - 240) % 360 == 0 then
            add(game.enemies, enemyFactory(0,64,config.enemyColor,game.player.x,game.player.y,config.enemySpeed))
        elseif (game.time - 330) % 360 == 0 then
            add(game.enemies, enemyFactory(64,0,config.enemyColor,game.player.x,game.player.y,config.enemySpeed))
        end
    end,

    level1=function(self)
        if ((game.time - 60) % 360 == 0) or ((game.time - 240) % 360 == 0) then
            add(game.enemies, enemyFactory(127,64,config.enemyColor,game.player.x,game.player.y,config.enemySpeed)) -- right
            add(game.enemies, enemyFactory(0,64,config.enemyColor,game.player.x,game.player.y,config.enemySpeed)) -- left
        elseif ((game.time - 150) % 360 == 0) or ((game.time - 330) % 360 == 0) then
            add(game.enemies, enemyFactory(64,127,config.enemyColor,game.player.x,game.player.y,config.enemySpeed)) -- bottom
            add(game.enemies, enemyFactory(64,0,config.enemyColor,game.player.x,game.player.y,config.enemySpeed)) -- top
        end
    end,
    level2=function(self)
        if ((game.time) % 30 == 0) then
            add(game.enemies, enemyFactory(flr(rnd(128)),flr(rnd(128)),config.enemyColor,game.player.x,game.player.y,config.enemySpeed))
        end
    end,
    level3=function(self)
        if ((game.time) % 20 == 0) then
            add(game.enemies, enemyFactory(flr(rnd(128)),flr(rnd(128)),config.enemyColor,game.player.x,game.player.y,config.enemySpeed))
        end
    end,
    level4=function(self)
        if ((game.time) % 10 == 0) then
            add(game.enemies, enemyFactory(flr(rnd(128)),flr(rnd(128)),config.enemyColor,game.player.x,game.player.y,config.enemySpeed))
        end
    end,


    }

    return eg
end

function makeGame()
    local game = {
        time=0,
        endtime=0,
        totalKills=0,
        state=0,
        bullets = {},
        enemies = {},
        player = playerFactory(64, 64, config.playerColor),
        drawPlayer=function(self)
            pset(self.player.x,self.player.y,self.player.color)
        end,
        bulletCollitionCheck=function(self)
            for b in all(self.bullets) do
                -- left
                if b.direction==0 then
                    for i=b.x,b.x-b.speed,-1 do
                        e=self:findEnemyByPosition(i,b.y)
                        if e!=nil then
                            b.hit=1
                            e.hit=1
                            self.totalKills+=1
                            sounds:playEnemyDead()
                            break
                        end
                    end
                -- right
                elseif b.direction==1 then
                    for i=b.x,b.x+b.speed,1 do
                        e=self:findEnemyByPosition(i,b.y)
                        if e!=nil then
                            b.hit=1
                            e.hit=1
                            self.totalKills+=1
                            sounds:playEnemyDead()
                            break
                        end
                    end
                -- up
                elseif b.direction==2 then
                    for i=b.y,b.y-b.speed,-1 do
                        e=self:findEnemyByPosition(b.x,i)
                        if e!=nil then
                            b.hit=1
                            e.hit=1
                            self.totalKills+=1
                            sounds:playEnemyDead()
                            break
                        end
                    end
                -- down
                elseif b.direction==3 then
                    for i=b.y,b.y+b.speed,1 do
                        e=self:findEnemyByPosition(b.x,i)
                        if e!=nil then
                            b.hit=1
                            e.hit=1
                            self.totalKills+=1
                            sounds:playEnemyDead()
                            break
                        end
                    end
                end
            end
        end,
        findEnemyByPosition=function(self,x,y)
            for e in all(self.enemies) do
                if e.x==x and e.y==y then return e end
            end

            return nil
        end,
        bulletCleanUp=function(self)
            for i=#self.bullets,1,-1 do
                if self.bullets[i].hit==1 then deli(self.bullets,i) end
            end
        end,
        enemyCleanUp=function(self)
            for i=#self.enemies,1,-1 do
                if self.enemies[i].hit==1 then
                    pset(self.enemies[i].x,self.enemies[i].y,10)
                    deli(self.enemies,i)
                end
            end
        end,
        moveBullets=function(self) -- I dont like this logic...
            local i,j=1,1               --to properly support objects being deleted, can't use del() or deli()
            while(self.bullets[i]) do           --if we used a for loop, adding new objects in object updates would break
                if self.bullets[i]:update() then
                    if(i!=j) then
                        self.bullets[j]=self.bullets[i]
                        self.bullets[i]=nil --shift objects if necessary
                    end
                    j+=1
                else
                    self.bullets[i]=nil
                end
                i+=1
            end
        end,
        moveEnemies=function(self)
            i=1
            while (self.enemies[i]) do
                self.enemies[i].tx=self.player.x
                self.enemies[i].ty=self.player.y
                self.enemies[i]:update()
                i+=1
            end
        end,
        drawBullets=function(self)
            for b in all(self.bullets) do pset(b.x,b.y,b.color) end
        end,
        drawEnemies=function(self)
            for e in all(self.enemies) do pset(e.x,e.y,e.color) end
        end,
        checkEnemyPlayerCollision=function(self)
            e=self.findEnemyByPosition(self,self.player.x,self.player.y)
            if e!=nil then
                sounds:playPlayerDead()
                -- endgame, or reduce weapons.
                self.state=2
                self.endtime=self.time
            end
        end
    }

    return game
end


function playerFactory(x, y)
    local player = {
        x=config.playerStartingPositionX,
        y=config.playerStartingPositionX,
        color=config.playerColor,
        direction=1,
        speed=config.playerSpeed,
        moveTop=function(self)
            self.y-=self.speed
            self.direction = 2
            if self.y<0 then self.y=0 end
        end,
        moveRight=function(self)
            self.x+=self.speed
            self.direction = 1
            if self.x>127 then self.x=127 end
        end,
        moveDown=function(self)
            self.y+=self.speed
            self.direction = 3
            if self.y>127 then self.y=127 end
        end,
        moveLeft=function(self)
            self.x-=self.speed
            self.direction = 0
            if self.x<0 then self.x=0 end
        end,
    }

    return player
end

function bulletFactory(x,y,direction)
    local dx=0
    local dy=0
    local speed=config.bulletSpeed
    if direction==0 then
        dx=-1*speed
    elseif direction==1 then
        dx=speed
    elseif direction==2 then
        dy=-1*speed
    elseif direction==3 then
        dy=speed
    end
    local b = {                 --only use the b table inside this function, it's "local" to it
    x=x,y=y,dx=dx,dy=dy,       --the x=x means let b.x = the value stored in newbullet()'s x variable
    time=config.bulletDuration,                   --this is how long a bullet will last before disappearing
    color=config.bulletColor,
    direction=direction,
    hit=0,
    speed=speed,
    update=function(self)
        self.x += self.dx                 --x moves by the change in x every frame (dx)
        self.y += self.dy                 --y moves by the change in y every frame (dy)
        self.time -= 1                 --if bullets have existed for too long, erase them
        if self.x > 127 or self.x<0 or self.y>127 or self.y<0 then return false end
        return self.time > 0
    end,
    }

    return b
end

function enemyFactory(x,y,color,tx,ty,speed)
    local enemy = {
        x=x,y=y,
        tx=tx,ty=ty,
        color=color,
        speed=speed,
        hit=0,
        update=function(self)
            if self.x>self.tx then self.x-=self.speed
            elseif self.x<self.tx then self.x+=self.speed
            end
            if self.y>self.ty then self.y-=self.speed
            elseif self.y<self.ty then self.y+=self.speed
            end
        end,
    }

    return enemy
end


__sfx__
000100002705025050230501f0501d0501a050170501405013050110500e0500c05009050070500405003050010500d2000b200092000820007200052000320002200012000c600106000f6000c6000960003600
000100003305032050300502e0502c0502a050280502605023050210501d0501b050180501605014050110500e0500b0500805005050030500005000050000000000000000000000000000000000000000000000
0001000029050270502505023050210501e0501c0501905015050110500e0500a0500505001050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001f6501f65020650216502165021650226502265022650226502265021650206501f6501d650196501565013650106500b650096500665002650006500000000000000000000000000000000000000000
00020000174501745016450164501545014450134501345011450104500e4500c4500b4500945007450054500345001450014500365005650096500b6500c6500d6500e6500e6500d6500b650076500565000650
000100002805000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002605026050260501d750260501f750260501e7502605026050260502605020000200001e0001d0001b000180001500012000120001a7001b7001c7001c7001d7001d7001d7001d7001d7001c7001b700
