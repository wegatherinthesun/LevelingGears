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

### 29. Window position doesn't restore to the exact dragged spot
- Status: Open, likely already resolved — extensive debug-log evidence (45+ logged save/apply pairs
  across three anchor points) shows zero drift, but this has never been confirmed across an actual
  `/reload` or client relaunch, only in-session close/reopen. Full investigation history is in
  `PROGRESS.md`'s Progress log (the 0.301/0.311/0.312/0.313 entries).
- Next step: drag the window, do a real `/reload` or relaunch, and check if it still lands off. If
  it round-trips clean, close this outright.

## Everything else

Solved or mitigated-with-no-further-code-action — see [`resolved-bugs.md`](resolved-bugs.md) for
the full history, including several entries whose investigation technique (especially reading the
on-disk debug log directly) is worth reusing on a new hard-to-pin-down bug.
