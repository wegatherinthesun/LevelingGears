"""pipeline/dependencies.py -- sequential dependency checks for big_data.py.

Each check reports whether a requirement is already present (with what was found) or missing (with
the exact shell command(s) to install it). Never assumes a bare machine and never assumes everything
is already there -- it actually checks, every run.
"""

import logging
import platform
import shutil
from dataclasses import dataclass, field

log = logging.getLogger("big_data.dependencies")

MIN_PYTHON = (3, 8)
MIN_FREE_DISK_GB = 2


@dataclass
class CheckResult:
    name: str
    ok: bool
    detail: str
    install_hint: str = field(default="")


def check_python_version() -> CheckResult:
    import sys

    version = sys.version_info
    found = f"Python {platform.python_version()}"
    if version >= MIN_PYTHON:
        return CheckResult("Python 3", True, f"{found} (>= {'.'.join(map(str, MIN_PYTHON))} required)")
    return CheckResult(
        "Python 3",
        False,
        f"{found} is too old (need >= {'.'.join(map(str, MIN_PYTHON))})",
        "Install a newer Python 3 via Homebrew:\n"
        '  1. Install Homebrew (if not already installed): /bin/bash -c "$(curl -fsSL '
        'https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"\n'
        "  2. brew install python@3.11\n"
        "  3. Re-run this script with the new interpreter, e.g. python3.11 big_data.py",
    )


def check_disk_space(path: str = ".") -> CheckResult:
    usage = shutil.disk_usage(path)
    free_gb = usage.free / (1024**3)
    detail = f"{free_gb:.1f} GB free at {path!r}"
    if free_gb >= MIN_FREE_DISK_GB:
        return CheckResult("Disk space", True, detail)
    return CheckResult(
        "Disk space",
        False,
        f"{detail} -- need at least {MIN_FREE_DISK_GB} GB free (cmangos tbc-db's SQL dump is "
        "~390 MB compressed, larger once decompressed)",
        "Free up disk space, then re-run this script.",
    )


# Every check big_data.py's cmangos-only run actually needs. git/lua/luac checks belong here too
# once Questie support resumes (its Lua->JSON bridge needs a lua interpreter, per DATA_PIPELINE.md)
# -- not added yet since nothing in THIS run needs them: cmangos is fetched over plain HTTPS via
# urllib, no git clone required for a single file from a public repo.
CHECKS = [check_python_version, check_disk_space]


def run_all() -> bool:
    """Runs every check in order, logging each result. Returns True only if every check passed."""
    all_ok = True
    for check in CHECKS:
        result = check()
        if result.ok:
            log.info("[OK] %s: %s", result.name, result.detail)
        else:
            all_ok = False
            log.error("[MISSING] %s: %s", result.name, result.detail)
            for line in result.install_hint.splitlines():
                log.error("  %s", line)
    return all_ok
