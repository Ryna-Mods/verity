-- Tooltip: a line on a player's tooltip with what this player noted of them before, and one line
-- in chat when someone you tagged joins your group (design 7.9, "In game first"). Both are the
-- player's own notebook: the pool's tags don't reach the game yet (Data/verity.lua isn't built).
-- Each has its own setting (verityTooltips, verityJoinLine), both on. The chat line is said once a
-- member a session, and never in combat.

local _, ns = ...
if ns.off then return end
local L = ns.L
local G, N, T = ns.Group, ns.Notebook, ns.Tags

local Tt = {}
ns.Tooltip = Tt

local MAX_TAGS = 2

local function setting(key)
  local settings = ns.API.Settings
  if type(settings) ~= "table" or type(settings.Get) ~= "function" then return true end
  return settings.Get(key) ~= false
end
Tt.Setting = setting

-- "you noted: needs on gear they can't use (2 days ago), ..." for a person, or nil.
function Tt.Noted(guid, key)
  local parts = {}
  for _, r in ipairs(N.About(guid, key)) do
    if #parts >= MAX_TAGS then break end
    parts[#parts + 1] = string.format("%s (%s)", T.Label(r.tag):lower(), ns.Ago(r.at) or "")
  end
  if #parts == 0 then return nil end
  return string.format(L["you noted: %s"], table.concat(parts, ", "))
end

function Tt.Line(guid)
  if type(guid) ~= "string" or not guid:find("^Player%-") then return nil end
  local noted = Tt.Noted(guid, nil)
  return noted and ("Ryna · " .. noted) or nil
end

local function unitGuid(tooltip, data)
  local guid = type(data) == "table" and data.guid
  if guid ~= nil and not ns.IsSecret(guid) and type(guid) == "string" then return guid end
  local unit
  if type(tooltip) == "table" and type(tooltip.GetUnit) == "function" then
    unit = select(2, ns.Try(tooltip.GetUnit, tooltip))
  end
  if unit == nil or ns.IsSecret(unit) then unit = "mouseover" end
  guid = ns.Try(ns.Fn("UnitGUID"), unit)
  if guid ~= nil and not ns.IsSecret(guid) and type(guid) == "string" then return guid end
  return nil
end

local function onUnit(tooltip, data, show)
  ns.Run("verity tooltip", function()
    if not setting("verityTooltips") then return end
    local line = Tt.Line(unitGuid(tooltip, data))
    if not line then return end
    local shared = ns.API.Tooltip
    if type(shared) == "table" and type(shared.AddLine) == "function" then
      shared.AddLine(tooltip, line, 0.75, 0.75, 0.75, true)
    elseif type(tooltip) == "table" and type(tooltip.AddLine) == "function" then
      tooltip:AddLine(line, 0.75, 0.75, 0.75, true)
    end
    if show and type(tooltip.Show) == "function" then tooltip:Show() end
  end)
end

-- Once, at login. Returns how the hook went in: "processor", "scripts" or nil.
function Tt.Register()
  if Tt.mode then return Tt.mode end
  local enum = _G.Enum
  local types = type(enum) == "table" and enum.TooltipDataType
  local postCall = ns.Fn("TooltipDataProcessor", "AddTooltipPostCall")
  if postCall and type(types) == "table" and types.Unit ~= nil then
    if ns.Try(function()
      postCall(types.Unit, function(tooltip, data) onUnit(tooltip, data, false) end)
      return true
    end) then Tt.mode = "processor" end
  end
  if not Tt.mode then
    local tip = _G.GameTooltip
    if type(tip) == "table" and type(tip.HookScript) == "function" and ns.Try(function()
      tip:HookScript("OnTooltipSetUnit", function(self) onUnit(self, nil, true) end)
      return true
    end) then Tt.mode = "scripts" end
  end
  return Tt.mode
end

-- The chat line for a member who just joined, or nil (nothing noted, said already, or in combat).
local said = {}
function Tt.JoinLine(m)
  if type(m) ~= "table" or said[m.key] or not setting("verityJoinLine") then return nil end
  if ns.Try(ns.Fn("InCombatLockdown")) == true then return nil end
  local noted = Tt.Noted(m.guid, m.key)
  if not noted then return nil end
  said[m.key] = true
  return string.format("%s: %s", tostring(m.name or "?"), noted)
end

G.OnSync(function(_, joined)
  for _, m in ipairs(joined) do
    local line = Tt.JoinLine(m)
    if line then ns.Print(line) end
  end
end)
