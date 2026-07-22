# TESTERS.md — Leveling Gears

**You probably don't need this file.** `TEST_PLAN.md`'s "Quick start" at the top has everything
required to test and submit your results: save the file, fill it in, email it back. This document
is optional extra context — read it if you want to understand why things are set up this way, or if
you want to give a more detailed report on something that went wrong. Nothing here is required
reading.

## Scope: what's actually testable right now

Leveling Gears is early (v0.44). The stat-weighting and scoring engine
— the settings window, direct-entry stat weights (one set per character), and the equipped-gear
outline coloring — is real and testable. A first real upgrade-recommendation engine and window are
now real and testable too: shift+right-click an equipped item to see up to 6 real suggested upgrades
for that slot (`TEST_PLAN.md`'s T36-T44). What's still **not built yet**: a real in-game entry point
for that window other than shift+right-click (the planned tooltip hook), and the "next step" that
walks you to actually go get a suggested item (quest chains, crafting, TomTom waypoints). If a
roadmap item in `ROADMAP.md` is marked "Not built," that's expected, not a defect. Only note
something as a problem if it should work today (per `TEST_PLAN.md`) and doesn't.

## Environment notes

- **Client:** World of Warcraft — TBC Classic Anniversary specifically (the build reporting
  `Interface: 20505`). Other Classic versions or retail are out of scope.
- **Install:** per `README.md`'s Installation section. Confirm `/levelinggears` or `/lgs` opens the
  settings window before starting — if it doesn't, that's worth noting right away.
- **Test across more than one class/spec if you can.** The scoring engine's default weights
  (`Priorities.lua`) are analytically derived per class/spec/mode from real TBC combat formulas —
  9 classes × up to 3 specs × 2 modes, each with its own real per-spec details (see `DESIGN.md`).
  Coverage across different characters is more valuable here than repeat runs on one. (`TEST_PLAN.md`
  already asks for this on the specific test case where it matters most.)

## A few things worth knowing

- **Reproduce before calling something a solid failure.** If it only happened once and you couldn't
  make it happen again, say so in your notes rather than stating it as a sure thing.
- **Say what you expected vs. what actually happened**, not just what happened. "I typed 8 into
  Attack Power's box and pressed Enter; it showed 5 instead" is something that can be acted on
  immediately. "The box is wrong" isn't.
- **A stale display is not the same as lost data.** This project has hit that exact false alarm more
  than once (see `bugs/resolved-bugs.md` #21/#22) — before deciding "my settings didn't save," reopen
  the settings window (or `/reload`) and check again first.

## Severity levels (optional — only if you want to rate how bad something is)

| Severity | Meaning | Example |
|---|---|---|
| **Blocker** | Addon fails to load, or breaks another core system | A Lua error on load; the settings window never appears |
| **Critical** | Data loss, corruption, or a wrong result that could mislead a real decision | Weights silently reset; the wrong item gets a green (good) outline when it's actually the worst piece equipped |
| **Major** | A documented feature doesn't work at all | Restore Defaults does nothing; `/lgs score` never prints |
| **Minor** | Works, but incorrectly in a limited way | A stat's default weight looks wrong for one spec; a label shows one extra decimal |
| **Cosmetic** | Visual only, no functional impact | A section slightly overlaps at an unusual window size; a color is a shade off |

## Giving extra detail on something serious (optional)

For most things, a plain-language note on the relevant `TEST_PLAN.md` test case is enough — what you
did, what you expected, what actually happened. If something feels Blocker/Critical/Major and you
want to give more detail than fits in that one line, add this alongside your notes for that test
case (in the same email, or as a second attachment):

```
### [one-line summary]
- Severity: Blocker / Critical / Major / Minor / Cosmetic
- Environment: character class/spec, level, addon version (from the window's title bar)
- Steps to reproduce:
  1.
  2.
- Expected:
- Actual:
- Reproducible: Yes (every time) / Yes (sometimes) / No (happened once)
- Debug log: easiest way is `/lgs report` — it opens a window with your version, character, and the
  whole debug log already assembled and selected, ready to paste here. (`/lgs debug` then
  `/lgs debug dump` still works if you'd rather read it in chat.)
- Screenshot, if relevant:
```

## Submitting

Covered in `TEST_PLAN.md`'s Quick start: rename the completed file and email it to
**wegatherinthesun@gmail.com**. Nothing else to set up — no accounts, no separate tool.

If the addon throws a Lua error while you're testing, it will offer you a report window once per
session — take it, copy the text, and paste it into your email. You can also open that window any
time with **`/lgs report`** or the "Copy report for developer" button in the settings window. It
never sends anything on its own (WoW addons can't); it just spares you scraping the log out of chat
by hand.
