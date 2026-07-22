# PACKAGING.md — the ship / no-ship manifest

This is `queue.md` Q6's deliverable: the authoritative list of what does and does not go into the
**player build**, and the mechanism options (Curse *and* non-Curse) for producing the split. Two
builds come out of one source tree:

- **Tester build** — the raw repo (debug markers active). The whole debug suite is available. This is
  a *separate download* for testers; it also includes `TEST_PLAN.md` / `TESTERS.md`.
- **Player build** — a packaged release: dev/tester code stripped, dev files excluded. Its **only**
  diagnostic surface is the error report (`/lgs report`, the "Copy report for developer" settings
  button, and the once-per-session auto-offer on a caught Lua error).

**Keep this file current.** Per `WORKFLOW.md`'s "Build debug in as you go," every new debug category,
test-only command, or dev file is added here in the same breath it's created. This file is itself
no-ship (see below).

---

## Mechanism: annotate once, package many ways

We are nowhere near shipping — this section only needs to leave us **prepared and not locked into any
one vendor**, not committed today. The principle: annotate the source in plain text (no tool required
to *read* it), then let any of several packaging backends — Curse or not — act on it. Decide the
exact backend at packaging time.

### The annotations (toolchain-agnostic — this is the durable part)

1. **In-file code stripping — `--@debug@` markers.** Wrap each no-ship command branch and no-ship
   function so it is active in the raw source (tester build) and removed for the player build.

   ```lua
   --@debug@
   -- dev/tester-only code here: active in source, stripped from the player release
   --@end-debug@
   ```

   These happen to be the CurseForge / BigWigs packager tokens — verified in use on this very client
   (AceGUI-3.0-SharedMediaWidgets `prototypes.lua`; PallyPower/ShamanPower's bundled
   `LibUIDropDownMenu` `.toc` files) — **but they are only Lua comments.** Nothing Curse-specific:
   any script that can match the tokens can strip the block. Keeping them means we're ready for a
   Curse packager *and* a local script, without choosing yet. (The inverse
   `--[===[@non-debug@ ... --@end-non-debug@]===]` marks code inactive in source and on only in the
   release — not expected here yet.)

2. **A file-exclusion list** (docs, linter config, pipeline build tooling — enumerated in NO-SHIP
   below). Just a list; expressed differently per backend.

### Packaging backends (all consume the same annotations — pick when the time comes)

**Non-Curse options (no account, no vendor toolchain) — the intended path for now:**

1. **Local strip script (recommended).** A ~30–50 line Python/bash script: copy the tree, delete
   `--@debug@…--@end-debug@` blocks by regex, drop the excluded files, zip it. Zero dependencies,
   runs offline, fully under our control. Because the markers are standard, this stays trivially
   swappable for the Curse packager later with no source changes.
2. **`git archive` + `.gitattributes export-ignore`.** Mark dev-only files with `export-ignore` in
   `.gitattributes`; `git archive` then emits a zip that omits them — pure git, no extra tooling.
   Covers the *file-exclusion* half; pair it with the strip script or the dev-`.toc` split for the
   *code* half.
3. **Whole-file separation via the `.toc` (no stripping at all).** Move the no-ship command
   registrations/handlers into dedicated dev-only file(s) (e.g. `DevCommands.lua`) and simply omit
   them from the player `.toc`; the tester `.toc` lists them. Cleanest for anything that can be filed
   on its own — the cost is refactoring interleaved dev code (the `HandleSlashCommand` branches,
   `Scoring.PrintBreakdown`, `Suggestions.PrintSuggestions`) out of shared files. Combines with
   markers for the bits that can't be cleanly moved.
4. **Runtime dev flag (zero build step, fallback only).** A single `LG.DEV_BUILD` constant gates
   registration of dev commands; flip it off for the player build. No packaging step at all — but the
   dev code physically ships (inert, not removed), so it does **not** satisfy "actually clean it out."
   Keep as the last-resort fallback, not the goal.

**Curse/Wago option (only if we later choose to publish there):**

5. **The `BigWigsMods/packager` script** — consumes the same `--@debug@` markers plus a `.pkgmeta`
   `ignore:` list, and can also upload to CurseForge / Wago / WoWInterface / GitHub releases.
   Adopting the markers now keeps this available without locking us in.

**Recommendation for now:** keep the `--@debug@` markers + a plain file-exclusion list as the durable
source annotation, and plan to produce the player build with the **local strip script (1)** and/or
**`git archive` (2)** — no Curse dependency — while staying trivially able to switch to the Curse
packager (5) later. Two artifacts either way: tester build = raw repo; player build = the backend's
output.

Dead code (see below) is simply **deleted outright**, independent of the build split.

---

## SHIP — the player build keeps these

**Files (the addon itself):**
- `LevelingGears.toc`
- Loaded Lua: `Debug.lua`, `Conversions.lua`, `Priorities.lua`, `Scoring.lua`, `Settings.lua`,
  `Weights.lua`, `GearEvaluation.lua`, `Suggestions.lua`, `UI.lua`, `SuggestionsUI.lua`, `Core.lua`
- Baked data: `pipeline/output/{Items,Sources,Quests,Chains,Recipes,BySlot}.lua`

