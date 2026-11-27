-- Whether Verity loads at all, by the core's API levels (Mod.lua's first lines), with no client but
-- the two things those lines read: the core's table and this addon's TOC field. From the
-- repository root:
--
--   lua5.1 test/level_test.lua
--
-- Verity's TOC asks for level 2. It loads on a core at or above that level which still serves it
-- (Ryna.API_MIN at or below 2, or absent: a core from before API_MIN, 0.5.0), and on nothing else.
local checks, failures = 0, 0
local function eq(got, want, what)
  checks = checks + 1
  if got ~= want then
    failures = failures + 1
    print(string.format("FAIL: %s: got %s, want %s", what, tostring(got), tostring(want)))
  end
end

-- Everything else a mod reaches for on the core as it loads: a thing that answers any field and any
-- call with itself, so the file runs to its end without a client.
local any
any = setmetatable({}, { __index = function() return any end, __call = function() return any end })

local function load(core, level)
  rawset(_G, "Ryna", core and setmetatable(core, { __index = function() return any end }) or nil)
  rawset(_G, "C_AddOns",
    { GetAddOnMetadata = function(_, field) if field == "X-Ryna-API" then return level end end })
  local mod = {}
  assert(loadfile("Ryna_Verity/Mod.lua"))("Ryna_Verity", mod)
  return mod.off
end

local function core(api, min)
  return { API = api, API_MIN = min, RegisterMod = function() return true end,
    Try = function(f, ...) if f then return f(...) end end, L = {} }
end

for _, case in ipairs({
  { have = 1, off = true, what = "a core below the level" },
  { have = 2, off = nil, what = "a core at the level, from before API_MIN" },
  { have = 2, min = 2, off = nil, what = "a core at the level that serves it" },
  { have = 3, min = 2, off = nil, what = "a newer core that still serves the level" },
  { have = 3, min = 3, off = true, what = "a newer core that no longer serves the level" },
}) do
  eq(load(core(case.have, case.min), "2"), case.off, case.what)
end
-- A client that won't say the TOC's level: the mod takes level 1 and is never turned off for age.
eq(load(core(3, 3), nil), nil, "the TOC's level can't be read")
eq(load(nil, "2"), true, "no core at all")

print(string.format("level: %d checks, %d failed", checks, failures))
os.exit(failures == 0 and 0 or 1)
