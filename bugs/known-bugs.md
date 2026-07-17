# Known bugs

This file is the working bug ledger for Leveling Gears — but **only outstanding, still-open
bugs live here.** Once a bug is Solved, or Mitigated with no further code action possible until a
live tester confirms it, move its entry to [`resolved-bugs.md`](resolved-bugs.md) (keeping its
original bug number) instead of leaving it here. Keep this file updated after every change.

Numbering is shared across both files and is never reused or renumbered — a bug's number is fixed
at the moment it's first filed, whichever file it currently lives in.

## Status legend
- Open: still affecting the addon or not yet verified as fixed
- Mitigated: reduced or partially improved but still needs follow-up (stays here only while a
  concrete next action remains; once nothing further can be done without new evidence, it belongs
  in `resolved-bugs.md` instead)

## Bug entries

### 55. SuggestionsUI window shows an empty box -- no rows, buttons, or text visible
- Status: Open
- Discovered: 2026-07-17 (live report: window pops up "with an inconsistent height with nothing in it")
- Version introduced: N/A -- `SuggestionsUI.lua` is new, unreleased code on the `data_implementation` branch, not a regression.
- Summary: The window's backdrop/border IS visible (confirmed directly: "a box... with nothing in it"), and its height varies correctly with candidate count (by design -- not itself a bug), but the title, Refresh/Settings buttons, equipped-score line, and every row's icon/name/source/category text are all invisible, even when `Suggestions.GetCandidates` is confirmed (via the debug log, same session) to have returned real, valid candidate data and the window itself logs `shown=true` with correct width/height/position/strata every time.
- Investigation so far, ruled out: a genuine engine bug (bugs #50-#52, all confirmed fixed with live log evidence of 6 real candidates found across several slots); the window never being shown at all (log confirms `IsShown()=true`, correct size, correct centered position after bug #53's fix); a Lua error aborting the populate function before it finishes (no error ever appears in the debug log, and the log's own final "window shown" line -- written after the row-population loop and `window:Show()` -- does fire every time). A full manual re-read of `SuggestionsUI.lua`'s anchor chain (title -> equippedText -> buttonRow -> rowParent -> rows) didn't turn up a definitive cause either.
- Next steps: Added direct geometry/visibility logging for the first row (`GetLeft`/`GetTop`/`GetWidth`/`GetHeight`/`IsVisible`/`GetFrameLevel`/`GetFrameStrata`/`GetAlpha`/its own `nameText:GetText()`) plus the window's own `GetFrameLevel`/`GetAlpha`, written to the debug log every time `SuggestionsUI.Show` runs -- objective, not inferred from a description. Also fixed a real (if not yet confirmed to be *the*) issue found during the re-read: `rowParent` never had an explicit height set (only `SetWidth`), now sized to match its actual row content. Awaiting the next live test's debug log to read the new geometry data and actually localize this.

See [`resolved-bugs.md`](resolved-bugs.md) for the full history, including several entries whose
investigation technique (especially reading the on-disk debug log directly, or comparing against
how other installed addons handle the same problem) is worth reusing on a new bug -- this one
included.
