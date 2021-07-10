function love.load()
    love.window.setMode(600, 820)
    love.window.setTitle('Space Shooter')

    WINDOW_WIDTH = love.graphics.getWidth()
    WINDOW_HEIGHT = love.graphics.getHeight()
    
    love.graphics.setDefaultFilter('nearest', 'nearest')

    gameState = {}
    gameState.menu = true 
    gameState.play = false 
    gameState.gameover = false

    fonts = {}
    fonts.small = love.graphics.newFont('fonts/AtariChunky.ttf', 16)
    fonts.medium = love.graphics.newFont('fonts/AtariChunky.ttf', 32)
    fonts.large = love.graphics.newFont('fonts/AtariChunky.ttf', 64)

    sounds = {}
    sounds.shoot = love.audio.newSource('sounds/laserShot.wav', 'static')
    sounds.explode = love.audio.newSource('sounds/explode.mp3', 'static')
    sounds.fail = love.audio.newSource('sounds/fail.wav', 'static')
    sounds.gameover = love.audio.newSource('sounds/gameover.wav', 'static')
    sounds.background = love.audio.newSource('sounds/background.mp3', 'static')
    sounds.background:setLooping(true)
    sounds.background:play()

    background = {}
    background.img = love.graphics.newImage('sprites/backgrounds/space.png')
    background.x = 0
    background.y = -1640
    background.scrollSpeed = 2

    ship = {}
    ship.life = 3
    ship.img_straight = love.graphics.newImage('sprites/player/spaceship.png')
    ship.img_left = love.graphics.newImage('sprites/player/spaceship_left.png')
    ship.img_right = love.graphics.newImage('sprites/player/spaceship_right.png')
    ship.active_sprite = ship.img_straight
    ship.width = ship.img_straight:getWidth()
    ship.height = ship.img_straight:getHeight()
    ship.x = love.graphics.getWidth()/2 - ship.width/2
    ship.y = love.graphics.getHeight() - ship.height - 10
    ship.speed = 5
    ship.bullets = {}
    bulletHeight = 20
    bulletWidth = 5
    bulletSpeed = 10

    enemies = {}
    spawnTimer = 0

    score = 0

    explosionTexture = love.graphics.newImage('sprites/particles/explosion.png')
    ps = love.graphics.newParticleSystem(explosionTexture, 500)
    ps:setSizeVariation(1)
    ps:setColors(255, 255, 255, 255, 255, 255, 255, 0)
    ps:setEmissionArea('normal', 15, 15)
    ps:setRadialAcceleration(30, 30)
    ps:setParticleLifetime(1,2)
    ps:setSizes(1, 1.5)
end

function love.update(dt) 
    background.y = (background.y + background.scrollSpeed)
    if background.y == 0 then 
        background.y = -1640
    end

    if ship.life == 0 then 
        gameState.gameover = true 
        gameState.play = false 
        gameState.menu = false
    end

    if gameState.play then 

        ship.active_sprite = ship.img_straight

        ps:update(dt*2)

        for i=1, #ship.bullets, 1 do 
            ship.bullets[i].y = ship.bullets[i].y - bulletSpeed*dt*60
        end

        for i=1, #enemies, 1 do 
            enemies[i].y = enemies[i].y + enemies[i].speed*dt*50
            if enemies[i].y > WINDOW_HEIGHT and enemies[i].isAlive then 
                love.audio.stop(sounds.fail)
                ship.life = ship.life - 1
                enemies[i].isAlive = false
                sounds.fail:play()
                if ship.life == 0 then 
                    sounds.gameover:play()
                end
            end
        end

        for i=1, #ship.bullets, 1 do 
            for j=1, #enemies, 1 do 
                if ship.bullets[i].y < enemies[j].y+enemies[j].height and 
                ship.bullets[i].y+bulletHeight > enemies[j].y and
                ship.bullets[i].x > enemies[j].x and
                ship.bullets[i].x+bulletWidth < enemies[j].x+enemies[j].width and
                enemies[j].isAlive == true and 
                ship.bullets[i].destroyed == false then 
                    ship.bullets[i].destroyed = true 
                    sounds.explode:play()
                    enemies[j].isAlive = false
                    score = score + 1
                    ps:moveTo(enemies[j].x + enemies[j].width/2, enemies[j].y + enemies[j].height/2)
                    ps:emit(500)
                end
            end
        end

        if love.keyboard.isDown('left') then 
            ship.active_sprite = ship.img_left
            ship.x = math.max(0, ship.x - ship.speed*dt*60)
        elseif love.keyboard.isDown('right') then 
            ship.active_sprite = ship.img_right
            ship.x = math.min(ship.x + ship.speed*dt*60, love.graphics.getWidth() - ship.width)
        end

        spawnTimer = spawnTimer + dt 
        if spawnTimer > math.random(1, 3) then 
            local enemy = {}
            enemy.img = love.graphics.newImage('sprites/enemy/enemy.png')
            enemy.width = enemy.img:getWidth()
            enemy.height = enemy.img:getHeight() 
            enemy.x = math.random(25, 570-enemy.width)
            enemy.y = -enemy.height 
            enemy.isAlive = true 
            enemy.speed = 4 + math.random(0, 5)
            table.insert(enemies, enemy)
            spawnTimer = 0 
        end
    end
