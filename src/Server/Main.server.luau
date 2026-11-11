--[[
	Server entry point. Wires services together in dependency order.
	The world is NOT built here - it is saved in Workspace/Greybox and found by name/tag.
]]

local PlotService = require(script.Parent.PlotService)
local CardService = require(script.Parent.CardService)
local CubeService = require(script.Parent.CubeService)
local PickaxeService = require(script.Parent.PickaxeService)
local SlotService = require(script.Parent.SlotService)
local LockService = require(script.Parent.LockService)
local GuardService = require(script.Parent.GuardService)
local CashService = require(script.Parent.CashService)

require(script.Parent.PlotAccess).Init()
PlotService.Init()
LockService.Init(PlotService)
CardService.Init(SlotService.ReturnStolen,SlotService)
SlotService.Init(PlotService, CardService, LockService)
CashService.Init(PlotService, SlotService)
PickaxeService.Init(CubeService, CardService)
GuardService.Init(CardService)

-- A broken cube drops a card of the tier it was carrying.
CubeService.OnBroken(CardService.DropFromCube)

CubeService.Init()

require(script.Parent.WeatherService).Init()
require(script.Parent.WorldLayout).Publish()

require(script.Parent.PlayerData).Init(PlotService,SlotService,CardService)
require(script.Parent.Purchases).Init()
require(script.Parent.IndexService).Init()
require(script.Parent.DailyReward).Init()
require(script.Parent.TreadmillService).Init(PlotService,CardService)
require(script.Parent.ToolShop).Init(CardService)
require(script.Parent.TrailShop).Init()
require(script.Parent.FeedbackService).Init()
require(script.Parent.Leaderboards).Init()

require(script.Parent.TorchMount).Apply()

require(script.Parent.FootballBall).Init()
require(script.Parent.FootballLobby).Init(PlotService, SlotService)
