# CLAUDE.md — Leveling Gears

Living project memory, kept deliberately small. Detail lives in the files below — read whichever
one the current task actually needs, not all of them, every time.

## Read when relevant

| File | Read it when... |
|---|---|
| [`README.md`](README.md) | you need the one-paragraph pitch, install steps, or slash-command list |
| [`ROADMAP.md`](ROADMAP.md) | proposing or starting the next step, or asked "what's next" |
| [`PROGRESS.md`](PROGRESS.md) | you need history: what's built, why a past decision was made, or before writing a new progress entry |
| [`CHANGELOG.md`](CHANGELOG.md) | you need a concise, version-by-version summary of what changed (starts at v0.383 — see `PROGRESS.md`/git log for anything earlier) |
| [`CONVENTIONS.md`](CONVENTIONS.md) | before writing or editing any code — coding rules, WoW/Lua sandbox limits, process rules, versioning ladder, technical reference notes |
| [`DESIGN.md`](DESIGN.md) | touching `Conversions.lua`/`Priorities.lua`/`Scoring.lua`/`Weights.lua` — the scoring engine's architecture and every judgment call behind it |
| [`DATA_PIPELINE.md`](DATA_PIPELINE.md) | working on the 0.41–0.44 data pipeline steps — exact source URLs, license status, file structure, and parser design |
| [`bugs/known-bugs.md`](bugs/known-bugs.md) | investigating or recording a bug — still-open bugs only |
| [`bugs/resolved-bugs.md`](bugs/resolved-bugs.md) | recording a fix once a bug is Solved/Mitigated, or — especially — when troubleshooting a difficult bug: the same root cause (a stale forward-declaration, an undebounced event, a client API returning an unexpected shape) has recurred before, and a past entry's investigation technique is often the fastest way in |
| [`TEST_PLAN.md`](TEST_PLAN.md) | before AND after every commit — what changed, what's at risk, and the full regression checklist; keep it current. Also the file testers fill in and email back (see its Quick start) |
| [`TESTERS.md`](TESTERS.md) | optional extra context for testers — not required reading, don't over-invest here |

Never build past the current step before first receiving beta testing feedback from the previous one — see
`CONVENTIONS.md`'s "Hard process rules for Claude Code."

## Current step

**Now on the `data_implementation` branch — the push to `ROADMAP.md`'s `0.4` has begun.** Testing
Phase 1's gate is considered cleared as of v0.384 (remaining `queue.md` items are minor polish, not
Blocker/Critical/Major — see `ROADMAP.md`'s "Testing Phase 1 follow-ups" section). This branch stays
separate from `main` until it tests well, per direct instruction.

Built so far: `pipeline/` (Python 3 standard library only, no pip packages) now runs the real
extraction end-to-end via `big_data.py --build-database` — `extract_items.py`/`extract_loot.py`/
`extract_vendor.py`/`extract_quests.py`/`extract_recipes.py`, tied together by `build_database.py`,
on top of `sql_extract.py` (a hand-rolled mysqldump row streamer) and `lua_writer.py` (Python->Lua
serializer). A real run produced 18,711 Items, 6,599 Quests, 1,108 Chains, 900 Recipes, and a merged
Sources table, all written to `pipeline/output/*.lua`. **Questie is intentionally excluded** — its
source license is still unresolved, and the author is resolving that directly before any code
touches that source.

Real findings from that run (see `ROADMAP.md`'s `0.41-0.44` entry for full detail): quest pickup/
turn-in coordinates work with **no Questie dependency** at all (cmangos's own `creature`/
`gameobject` + questrelation tables are enough); `spell_template` ships **completely empty** in this
dump, so recipe reagents/created-items stay empty until a different source is found; `zone` is a
numeric map id, not a real zone name; and shared loot-pool reference groups blew `Sources.lua` up to
162MB, collapsed to one representative creature per item for now (down to 16MB) — the real fix is
the new `ROADMAP.md` `0.46`, a data-curation phase explicitly scheduled after the addon otherwise
works, before Alpha, not attempted now. Also added `ROADMAP.md`'s `0.45`: an Auction House BOE
scanner, a client-side in-game Lua feature (not a `big_data.py` step).

**Next step:** the addon's own Lua code needs to start consuming `pipeline/output/*.lua` (or a
hand-made subset per `ROADMAP.md`'s `0.4`) to actually become useful — "draw the outline, then fill
it in" per direct instruction: get the addon working end-to-end against what's real now, before
chasing more data sources (spell reagents, Questie, the 0.46 curation pass).

`ROADMAP.md`'s "Starting to actually use the database" section lays out the concrete order. First
two items are **Built and verified live**, one piece at a time:
- **Settings window resize**: 40% bigger default (588x462), resizable by dragging the bottom two
  corners (top corners disabled per direct instruction), a visible grip texture instead of a cursor
  swap (no installed addon on this client uses a resize-specific `SetCursor` name). Real bug found
  and fixed along the way: `SetMinResize`/`SetMaxResize` silently broke the rest of `UI.lua`'s load
  on this client — see `bugs/resolved-bugs.md` #47.
- **Popout box**: shift+right-click (moved off shift+left-click, which already means something to
  players) an equipped item opens `UI.ShowScorePopout` beside it — the score breakdown that used to
  print to chat, now closable via its own X or a click-away catcher frame. This is `0.5`'s
  flyout-frame concept, built for real.

Still ahead, per direct instruction **not version-numbered yet** — versions get assigned once each
piece actually ships, not planned in advance: continent-aware querying (scope suggestions to the
player's own continent first), then actually suggesting upgrades from the pipeline's real data.

See `DATA_PIPELINE.md`'s Status note and `pipeline/README.md` for details.

---

**Previous milestone: v0.384 — six more items from the v0.383 test pass's own follow-up notes.**
Same process as every cycle before it: each item was built and individually retested with no version
bump in between (see `queue.md` for the working list), then batched into this one real version:
- **Bug #43 (Solved):** low-level gear with no clean numeric stats scored a dead, indistinguishable
  0 — `GetItemStats` never itemizes a plain item's base armor. Added a hidden-tooltip scan
  (`Scoring.ScanItemArmorValue`) and folded it in as a small, fixed, non-adjustable weight, so real
  stats still dominate everywhere except very early gear.
- **Bug #44 (Solved):** minimap right-click was a redundant copy of left-click; repurposed as
  press-and-hold-and-drag to reposition the button around the minimap (this was `ROADMAP.md`'s
  planned 0.36, now Built).
- **Bug #45 (Solved):** added a per-category debug-log toggle (`/lgs debug window`) so one noisy
  channel can be silenced without touching the main `/lgs debug` switch.
- **Bug #46 (Solved, clarification):** added a helper note explaining why a caster's "Haste Rating"
  box isn't labeled "Spell Haste" (TBC never itemized them separately — the scoring was already
  correct). Also audited every class/spec table in `Priorities.lua` for a broader "Mage defaults
  look weird" report — found no anomalies; a live nonzero Expertise reading is more likely a stale
  saved weight than a table bug, left for the tester to confirm via "Restore Defaults."
- **Bug #42 (Solved):** the Haste note above caused a real regression (a Lua error indexing
  `debugCategories` before it reliably existed) — caught via a routine debug-log pull within minutes
  of shipping, not a tester report. Made the category functions defensive.
