-- Verity against a stand-in for the core's mod API and the client: who is kept for a run and who
-- left it early (Group.lua), the facts from Chronicle's run (Facts.lua), the notebook and the
-- journal event it writes (Notebook.lua), the run's code (Comms.lua), and the rows, menu and words
-- (Section.lua, Tooltip.lua). From the repository root, with Lua 5.1 (what the game runs) or later:
--
--   lua5.1 test/verity_test.lua
-- luacheck: ignore 1
-- luacheck: no max line length

local ADDON = "Ryna_Verity/"
local failures, checks = 0, 0
local function check(cond, what)
  checks = checks + 1
  if not cond then
    failures = failures + 1
    print("FAIL: " .. what)
  end
end

local DAY = 86400
local now = 1800000000
local ME = "Player-91-00000001"
local db = { characters = { [ME] = {}, ["Player-91-000000AA"] = {} }, chronicle = { runs = {} }, journal = {} }
local handlers, commands, printed, after, settings = {}, {}, {}, {}, {}
local section, refreshed, opened = nil, 0, nil

-- The client: a party, an instance, and what it lets an addon send.
local party, inside, inCombat, locked, sentMessages, inRaid = {}, true, false, false, {}, false
local items = {
  [100] = { "INVTYPE_CHEST", 4, 4 }, -- plate chest
  [101] = { "INVTYPE_WEAPON", 2, 7 }, -- one-hand sword
  [102] = { "INVTYPE_CLOAK", 4, 1 }, -- a cloak
  [103] = { "INVTYPE_SHIELD", 4, 6 }, -- a shield
  [104] = { "INVTYPE_2HWEAPON", 2, 10 }, -- a staff
}
local client = {
  UnitGUID = function(unit)
    if unit == "player" then return ME end
    local i = tonumber(tostring(unit):match("^party(%d)$"))
    return i and party[i] and party[i].guid or nil
  end,
  UnitFullName = function() return "Maddiep", "Ryna" end,
  UnitName = function(unit)
    local i = tonumber(tostring(unit):match("^party(%d)$"))
    if i and party[i] then return party[i].name, party[i].realm end
  end,
  UnitExists = function(unit)
    local i = tonumber(tostring(unit):match("^party(%d)$"))
    return i ~= nil and party[i] ~= nil
  end,
  UnitIsUnit = function() return false end,
  UnitClass = function(unit)
    local i = tonumber(tostring(unit):match("^party(%d)$"))
    if i and party[i] then return party[i].class, party[i].class end
  end,
  UnitGroupRolesAssigned = function(unit)
    local i = tonumber(tostring(unit):match("^party(%d)$"))
    return i and party[i] and party[i].role or "NONE"
  end,
  IsInRaid = function() return inRaid end,
  IsInGroup = function() return #party > 0 end,
  IsInInstance = function() return inside, inside and "party" or "none" end,
  InCombatLockdown = function() return inCombat end,
  ["C_Item.GetItemInfoInstant"] = function(id)
    local it = items[id]
    if it then return id, "", "", it[1], 0, it[2], it[3] end
  end,
  ["C_ChatInfo.InChatMessagingLockdown"] = function() return locked end,
  ["C_ChatInfo.SendAddonMessage"] = function(prefix, text, channel)
    sentMessages[#sentMessages + 1] = { prefix = prefix, text = text, channel = channel }
    return 0
  end,
  ["C_ChatInfo.RegisterAddonMessagePrefix"] = function(prefix) _G.registeredPrefix = prefix return 0 end,
}

local function passResults(ok, ...)
  if ok then return ... end
  return nil
end

_G.Ryna = {
  API = 2, VERSION = "test", L = setmetatable({}, { __index = function(_, k) return k end }),
  Try = function(fn, ...)
    if type(fn) ~= "function" then return nil end
    return passResults(pcall(fn, ...))
  end,
  Fn = function(a, b) return client[b and (a .. "." .. b) or a] end,
  IsSecret = function() return false end,
  NonEmpty = function(v) if type(v) == "string" and v ~= "" then return v end end,
  Now = function() return now end,
  Print = function(m) printed[#printed + 1] = m end,
  Debug = function() end,
  Run = function(_, fn, ...) return fn(...) end,
  Debounce = function(_, _, fn) fn() end,
  After = function(delay, _, fn) after[#after + 1] = { delay = delay, fn = fn } end,
  On = function(event, f)
    handlers[event] = handlers[event] or {}
    table.insert(handlers[event], f)
  end,
  Ago = function(t)
    if type(t) ~= "number" then return nil end
    return string.format("%d days ago", math.floor((now - t) / DAY))
  end,
  DB = function() return db end,
  RegisterMod = function(spec) _G.registered = spec return true end,
  Journal = {
    Add = function(eventType, fields)
      local e = { type = eventType, at = now, char = ME }
      for k, v in pairs(fields or {}) do e[k] = v end
      db.journal[#db.journal + 1] = e
      return e
    end,
  },
  Settings = {
    AddDefaults = function(d) for k, v in pairs(d) do if settings[k] == nil then settings[k] = v end end end,
    Get = function(k) return settings[k] end,
    Set = function(k, v) settings[k] = v end,
  },
  Slash = { Add = function(spec) commands[spec.word] = spec end },
  Tooltip = { AddLine = function(tip, text) tip.lines[#tip.lines + 1] = text return true end },
  Window = {
    AddSection = function(spec) section = spec return true end,
    ClassColor = function(class) return "|c" .. tostring(class) .. ":" end,
    Match = function(text, search)
      if search == "" then return true end
      return type(text) == "string" and text:lower():find(search, 1, true) ~= nil
    end,
    Open = function(key) opened = key end,
    Refresh = function() refreshed = refreshed + 1 end,
  },
}
_G.C_AddOns = { GetAddOnMetadata = function(_, key) return key == "X-Ryna-API" and "2" or "0.1.0" end }

local ns = {}
for _, file in ipairs({ "Mod.lua", "Locales/enUS.lua", "Tags.lua", "Group.lua", "Facts.lua", "Notebook.lua",
  "Comms.lua", "Section.lua", "Tooltip.lua", "Init.lua" }) do
  assert(loadfile(ADDON .. file))("Ryna_Verity", ns)
end
local G, F, N, C, S, T, Tt = ns.Group, ns.Facts, ns.Notebook, ns.Comms, ns.Section, ns.Tags, ns.Tooltip
check(not ns.off and _G.registered and _G.registered.id == "verity", "Verity registers as a mod")
check(section and section.key == "verity" and section.group == "world", "and adds one section to the window")
check(#T.LIST == 9 and T.Kind("needs") == "negative" and T.Kind("fairLoot") == "positive", "the nine tags, by kind")

-- Names ------------------------------------------------------------------------------------------------
check(G.Key("Sam-Hammiche") == "samhammiche" and G.Key("Sam Hammiche") == "samhammiche", "a name is keyed without its separator")
check(G.Key("") == nil and G.Key(nil) == nil, "and nothing has no key")
check(G.SameKey("brakkusryna", "brakkus") and not G.SameKey("brakkusryna", "brak"),
  "a name without its realm is the same person on the player's realm, and a prefix is not")

-- A run, and who was in it. ----------------------------------------------------------------------------
local function boss(ok) return { encounterId = 1, name = "b", success = ok } end
local run = { id = "1800000000-36", mapId = 36, instance = "Deadmines", bosses = {}, drops = {} }
db.chronicle.runs[ME] = { open = run, list = {} }
party = {
  { guid = "Player-91-0000000B", name = "Brakkus", class = "MAGE", role = "DAMAGER" },
  { guid = "Player-91-0000000C", name = "Lumiel", realm = "Hammiche", class = "PRIEST", role = "HEALER" },
  { guid = "Player-91-0000000D", name = "Torvin", class = "WARRIOR", role = "TANK" },
  { guid = nil, name = "Sashi", class = "ROGUE", role = "DAMAGER" },
}
local g = G.Sync()
check(g and g.runId == run.id and g.instance == "Deadmines" and g.char == ME, "the open run gets a group")
check(g.members.brakkusryna and g.members.brakkusryna.guid == "Player-91-0000000B"
  and g.members.brakkusryna.name == "Brakkus-Ryna", "a member on the player's realm is kept with it")
check(g.members.lumielhammiche and g.members.lumielhammiche.role == "HEALER", "and one from another realm with theirs")
check(g.members.sashiryna and g.members.sashiryna.guid == nil, "a member whose GUID the game withheld is kept by name")
check(#db.verity.groups == 1 and G.Sync() == g and #db.verity.groups == 1, "a second reading is the same group")

-- Two bosses with everyone, then the tank leaves, then two more.
run.bosses = { boss(true), boss(false), boss(true) }
G.Sync()
check(g.bosses == 2 and g.members.torvinryna.bossesSeen == 2, "a kill counts for whoever was there; a wipe doesn't")
table.remove(party, 3)
G.Sync()
check(g.members.torvinryna.present == false and g.members.torvinryna.leftBosses == 2, "a member who is gone is marked, with the kills so far")
run.bosses[#run.bosses + 1] = boss(true)
run.bosses[#run.bosses + 1] = boss(true)
G.Sync()
check(g.bosses == 4 and g.members.torvinryna.bossesSeen == 2 and g.members.brakkusryna.bossesSeen == 4,
  "later kills count only for those still there")

-- Outside, the next group is not written onto this run.
inside = false
party[#party + 1] = { guid = "Player-91-0000000E", name = "Stranger", class = "DRUID" }
G.Sync()
check(g.members.strangerryna == nil, "someone met outside is never added to the run")
table.remove(party)
inside = true

-- The facts. -------------------------------------------------------------------------------------------
check(F.CantEquip("MAGE", 100) and not F.CantEquip("WARRIOR", 100), "plate on a mage can't be equipped; on a warrior it can")
check(not F.CantEquip("MAGE", 101) and F.CantEquip("PRIEST", 101), "a sword: a mage can, a priest can't")
check(not F.CantEquip("MAGE", 102), "a cloak is never counted, whatever it is made of")
check(F.CantEquip("ROGUE", 103) and not F.CantEquip("SHAMAN", 103), "a shield, by class")
check(not F.CantEquip("MONK", 104) and not F.CantEquip("MAGE", 999) and not F.CantEquip(nil, 100),
  "a class or an item nobody can describe is never counted")
run.drops = {
  { key = 1, itemId = 100, rolls = { { name = "Brakkus", class = "MAGE", type = "need" },
    { name = "Lumiel Hammiche", class = "PRIEST", type = "pass" }, { name = "Maddiep", type = "need", self = true } } },
  { key = 2, itemId = 104, rolls = { { name = "Brakkus", class = "MAGE", type = "need" },
    { name = "Lumiel Hammiche", class = "PRIEST", type = "pass" } } },
  { key = 3, itemId = 101, rolls = { { name = "Brakkus", class = "MAGE", type = "greed" } } },
}
local facts = F.For(g, g.members.brakkusryna)
check(facts.needs and facts.needs.needRolls == 2 and facts.needs.cantEquip == 1, "Need rolls, and those the class can't equip")
check(facts.leaves == nil and facts.fairLoot == nil, "and nothing else is said of someone who stayed and passed on nothing")
facts = F.For(g, g.members.lumielhammiche)
check(facts.fairLoot and facts.fairLoot.passed == 2 and facts.needs == nil, "passes, matched through the roll's spaced name")
facts = F.For(g, g.members.torvinryna)
check(facts.leaves and facts.leaves.bosses == 4 and facts.leaves.bossesSeen == 2, "leaving early: kills seen of kills")
check(F.Line(F.For(g, g.members.brakkusryna)) == "needed 2, can't equip 1", "the facts as a row's words")
check(T.FactText("leaves", facts.leaves) == "left after boss 2 of 4", "and for a member who left")

-- The notebook. ----------------------------------------------------------------------------------------
local brak, sashi = g.members.brakkusryna, g.members.sashiryna
check(N.Blocked(g, brak) == nil and N.Blocked(g, sashi) == "guid", "a member with no GUID can't be tagged")
check(N.Blocked(g, { key = "alt", guid = "Player-91-000000AA" }) == "own", "nor one of this account's own characters")
check(N.Toggle(g, brak, "nonsense") == nil, "a tag that isn't on the list is refused")
check(N.Toggle(g, brak, "needs") == "added" and #db.verity.reports == 1, "a tick writes a pending report")
check(db.verity.reports[1].state == "pending" and db.verity.reports[1].facts.needRolls == 2, "with its facts")
check(#after > 0 and after[#after].delay == N.HOLD + 1, "and a send is scheduled after the hold")
check(N.Flush(false) == 0 and #db.journal == (function()
  local n = 0
  for _, e in ipairs(db.journal) do if e.type == "verityRun" then n = n + 1 end end
  return n
end)(), "nothing is sent inside the hold")
check(N.Toggle(g, brak, "needs") == "removed" and #db.verity.reports == 0, "unticking inside the hold removes it: never sent")
N.Toggle(g, brak, "needs")
N.Toggle(g, g.members.lumielhammiche, "fairLoot")
now = now + N.HOLD + 5
check(N.Flush(false) == 2, "past the hold both are sent")
local event
for _, e in ipairs(db.journal) do if e.type == "verity" and e.tag == "needs" then event = e end end
check(event and event.runId == run.id and event.member.guid == "Player-91-0000000B"
  and event.member.fullName == "Brakkus-Ryna" and event.member.class == "MAGE"
  and event.facts.needRolls == 2 and event.facts.cantEquip == 1 and event.token == g.token,
  "the journal event is the wire's: run, member, tag, facts and the run's code")
check(N.Toggle(g, brak, "needs") == "sent" and #db.verity.reports == 2, "a sent tag can't be taken back")
N.Toggle(g, g.members.torvinryna, "leaves")
check(_G.registered.onLogout() == nil and db.verity.reports[3].state == "sent", "logging out sends what is pending")
check(#N.About("Player-91-0000000B", nil) == 1 and N.About(nil, "brakkus")[1].tag == "needs", "what you noted of someone, by GUID or name")

-- The run's code. --------------------------------------------------------------------------------------
check(C.Valid(g.token) and g.token == g.own, "a run gets a code of its own")
check(C.Valid("abcDEF12") and not C.Valid("short") and not C.Valid("has space1") and not C.Valid(string.rep("a", 65)),
  "a code is 8 to 64 of the wire's characters")
local runTokens = 0
for _, e in ipairs(db.journal) do if e.type == "verityRun" then runTokens = runTokens + 1 end end
check(runTokens == 1 and sentMessages[1] and sentMessages[1].prefix == "RynaVerity"
  and sentMessages[1].text == "T:" .. g.token and sentMessages[1].channel == "PARTY",
  "it is written to the journal once and said to the party")
check(C.Receive("RynaVerity", "T:00000000smaller", "PARTY", "Stranger Ryna") == false, "a code from someone outside the group is ignored")
check(C.Receive("Other", "T:00000000smaller", "PARTY", "Brakkus Ryna") == false, "and so is another addon's prefix")
check(C.Receive("RynaVerity", "T:bad code!", "PARTY", "Brakkus Ryna") == false, "and a malformed code")
check(C.Receive("RynaVerity", "T:00000000smaller", "PARTY", "Brakkus Ryna") == true and g.token == "00000000smaller",
  "a smaller code from a member (the sender written with a space) is taken")
runTokens = 0
for _, e in ipairs(db.journal) do if e.type == "verityRun" then runTokens = runTokens + 1 end end
check(runTokens == 2, "and written to the journal")
local before = #sentMessages
now = now + 60
check(C.Receive("RynaVerity", "T:zzzzzzzzlarger", "PARTY", "Lumiel Hammiche") == false and g.token == "00000000smaller"
  and #sentMessages == before + 1, "a larger one is not, and ours is said back")
inCombat = true
now = now + 60
check(C.Send() == false and #sentMessages == before + 1, "nothing is said in combat")
inCombat, locked = false, true
check(C.Send() == false and #sentMessages == before + 1, "nor while the game has chat locked down")
locked = false
check(C.Send() == true and C.Send() == false, "and never twice in twenty seconds")

-- The section. -----------------------------------------------------------------------------------------
local ctx = { search = "", filter = nil }
local rows = section.rows(ctx)
check(rows[1].header and rows[1].cells[1]:find("Deadmines", 1, true) and rows[1].cells[1]:find("4 bosses killed", 1, true),
  "Recent groups: a heading for the run")
check(#rows == 5 and rows[2].cells[1] == "Brakkus-Ryna" and rows[2].cells[2] == "Damage"
  and rows[2].cells[3] == "needed 2, can't equip 1" and rows[2].cells[4]:find("Needs on gear", 1, true),
  "then a row a member: role, facts and your tags")
check(rows[4].cells[4]:find("didn't say who", 1, true) ~= nil, "a member who can't be tagged says why")
check(#section.rows({ search = "lumiel", filter = nil }) == 2, "the search narrows the members")
local menu = S.MenuRows(g, brak)
local ticked, sentWord = 0, false
for _, r in ipairs(menu) do
  if r.checked and r.checked() then ticked = ticked + 1 end
  if r.tag == "needs" and r.text:find("sent", 1, true) and r.text:find("needed 2", 1, true) then sentWord = true end
end
check(menu[1].title == "Brakkus-Ryna" and menu[2].title == "Commend" and #menu == 12 and ticked == 1 and sentWord,
  "the menu: the member, two headings, nine tags, the sent one ticked with its facts")
check(#S.MenuRows(g, sashi) == 2, "a member who can't be tagged has no tags to tick")
local was = refreshed
check(S.Pick(g, brak, "role") == "added" and refreshed == was + 1, "a pick ticks the tag and redraws the section")
check(S.Pick(g, brak, "needs") == "sent" and printed[#printed]:find("can't be taken back", 1, true), "picking a sent one says why nothing changed")
rows = section.rows({ search = "", filter = "reports" })
check(#rows == 4 and rows[1].cells[2]:find("Good at their role", 1, true) and rows[1].cells[5] == "sends in 5 min"
  and rows[2].cells[5] == "sent", "Your reports: newest first, with whether each was sent")
rows = section.rows({ search = "", filter = "group" })
check(#rows == 3 and rows[1].cells[3]:find("Needs on gear", 1, true), "This group: who is here, and what you noted before")
check(type(section.footer(ctx)) == "string" and type(section.empty(ctx)) == "string", "a footer and an empty line")

-- The tooltip and the join line. -----------------------------------------------------------------------
check(Tt.Line("Player-91-0000000B") == "Ryna · you noted: good at their role (0 days ago), needs on gear they can't use (0 days ago)",
  "a player's tooltip line: your two newest tags")
check(Tt.Line("Player-91-00000099") == nil and Tt.Line("Creature-0-1") == nil, "and nothing for someone you never tagged, or a creature")
check(Tt.JoinLine(brak) ~= nil and Tt.JoinLine(brak) == nil, "the join line is said once a member")
settings.verityJoinLine = false
check(Tt.JoinLine(g.members.lumielhammiche) == nil, "and not at all with its setting off")
commands.verity.run("joins")
check(settings.verityJoinLine == true, "/ryna verity joins flips the setting")
commands.verity.run()
check(opened == "verity", "/ryna verity opens the section")

-- Seven days on. ---------------------------------------------------------------------------------------
now = now + 7 * DAY + 60
check(N.Blocked(g, g.members.lumielhammiche) == "old", "a run older than seven days can't be tagged")
now = now + 2 * DAY
check(#G.Recent() == 0, "and after eight it leaves Recent groups")
now = now + 90 * DAY
N.Prune()
check(#db.verity.reports == 0, "a report is dropped when the pool stops counting it")

print(string.format("verity: %d checks, %d failed", checks, failures))
os.exit(failures == 0 and 0 or 1)
