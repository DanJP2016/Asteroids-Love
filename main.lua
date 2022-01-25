function love.load()
  player = require('player')
  
  love.graphics.setBackgroundColor(0, 0, 0, 1)
  WIDTH = love.graphics.getWidth()
  HEIGHT = love.graphics.getHeight()

  centerX = love.graphics.getWidth() / 2
  centerY = love.graphics.getHeight() / 2

  math.randomseed(os.time())

  timer = 0
  ufoSpawnTime = 0
  ufoShootTime = 0

  -- *REMOVE*
  lastRad = 0

    -- bullets - holds all bullets
  bullets = {}
  maxBullets = 10

  -- asteroids
  asteroids = {}
  maxAsteroids = 10

  -- ufo
  ufo = {}
  ufo.alive = false
  ufo.shotCount = 0

  -- particle system
  particle = love.graphics.newCanvas(10, 10)
    love.graphics.setCanvas(particle)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('fill', 0, 0, 5, 5)
  love.graphics.setCanvas()

  particles = love.graphics.newParticleSystem(particle, 500)
  particles:setParticleLifetime(1, 1.5)
  particles:setInsertMode('random')
  particles:setEmissionArea(ellipse, 10, 20, 60, false)
  particles:setLinearAcceleration(-100, -100, 100, 100)
  particles:setColors(1, 1, 1, 1, 0.7, 0.8, 0.9, 0)
end

function getRandInt(val1, val2)
  if math.random() < 0.5 then
    return val1
  end

  return val2
end

-- helper functions for creating asteroids
function setOffsets()
  local offsets = {}
  local dx = 0
  local dy = 0
  local jag = math.random(1, 3) / getRandInt(10, 20)

  for i = 1, 8 do
    dx = math.random() * jag * 2 + 1 - jag
    dy = math.random() * jag * 2 + 1 - jag

    table.insert(offsets, dx)
    table.insert(offsets, dy)

  end

  return offsets
end

function setVerts(x, y, radius, angle, offset)
  local dx = 0
  local dy = 0
  local verts = {}
  local maxVerts = 8

  for i = 1, maxVerts do
    dx = x + radius * offset[i] * math.cos(angle + i * math.pi * 2 / maxVerts)
    dy = y + radius * offset[i] * math.sin(angle + i * math.pi * 2 / maxVerts)

    table.insert(verts, dx)
    table.insert(verts, dy)
  end

  return verts
end

function chance_spawn(cb, val)
  val = val or 0.5

  if math.random() > val then
    cb()
  end
end
-- end helper functions for creating asteroids

function loadBullet(ship)
  if #bullets < maxBullets then
    table.insert(bullets, {
      pos = {
             x = ship.pos.x,
             y = ship.pos.y,
           },
      size = {
             w = 2,
             h = 2
      },
      radius = 2,
      angle = ship.angle,
      speed = 12
    })
  end
end

function distanceBetweenObjects(obj1, obj2)
  return math.sqrt((obj2.pos.x - obj1.pos.x)^2 + (obj2.pos.y - obj1.pos.y)^2)
end

