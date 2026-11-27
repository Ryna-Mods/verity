-- Section: Verity's section of Ryna's window (Ryna.Window.AddSection; design 7.9, "In game first",
-- and the drawing Maddison agreed on 2026-11-27). One section with a picker of views:
--
--   Recent groups   the runs of the last 7 days, each a heading and its members: role, what Verity
--                   counted for them in that run, and the tags you gave. A click on a member opens
--                   the tag menu: tick or untick, two clicks to commend or report
--   This group      who is with you now, and what you noted of them before
--   Your reports    every tag you gave, newest first, and whether it has been sent
--
-- A tick can be taken back for five minutes; after that it is sent and the menu shows it ticked.

local _, ns = ...
if ns.off then return end
local L = ns.L
local G, N, F, T = ns.Group, ns.Notebook, ns.Facts, ns.Tags

local S = {}
ns.Section = S
S.KEY = "verity"

local RW = ns.API.Window
local NOW_VIEW, REPORTS = "group", "reports"
local GOOD, BAD, DIM = "|cff58c26a", "|cffe06c6c", "|cff888888"

local ROLE = { TANK = L["Tank"], HEALER = L["Healer"], DAMAGER = L["Damage"] }

local function viewLabel(v)
  if v == NOW_VIEW then return L["This group"] end
  if v == REPORTS then return L["Your reports"] end
  return L["Recent groups"]
end

local function tagText(id)
  return (T.Kind(id) == "negative" and BAD or GOOD) .. T.Label(id) .. "|r"
end

local BLOCKED = {
  guid = L["can't be tagged: the game didn't say who this is"],
  own = L["your own character"],
  old = L["more than 7 days ago"],
}

