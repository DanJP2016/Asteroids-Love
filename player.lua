local player = {}

player.pos = {x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() / 2}
player.vel = {x = 0, y = 0}
player.size = {w = 20, h = 20}
player.speed = 0.09
player.angle = 0
player.radius = 30
player.rotateSpeed = 200
player.dir = 1
player.thrust = false
player.alive = true

function player:update(dt)
  -- handle player out of bounds
  if player.pos.x < 0 then
    player.pos.x = WIDTH
  end

  if player.pos.x > WIDTH then
    player.pos.x = 0
  end

  if player.pos.y < 0 then
    player.pos.y = HEIGHT
  end

  if player.pos.y > HEIGHT then
    player.pos.y = 0
  end

  -- handle player rotation and movement
  if love.keyboard.isDown('left') then
    player.angle = player.angle - player.rotateSpeed * dt
  end

  if love.keyboard.isDown('right') then
    player.angle = player.angle + player.rotateSpeed * dt
  end

  if love.keyboard.isDown('up') then
    player.thrust = true
  else
    player.thrust = false
  end

  if player.thrust == true then
    player.vel.x = player.vel.x + math.cos(math.rad(player.angle)) * player.speed
    player.vel.y = player.vel.y + math.sin(math.rad(player.angle)) * player.speed
  end

  -- slow/stop ship when not thrusting
  player.vel.x = player.vel.x * 0.99
  player.vel.y = player.vel.y * 0.99

  -- move ship
  player.pos.x = player.pos.x - player.vel.x
  player.pos.y = player.pos.y - player.vel.y
end

function player:draw()
  -- player graphics
  love.graphics.push()
  love.graphics.translate(player.pos.x, player.pos.y)
  love.graphics.rotate(math.rad(player.angle) * player.dir)
  love.graphics.setColor(0, 1, 0, 0.1)
  love.graphics.circle('line', 0, 0, player.radius, 10)
  love.graphics.setColor(0, 1, 0, 1)
  love.graphics.line(0, 0,
                     0 + player.size.w, 0 + player.size.h / 2,
                     player.size.h, player.size.h - player.radius,
                     player.size.h - player.size.h, 0)
  love.graphics.pop()
end

return player
