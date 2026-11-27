-- Tags: the fixed list a member can be tagged from (design 7.9, "The tags"; Maddison's list, and
-- the same ids the API takes, docs/wow.md 22.1). There is no free text anywhere in Verity. A tag's
-- words say what happened in groups, never what a person is.
--
-- A tag may carry facts: counts Verity worked out for that member in that run (Facts.lua). The
-- numbers never apply a tag: a person picks it, and the facts go along as evidence.

local _, ns = ...
if ns.off then return end
local L = ns.L

local T = {}
ns.Tags = T

-- In the order the menu shows them: the commendations, then the reports.
T.LIST = {
  { id = "role", kind = "positive", label = L["Good at their role"] },
  { id = "patient", kind = "positive", label = L["Patient and helpful"] },
  { id = "led", kind = "positive", label = L["Led the group well"] },
  { id = "versatile", kind = "positive", label = L["Versatile"] },
  { id = "fairLoot", kind = "positive", label = L["Fair with loot"] },
  { id = "needs", kind = "negative", label = L["Needs on gear they can't use"] },
  { id = "inactive", kind = "negative", label = L["Often inactive in groups"] },
  { id = "leaves", kind = "negative", label = L["Leaves runs early"] },
  { id = "threat", kind = "negative", label = L["Pulls threat off the tank"] },
}

T.BY_ID = {}
for _, tag in ipairs(T.LIST) do T.BY_ID[tag.id] = tag end

function T.Label(id)
  local tag = T.BY_ID[id]
  return tag and tag.label or tostring(id)
end

function T.Kind(id)
  local tag = T.BY_ID[id]
  return tag and tag.kind or nil
end

-- A tag's facts in words, for the row and the menu; nil when there are none worth a line.
function T.FactText(id, facts)
  if type(facts) ~= "table" then return nil end
  if id == "needs" and (facts.needRolls or 0) > 0 then
    if (facts.cantEquip or 0) > 0 then
      return string.format(L["needed %d, can't equip %d"], facts.needRolls, facts.cantEquip)
    end
    return string.format(L["needed %d"], facts.needRolls)
  elseif id == "fairLoot" and (facts.passed or 0) > 0 then
    return string.format(L["passed on %d"], facts.passed)
  elseif id == "leaves" and facts.bosses and facts.bossesSeen and facts.bossesSeen < facts.bosses then
    return string.format(L["left after boss %d of %d"], facts.bossesSeen, facts.bosses)
  end
  return nil
end
