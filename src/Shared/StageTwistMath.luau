-- Stage-twist timelines, a pure function of the shared server clock: the server decides the effects from them and the client draws the same state.
local M = {}

--- "active" during the first `duration` seconds of every `period` (shifted by `offset`), "warn" during the last `warn` seconds before the next
--- window, otherwise "idle". The second value is the seconds left in that state.
function M.State(now, period, duration, warn, offset)
	local p = (now + offset) % period
	if p < duration then return "active", duration - p end
	if p >= period - warn then return "warn", period - p end
	return "idle", period - warn - p
end

--- Z of lane `index` of `count` lanes spread along a stage floor.
function M.LaneZ(floor, index, count)
	return floor.Position.Z - floor.Size.Z / 2 + floor.Size.Z * index / (count + 1)
end

--- Minecart x offset from the stage centre line, or nil while the cart is parked. Lanes start one crossing apart; odd lanes run left to right.
function M.CartX(cfg, lane, now, half)
	local p = (now + (lane - 1) * cfg.Crossing) % cfg.Period
	if p >= cfg.Crossing then return nil end
	return (lane % 2 == 1 and 1 or -1) * (-half + 2 * half * p / cfg.Crossing)
end
function M.CartState(cfg, lane, now) return M.State(now, cfg.Period, cfg.Crossing, cfg.Warn, (lane - 1) * cfg.Crossing) end

--- Container x offset: parked at one side, sliding to the other side during the first `Move` seconds of every period. Containers are staggered.
function M.ContainerX(cfg, index, now, half)
	local reach = half - cfg.Edge
	local t = now + (index - 1) * cfg.Period / cfg.Count
	local k, p = math.floor(t / cfg.Period), t % cfg.Period
	local function side(n) return n % 2 == 0 and -reach or reach end
	if p >= cfg.Move then return side(k) end
	local u = p / cfg.Move
	u = u * u * (3 - 2 * u)
	return side(k - 1) + (side(k) - side(k - 1)) * u
end
function M.ContainerState(cfg, index, now) return M.State(now, cfg.Period, cfg.Move, cfg.Warn, (index - 1) * cfg.Period / cfg.Count) end

function M.PadLit(cfg, index, now) return M.State(now, cfg.Period, cfg.Lit, 0, (index - 1) * cfg.Stagger) == "active" end
return M
