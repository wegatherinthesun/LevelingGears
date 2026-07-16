"""pipeline/inspect_schema.py -- confirms cmangos's real table/column names before any extraction
parser gets written against them (DATA_PIPELINE.md flags these as unconfirmed guesses, informed by
general mangos-schema knowledge but not yet checked against the actual dump).

Streams the .sql file line-by-line rather than loading it whole into memory -- DATA_PIPELINE.md
already flags the full dump as too large for that (~390 MB compressed, larger uncompressed), and the
real extraction parser this scaffold is preparing for will need the same streaming approach.
"""

import logging
import re
from pathlib import Path

log = logging.getLogger("big_data.inspect_schema")

EXPECTED_TABLES = [
    "creature_loot_template",
    "reference_loot_template",
    "quest_template",
    "creature_template",
    "npc_vendor",
    "skill_line_ability",
    "item_template",
]

# `skill_line_ability` turned out not to exist in this dump (confirmed by a first real run) --
# these are the real candidates for recipe teaching/reagent data found in the full table list
# instead, worth confirming their actual columns before designing the recipe parser around them.
CANDIDATE_RECIPE_TABLES = [
    "npc_trainer",
    "npc_trainer_template",
    "skill_discovery_template",
    "skill_extra_item_template",
]

# spell_template has 180 columns total -- only its Reagent/Effect columns matter for building
# Recipes[recipeId].reagents (what the crafting spell consumes/creates), so report just those
# instead of dumping all 180 like a normal candidate table would.
SPELL_TEMPLATE_COLUMN_KEYWORDS = ("Reagent", "Effect")

# A standard mysqldump CREATE TABLE starts on its own line, e.g. CREATE TABLE `creature_template` (
CREATE_TABLE_START_RE = re.compile(r"^CREATE TABLE `(\w+)` \(")
# ...and ends on its own line, e.g. ) ENGINE=InnoDB ...
CREATE_TABLE_END_RE = re.compile(r"^\)\s*ENGINE")
# A column definition line's leading backtick-quoted name, e.g.   `entry` int(10) unsigned NOT NULL,
COLUMN_NAME_RE = re.compile(r"^\s*`(\w+)`")


def scan_sql_file(sql_path: Path) -> dict:
    """Returns {table_name: [column_name, ...]} for every CREATE TABLE found in the dump."""
    log.info("Streaming %s for CREATE TABLE statements...", sql_path)
    tables = {}
    current_table = None
    current_columns = []

    with sql_path.open("r", encoding="utf-8", errors="replace") as sql_file:
        for line in sql_file:
            if current_table is None:
                start_match = CREATE_TABLE_START_RE.match(line)
                if start_match:
                    current_table = start_match.group(1)
                    current_columns = []
                continue

            if CREATE_TABLE_END_RE.match(line):
                tables[current_table] = current_columns
                current_table = None
                continue

            column_match = COLUMN_NAME_RE.match(line)
            if column_match:
                current_columns.append(column_match.group(1))

    log.info("Found %d CREATE TABLE statements total", len(tables))
    return tables


def write_report(tables: dict, report_path: Path) -> None:
    report_path.parent.mkdir(parents=True, exist_ok=True)
    lines = ["# big_data.py schema report", ""]

    lines.append("## Expected tables (per DATA_PIPELINE.md)")
    for name in EXPECTED_TABLES:
        if name in tables:
            columns = ", ".join(tables[name])
            lines.append(f"- FOUND `{name}` ({len(tables[name])} columns): {columns}")
        else:
            lines.append(
                f"- MISSING `{name}` -- not in this dump, DATA_PIPELINE.md's parser design needs "
                "revisiting for this table"
            )

    lines.append("")
    lines.append("## Candidate recipe/profession tables (replacing missing skill_line_ability)")
    for name in CANDIDATE_RECIPE_TABLES:
        if name in tables:
            columns = ", ".join(tables[name])
            lines.append(f"- FOUND `{name}` ({len(tables[name])} columns): {columns}")
        else:
            lines.append(f"- MISSING `{name}` -- not in this dump either")

    lines.append("")
    lines.append("## spell_template's Reagent/Effect columns (what a crafting spell consumes/creates)")
    if "spell_template" in tables:
        matches = [c for c in tables["spell_template"] if any(k in c for k in SPELL_TEMPLATE_COLUMN_KEYWORDS)]
        lines.append(f"- FOUND `spell_template` ({len(tables['spell_template'])} columns total, "
                      f"{len(matches)} Reagent/Effect): {', '.join(matches)}")
    else:
        lines.append("- MISSING `spell_template` -- not in this dump")

    lines.append("")
    lines.append(f"## All {len(tables)} tables found in the dump")
    for name in sorted(tables):
        lines.append(f"- `{name}` ({len(tables[name])} columns)")

    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    log.info("Wrote schema report to %s", report_path)
