# pipeline/ — Leveling Gears data pipeline

Not part of the addon itself — this is offline tooling that will eventually produce the `Items`/
`Sources`/`Quests`/`Chains`/`Recipes`/`BySlot` Lua files `ROADMAP.md`'s `0.4` step calls for. See
[`../DATA_PIPELINE.md`](../DATA_PIPELINE.md) for the full source/schema/parser design.

## Current state (scaffold only)

`big_data.py` downloads cmangos tbc-db's current SQL dump and reports its real table/column
structure — it does not yet extract loot/quest/vendor/recipe data into our schema. Questie is not
included yet (its source license is unresolved — see `DATA_PIPELINE.md`).

## Running it

```
python3 big_data.py
```

Flags:
- `--skip-download` — reuse the `.sql.gz` already in `downloads/` instead of fetching it again.
- `--verbose` — DEBUG-level logging.

No third-party packages required — standard library only.

## Where things land

- `downloads/` — the raw `.sql.gz` and decompressed `.sql` (gitignored, ~390 MB+, re-downloadable).
- `output/` — generated reports, and eventually the real `Items.lua`/etc. output (gitignored).
- `logs/` — one timestamped log file per run, mirroring everything printed to the console
  (gitignored).