**Slash commands (player-facing):**
- `/lgs` / `/levelinggears` (no arg) → open the settings window (`UI.ToggleLevelingGears`)
- `/lgs report` → the copy-ready developer report (`Debug.BuildReportText` + `UI.ShowReportWindow`)

**Subroutines the player build needs (do NOT wrap in `--@debug@`):**
- `Debug.PrintChat`, `Debug.SafeCall` (error safety + the report auto-offer)
- `Debug.WriteDebugLog` and its readers `Debug.IsDebugEnabled` / `Debug.GetDebugLevel` /
  `Debug.IsCategoryEnabled` — **buffer logging stays on in the player build**: it is exactly what
  gives the error report useful content. Only the *chat echo* and the toggle/dump commands are
  stripped (see below); the buffer keeps filling silently.
- `Debug.BuildReportText`
- `UI.ShowReportWindow` / `EnsureReportWindow`, the "Copy report for developer" button, and
  `StaticPopupDialogs["LEVELINGGEARS_ERROR_REPORT"]`
- The `WriteDebugLog(..., "report")` instrumentation calls (cheap; feed the report buffer)

---

## NO-SHIP — stripped from the player build (`--@debug@`)

**Slash commands (dev/tester only):**
| Command | Handler chain |
|---|---|
| `/lgs score <link>` | `HandleScoreCommand` → `Scoring.PrintBreakdown` |
| `/lgs suggest <slot>` | `Suggestions.PrintSuggestions` |
| `/lgs suggestwindow <slot>` | `SuggestionsUI.Show` *(the window ships; players reach it via shift+right-click — only this debug trigger command is stripped)* |
| `/lgs testerror` | forced `error()` through `SafeCall` |
| `/lgs debug` / `/lgs debug <level>` | `Debug.ToggleDebugMode` → `Debug.SetDebugEnabled` (chat-echo toggle) |
| `/lgs debug dump` | `Debug.DumpDebugLog` |
| `/lgs debug <category>` | `Debug.ToggleCategory` → `Debug.SetCategoryEnabled` |

**Subroutines reachable only via the commands above (wrap in `--@debug@`):**
- `Core.lua` — the `score` / `suggest` / `suggestwindow` / `testerror` / `debug*` dispatch branches
  in `HandleSlashCommand`, and the local `HandleScoreCommand`
- `Scoring.lua` — `Scoring.PrintBreakdown` (only `/lgs score` calls it)
- `Suggestions.lua` — `Suggestions.PrintSuggestions` (only `/lgs suggest`)
- `Debug.lua` — `DumpDebugLog`, `SetDebugEnabled`, `ToggleDebugMode`, `SetCategoryEnabled`,
  `ToggleCategory` (the `/lgs debug` family). *Leave the `WriteDebugLog` readers listed under SHIP.*

**Dead code — delete outright (not just strip):**
- `UI.lua` — `UI.ShowScorePopout`, `EnsureScorePopoutFrames`, and the `scorePopout*` locals /
  `MAX_SCORE_POPOUT_LINES`. Superseded when shift+right-click moved to `SuggestionsUI.Show`; nothing
  calls it anymore (only a comment in `GearEvaluation.lua` references what it "used to" do).

**Files excluded from the player zip** (expressed via `.gitattributes export-ignore` for `git
archive`, a strip-script exclude list, or `.pkgmeta` `ignore:` for the Curse packager — same list
whichever backend):
- Docs: `README.md`, `ROADMAP.md`, `PROGRESS.md`, `CONVENTIONS.md`, `DESIGN.md`, `DATA_PIPELINE.md`,
  `CHANGELOG.md`, `TEST_PLAN.md`, `TESTERS.md`, `PACKAGING.md`, `bugs/` (`known-bugs.md`,
  `resolved-bugs.md`)
- Dev tooling: `.luacheckrc`, `.gitignore`, `.git/`
- Pipeline **build** tooling (the baked `output/*.lua` data stays — only the tooling is excluded):
  `pipeline/big_data.py` (and any `*.py`), `pipeline/downloads/`, `pipeline/logs/`,
  `pipeline/README.md`, `pipeline/output/schema_report.txt` and any non-shipped `output/` artifact
- Local-only (already gitignored, never in the repo anyway): `CLAUDE.md`, `WORKFLOW.md`, `queue.md`,
  `testing-log.md`
- Test-session tooling that runs on the test computer rather than inside the client (the log-watcher
  script tracked as `queue.md` Q13). It is external to the addon, so the client never loads it — but
  it is dev-only and must not end up in a player zip.

---

## Implementation steps (not yet done — this file is the plan)

1. Delete the dead `ShowScorePopout` code from `UI.lua`.
2. Wrap the no-ship command branches and functions in `--@debug@` / `--@end-debug@` — **or**, if going
   the whole-file route (backend 3), move them into dev-only file(s) omitted from the player `.toc`.
3. Express the file-exclusion list in whichever backend is chosen: `.gitattributes export-ignore`
   (git archive), a strip-script exclude list, or `.pkgmeta` `ignore:` (Curse packager). No need to
   commit to one yet.
4. Emit the player zip via the chosen backend (local strip script / `git archive` / Curse packager);
   the tester build is just the raw repo.
5. **Verify a packaged player build live:** load it, confirm the dev commands are gone, confirm
   `/lgs report` + the settings button + the error auto-offer still work, and confirm no Lua errors
   from any stripped reference the player build still points at.