function distanceBetweenPoints(x1, x2, y1, y2)
  return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function spawnAsteroid()
  local rads = {50, 30, 15}
  local px = math.random(WIDTH)
  local py = math.random(HEIGHT)
  local r = rads[math.random(#rads)]
  local a = math.random(359)
  local offs = setOffsets()

  if distanceBetweenPoints(player.pos.x, px, player.pos.y, py) > r + player.radius then
    table.insert(asteroids, {
      pos = {
        x = px,
        y = py
      },
      vel = {
        x = math.random(0),
        y = math.random(0)
      },
      speed = math.random(0.5, 1),
      radius = r,
      angle = a,
      offsets = offs,
      verts = setVerts(px, py, r, a, offs)
    })
  end
end

function spawnUfo()
  ufo.pos = {x = math.random(WIDTH), y = math.random(HEIGHT)}
  ufo.vel = {x = 0, y = 0}
  ufo.points = {
    ufo.pos['x'] - 10, ufo.pos['y'] - 10,
    ufo.pos['x'] - 20, ufo.pos['y'],
    ufo.pos['x'] - 10, ufo.pos['y'] - 10,
    ufo.pos['x'] + 10, ufo.pos['y'] - 10,
    ufo.pos['x'] + 20, ufo.pos['y'],
    ufo.pos['x'] + 10, ufo.pos['y'] + 10,
    ufo.pos['x'] - 10, ufo.pos['y'] + 10,
    ufo.pos['x'] - 20, ufo.pos['y'],
    ufo.pos['x'] - 10, ufo.pos['y'] - 10,
    ufo.pos['x'], ufo.pos['y'] - 10
  }

  ufo.alive = true
end

function rectCollider(obj1, obj2)
  return obj1.pos.x < obj2.pos.x + obj2.size.w and
         obj1.pos.x + obj1.size.w > obj2.pos.x and
         obj1.pos.y < obj2.pos.y + obj2.size.h and
         obj1.pos.y + obj1.size.h > obj2.pos.y
end

function circleCollider(obj1, obj2)
  local dx = obj1.pos.x - obj2.pos.x
  local dy = obj1.pos.y - obj2.pos.y
  local distance = math.sqrt((dx * dx) + (dy * dy))

  if distance < obj1.radius + obj2.radius then
    return true
  end

  return false
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  end

  -- fire bullet
  if key == 'space' then
    loadBullet(player)
  end
end

function love.update(dt)
  -- handle player update
  player:update(dt)
  
  -- update active bullets and remove out of bounds bullets
  if #bullets > 0 then
    for i  = 1, #bullets do
      bullets[i].pos.x = bullets[i].pos.x - math.cos(math.rad(bullets[i].angle)) * bullets[i].speed
      bullets[i].pos.y = bullets[i].pos.y - math.sin(math.rad(bullets[i].angle)) * bullets[i].speed
    end

    for i = #bullets, 1, -1 do
      if bullets[i].pos.x < 0 or bullets[i].pos.y < 0 then
        table.remove(bullets, i)
      elseif bullets[i].pos.x > WIDTH or bullets[i].pos.y > HEIGHT then
        table.remove(bullets, i)
      end
    end
  end

  -- asteroids
  timer = timer + dt

  if #asteroids < maxAsteroids then
    if timer >= 0.5 then
      chance_spawn(spawnAsteroid, 0.4)
      timer = 0
    end
  end

  if #asteroids > 0 then
    for i = 1, #asteroids do
      asteroids[i].pos.x = asteroids[i].pos.x + math.cos(asteroids[i].angle) * asteroids[i].speed
      asteroids[i].pos.y = asteroids[i].pos.y + math.sin(asteroids[i].angle) * asteroids[i].speed
    end

    for i = 1, #asteroids do
      if asteroids[i].pos.x < 0 then
        asteroids[i].pos.x = WIDTH
      end

      if asteroids[i].pos.x > WIDTH then
        asteroids[i].pos.x = 0
      end

      if asteroids[i].pos.y < 0 then
        asteroids[i].pos.y = HEIGHT
      end

      if asteroids[i].pos.y > HEIGHT then
        asteroids[i].pos.y = 0
      end
    end
  end

  -- update particle system
  particles:update(dt)

  -- collision detection for bullets vs asteroids
  if #bullets > 0 and #asteroids > 0 then
    for i = #bullets, 1, -1 do
      for j = #asteroids, 1, -1 do
        if circleCollider(bullets[i], asteroids[j]) == true then
          particles:moveTo(asteroids[j].pos.x, asteroids[j].pos.y)
          -- particles:setEmissionArea(ellipse, 100, 100, 100, true)
          particles:emit(64)

          if asteroids[j].radius > 10 then
            local count = 0
            local newRad = 0
            local newOffs = setOffsets()
            local newVerts = setVerts(asteroids[j].pos.x, asteroids[j].pos.y, asteroids[j].radius, asteroids[j].angle, newOffs)

            repeat
              newRad = asteroids[j].radius - 15
              if newRad > 15 then
                table.insert(asteroids, {
                  pos = {
                    x = asteroids[j].pos.x,
                    y = asteroids[j].pos.y
                  },
                  vel = {
                    x = asteroids[j].vel.x,
                    y = asteroids[j].vel.y
                  },
                  speed = math.random(-0.8, 1.5),
                  radius = asteroids[j].radius - 15,
                  angle = math.random(359),
                  offsets = newOffs,
                  offset = newVerts
                })
              end

              newRad = 0
              count = count + 1
            until count == 2
          end

          -- DEBUG *REMOVE*
          lastRad = asteroids[j].radius

          table.remove(bullets, i)
          table.remove(asteroids, j)
          break
        end
      end
    end
  end

  -- ufo
  if ufo.alive == false then
    ufoSpawnTime = ufoSpawnTime + dt
    if ufoSpawnTime >= 3 then
      local spawnTime = math.random()
      if spawnTime < 0.3 then
        print('spawnTime: ', spawnTime)
        spawnUfo()
      end
      ufoSpawnTime = 0
    end
  end

  if ufo.alive == true then
    ufoShootTime = ufoShootTime + dt * 2
    if ufo.shotCount <= 3 and ufoShootTime > 2 then
      print('ufo shoot')
      ufo.shotCount = ufo.shotCount + 1
      ufoShootTime = 0
    end

    if ufo.shotCount >= 3 then
      ufo.alive = false
      ufo.shotCount = 0
      print('ufo is alive: ', ufo.alive)
    end
  end
end

function love.draw()
  -- player graphics
  player:draw()

  -- draw bullets
  if #bullets > 0 then
    love.graphics.setColor(1, 0.8, 0, 1)
    for i = 1, #bullets do
      love.graphics.circle('fill', bullets[i].pos.x, bullets[i].pos.y, bullets[i].radius)
    end
  end

  -- asteroids
  love.graphics.setColor(1, 1, 1, 1)
  if #asteroids > 0 then
    for i = 1, #asteroids do
      asteroids[i].verts = setVerts(asteroids[i].pos.x, asteroids[i].pos.y, asteroids[i].radius, asteroids[i].angle, asteroids[i].offsets)
      love.graphics.polygon('line', asteroids[i].verts)
    end
  end

  -- draw ufo
  if ufo.alive == true then
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.polygon('line', ufo.points)
  end

  -- particles
  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.draw(particles)

  -- debug data
  love.graphics.setColor(1, 1, 0, 1)
  love.graphics.print('player pos x: ' .. tostring(player.pos.x), 10, 10)
  love.graphics.print('player pos y: ' .. tostring(player.pos.y), 10, 30)
  love.graphics.print('player vel x: ' .. tostring(player.vel.x), 10, 50)
  love.graphics.print('player vel y: ' .. tostring(player.vel.y), 10, 70)
  love.graphics.print('player thrst: ' .. tostring(player.thrust), 10, 90)
  love.graphics.print('player angle: ' .. tostring(player.angle), 10, 110)
  love.graphics.print('# of asteroids: ' .. tostring(#asteroids), 10, 170)
  love.graphics.print('last radius: ' .. tostring(lastRad), 10, 190)
  -- end debug data
end
