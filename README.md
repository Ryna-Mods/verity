# Verity by Ryna

A mod of [Ryna](https://github.com/Ryna-Mods/ryna) for World of Warcraft: Forever. What a group
says of the people it played with: `/ryna verity`.

After a dungeon or raid run, each member of the group can be tagged from a fixed list. There is no
free text anywhere.

| Commend | Report |
|---|---|
| Good at their role | Needs on gear they can't use |
| Patient and helpful | Often inactive in groups |
| Led the group well | Leaves runs early |
| Versatile | Pulls threat off the tank |
| Fair with loot | |

- **Recent groups**: the runs of the last seven days, each with its members, what Verity counted
  for them in that run, and the tags you gave. Click a member to tick or untick a tag.
- **This group**: who is with you now, and what you noted of them before.
- **Your reports**: every tag you gave, and whether it has been sent.
- **On a player's tooltip**: your own notes on them. A line in chat says the same once when
  someone you tagged joins your group, never in combat. Both can be turned off from the Ryna
  minimap button's menu (`/ryna verity tooltips`, `/ryna verity joins`).

A person picks a tag; the numbers never do. What Verity counts goes along as evidence, and in this
version that is three things: Need rolls on items the member's class can never equip, items they
passed on, and bosses killed after they left. "Can't equip" is said only when it is certain.

## What leaves your computer

This mod is the one part of Ryna that keeps and sends a record about another player by name, so
here is all of it.

- **To the other players in your group**: one short message on the addon channel, a random code
  for the run (`T:` and 20 letters and digits). Nothing about anyone is in it. Ryna clients in a
  group agree on one code, so Ryna's pool can tell a run two people recorded from one only the
  reporter did. It is never sent in combat, and at most once in twenty seconds.
- **To ryna.io, through the Ryna app, when you tag someone**: the run, the member's character
  (its GUID, name and class), the tag, and the counts for that tag. Your tick can be taken back
  for five minutes; after that it is sent. A sent tag can't be withdrawn, and it fades out of the
  pool by itself: full weight for 30 days, gone at 90.
- **Never**: anything said in chat, where anyone stood on a damage meter, or free text.

Without the Ryna app nothing is sent to ryna.io; your tags stay in your saved file
(`RynaDB.verity`) for 90 days.

In the pool a tag shows as its words and how sure it is (unconfirmed, likely or confirmed) to
people signed in to Ryna, never on the open internet. Who sent a tag is shown to nobody. The counts
behind it are shown only to the character's own player, 47 hours after they arrive. One run, however
many of its group report, can make a tag likely and never confirmed.

The pool's tags don't come back into the game yet: in this version a tooltip shows only what you
noted yourself.

## Installing

Verity needs **Ryna Core** (the folder `Ryna_Core`), 0.5.1 or newer, and **Chronicle by Ryna** with
"record dungeon runs" on: Chronicle records the run and its loot rolls, and Verity reads them.
Unzip `Ryna_Verity-<version>.zip` from this repository's releases into `Interface/AddOns` beside
them. With the Ryna app, turn Verity on in Mods.

## Working on it

`Ryna_Verity/` is the addon:

- `Tags.lua`: the fixed list of tags and their words.
- `Group.lua`: who was in the group for each run, and who left when.
- `Facts.lua`: what is counted for a member, and the table of what a class can never equip.
- `Notebook.lua`: your tags, the five minute hold, and the journal event that is sent.
- `Comms.lua`: the run's code and the one addon message.
- `Section.lua`, `Tooltip.lua`: the section of Ryna's window, the tag menu, the tooltip and join lines.
- `Mod.lua`, `Init.lua`: the namespace and API-level gate, the `/ryna verity` command and the
  registration with the core.

`scripts/check.sh` runs everything CI does: luacheck, a Lua 5.1 parse of every file, the strings
check, and the tests in `test/` against a stand-in for the core's mod API and the client.

MIT licensed.
