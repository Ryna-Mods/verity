-- Comms: the run's code, agreed between the Ryna clients in a group over the addon channel (design
-- 7.9, "The run was real"). Each client with Verity makes a code for its run and says it to the
-- group; everyone keeps the smallest code they heard, so they end up with the same one, and writes
-- it to the journal (`verityRun`). The pool calls a run two accounts hold the same code for
-- "witnessed"; a run only the reporter recorded counts half. The rated person needs no Ryna.
--
-- This is the only thing Verity says to other players: one short message, "T:<code>", to the party
-- or raid, never more than once in twenty seconds, never in combat and never while the game has
-- chat locked down. Nothing about anyone is in it. A code is believed only from someone the game
-- stamps as a member of this group (an addon can't forge the sender). Chat is never read.
--
-- Not yet seen in the game: whether a message goes out in combat, or in a raid (design V2). Until
-- then a send that the game refuses is tried again later, and an unwitnessed run still counts.

local _, ns = ...
if ns.off then return end

local C = {}
ns.Comms = C
local G = ns.Group

C.PREFIX = "RynaVerity"
local GAP = 20
local MAX_TOKENS = 4 -- `verityRun` events one run may write
local ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

local lastSent, wanted = 0, false

local function plain(v)
  if v == nil or ns.IsSecret(v) then return nil end
  return v
end

function C.Valid(token)
  return type(token) == "string" and #token >= 8 and #token <= 64 and token:find("^[0-9A-Za-z_%-]+$") ~= nil
end

-- A new code: 20 characters. It only has to differ from the other codes in one group.
function C.NewToken()
  local out = {}
  for i = 1, 20 do
    local n = math.random(1, #ALPHABET)
    out[i] = ALPHABET:sub(n, n)
  end
  return table.concat(out)
end

-- Keep `token` as the run's code and write it to the journal (a few times a run at most).
local function adopt(g, token)
  if g.token == token then return false end
  g.token = token
  g.tokens = (g.tokens or 0) + 1
  local journal = ns.API.Journal
  if g.tokens <= MAX_TOKENS and type(journal) == "table" and type(journal.Add) == "function" then
    journal.Add("verityRun", { token = token }, true)
  end
  return true
end

local function canSend()
  if plain(ns.Try(ns.Fn("IsInGroup"))) ~= true then return false end
  if plain(ns.Try(ns.Fn("InCombatLockdown"))) == true then return false end
  local locked = ns.Try(ns.Fn("C_ChatInfo", "InChatMessagingLockdown"))
  if locked ~= nil and plain(locked) ~= false then return false end
  return true
end

-- Say this run's code to the group, now if the game allows it and it wasn't said just before.
function C.Send()
  local g = G.Current()
  if not g or not C.Valid(g.token) then return false end
  local now = ns.Now()
  if now - lastSent < GAP or not canSend() then
    wanted = true
    return false
  end
  local send = ns.Fn("C_ChatInfo", "SendAddonMessage")
  if not send then return false end
  local channel = plain(ns.Try(ns.Fn("IsInRaid"))) == true and "RAID" or "PARTY"
  wanted, lastSent = false, now
  ns.Try(send, C.PREFIX, "T:" .. g.token, channel)
  return true
end

-- A message on our prefix from `sender`. Returns true when it changed the run's code.
function C.Receive(prefix, text, _, sender)
  if prefix ~= C.PREFIX or plain(text) == nil or plain(sender) == nil then return false end
  if type(text) ~= "string" or type(sender) ~= "string" then return false end
  local token = text:match("^T:(.+)$")
  if not C.Valid(token) then return false end
  local g = G.Current()
  if not g then return false end
  local from = G.Key(sender)
  local member = false
  for key, m in pairs(g.members) do
    if m.present and G.SameKey(key, from) then
      member = true
      break
    end
  end
  if not member then return false end
  if not C.Valid(g.token) or token < g.token then return adopt(g, token) end
  -- They hold a larger code than ours: say ours so they come down to it.
  if token > g.token then C.Send() end
  return false
end

-- After each reading of the group: a run with no code gets one, and a change in who is here says it.
G.OnSync(function(g, joined)
  if not C.Valid(g.own) then g.own = C.NewToken() end
  local fresh = not C.Valid(g.token)
  if fresh then adopt(g, g.own) end
  if fresh or #joined > 0 or wanted then C.Send() end
end)

function C.Register()
  ns.Try(ns.Fn("C_ChatInfo", "RegisterAddonMessagePrefix"), C.PREFIX)
end

ns.On("CHAT_MSG_ADDON", function(_, ...) C.Receive(...) end)
