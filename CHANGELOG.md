# CHANGELOG.md — Leveling Gears

A concise, version-by-version summary of what changed and why it matters to a player or tester.
This file starts at **v0.383** — everything before that point has full detail in `PROGRESS.md`'s
Progress log and the git history, and can be reassembled into earlier changelog entries later if
that's ever useful; it isn't backfilled here now.

For the full investigation behind any fix below (root cause, evidence, validation), see
`bugs/resolved-bugs.md` by bug number. For the day-to-day build narrative, see `PROGRESS.md`.

---

## v0.44 (2026-07-17)

**The `0.4` milestone (`ROADMAP.md`: freeze the schema, build the real data pipeline) is complete
and shipped** — this version number was overdue; the work itself landed gradually across several
unversioned commits on the `data_implementation` branch before this catch-up bump. Merged to `main`.

- **Added: the real data pipeline.** `pipeline/big_data.py --build-database` produces real `Items`/
  `Sources`/`Quests`/`Chains`/`Recipes`/`BySlot` Lua files from the cmangos tbc-db dump (Questie still
  license-blocked, deferred) — 18,711 items, 6,599 quests, 1,108 chains, 900 recipes. These now ship
  as real, committed addon data (`LevelingGears.toc` loads `pipeline/output/*.lua` directly).
- **Added: `Suggestions.lua`, the upgrade-recommendation engine.** For any equipped slot: never a
  downgrade from what's equipped, up to 6 candidates mixing guaranteed category diversity (crafted,
  BOE/AH, nearby quest) with pure score, a dynamic (not fixed) threshold for showing an opposite-
  continent quest source, level and armor-type filtering, a background queue that warms the item
  cache on login/continent-switch/new-equip/spec-change/level-up, and per-character memory of
  previously-found upgrades.
- **Added: `SuggestionsUI.lua`, the recommendation window.** Shift+right-click an equipped item
  (replacing the old score-breakdown popout) to see up to 6 real suggested upgrades — icon, name in
  native quality color, upgrade %, and source (drop/quest/craft/vendor/BOE). Hover a row for the full
  native item tooltip; Refresh re-checks on demand; Settings opens the main settings window alongside
  it.
- Six real bugs found and fixed while building this (`bugs/resolved-bugs.md` #50-#55): a caching
  check that mistook a fully-cached plain-armor item for an uncached one; an armor-type filter with
  no allow-list for non-proficiency values (rings, necks, trinkets, shields, relics); `reqLevel = 0`
  misread as a literal level-0 requirement instead of "no requirement"; the recommendation window's
  position drifting around the screen from an unintended full-body drag zone; identical wording for
  "still loading" and "genuinely no upgrades"; and the window's content not rendering at all (root
  cause not fully isolated — most likely a missing explicit height on a container frame, possibly
  combined with the drag fix above).
