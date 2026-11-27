-- English (enUS): every string Verity by Ryna shows, keyed by the English text itself. `true` means
-- "the text is the key"; ns.L returns the key for anything no locale file translates, so English is
-- always the fallback. The other Locales/*.lua files are templates for translators, generated from
-- this one: after adding, changing or removing a string here, run (from the repository root)
--
--   node tools/strings.mjs --templates
--
-- which rewrites them with the same keys, keeping every translation already in them. Without
-- --templates it only checks that this list matches what the code uses (L["..."] and N("...")).
-- Debug lines (ns.Debug) are English on purpose and are not listed. A key the core addon's
-- Locales/enUS.lua already has isn't repeated here: Verity's L falls back to it.

local _, ns = ...
if ns.off then return end
local L = ns.L

-- Tags.lua
-- The tags a member of a run can be given. They say what happened in groups, never what a person is.
L["Good at their role"] = true
L["Patient and helpful"] = true
L["Led the group well"] = true
L["Versatile"] = true
L["Fair with loot"] = true
L["Needs on gear they can't use"] = true
L["Often inactive in groups"] = true
L["Leaves runs early"] = true
L["Pulls threat off the tank"] = true
-- What Verity counted for a member in a run: Need rolls, and how many of those items their class
-- can never equip.
L["needed %d, can't equip %d"] = true
L["needed %d"] = true
-- Items the member passed on.
L["passed on %d"] = true
-- They left the group early: bosses killed while they were there, of the bosses killed in the run.
L["left after boss %d of %d"] = true

-- Section.lua
-- The section's name in the window's rail and in its title ("Verity › Recent groups").
L["Verity"] = true
-- The three views of the section's picker.
L["Recent groups"] = true
L["This group"] = true
L["Your reports"] = true
-- A member's role in the group.
L["Tank"] = true
L["Healer"] = true
L["Damage"] = true
-- Why a member can't be tagged.
L["can't be tagged: the game didn't say who this is"] = true
L["your own character"] = true
L["more than 7 days ago"] = true
-- In the "Your tags" column of a member with no tag yet.
L["click to tag"] = true
-- A run's heading when its dungeon's name isn't known, and its kills ("Deadmines · 3 days ago · 6 bosses killed").
L["A dungeon"] = true
L["%d boss killed"] = true
L["%d bosses killed"] = true
-- Your reports: how long until a tag is sent, and that it has been.
L["sends in %d min"] = true
L["sent"] = true
-- The two headings of the tag menu.
L["Commend"] = true
L["Report"] = true
L["That tag has been sent, so it can't be taken back. It fades out by itself over 90 days."] = true
L["Tagging needs the game's menus, which this client doesn't have."] = true
-- Column headings.
L["Member"] = true
L["Role"] = true
L["In this run"] = true
L["Your tags"] = true
L["You noted before"] = true
L["Tag"] = true
L["Run"] = true
L["When"] = true
L["State"] = true
-- A member row's tooltip.
L["Click: commend or report."] = true
-- An empty list, by view.
L["You haven't tagged anyone yet."] = true
L["You're not in a group."] = true
L["No groups yet. Run a dungeon with Chronicle recording runs, and its members are listed here."] = true
-- The footer.
L["Your own notes on the people with you. Nothing here is from anyone else."] = true
L["A tag can be taken back for 5 minutes. After that it is sent to Ryna's pool and counts for 90 days."] = true

-- Tooltip.lua
-- On a player's tooltip and in chat when they join: the tags you gave them, with how long ago
-- ("you noted: leaves runs early (3 days ago)").
L["you noted: %s"] = true

-- Init.lua
-- /ryna's help line for the command, and its rows in the minimap button's menu.
L["/ryna verity: tag the people you ran a dungeon with, and see your notes on them"] = true
L["Open Verity"] = true
L["Your notes on player tooltips"] = true
L["A line when someone you tagged joins"] = true
L["Verity needs Ryna's window, which this version of Ryna Core doesn't have."] = true
