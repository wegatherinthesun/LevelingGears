# PACKAGING.md — the ship / no-ship manifest

This is `queue.md` Q6's deliverable: the authoritative list of what does and does not go into the
**player build**, and the decided mechanism for producing the split. Two builds come out of one
source tree:

- **Tester build** — the raw repo (debug markers active). The whole debug suite is available. This is
  a *separate download* for testers; it also includes `TEST_PLAN.md` / `TESTERS.md`.
- **Player build** — a packaged release: dev/tester code stripped, dev files excluded. Its **only**
  diagnostic surface is the error report (`/lgs report`, the "Copy report for developer" settings
  button, and the once-per-session auto-offer on a caught Lua error).

**Keep this file current.** Per `WORKFLOW.md`'s "Build debug in as you go," every new debug category,
test-only command, or dev file is added here in the same breath it's created. This file is itself
no-ship (see below).

---

## Decided mechanism (how the split is produced)

Adopt the **CurseForge / BigWigs packager conventions** — verified in use on this very client
(AceGUI-3.0-SharedMediaWidgets `prototypes.lua`; PallyPower/ShamanPower's bundled
`LibUIDropDownMenu` `.toc` files), so this is a real, standard toolchain, not a bespoke invention.
It is also **forward-compatible with actually publishing to CurseForge/Wago later** — the same
`BigWigsMods/packager` script does exactly this, so none of the markup is throwaway.

1. **In-file code stripping — `--@debug@` markers.** Wrap each no-ship command branch and no-ship
   function in the packager's debug tokens. In the raw source the code is active (tester build); the
   packager comments the block out for the release/player build.

   ```lua
   --@debug@
   -- dev/tester-only code here: active in source, stripped from the player release
   --@end-debug@
   ```

   (The inverse, `--[===[@non-debug@ ... --@end-non-debug@]===]`, marks code that is inactive in
   source and only turned on in the release — not expected to be needed here yet.)

2. **File exclusion — `.pkgmeta` `ignore:` list.** A `.pkgmeta` at the repo root lists the dev-only
   files/dirs to keep out of the packaged zip (docs, linter config, pipeline build tooling). The
   loaded addon files and the baked pipeline data stay in.

3. **Two artifacts.** Tester build = the raw repo as-is. Player build = the packager's output. Until
   the addon is actually published, run the packager locally (or a small local script that mimics
   these two rules) to emit the player zip.

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

**Files excluded from the player zip (`.pkgmeta` `ignore:`):**
- Docs: `README.md`, `ROADMAP.md`, `PROGRESS.md`, `CONVENTIONS.md`, `DESIGN.md`, `DATA_PIPELINE.md`,
  `CHANGELOG.md`, `TEST_PLAN.md`, `TESTERS.md`, `PACKAGING.md`, `bugs/` (`known-bugs.md`,
  `resolved-bugs.md`)
- Dev tooling: `.luacheckrc`, `.gitignore`, `.git/`
- Pipeline **build** tooling (the baked `output/*.lua` data stays — only the tooling is excluded):
  `pipeline/big_data.py` (and any `*.py`), `pipeline/downloads/`, `pipeline/logs/`,
  `pipeline/README.md`, `pipeline/output/schema_report.txt` and any non-shipped `output/` artifact
- Local-only (already gitignored, never in the repo anyway): `CLAUDE.md`, `WORKFLOW.md`, `queue.md`,
  `testing-log.md`

---

## Implementation steps (not yet done — this file is the plan)

1. Delete the dead `ShowScorePopout` code from `UI.lua`.
2. Wrap the no-ship command branches and functions in `--@debug@` / `--@end-debug@`.
3. Add a `.pkgmeta` with the `ignore:` list above.
4. Wire the packager (the `BigWigsMods/packager` script, or a small local equivalent) to emit the
   player zip; the tester build is just the raw repo.
5. **Verify a packaged player build live:** load it, confirm the dev commands are gone, confirm
   `/lgs report` + the settings button + the error auto-offer still work, and confirm no Lua errors
   from any stripped reference the player build still points at.
