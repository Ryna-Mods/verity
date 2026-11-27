-- Facts: what Verity can say for certain about one member in one run, from the run Chronicle keeps
-- and the group Verity kept (design 7.9, "The tags"). Counts only, for three tags in this version:
--
--   needs     needRolls (items they rolled Need on), cantEquip (of those, items their class can
--             never equip)
--   fairLoot  passed (items they passed on)
--   leaves    bosses (killed in the run), bossesSeen (killed while they were in the group)
--
-- The other tags (inactive, threat, versatile, and the three that are the reporter's view) carry no
-- facts yet: they need the meter and probes of their own (design, V2 to V4).
--
-- "Can't equip" is said only when it is certain: armour heavier than the class ever wears, a shield
-- on a class with none, or a weapon the class can never train (the Classic lists, with the later
-- additions left in so a doubt never counts against anyone). A class this table doesn't know, or
-- an item the client can't describe, is never counted. "No upgrade for their spec" is not judged at
-- all: that would be a guess.

local _, ns = ...
if ns.off then return end

local F = {}
ns.Facts = F
local G = ns.Group

local WEAPON, ARMOR = 2, 4
local SHIELD = 6

-- The heaviest armour a class ever wears: 1 cloth, 2 leather, 3 mail, 4 plate.
local MAX_ARMOR = {
  WARRIOR = 4, PALADIN = 4, DEATHKNIGHT = 4, HUNTER = 3, SHAMAN = 3, EVOKER = 3, ROGUE = 2, DRUID = 2,
  MONK = 2, DEMONHUNTER = 2, MAGE = 1, PRIEST = 1, WARLOCK = 1,
}
local SHIELDS = { WARRIOR = true, PALADIN = true, SHAMAN = true }

local function set(...)
  local out = {}
  for _, id in ipairs({ ... }) do out[id] = true end
  return out
end

-- Weapon subclasses a class can train: 0 one-hand axe, 1 two-hand axe, 2 bow, 3 gun, 4 one-hand mace,
-- 5 two-hand mace, 6 polearm, 7 one-hand sword, 8 two-hand sword, 10 staff, 13 fist, 15 dagger,
-- 16 thrown, 18 crossbow, 19 wand. A class with no list here is never judged.
local WEAPONS = {
  WARRIOR = set(0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 15, 16, 18),
  PALADIN = set(0, 1, 4, 5, 6, 7, 8),
  DEATHKNIGHT = set(0, 1, 4, 5, 6, 7, 8),
  HUNTER = set(0, 1, 2, 3, 6, 7, 8, 10, 13, 15, 16, 18),
  ROGUE = set(0, 2, 3, 4, 7, 13, 15, 16, 18),
  PRIEST = set(4, 10, 15, 19),
  SHAMAN = set(0, 1, 4, 5, 10, 13, 15),
  MAGE = set(7, 10, 15, 19),
  WARLOCK = set(7, 10, 15, 19),
  DRUID = set(4, 5, 6, 10, 13, 15),
}
local JUDGED_WEAPONS = set(0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 15, 16, 18, 19)

-- Whether `class` can never equip the item: true only when certain.
function F.CantEquip(class, itemId)
  if type(class) ~= "string" or type(itemId) ~= "number" then return false end
  local _, _, _, equipLoc, _, classId, subclassId = ns.Try(ns.Fn("C_Item", "GetItemInfoInstant"), itemId)
  if classId == nil then
    _, _, _, equipLoc, _, classId, subclassId = ns.Try(ns.Fn("GetItemInfoInstant"), itemId)
  end
  if type(classId) ~= "number" or type(subclassId) ~= "number" or ns.IsSecret(classId) then return false end
  if classId == ARMOR then
    if subclassId == SHIELD then return MAX_ARMOR[class] ~= nil and not SHIELDS[class] end
    -- A cloak is cloth and everyone wears one; only the body's armour has a weight.
    if equipLoc == "INVTYPE_CLOAK" then return false end
    local max = MAX_ARMOR[class]
    return max ~= nil and subclassId >= 2 and subclassId <= 4 and subclassId > max
  elseif classId == WEAPON then
    local can = WEAPONS[class]
    return can ~= nil and JUDGED_WEAPONS[subclassId] == true and not can[subclassId]
  end
  return false
end

-- The facts for one member of one group: { needs = {...}, fairLoot = {...}, leaves = {...} }, each
-- present only when there is something to say. `run` is Chronicle's (open or closed), or nil.
function F.For(g, m, run)
  local out = {}
  if type(g) ~= "table" or type(m) ~= "table" then return out end
  run = run or G.Run(g.runId)

  local need, cant, passed = 0, 0, 0
  for _, d in ipairs(type(run) == "table" and type(run.drops) == "table" and run.drops or {}) do
    for _, r in ipairs(type(d) == "table" and type(d.rolls) == "table" and d.rolls or {}) do
      if type(r) == "table" and not r.self and G.SameKey(G.Key(r.name), m.key) then
        if r.type == "need" then
          need = need + 1
          if F.CantEquip(m.class or r.class, d.itemId) then cant = cant + 1 end
        elseif r.type == "pass" then
          passed = passed + 1
        end
      end
    end
  end
  if need > 0 then out.needs = { needRolls = need, cantEquip = cant } end
  if passed > 0 then out.fairLoot = { passed = passed } end

  local bosses = run and G.Killed(run) or (g.bosses or 0)
  if bosses > 0 and not m.present and type(m.leftBosses) == "number" and (m.bossesSeen or 0) < bosses then
    out.leaves = { bosses = bosses, bossesSeen = m.bossesSeen or 0 }
  end
  return out
end

-- The facts as one line for a row ("needed 5, can't equip 4 · left after boss 2 of 4"), or "".
function F.Line(facts)
  local parts = {}
  for _, id in ipairs({ "needs", "fairLoot", "leaves" }) do
    local text = ns.Tags.FactText(id, facts[id])
    if text then parts[#parts + 1] = text end
  end
  return table.concat(parts, " · ")
end