- **Bug #41 (Solved):** "Core stats" overlapped "Restore Defaults" — the third wrong guess in a row
  for that section's hand-guessed starting offset (bug #25's `-134`, 0.37's `-160`, this cycle's
  `-195`). Fixed for good by anchoring to `restoreDefaultsButton:GetBottom()` directly instead of
  guessing a fourth number — this removes the whole recurring bug class, not just this instance.
- One attempted fix was **rolled back** on direct instruction: the excess blank space at the bottom
  of the settings window (still open) — a rewritten height formula was judged to look worse in
  practice than the old hardcoded-760px one, so the old formula is back. Needs a different approach
  next time, not the same fix again.

See `bugs/resolved-bugs.md` #41-#46 for full investigation detail, and `CHANGELOG.md` for the short
version.

This is a **bug-fix → test → ship cycle** the author asked to set up and repeat until the addon is
ready for `ROADMAP.md`'s `0.4` (freeze the item/quest schema, start the real database). Builds on
0.31 (single weight set per character, direct-entry stat editing, analytically-derived `Priorities.
lua` defaults — see `PROGRESS.md`'s Current status and `bugs/resolved-bugs.md` #31-#35), 0.311-0.313
(research gaps closed, debug log ring buffer bumped, a gear-evaluation debounce gap fixed — see
`bugs/resolved-bugs.md` #36), and 0.38 (the versioning-ladder slots 0.31-0.38 are documented in
`CONVENTIONS.md`; the next free two-decimal slot is 0.39). 0.381-0.384 are thousandths bugfix
patches on 0.38, not new sub-features.

**`bugs/known-bugs.md` still has zero open bugs.** (The rolled-back blank-space item and the
still-unconfirmed Expertise question live in `queue.md`, not the bug ledger, since neither is a
confirmed defect yet.) A v0.384 retest (T22b-T35, extra attention on T8/T10/T13) can still happen
whenever convenient, but it's no longer the gate blocking `0.4` — see "Current step" above.

**Exit criterion for this cycle:** once a full T1-T35 pass comes back with no unresolved Blocker/
Critical/Major findings (`TESTERS.md`'s severity scale), move to `ROADMAP.md`'s `0.4` — not before.
Until then, whatever the pass finds becomes the next cycle's patch list: fix with real evidence (add
diagnostic logging first if the cause isn't obvious, or compare against how another installed addon
solves the same problem, same as this cycle's bugs), re-validate, and — per direct instruction — do
NOT re-version or do a full doc pass after every individual fix; batch it all into one version bump
once a meaningful round of testing is done, the same way this version was assembled.

Testers (including the author, for their own runs) email completed checklists to
`wegatherinthesun@gmail.com` per `TEST_PLAN.md`'s own Quick start — or report results directly if
that's more practical.

How to handle a completed test report is a standing rule — see `CONVENTIONS.md`'s Hard process
rules.

**When troubleshooting a difficult or hard-to-pin-down bug, check `bugs/resolved-bugs.md` before
guessing at a fix.** This project's history repeats root causes more often than it invents new
ones — a stale forward-declaration, a client API returning an unexpected type/shape, an
undebounced event handler, a client-specific slot/API quirk — and a past entry often already
contains the exact investigation technique (most notably: reading the on-disk debug log directly
rather than reasoning from code alone) that cracked a similar-looking problem before.

After finishing any step: update `PROGRESS.md` and the bug ledger before considering the task
done — `bugs/known-bugs.md` while a bug is still open, moved to `bugs/resolved-bugs.md` (same bug
number) the moment it's Solved or Mitigated with nothing further to do — see `CONVENTIONS.md`'s
Mandatory maintenance rules.
