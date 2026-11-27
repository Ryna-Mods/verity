-- Init: Verity registers with the core (Ryna.RegisterMod). Loaded last, so every handler exists.
-- At login it registers its addon-message prefix and its tooltip line, sends what was left pending
-- and reads the group; at logout it sends every pending tag, since the journal is what the Ryna
-- app uploads. /ryna verity opens its section.

local _, ns = ...
if ns.off then return end
local L = ns.L

local settings = ns.API.Settings
if type(settings) == "table" and type(settings.AddDefaults) == "function" then
  settings.AddDefaults({ verityTooltips = true, verityJoinLine = true })
end

ns.API.RegisterMod({
  id = "verity",
  addon = ns.NAME,
  name = "Verity",
  version = ns.VERSION,
  onLogin = function()
    ns.Run("verity comms", ns.Comms.Register)
    ns.Run("verity tooltip", ns.Tooltip.Register)
    ns.Run("verity prune", ns.Notebook.Prune)
    ns.Run("verity send", ns.Notebook.Flush, false)
    ns.Run("verity sync", ns.Group.Sync)
  end,
  onLogout = function()
    ns.Run("verity send", ns.Notebook.Flush, true)
  end,
})

ns.Section.Register()

local function flip(key)
  if type(settings) ~= "table" or type(settings.Set) ~= "function" then return end
  settings.Set(key, not ns.Tooltip.Setting(key))
end

local Slash = ns.API.Slash
if type(Slash) == "table" and type(Slash.Add) == "function" then
  Slash.Add({
    word = "verity",
    order = 78,
    label = L["Verity"],
    help = L["/ryna verity: tag the people you ran a dungeon with, and see your notes on them"],
    menu = {
      { label = L["Open Verity"], arg = "" },
      { label = L["Your notes on player tooltips"], arg = "tooltips",
        checked = function() return ns.Tooltip.Setting("verityTooltips") end },
      { label = L["A line when someone you tagged joins"], arg = "joins",
        checked = function() return ns.Tooltip.Setting("verityJoinLine") end },
    },
    run = function(arg)
      if arg == "tooltips" then return flip("verityTooltips") end
      if arg == "joins" then return flip("verityJoinLine") end
      local RW = ns.API.Window
      if ns.Section.registered and type(RW.Open) == "function" then
        RW.Open(ns.Section.KEY)
      else
        ns.Print(L["Verity needs Ryna's window, which this version of Ryna Core doesn't have."])
      end
    end,
  })
end
