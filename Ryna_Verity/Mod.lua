-- Mod: Verity's namespace, built from the core's mod API (the `Ryna` table, the core addon's Mods.lua).
-- Verity is what a group says of the people it played with (ryna_agent
-- docs/ryna-agent-cores-mods.md 7.9; the API's docs/wow.md 22 is the wire). In a dungeon run it
-- keeps who was in the group (Group.lua), works out a few facts about each member from the run
-- Chronicle records (Facts.lua), and lets the player tag a member from a fixed list, with no free
-- text (Tags.lua, Notebook.lua, Section.lua). A tag is kept in the player's notebook
-- (RynaDB.verity) and, five minutes later, written to the journal, which the Ryna app sends to
-- Ryna's pool. Ryna clients in one group agree a short code over the addon channel so the pool can
-- tell a run two accounts recorded from one only the reporter did (Comms.lua).
--
-- This is the one mod that keeps and sends a named record about another player, so what it takes
-- is bounded by the design: a member's GUID, name and class, a tag, and the facts for that tag.
-- Chat is never read, and nothing here is shown to anyone but the player.
--
-- Every file starts with `if ns.off then return end`: without the mod API (a core addon from before
-- it), Verity loads nothing at all, and says nothing either.

local addonName, ns = ...

local R = _G.Ryna
-- The core API level this mod needs is the TOC's (## X-Ryna-API), the one place it is written;
-- on a core below it nothing loads, and the core's Mods tab says why.
local needs, known = 1, false
do
  local read = (_G.C_AddOns and _G.C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
  local ok, level = pcall(function() return tonumber(read(addonName, "X-Ryna-API")) end)
  if ok and level then needs, known = level, true end
end
-- Nor on a core that no longer serves this mod's level (R.API_MIN, absent on a core before it);
-- only when the TOC's level could be read, so a client that won't say never turns the mod off.
local tooOld = known and type(R) == "table" and type(R.API_MIN) == "number" and needs < R.API_MIN
if type(R) ~= "table" or type(R.API) ~= "number" or R.API < needs or tooOld or type(R.RegisterMod) ~= "function" then
  ns.off = true
  return
end

ns.NAME = addonName
ns.API = R

-- The version is the TOC's, so there is no second copy to keep in step.
local metadata = (_G.C_AddOns and _G.C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
ns.VERSION = R.Try(metadata, addonName, "Version")

for _, name in ipairs({ "Try", "Fn", "IsSecret", "NonEmpty", "Now", "Print", "Debug", "Run", "Debounce", "On",
  "Ago", "After" }) do
  ns[name] = R[name]
end

-- Verity's strings (Locales/), falling back to the core's (Ryna.L), which fall back to the key.
ns.L = setmetatable({}, {
  __index = function(_, key) return R.L[key] end,
  __newindex = function(t, key, value)
    if type(value) == "string" and value ~= "" then rawset(t, key, value) end
  end,
})