end

function love.keypressed(key) 
    if key == 'escape' then 
        love.event.quit()
    end
    if (key == 'space' or key == 'up') and gameState.play then 
        love.audio.stop(sounds.shoot)
        local bullet = {}
        bullet.img = love.graphics.newImage('sprites/player/spaceship_bullet.png')
        bullet.y = ship.y - bulletHeight 
        bullet.x = ship.x + (ship.width)/2 - bulletWidth/2 
        bullet.destroyed = false
        table.insert(ship.bullets, bullet)
        sounds.shoot:play()
    end
    if key == 'return' and gameState.gameover then 
        gameState.gameover = false 
        gameState.play = true
        ship.life = 3
        score = 0
        for i=1, #enemies, 1 do 
            enemies[i].isAlive = false 
        end
        for i=1, #ship.bullets, 1 do 
            ship.bullets[i].destroyed = true
        end
    end
    if key == 'return' and gameState.menu then 
        gameState.menu = false 
        gameState.play = true 
    end
end

function love.draw()
    love.graphics.reset()

    love.graphics.draw(background.img, background.x, background.y)

    if gameState.menu then 
        love.graphics.reset()
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle('fill', 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
        love.graphics.reset()
        love.graphics.setFont(fonts.medium)
        love.graphics.print('SPACE SHOOTER', WINDOW_WIDTH/2-fonts.medium:getWidth('SPACE SHOOTER')/2, WINDOW_HEIGHT/2-50)
        love.graphics.reset()
        love.graphics.setColor(0, 0, 255)
        love.graphics.setFont(fonts.small)
        love.graphics.print('Press enter to start...', WINDOW_WIDTH/2-fonts.small:getWidth('Press enter to start...')/2, WINDOW_HEIGHT/2+50)
    end

    if gameState.gameover or gameState.play then 
        love.graphics.draw(ship.active_sprite, ship.x, ship.y)
        
        for i=1, #enemies, 1 do 
            if enemies[i].isAlive then 
                love.graphics.draw(enemies[i].img, enemies[i].x, enemies[i].y)
            end
        end

        for i=1, #ship.bullets, 1 do 
            if ship.bullets[i].destroyed == false then 
                love.graphics.draw(ship.bullets[i].img, ship.bullets[i].x, ship.bullets[i].y)
            end
        end

        love.graphics.draw(ps)

        love.graphics.setFont(fonts.small)
        love.graphics.setColor(0, 0, 255)
        love.graphics.print('SCORE:'..tostring(score), 10, 10)
        love.graphics.reset()
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(255, 0, 0)
        love.graphics.print('Life: '..tostring(ship.life), WINDOW_WIDTH-fonts.small:getWidth('Life: X')-10, 10)
    end

    if gameState.gameover then 
        love.graphics.reset()
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle('fill', 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
        love.graphics.reset()
        love.graphics.setFont(fonts.large)
        love.graphics.print('GAME OVER', WINDOW_WIDTH/2-fonts.large:getWidth('GAME OVER')/2, WINDOW_HEIGHT/2-100)
        love.graphics.reset()
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(0, 0, 255)
        love.graphics.print('Your Score: '..tostring(score), WINDOW_WIDTH/2-fonts.small:getWidth('Your Score: X')/2, WINDOW_HEIGHT/2)
        love.graphics.reset()
        love.graphics.setFont(fonts.small)
        love.graphics.print('Press enter to play again...', WINDOW_WIDTH/2-fonts.small:getWidth('Press enter to play again...')/2, WINDOW_HEIGHT/2+100)
    end 
end