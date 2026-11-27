-- Group: who was in the group for each dungeon or raid run, kept so a member can be tagged for up to
-- seven days after (design 7.9). Chronicle records the run itself (RynaDB.chronicle.runs); Verity
-- reads the open run's id and bosses from there and keeps its own record beside it:
--
--   RynaDB.verity.groups = { <one per run, oldest first> }
--   a group  = { runId, instance, at (first seen), lastAt, char (the reporter's GUID), bosses (killed
--               so far), token, own (this client's code, Comms.lua), members = { [key] = member } }
--   a member = { key, name ("Name-Realm"), guid (when the client gave it plainly), class, role,
--               present (in the group at the last reading), bossesSeen (kills they were there for),
--               leftBosses (the kill count when they were first found gone; nil once back) }
--
-- A member is keyed by their name with the separator dropped (Group.Key): the game writes one
-- person "Sam-Hammiche", "Sam Hammiche" or plain "Sam" in different places. The GUID is what a
-- report needs, and is filled in whenever the client hands it over plainly (inside an instance it
-- may not): a member with no GUID is listed and can't be tagged.
--
-- New members are taken only while inside the instance, so the group the player joins next,
-- outside, is never written onto the last run. Kept for 8 days, the newest 40. Silent.

local _, ns = ...
if ns.off then return end

local G = {}
ns.Group = G
G.version = 0

local KEEP_SECONDS = 8 * 86400
local KEEP = 40
local MAX_MEMBERS = 40

local function plain(v)
  if v == nil or ns.IsSecret(v) then return nil end
  return v
end

local function str(v)
  v = plain(v)
  if type(v) == "string" and v ~= "" then return v end
  return nil
end

-- A name as a key: lower case, with spaces, hyphens and apostrophes dropped.
function G.Key(name)
  if type(name) ~= "string" or name == "" then return nil end
  local key = name:lower():gsub("[%s%-']", "")
  if key == "" then return nil end
  return key
end

-- Whether two keys are the same person: equal, or one is the other without its realm (a roll on the
-- player's own realm is written with the name alone).
function G.SameKey(a, b)
  if type(a) ~= "string" or type(b) ~= "string" then return false end
  if a == b then return true end
  local long, short = a, b
  if #long < #short then long, short = short, long end
  if G.realmKey == nil then G.MyRealm() end
  return #short >= 2 and long:sub(1, #short) == short and G.realmKey ~= nil and long:sub(#short + 1) == G.realmKey
end

function G.MyGuid()
  return str(ns.Try(ns.Fn("UnitGUID"), "player"))
end

function G.MyRealm()
  local _, realm = ns.Try(ns.Fn("UnitFullName"), "player")
  realm = str(realm) or str(ns.Try(ns.Fn("GetNormalizedRealmName")))
  G.realmKey = G.Key(realm)
  return realm
end

-- Verity's own table in the saved data, made on first use.
function G.Store()
  local db = ns.API.DB()
  if type(db) ~= "table" then return nil end
  if type(db.verity) ~= "table" then db.verity = {} end
  local v = db.verity
  if type(v.groups) ~= "table" then v.groups = {} end
  if type(v.reports) ~= "table" then v.reports = {} end
  return v
end

-- This character's runs as Chronicle keeps them ({ open, list }), or nil.
function G.Runs(guid)
  local db = ns.API.DB()
  local c = type(db) == "table" and db.chronicle
  local runs = type(c) == "table" and type(c.runs) == "table" and c.runs[guid or G.MyGuid()]
  if type(runs) == "table" then return runs end
  return nil
end

-- A run by its id, among every character's (open or closed), or nil.
function G.Run(runId)
  local db = ns.API.DB()
  local c = type(db) == "table" and db.chronicle
  if type(c) ~= "table" or type(c.runs) ~= "table" or runId == nil then return nil end
  for _, runs in pairs(c.runs) do
    if type(runs) == "table" then
      if type(runs.open) == "table" and runs.open.id == runId then return runs.open end
      for _, r in ipairs(type(runs.list) == "table" and runs.list or {}) do
        if type(r) == "table" and r.id == runId then return r end
      end
    end
  end
  return nil
end

function G.Killed(run)
  local n = 0
  for _, b in ipairs(type(run) == "table" and type(run.bosses) == "table" and run.bosses or {}) do
    if type(b) == "table" and b.success then n = n + 1 end
  end
  return n
end

-- The other members of the group as the client gives them now: { { key, name, guid, class, role } }.
function G.Roster()
  local realm = G.MyRealm()
  local raid = plain(ns.Try(ns.Fn("IsInRaid"))) == true
  local exists, isUnit = ns.Fn("UnitExists"), ns.Fn("UnitIsUnit")
  local out = {}
  for i = 1, raid and 40 or 4 do
    local unit = (raid and "raid" or "party") .. i
    if exists and plain(ns.Try(exists, unit)) == true and plain(ns.Try(isUnit, unit, "player")) ~= true
      and #out < MAX_MEMBERS then
      local name, theirs = ns.Try(ns.Fn("UnitName"), unit)
      name, theirs = str(name), str(theirs) or realm
      local full = name and (theirs and (name .. "-" .. theirs) or name)
      local key = G.Key(full)
      if key then
        local _, class = ns.Try(ns.Fn("UnitClass"), unit)
        local role = str(ns.Try(ns.Fn("UnitGroupRolesAssigned"), unit))
        if role == "NONE" then role = nil end
        local guid = str(ns.Try(ns.Fn("UnitGUID"), unit))
        if guid and not guid:find("^Player%-") then guid = nil end
        out[#out + 1] = { key = key, name = full, guid = guid, class = str(class), role = role }
      end
    end
  end
  return out
end

function G.Inside()
  local inside, kind = ns.Try(ns.Fn("IsInInstance"))
  inside, kind = plain(inside), plain(kind)
  return inside == true and (kind == "party" or kind == "raid")
end

-- The record for a run, or nil.
function G.Find(runId)
  local v = G.Store()
  if not v or runId == nil then return nil end
  for i = #v.groups, 1, -1 do
    if type(v.groups[i]) == "table" and v.groups[i].runId == runId then return v.groups[i] end
  end
  return nil
end

-- The open run's record, or nil when there is no open run (or none was made for it).
function G.Current()
  local runs = G.Runs()
  local open = runs and type(runs.open) == "table" and runs.open
  if not open or type(open.id) ~= "string" then return nil end
  return G.Find(open.id), open
end

local function prune(v, now)
  local kept = {}
  for _, g in ipairs(v.groups) do
    if type(g) == "table" and type(g.at) == "number" and now - (g.lastAt or g.at) <= KEEP_SECONDS then
      kept[#kept + 1] = g
    end
  end
  while #kept > KEEP do table.remove(kept, 1) end
  v.groups = kept
end

local listeners = {}
-- fn(group, joined): after a reading, with the members seen for the first time in this run.
function G.OnSync(fn)
  listeners[#listeners + 1] = fn
end

-- Read the group against the open run. Called (debounced) on the roster, zone and encounter events.
function G.Sync()
  local v = G.Store()
  local runs = G.Runs()
  local open = runs and type(runs.open) == "table" and runs.open
  if not v or not open or type(open.id) ~= "string" then return nil end
  local now = ns.Now()
  local inside = G.Inside()
  local g = G.Find(open.id)
  if not g then
    if not inside then return nil end
    prune(v, now)
    g = { runId = open.id, instance = type(open.instance) == "string" and open.instance or nil, at = now,
      char = G.MyGuid(), bosses = 0, members = {} }
    v.groups[#v.groups + 1] = g
  end
  g.lastAt = now

  -- A kill since the last reading counts for whoever was there at that reading.
  local killed = G.Killed(open)
  local delta = killed - (g.bosses or 0)
  if delta > 0 then
    for _, m in pairs(g.members) do
      if m.present then m.bossesSeen = (m.bossesSeen or 0) + delta end
    end
  end
  g.bosses = killed

  local here, joined = {}, {}
  for _, r in ipairs(G.Roster()) do
    here[r.key] = true
    local m = g.members[r.key]
    if not m and inside then
      m = { key = r.key, name = r.name, bossesSeen = 0 }
      g.members[r.key] = m
      joined[#joined + 1] = m
    end
    if m then
      m.present, m.leftBosses = true, nil
      m.guid = r.guid or m.guid
      m.class = r.class or m.class
      m.role = r.role or m.role
    end
  end
  for key, m in pairs(g.members) do
    if not here[key] and m.present then
      m.present = false
      m.leftBosses = g.bosses
    end
  end
  G.version = G.version + 1
  for i = 1, #listeners do ns.Run("verity group", listeners[i], g, joined) end
  return g
end

-- The runs with a group, newest first.
function G.Recent()
  local v = G.Store()
  local out = {}
  if not v then return out end
  local now = ns.Now()
  for i = #v.groups, 1, -1 do
    local g = v.groups[i]
    if type(g) == "table" and type(g.members) == "table" and now - (g.lastAt or g.at or 0) <= KEEP_SECONDS then
      out[#out + 1] = g
    end
  end
  return out
end

-- A group's members in a steady order: by name.
function G.Members(g)
  local out = {}
  for _, m in pairs(type(g) == "table" and type(g.members) == "table" and g.members or {}) do
    if type(m) == "table" then out[#out + 1] = m end
  end
  table.sort(out, function(a, b) return tostring(a.name) < tostring(b.name) end)
  return out
end

local function queue()
  ns.Debounce("verity-sync", 1, function() ns.Run("verity sync", G.Sync) end)
end

for _, event in ipairs({ "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ENCOUNTER_END",
  "PLAYER_REGEN_ENABLED" }) do
  ns.On(event, queue)
end