-- The "Your tags" cell for a member of a run.
local function tagsCell(g, m)
  local given = {}
  for _, r in ipairs(N.InRun(g, m)) do given[#given + 1] = tagText(r.tag) end
  if #given > 0 then return table.concat(given, ", ") end
  local blocked = N.Blocked(g, m)
  if blocked then return DIM .. BLOCKED[blocked] .. "|r" end
  return DIM .. L["click to tag"] .. "|r"
end

local function memberRow(g, m, run)
  return {
    cells = { tostring(m.name or "?"), ROLE[m.role] or "", F.Line(F.For(g, m, run)), tagsCell(g, m) },
    color = RW.ClassColor(m.class), group = g, member = m,
  }
end

-- Recent groups ---------------------------------------------------------------------------------------

function S.RecentRows(ctx)
  local rows = {}
  for _, g in ipairs(G.Recent()) do
    local run = G.Run(g.runId)
    local members = {}
    for _, m in ipairs(G.Members(g)) do
      if ctx.search == "" or RW.Match(m.name, ctx.search) or RW.Match(g.instance, ctx.search) then
        members[#members + 1] = memberRow(g, m, run)
      end
    end
    if #members > 0 then
      local killed = run and G.Killed(run) or (g.bosses or 0)
      local head = string.format("%s · %s", g.instance or L["A dungeon"], ns.Ago(g.lastAt or g.at) or "")
      if killed > 0 then
        head = head .. " · " .. string.format(killed == 1 and L["%d boss killed"] or L["%d bosses killed"], killed)
      end
      rows[#rows + 1] = { header = true, cells = { head } }
      for _, row in ipairs(members) do rows[#rows + 1] = row end
    end
  end
  return rows
end

-- This group ------------------------------------------------------------------------------------------

-- What you noted of someone before, as one cell: "Leaves runs early (3 days ago), ...".
local function notesCell(guid, key)
  local parts = {}
  for _, r in ipairs(N.About(guid, key)) do
    parts[#parts + 1] = string.format("%s %s(%s)|r", tagText(r.tag), DIM, ns.Ago(r.at) or "")
  end
  return table.concat(parts, ", ")
end

function S.NowRows(ctx)
  local rows = {}
  local g, open = G.Current()
  local run = g and open or nil
  local seen = {}
  if g then
    for _, m in ipairs(G.Members(g)) do
      if m.present and (ctx.search == "" or RW.Match(m.name, ctx.search)) then
        seen[m.key] = true
        local row = memberRow(g, m, run)
        row.cells[3] = notesCell(m.guid, m.key)
        rows[#rows + 1] = row
      end
    end
  end
  -- Outside a run (or before Verity has read it): the group as it is, to read and not to tag.
  for _, r in ipairs(G.Roster()) do
    if not seen[r.key] and (ctx.search == "" or RW.Match(r.name, ctx.search)) then
      rows[#rows + 1] = { cells = { r.name, ROLE[r.role] or "", notesCell(r.guid, r.key), "" },
        color = RW.ClassColor(r.class) }
    end
  end
  return rows
end

-- Your reports ----------------------------------------------------------------------------------------

function S.ReportRows(ctx)
  local rows = {}
  for _, r in ipairs(N.All()) do
    if ctx.search == "" or RW.Match(r.name, ctx.search) or RW.Match(T.Label(r.tag), ctx.search)
      or RW.Match(r.instance, ctx.search) then
      local wait = N.SendsIn(r)
      local state = wait and string.format(L["sends in %d min"], math.ceil(wait / 60)) or L["sent"]
      rows[#rows + 1] = {
        cells = { tostring(r.name or "?"), tagText(r.tag), r.instance or "", ns.Ago(r.at) or "", state },
        sort = { tostring(r.name or ""), T.Label(r.tag), r.instance or "", r.at or 0, wait and 0 or 1 },
        color = RW.ClassColor(r.class), facts = T.FactText(r.tag, r.facts),
      }
    end
  end
  return rows
end

-- The tag menu ----------------------------------------------------------------------------------------

-- A member's menu as rows: { title } or { text, checked(), pick() }. A member who can't be tagged
-- gets the reason and nothing to tick.
function S.MenuRows(g, m)
  local rows = { { title = tostring(m.name or "?") } }
  local blocked = N.Blocked(g, m)
  if blocked and #N.InRun(g, m) == 0 then
    rows[#rows + 1] = { title = BLOCKED[blocked] }
    return rows
  end
  local facts = F.For(g, m)
  local function add(kind, heading)
    rows[#rows + 1] = { title = heading }
    for _, tag in ipairs(T.LIST) do
      if tag.kind == kind then
        local text = tag.label
        local fact = T.FactText(tag.id, facts[tag.id])
        if fact then text = text .. " " .. DIM .. "· " .. fact .. "|r" end
        local had = N.Get(g, m, tag.id)
        if had and had.state ~= "pending" then text = text .. " " .. DIM .. "(" .. L["sent"] .. ")|r" end
        rows[#rows + 1] = {
          text = text, tag = tag.id,
          checked = function() return N.Get(g, m, tag.id) ~= nil end,
          pick = function() S.Pick(g, m, tag.id) end,
        }
      end
    end
  end
  add("positive", L["Commend"])
  add("negative", L["Report"])
  return rows
end

-- A click on a tag in the menu.
function S.Pick(g, m, tag)
  local what, why = N.Toggle(g, m, tag)
  if what == "sent" then
    ns.Print(L["That tag has been sent, so it can't be taken back. It fades out by itself over 90 days."])
  elseif not what and BLOCKED[why] then
    ns.Print(string.format("%s: %s", tostring(m.name or "?"), BLOCKED[why]))
  end
  if type(RW.Refresh) == "function" then RW.Refresh(S.KEY) end
  return what
end

function S.OpenMenu(g, m)
  local open = ns.Fn("MenuUtil", "CreateContextMenu")
  local owner = _G.RynaWindow or _G.UIParent
  local ok = open and owner and pcall(open, owner, function(_, root)
    for _, row in ipairs(S.MenuRows(g, m)) do
      if row.title then
        root:CreateTitle(row.title)
      else
        root:CreateCheckbox(row.text, function() return row.checked() and true or false end, function()
          ns.Run("verity menu", row.pick)
        end)
      end
    end
  end)
  if not ok then ns.Print(L["Tagging needs the game's menus, which this client doesn't have."]) end
  return ok and true or false
end

-- The section -----------------------------------------------------------------------------------------

local RECENT_COLUMNS = {
  { title = L["Member"], width = 170, sort = false }, { title = L["Role"], width = 70, sort = false },
  { title = L["In this run"], width = 180, sort = false }, { title = L["Your tags"], width = 196, sort = false },
}
local NOW_COLUMNS = {
  { title = L["Member"], width = 170, sort = false }, { title = L["Role"], width = 70, sort = false },
  { title = L["You noted before"], width = 250, sort = false }, { title = L["Your tags"], width = 126, sort = false },
}
local REPORT_COLUMNS = {
  { title = L["Member"], width = 170 }, { title = L["Tag"], width = 190 }, { title = L["Run"], width = 120 },
  { title = L["When"], width = 76, justify = "RIGHT" }, { title = L["State"], width = 60, justify = "RIGHT" },
}

function S.Register()
  if S.registered or type(RW) ~= "table" or type(RW.AddSection) ~= "function" then return false end
  S.registered = RW.AddSection({
    key = S.KEY, group = "world", label = L["Verity"], order = 60,
    title = function(ctx) return L["Verity"] .. " › " .. viewLabel(ctx.filter) end,
    characters = "current", sortable = false,
    filter = function()
      return { { value = nil, label = viewLabel(nil) }, { value = NOW_VIEW, label = viewLabel(NOW_VIEW) },
        { value = REPORTS, label = viewLabel(REPORTS) } }
    end,
    columns = function(ctx)
      if ctx.filter == REPORTS then return REPORT_COLUMNS end
      if ctx.filter == NOW_VIEW then return NOW_COLUMNS end
      return RECENT_COLUMNS
    end,
    rows = function(ctx)
      if ctx.filter == REPORTS then return S.ReportRows(ctx) end
      if ctx.filter == NOW_VIEW then return S.NowRows(ctx) end
      return S.RecentRows(ctx)
    end,
    click = function(row)
      if row.group and row.member then S.OpenMenu(row.group, row.member) end
    end,
    tooltip = function(row, tip)
      if row.facts then tip:AddLine(row.facts, 1, 1, 1, true) end
      if row.group and row.member then
        local line = F.Line(F.For(row.group, row.member))
        if line ~= "" then tip:AddLine(line, 1, 1, 1, true) end
        tip:AddLine(L["Click: commend or report."], 0.6, 0.6, 0.6, true)
      end
    end,
    version = function() return G.version * 100000 + N.version end,
    empty = function(ctx)
      if ctx.filter == REPORTS then return L["You haven't tagged anyone yet."] end
      if ctx.filter == NOW_VIEW then return L["You're not in a group."] end
      return L["No groups yet. Run a dungeon with Chronicle recording runs, and its members are listed here."]
    end,
    footer = function(ctx)
      if ctx.filter == NOW_VIEW then
        return L["Your own notes on the people with you. Nothing here is from anyone else."]
      end
      return L["A tag can be taken back for 5 minutes. After that it is sent to Ryna's pool and counts for 90 days."]
    end,
  }) and true or false
  return S.registered
end
