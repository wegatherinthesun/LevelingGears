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

### 59. A single per-slot candidate scan can still trip the "script ran too long" watchdog
- Status: Open
- Discovered: 2026-07-21, while fixing bug #58.
- Summary: #58 fixed the *triggering* fault — scans were re-running on every instance loading screen,
  which is what actually produced the observed `script ran too long` errors. But that fix does not
  make an individual scan cheap. `BuildCandidatePool` still walks hundreds of items for one slot
  inside a single contiguous call (626 items / 163 class-eligible for one real slot in the logged
  session), calling `ScoreEquippedItem` per item, which itself re-runs `DetectSpec`'s full talent
  scan every time. On a slow machine or a large slot pool that remains capable of exceeding WoW's
  per-execution budget on its own.
- Why it is not yet fixed: the remedy is an architecture change, not a tweak — splitting the work
  into short-lived chained executions so each gets a fresh runtime budget. Tracked as `queue.md` Q8.
- Known mechanism for the fix (verified available on this client): nested calls all count as **one**
  script no matter how deep, so refactoring into more functions changes nothing; a new execution
  context is what resets the budget, and `C_Timer.After(0, fn)` provides one (in use by Attune,
  Auctionator, Questie, DBM-Core). `debugprofilestop()` can make chunk size adaptive. See
  `CONVENTIONS.md`'s Technical notes.
- Severity note: not currently observed in play since #58 landed, because the scans that were firing
  constantly no longer do. This is recorded as a real remaining risk rather than a live symptom —
  the ledger should not claim we are clear when a known cause is still present.

See [`resolved-bugs.md`](resolved-bugs.md) for the full history, including several entries whose
investigation technique (especially reading the on-disk debug log directly, or comparing against how
other installed addons handle the same problem) is worth reusing on a new bug — most recently #58,
where the log showed the real fault was upstream of where the error was being reported.
