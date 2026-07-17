"""pipeline/sql_extract.py -- streams rows out of a mysqldump .sql file for one table at a time.

DATA_PIPELINE.md's own recommended approach: rather than a full SQL parser (or translating to
SQLite), stream the file line-by-line and hand-parse just the `INSERT INTO \`table\` VALUES (...)`
statements for the handful of tables we actually need -- everything else in the file is skipped
without ever being fully parsed. mysqldump's INSERT syntax is regular enough for this.
"""

import logging
import re
from pathlib import Path
from typing import Dict, Iterator, List

log = logging.getLogger("big_data.sql_extract")

_ESCAPE_MAP = {"n": "\n", "r": "\r", "t": "\t", "0": "\0", "'": "'", '"': '"', "\\": "\\"}
_ESCAPE_RE = re.compile(r"\\(.)|''")


def _unescape_mysql_string(inner: str) -> str:
    def repl(match):
        if match.group(0) == "''":
            return "'"
        return _ESCAPE_MAP.get(match.group(1), match.group(1))

    return _ESCAPE_RE.sub(repl, inner)


def _convert_field(raw: str):
    """Converts one raw VALUES field (already comma-split) to a Python value."""
    raw = raw.strip()
    if raw == "NULL":
        return None
    if len(raw) >= 2 and raw[0] == "'" and raw[-1] == "'":
        return _unescape_mysql_string(raw[1:-1])
    try:
        if "." in raw or "e" in raw.lower():
            return float(raw)
        return int(raw)
    except ValueError:
        # Shouldn't normally happen for a well-formed dump -- surfaced as-is rather than raising,
        # so one odd field doesn't abort extracting every other row.
        return raw


def _split_top_level(text: str, sep: str = ",") -> List[str]:
    """Splits `text` on `sep` occurrences that are outside single-quoted strings."""
    parts = []
    current = []
    in_quotes = False
    i, n = 0, len(text)
    while i < n:
        ch = text[i]
        if in_quotes:
            if ch == "\\" and i + 1 < n:
                current.append(ch)
                current.append(text[i + 1])
                i += 2
                continue
            if ch == "'":
                if i + 1 < n and text[i + 1] == "'":
                    current.append("''")
                    i += 2
                    continue
                in_quotes = False
            current.append(ch)
            i += 1
            continue
        if ch == "'":
            in_quotes = True
            current.append(ch)
            i += 1
            continue
        if ch == sep:
            parts.append("".join(current))
            current = []
            i += 1
            continue
        current.append(ch)
        i += 1
    parts.append("".join(current))
    return parts


def _split_tuples(values_text: str) -> List[str]:
    """Splits '(...),(...),...' into a list of inner tuple strings (without the outer parens)."""
    tuples = []
    current = []
    depth = 0
    in_quotes = False
    i, n = 0, len(values_text)
    while i < n:
        ch = values_text[i]
        if in_quotes:
            if ch == "\\" and i + 1 < n:
                current.append(ch)
                current.append(values_text[i + 1])
                i += 2
                continue
            if ch == "'":
                if i + 1 < n and values_text[i + 1] == "'":
                    current.append("''")
                    i += 2
                    continue
                in_quotes = False
            current.append(ch)
            i += 1
            continue
        if ch == "'":
            in_quotes = True
            current.append(ch)
            i += 1
            continue
        if ch == "(":
            depth += 1
            if depth == 1:
                current = []
                i += 1
                continue
            current.append(ch)
            i += 1
            continue
        if ch == ")":
            depth -= 1
            if depth == 0:
                tuples.append("".join(current))
                i += 1
                continue
            current.append(ch)
            i += 1
            continue
        if depth >= 1:
            current.append(ch)
        i += 1
    return tuples


def extract_rows(sql_path: Path, table_name: str, columns: List[str]) -> Iterator[Dict]:
    """Yields one dict per row (keyed by `columns`, in order) from every `INSERT INTO
    \`table_name\` VALUES ...` statement found while streaming the file. `columns` must match the
    real column order confirmed by inspect_schema.py -- this does not read CREATE TABLE itself.
    """
    prefix = f"INSERT INTO `{table_name}` VALUES "
    row_count = 0
    mismatch_count = 0

    with sql_path.open("r", encoding="utf-8", errors="replace") as sql_file:
        for line in sql_file:
            if not line.startswith(prefix):
                continue

            values_text = line[len(prefix):].rstrip("\n").rstrip(";").rstrip()
            for tuple_text in _split_tuples(values_text):
                fields = _split_top_level(tuple_text, ",")
                if len(fields) != len(columns):
                    mismatch_count += 1
                    continue
                values = [_convert_field(field) for field in fields]
                row_count += 1
                yield dict(zip(columns, values))

    if mismatch_count:
        log.warning(
            "%s: %d row(s) had a different field count than the %d expected columns -- skipped",
            table_name, mismatch_count, len(columns),
        )
    log.info("%s: extracted %d rows", table_name, row_count)
