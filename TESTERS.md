# TESTERS.md — Leveling Gears

Welcome. This project runs its testing the way an engineering team runs a QA pass on a build before
release: a defined scope, a repeatable checklist, and defect reports precise enough that the person
fixing them doesn't have to guess what happened. This document is your onboarding — read it once,
then work from [`TEST_PLAN.md`](TEST_PLAN.md) for every actual test session.

## Reading order

1. [`README.md`](README.md) — what the addon does and how to install it. Read this first if you
   haven't already.
2. **This file** — how testing works here, once.
3. [`TEST_PLAN.md`](TEST_PLAN.md) — before every test session. It changes with every commit: it
   names what changed, what's at risk because of that change, and the full regression checklist for
   the current testing phase. Always pull the latest version before you start.

## Scope: what's actually testable right now

Leveling Gears is early (v0.3). The stat-weighting and scoring engine — the settings window, weight
sliders, profiles, and the equipped-gear outline coloring — is real and testable. The longer-term
"tells you where to get your next upgrade" feature is **not built yet** — there's no item database,
no tooltip integration, no recommendation window. If a roadmap item in `ROADMAP.md` is marked "Not
built," that's expected, not a defect. Only file a report for something that should work today
(per `TEST_PLAN.md`) and doesn't.

## Environment setup

- **Client:** World of Warcraft — TBC Classic Anniversary specifically (the build reporting
  `Interface: 20505`). Other Classic versions or retail are out of scope.
- **Install:** per `README.md`'s Installation section. Confirm `/levelinggears` or `/lgs` opens the
  settings window before starting any test session — if it doesn't, stop and report that first.
- **Turn on Lua error display**, if it isn't already: `/console scriptErrors 1`, or enable "Display
  Lua Errors" in the default UI's AddOns options. Silent failures are the hardest kind to fix —
  we want to see every error, not just the ones that show up as broken behavior.
- **Enable the addon's own debug log** at the start of every session: `/lgs debug`. It's a
  SavedVariables-backed ring buffer (the sandbox has no file access), and `/lgs debug dump` prints
  its recent entries to chat — include the relevant lines in any defect report.
- **Test across more than one class/spec if you can.** The scoring engine's default weights
  (`Priorities.lua`) are authored per class/spec/mode — 9 classes × up to 3 specs × 2 modes.
  Coverage across different characters is more valuable here than repeat runs on one.

## Testing conventions

- **Work from `TEST_PLAN.md`, not ad hoc.** It's the current source of truth for what to test and
  why. If you find something worth testing that isn't on it, test it anyway and mention the gap in
  your report — the checklist gets updated from exactly that kind of feedback.
- **Reproduce before reporting.** If you can't make it happen twice, say so explicitly in the
  report rather than letting it read as a confirmed, repeatable defect.
- **State expected vs. actual, not just actual.** "Clicking + should raise the value by 0.05; it
  raised it by 1" is a report someone can act on immediately. "The button is wrong" is not.
- **A stale display is not the same as lost data.** This project has hit that exact false alarm
  more than once (see `bugs/known-bugs.md` #21/#22) — before reporting "my settings didn't save,"
  reopen the settings window (or `/reload`) and check again before concluding data was actually
  lost.

## Severity levels

| Severity | Meaning | Example |
|---|---|---|
| **Blocker** | Addon fails to load, or breaks another core system | A Lua error on load; the settings window never appears |
| **Critical** | Data loss, corruption, or a wrong result that could mislead a real decision | Weights silently reset; the wrong item gets a green (good) outline when it's actually the worst piece equipped |
| **Major** | A documented feature doesn't work at all | Restore Defaults does nothing; `/lgs score` never prints |
| **Minor** | Works, but incorrectly in a limited way | A stat's default weight looks wrong for one spec; a label shows one extra decimal |
| **Cosmetic** | Visual only, no functional impact | A section slightly overlaps at an unusual window size; a color is a shade off |

## Defect report template

Copy this for each finding. It mirrors `bugs/known-bugs.md`'s own structure so a good report can go
almost straight into the ledger.

```
### [one-line summary]
- Severity: Blocker / Critical / Major / Minor / Cosmetic
- Environment: character class/spec, level, active profile name, addon version (from the window's
  title bar)
- Steps to reproduce:
  1.
  2.
- Expected:
- Actual:
- Reproducible: Yes (every time) / Yes (sometimes) / No (happened once)
- Debug log excerpt (`/lgs debug dump`), if relevant:
- Screenshot, if relevant:
```

## Submitting findings

Submit completed reports the way the project maintainer has asked for them (a shared doc, a GitHub
issue, a message — whichever channel you were given). Don't edit `bugs/known-bugs.md` directly
unless you've been explicitly asked to; it's a living, curated ledger, and someone needs to fold
your report in alongside root-cause analysis, not just append it.