- **Known gaps, not yet closed:** no real in-game trigger for the recommendation window besides
  shift+right-click and debug commands (`ROADMAP.md`'s `0.5` tooltip hook); no "next step" to actually
  walk a player to a suggested item (`0.7`); no way to tell a dungeon-boss drop from an overworld one
  yet (a real pipeline gap, not a design choice); recipe reagents and human-readable zone names are
  still empty/absent (client-side DBC data the SQL dump doesn't carry).
- `TEST_PLAN.md` extended with T36-T44 for the new engine/window; `ROADMAP.md` reordered around
  "draw the outline first, color it in after."

## v0.385 (2026-07-16)

Built on the `data_implementation` branch on top of v0.384, pushing toward `ROADMAP.md`'s `0.4`:
two already-built-and-verified pieces (settings window resize, the score popout box) plus two more
fixes from `queue.md`'s remaining test-pass feedback, addressed one at a time and merged back to
`main`.

- **Added:** the settings window is 40% bigger by default and resizable by dragging its bottom-left
  or bottom-right corner (a visible grip texture marks them; top corners are deliberately fixed).
  Found and fixed a real client bug along the way: `SetMinResize`/`SetMaxResize` silently broke the
  rest of the window's load on this client. (Bug #47)
- **Changed:** shift+right-clicking an equipped item (moved off shift+left-click, which now stays
  purely native — "insert item link in chat") opens a small popout box beside it with the score
  breakdown, replacing the old chat-printed output.
- **Fixed:** the "Spec:" dropdown's "Auto-detect" option now actually re-engages talent-point
  detection after a manual spec was picked — it used to silently do nothing, due to a real quirk in
  this client's own dropdown menu API. (Bug #48)
- **Added:** stat weights now enforce a real 0-20 range, rounded to the nearest tenth, with a popup
  explaining exactly why a rejected value (negative, over 20, or non-numeric) didn't stick — instead
  of accepting any number with no warning. (Bug #49)
- Bug ledger: zero open bugs remain in `bugs/known-bugs.md` as of this version.

## v0.384 (2026-07-15)

A second round of fixes, this time addressed one queued item at a time from live testing
(`TEST_RESULTS_Helio_0383.md`) with no version bump in between, then batched together here.

- **Added:** base armor value now factors into item scoring (a small, fixed, non-adjustable nudge —
  real stats still dominate), read via a hidden-tooltip scan since `GetItemStats` never itemizes a
  plain item's base armor. Mainly matters for very early gear, which often has no other clean
  numeric stats to compare by. (Bug #43)
- **Changed:** the minimap button's right-click no longer duplicates left-click's open/close — it's
  now press-and-hold-and-drag to reposition the button around the minimap, with the new position
  saved across reloads. This was `ROADMAP.md`'s planned 0.36 item. (Bug #44)
- **Added:** a per-category debug-log toggle (`/lgs debug window` disables just the window-position
  log channel, independent of the main `/lgs debug` switch). (Bug #45)
- **Added:** a helper-text note explaining why a caster's "Haste Rating" box isn't labeled "Spell
  Haste" — TBC never itemized them separately; the single stat was already being scored correctly
  per class. (Bug #46)
- **Fixed:** a Lua error thrown by the new per-category debug toggle the moment a window-position log
  line fired, caught via a routine debug-log pull before it reached a tester. (Bug #42)
- **Fixed:** "Core stats" overlapping "Restore Defaults" and the note above it — a regression this
  version's own Haste note caused. The layout no longer relies on a hand-guessed pixel offset for
  this (a recurring source of bugs since v0.26); it's now anchored to the button's real position.
  (Bug #41)
- Removed the `/lg`-alias test case from `TEST_PLAN.md` (confirmed permanently fine, no longer worth
  a retest slot every round).
- Bug ledger: zero open bugs remain in `bugs/known-bugs.md` as of this version.

## v0.383 (2026-07-15)

A full round of fixes from live testing (`TEST_RESULTS_Helio_v0382.md`), addressed one at a time and
retested individually before this batch was versioned together.

- **Fixed:** typing a new stat weight and clicking "Save Settings" directly (without pressing Enter
  first) discarded the edit instead of saving it. (Bug #38)
- **Fixed:** window position now saves and restores using two independent absolute screen
  coordinates instead of a single point/offset anchor — the same technique other addons on this
  client use (AceGUI's Window widget). This closes the long-standing "restores close, but not to the
  exact spot" bug. (Bug #29)
- **Fixed:** scoring an item with no clean numeric stats (e.g. a totem) now shows a clear message
  explaining why, instead of a misleading "try again" prompt or — for shift-click — no response at
  all. (Bug #39)
- **Changed:** the "Spec:" selector in the settings window is now a real Blizzard dropdown instead
  of a custom button with a hand-rolled menu, which used to leave a permanent empty gap below it.
  (Bug #40)
- **Changed:** the debug log's ring buffer capacity increased from 500 to 2000 entries, to
  comfortably hold a full test pass's worth of logging without wrapping.
- Bug ledger: zero open bugs remain in `bugs/known-bugs.md` as of this version.
