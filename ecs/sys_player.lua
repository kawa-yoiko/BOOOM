local ecs = require 'ecs/ecs'
require 'ecs/utils'

local keys = function (a, b)
    local result = 0
    if love.keyboard.isDown(a) then result = result + 1 end
    if love.keyboard.isDown(b) then result = result - 1 end
    return result
end

local updateVel = function (orig, tx, ty)
    local A = 768   -- Acceleration
    if tx == 0 and ty == 0 then A = 256 end
    local DV = A * DT
    local dx, dy = tx - orig[1], ty - orig[2]
    local dsq = dx * dx + dy * dy
    if dsq <= DV * DV then
        orig[1], orig[2] = tx, ty
    else
        local dinv = DV / math.sqrt(dsq)
        orig[1] = orig[1] + dx * dinv
        orig[2] = orig[2] + dy * dinv
    end
end

local nearest = function (e, v, es)
    local K = 0.3
    local cx, cy =
        e.dim[1] + e.dim[3] * 0.5,
        e.dim[2] + e.dim[4] * 0.5
    local vx, vy = e.vel[1], e.vel[2]
    local vsq = vx * vx + vy * vy
    if vsq <= 1e-5 then
        vx, vy = v[1], v[2]
    else
        local vinv = 1 / math.sqrt(vsq)
        vx, vy = vx * vinv, vy * vinv
        v[1], v[2] = vx, vy
    end
    local best, ret = 1e10, nil
    for _, t in ipairs(es) do
        local tx, ty =
            t.dim[1] + t.dim[3] * 0.5,
            t.dim[2] + t.dim[4] * 0.5
        local dx, dy = tx - cx, ty - cy
        -- Project d onto v
        local p = dx * vx + dy * vy
        if p > 1e-5 then
            local psq = p * p
            local d2sq = dx * dx + dy * dy + (K * K - 1) * psq
            if d2sq < best then best, ret = d2sq, t end
        end
    end
    return ret
end

return function () return {

lastUDown = false,
lastValidVel = {1, 0},
update = function (self, cs)
    for _, e in pairs(cs.player) do
        local horz = keys('right', 'left')
        local vert = keys('down', 'up')
        if horz ~= 0 and vert ~= 0 then
            horz = horz / 1.414213562
            vert = vert / 1.414213562
        end
        updateVel(e.vel, horz * 96, vert * 96)

        local UDown = love.keyboard.isDown('u')
        local target = nearest(e, self.lastValidVel, cs.enemy)
        if target ~= nil then
            local dx, dy = targetVec(e.dim, target.dim, 16)
            if UDown and not lastUDown then
                local bullet = {
                    dim = {
                        e.dim[1] + e.dim[3] * 0.5 + dx * 0.25,
                        e.dim[2] + e.dim[4] * 0.5 + dy * 0.25,
                        4, 4
                    },
                    vel = { dx * 10, dy * 10 },
                    sprite = { name = 'quq9' },
                    bullet = { mask = 5 }
                }
                ecs.addEntity(bullet)
            end
        end
        lastUDown = UDown
    end
end

} end
