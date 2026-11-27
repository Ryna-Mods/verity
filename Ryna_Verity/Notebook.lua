-- Notebook: the tags this player gave, and sending them (design 7.9, "A report, and what makes it
-- count"; the wire is the API's docs/wow.md 22.1).
--
--   RynaDB.verity.reports = { { runId, key, guid, name, class, tag, at, facts, token, instance,
--                               state = "pending" | "sent", sentAt }, ... }   oldest first
--
-- A tag is one member, one run, one tag. Ticking it writes a pending report; for five minutes it
-- can be unticked and nothing was ever sent. After that (or at logout, whichever is first) it is
-- written to the journal as a `verity` event, which the Ryna app uploads to the pool, and it can't
-- be taken back: the pool has no removal, and its weight fades out by itself over 90 days.
--
-- What may be tagged: a member whose GUID the game gave plainly (a name alone is never reported),
-- who isn't one of this account's own characters, in a run from the last seven days. Kept for 90
-- days, as long as the pool counts it. Silent.

local _, ns = ...
if ns.off then return end

local N = {}
ns.Notebook = N
N.version = 0
local G = ns.Group

N.HOLD = 300 -- seconds a tick can be taken back
N.WINDOW = 7 * 86400 -- how long after a run a member can be tagged
local KEEP_SECONDS = 90 * 86400
local MAX_REPORTS = 2000

local function reports()
  local v = G.Store()
  return v and v.reports or nil
end

-- Why this member can't be tagged ("guid", "own", "old"), or nil when they can.
function N.Blocked(g, m)
  if type(g) ~= "table" or type(m) ~= "table" then return "guid" end
  if type(m.guid) ~= "string" or not m.guid:find("^Player%-") then return "guid" end
  local db = ns.API.DB()
  if type(db) == "table" and type(db.characters) == "table" and db.characters[m.guid] ~= nil then return "own" end
  if ns.Now() - (g.lastAt or g.at or 0) > N.WINDOW then return "old" end
  return nil
end

local function find(list, runId, key, tag)
  for i, r in ipairs(list) do
    if type(r) == "table" and r.runId == runId and r.key == key and r.tag == tag then return r, i end
  end
  return nil
end

-- The report for a member, a run and a tag, or nil.
function N.Get(g, m, tag)
  local list = reports()
  if not list or type(g) ~= "table" or type(m) ~= "table" then return nil end
  return (find(list, g.runId, m.key, tag))
end

-- Tick or untick a tag. Returns "added", "removed", "sent" (already sent: nothing changes) or
-- nil and why it can't be given.
function N.Toggle(g, m, tag)
  local list = reports()
  if not list or not ns.Tags.BY_ID[tag] then return nil, "tag" end
  local had, at = find(list, g.runId, m.key, tag)
  if had then
    if had.state ~= "pending" then return "sent" end
    table.remove(list, at)
    N.version = N.version + 1
    return "removed"
  end
  local blocked = N.Blocked(g, m)
  if blocked then return nil, blocked end
  local facts = ns.Facts.For(g, m)[tag]
  list[#list + 1] = { runId = g.runId, key = m.key, guid = m.guid, name = m.name, class = m.class, tag = tag,
    at = ns.Now(), facts = facts, token = g.token, instance = g.instance, state = "pending" }
  N.version = N.version + 1
  ns.After(N.HOLD + 1, "verity send", function() N.Flush(false) end)
  return "added"
end

-- Write the pending reports that are past their hold (every one, with `all`) to the journal.
-- Returns how many were sent.
function N.Flush(all)
  local list = reports()
  local journal = ns.API.Journal
  if not list or type(journal) ~= "table" or type(journal.Add) ~= "function" then return 0 end
  local now, sent = ns.Now(), 0
  for _, r in ipairs(list) do
    if type(r) == "table" and r.state == "pending" and (all or now - (r.at or 0) >= N.HOLD) then
      local g = G.Find(r.runId)
      local e = journal.Add("verity", {
        runId = r.runId, token = (g and g.token) or r.token,
        member = { guid = r.guid, fullName = r.name, class = r.class },
        tag = r.tag, facts = r.facts,
      }, true)
      if e then
        r.state, r.sentAt = "sent", now
        sent = sent + 1
      end
    end
  end
  if sent > 0 then N.version = N.version + 1 end
  return sent
end

-- Seconds until a pending report is sent, or nil when it has been.
function N.SendsIn(r)
  if type(r) ~= "table" or r.state ~= "pending" then return nil end
  return math.max(0, N.HOLD - (ns.Now() - (r.at or 0)))
end

-- Drop what is older than the pool keeps it.
function N.Prune()
  local v = G.Store()
  if not v then return end
  local now, kept = ns.Now(), {}
  for _, r in ipairs(v.reports) do
    if type(r) == "table" and type(r.at) == "number" and now - r.at <= KEEP_SECONDS then kept[#kept + 1] = r end
  end
  while #kept > MAX_REPORTS do table.remove(kept, 1) end
  v.reports = kept
end

-- Every report, newest first.
function N.All()
  local out = {}
  local list = reports() or {}
  for i = #list, 1, -1 do
    if type(list[i]) == "table" then out[#out + 1] = list[i] end
  end
  return out
end

-- This player's reports about one person (by GUID, else by name key), newest first, one per tag.
function N.About(guid, key)
  local out, seen = {}, {}
  for _, r in ipairs(N.All()) do
    local same = (guid ~= nil and r.guid == guid) or (key ~= nil and G.SameKey(r.key, key))
    if same and not seen[r.tag] then
      seen[r.tag] = true
      out[#out + 1] = r
    end
  end
  return out
end

-- The tags given to a member in one run, in the menu's order.
function N.InRun(g, m)
  local out = {}
  for _, tag in ipairs(ns.Tags.LIST) do
    local r = N.Get(g, m, tag.id)
    if r then out[#out + 1] = r end
  end
  return out
end
