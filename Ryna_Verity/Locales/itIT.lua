-- Italian (itIT) strings for Verity by Ryna. Loaded on every client, applied only when the game
-- runs in itIT: GetLocale() is "itIT".
--
-- How to translate:
--   - Each line is L["English"] = nil. Replace nil with your text in double quotes:
--       L["Take part in the census"] = "..."
--     A line left as nil shows the English, so a partial translation is fine.
--   - Keep every %s and %d, in the same order (WoW's string.format can't reorder them).
--   - Keep "||" as it is: it prints one "|" in chat. Inside a command (/ryna debug on||off||toggle,
--     /who, /reload) keep the words in English: they are what the player types.
--   - Plurals: a pair like "%d player" / "%d players" is used for 1 / everything else.
--     For a language with more forms, use the wording that reads best for most numbers.
--   - Keys are the English text and must stay exactly as they are; only change the values.
--   - Test: set the client's language (Battle.net -> Settings -> Game Settings -> Text Language,
--     or SET textLocale "itIT" in WTF/Config.wtf, with that language installed), log in, then
--     /ryna, /ryna status and /ryna help.
-- This file is generated from enUS.lua by cores/wow/addon/tools/strings.mjs --templates, which keeps the
-- translations already here; run it after enUS.lua changes.

local _, ns = ...
if ns.off then return end
if ns.Locale() ~= "itIT" then return end
local L = ns.L

-- Tags.lua
-- The tags a member of a run can be given. They say what happened in groups, never what a person is.
L["Good at their role"] = nil
L["Patient and helpful"] = nil
L["Led the group well"] = nil
L["Versatile"] = nil
L["Fair with loot"] = nil
L["Needs on gear they can't use"] = nil
L["Often inactive in groups"] = nil
L["Leaves runs early"] = nil
L["Pulls threat off the tank"] = nil
-- What Verity counted for a member in a run: Need rolls, and how many of those items their class
-- can never equip.
L["needed %d, can't equip %d"] = nil
L["needed %d"] = nil
-- Items the member passed on.
L["passed on %d"] = nil
-- They left the group early: bosses killed while they were there, of the bosses killed in the run.
L["left after boss %d of %d"] = nil

-- Section.lua
-- The section's name in the window's rail and in its title ("Verity › Recent groups").
L["Verity"] = nil
-- The three views of the section's picker.
L["Recent groups"] = nil
L["This group"] = nil
L["Your reports"] = nil
-- A member's role in the group.
L["Tank"] = nil
L["Healer"] = nil
L["Damage"] = nil
-- Why a member can't be tagged.
L["can't be tagged: the game didn't say who this is"] = nil
L["your own character"] = nil
L["more than 7 days ago"] = nil
-- In the "Your tags" column of a member with no tag yet.
L["click to tag"] = nil
-- A run's heading when its dungeon's name isn't known, and its kills ("Deadmines · 3 days ago · 6 bosses killed").
L["A dungeon"] = nil
L["%d boss killed"] = nil
L["%d bosses killed"] = nil
-- Your reports: how long until a tag is sent, and that it has been.
L["sends in %d min"] = nil
L["sent"] = nil
-- The two headings of the tag menu.
L["Commend"] = nil
L["Report"] = nil
L["That tag has been sent, so it can't be taken back. It fades out by itself over 90 days."] = nil
L["Tagging needs the game's menus, which this client doesn't have."] = nil
-- Column headings.
L["Member"] = nil
L["Role"] = nil
L["In this run"] = nil
L["Your tags"] = nil
L["You noted before"] = nil
L["Tag"] = nil
L["Run"] = nil
L["When"] = nil
L["State"] = nil
-- A member row's tooltip.
L["Click: commend or report."] = nil
-- An empty list, by view.
L["You haven't tagged anyone yet."] = nil
L["You're not in a group."] = nil
L["No groups yet. Run a dungeon with Chronicle recording runs, and its members are listed here."] = nil
-- The footer.
L["Your own notes on the people with you. Nothing here is from anyone else."] = nil
L["A tag can be taken back for 5 minutes. After that it is sent to Ryna's pool and counts for 90 days."] = nil

-- Tooltip.lua
-- On a player's tooltip and in chat when they join: the tags you gave them, with how long ago
-- ("you noted: leaves runs early (3 days ago)").
L["you noted: %s"] = nil

-- Init.lua
-- /ryna's help line for the command, and its rows in the minimap button's menu.
L["/ryna verity: tag the people you ran a dungeon with, and see your notes on them"] = nil
L["Open Verity"] = nil
L["Your notes on player tooltips"] = nil
L["A line when someone you tagged joins"] = nil
L["Verity needs Ryna's window, which this version of Ryna Core doesn't have."] = nil
