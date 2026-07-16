"""pipeline/lua_writer.py -- serializes plain Python data (dict/list/str/int/float/bool/None) into
Lua table literal source text.

Hand-written rather than pulled in as a dependency -- the same policy DATA_PIPELINE.md already
uses for the Questie Lua->JSON bridge (a small hand-rolled serializer over a third-party library),
just applied in the opposite direction here: Python -> Lua instead of Lua -> JSON.
"""

from pathlib import Path
from typing import Any


def _lua_string(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return f'"{escaped}"'


def _lua_key(key: Any) -> str:
    if isinstance(key, int):
        return f"[{key}]"
    key_str = str(key)
    if key_str.isidentifier():
        return key_str
    return f"[{_lua_string(key_str)}]"


def to_lua(value: Any, indent: int = 0) -> str:
    pad = "\t" * indent
    inner_pad = "\t" * (indent + 1)

    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return _lua_string(value)
    if isinstance(value, dict):
        if not value:
            return "{}"
        lines = ["{"]
        for key, item in value.items():
            lines.append(f"{inner_pad}{_lua_key(key)} = {to_lua(item, indent + 1)},")
        lines.append(f"{pad}}}")
        return "\n".join(lines)
    if isinstance(value, (list, tuple)):
        if not value:
            return "{}"
        lines = ["{"]
        for item in value:
            lines.append(f"{inner_pad}{to_lua(item, indent + 1)},")
        lines.append(f"{pad}}}")
        return "\n".join(lines)
    raise TypeError(f"Cannot serialize {type(value)!r} to Lua")


def write_lua_table(variable_name: str, data: Any, output_path: Path, header_comment: str = "") -> None:
    lines = []
    if header_comment:
        for comment_line in header_comment.splitlines():
            lines.append(f"-- {comment_line}")
    lines.append(f"{variable_name} = {to_lua(data)}")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
