pico-8 cartridge // http://www.pico-8.com
version 32
__lua__


function _init()
    game = makeGame()
    sounds = makeSounds()
    -- endGameTimeCounter = 0
    cls()
    -- game.state=0

end

function _update()
    -- start
    if game.state==0 then
        if btn(0) or btn(1) or btn(2) or btn(3) or btn(4) or btn(5) then
            game.state=1
        end

    end
    if game.state==1 then
        enemyGenerator()
        if (btn(0)) then game.player:moveLeft() end
        if (btn(1)) then game.player:moveRight() end
        if (btn(2)) then game.player:moveTop() end
        if (btn(3)) then game.player:moveDown() end

        if(btnp(4)) then
            sounds:playLaser()
            add(game.bullets, bulletFactory(game.player.x,game.player.y,game.player.direction))
        end

        if(btnp(5)) then
            add(game.enemies, enemyFactory(10,10,12,game.player.x,game.player.y))
        end
    elseif game.state==2 then
         endGame = makeEndgameTimeCounter(game.totalKills)
        if(btnp(4)) then
            cls()
            game.state=3
        end
    elseif game.state==3 then
        if(btnp(4)) then
            _init()
        end
    end
end

function _draw()

    -- wating to begin
    if game.state==0 then
        cls(0)
        game:drawPlayer()
    -- play
    elseif game.state==1 then
        cls(0)
         game:drawPlayer()
         game:bulletCollitionCheck()
         game:bulletCleanUp()
         game:enemyCleanUp()
         game:moveBullets()
         game:moveEnemies()
         game:checkEnemyPlayerCollision()
         game:drawBullets()
         game:drawEnemies()
         game.time+=1
         -- print(game.time,0,0,7)
     -- endgame with enemies still heading for dead player
     elseif game.state==2 then
         cls(0)
         game:bulletCollitionCheck()
         game:bulletCleanUp()
         game:enemyCleanUp()
         game:moveBullets()
         game:moveEnemies()
         -- game:checkEnemyPlayerCollision()
         game:drawBullets()
         game:drawEnemies()
     elseif game.state==3 then
         -- count time (or enemies)
         -- if endGameTimeCounter%2 == 0 then endGame:draw() end
         endGame:draw()
         -- endGameTimeCounter+=1
     end


end

function makeSounds()
    s = {
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

function makeEndgameTimeCounter(maxTime)
    m = {
        maxTime=15,
        x=0,
        y=0,
        current=0,
        playend=0,
        draw=function(self)
            if self.current<self.maxTime then
                pset(self.x,self.y,7)
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

function enemyGenerator()
    -- first 30 seconds
    if game.time<900 then
        if (game.time - 60) % 360 == 0 then
            add(game.enemies, enemyFactory(127,64,12,game.player.x,game.player.y))
            -- add(game.enemies, enemyFactory(flr(rnd(128)),flr(rnd(128)),12,game.player.x,game.player.y))
        elseif (game.time - 150) % 360 == 0 then
            add(game.enemies, enemyFactory(64,127,12,game.player.x,game.player.y))
        elseif (game.time - 240) % 360 == 0 then
            add(game.enemies, enemyFactory(0,64,12,game.player.x,game.player.y))
        elseif (game.time - 330) % 360 == 0 then
            add(game.enemies, enemyFactory(64,0,12,game.player.x,game.player.y))
        end
    -- elseif game.time>900 and game.time>1800 then
    --     if (game.time - 60) % 360 == 0 then
    --         -- left
    --         add(game.enemies, enemyFactory(127,64,12,game.player.x,game.player.y))
    --         add(game.enemies, enemyFactory(0,64,12,game.player.x,game.player.y))
    --         -- add(game.enemies, enemyFactory(flr(rnd(128)),flr(rnd(128)),12,game.player.x,game.player.y))
    --     elseif (game.time - 150) % 360 == 0 then
    --         add(game.enemies, enemyFactory(64,127,12,game.player.x,game.player.y))
    --         add(game.enemies, enemyFactory(64,0,12,game.player.x,game.player.y))
    --     elseif (game.time - 240) % 360 == 0 then
    --         add(game.enemies, enemyFactory(127,64,12,game.player.x,game.player.y))
    --         add(game.enemies, enemyFactory(0,64,12,game.player.x,game.player.y))
    --     elseif (game.time - 330) % 360 == 0 then
    --         add(game.enemies, enemyFactory(64,0,12,game.player.x,game.player.y))
    --         add(game.enemies, enemyFactory(64,0,12,game.player.x,game.player.y))
    --     end
    -- elseif game.time>1800 then
    --     if (game.time) % 30 == 0 then
    --         add(game.enemies, enemyFactory(flr(rnd(128)),flr(rnd(128)),12,game.player.x,game.player.y))
    --     end
    end
end

function makeGame()
    game = {
        time=0,
        totalKills=0,
        state=0,
        bullets = {},
        enemies = {},
        player = playerFactory(64, 64, 7),
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
        moveBullets=function(self)
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
            end
        end
    }

    return game
end


function playerFactory(x, y, color)
    local player = {
        x=x,
        y=y,
        color=color,
        direction=1,
        speed=2,
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
    local speed=5
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
    time=60,                   --this is how long a bullet will last before disappearing
    color=8,
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
    -- add(bullets,b)                 --now we can manage all bullets in a list
    return b                    --and if some are special, we can adjust them a bit outside of this function
end

function enemyFactory(x,y,color,tx,ty)
    local enemy = {
        x=x,y=y,
        tx=tx,ty=ty,
        color=color,
        speed=1,
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


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100002705025050230501f0501d0501a050170501405013050110500e0500c05009050070500405003050010500d2000b200092000820007200052000320002200012000c600106000f6000c6000960003600
000100003305032050300502e0502c0502a050280502605023050210501d0501b050180501605014050110500e0500b0500805005050030500005000050000000000000000000000000000000000000000000000
0001000029050270502505023050210501e0501c0501905015050110500e0500a0500505001050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001f6501f65020650216502165021650226502265022650226502265021650206501f6501d650196501565013650106500b650096500665002650006500000000000000000000000000000000000000000
00020000174501745016450164501545014450134501345011450104500e4500c4500b4500945007450054500345001450014500365005650096500b6500c6500d6500e6500e6500d6500b650076500565000650
000100002805000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002605026050260501d750260501f750260501e7502605026050260502605020000200001e0001d0001b000180001500012000120001a7001b7001c7001c7001d7001d7001d7001d7001d7001c7001b700
