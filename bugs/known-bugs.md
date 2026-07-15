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

None currently open — bug #29 (window position) was confirmed solved during the v0.383 testing
round. See [`resolved-bugs.md`](resolved-bugs.md) for the full history, including several entries
whose investigation technique (especially reading the on-disk debug log directly, or comparing
against how other installed addons handle the same problem) is worth reusing on a new bug.
