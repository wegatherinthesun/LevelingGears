"""pipeline/download.py -- fetches cmangos tbc-db's current Full_DB/*.sql.gz over plain HTTPS.

No git dependency: we only need one file from a public GitHub repo, and both the GitHub Contents API
and the file's own download URL are served over plain HTTPS -- no auth needed for a public repo, well
under the unauthenticated rate limit for the single API call this makes.
"""

import gzip
import json
import logging
import shutil
import urllib.request
from pathlib import Path

log = logging.getLogger("big_data.download")

REPO_CONTENTS_URL = "https://api.github.com/repos/cmangos/tbc-db/contents/Full_DB"
USER_AGENT = "LevelingGears-big_data/0.1 (+https://github.com/wegatherinthesun/LevelingGears)"


def _get_json(url: str):
    request = urllib.request.Request(
        url, headers={"User-Agent": USER_AGENT, "Accept": "application/vnd.github+json"}
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.loads(response.read().decode("utf-8"))


def find_current_sql_gz_entry() -> dict:
    """Returns the GitHub API entry (name, download_url, size) for the current .sql.gz dump.

    The exact filename changes with each cmangos release (DATA_PIPELINE.md's own warning) -- never
    hardcode it, always ask the API what's actually there right now.
    """
    log.info("Listing %s ...", REPO_CONTENTS_URL)
    entries = _get_json(REPO_CONTENTS_URL)
    sql_gz_entries = [entry for entry in entries if entry.get("name", "").endswith(".sql.gz")]
    if not sql_gz_entries:
        raise RuntimeError(
            f"No .sql.gz file found in Full_DB/ -- cmangos may have restructured the repo, "
            f"check {REPO_CONTENTS_URL} by hand"
        )
    if len(sql_gz_entries) > 1:
        log.warning(
            "Multiple .sql.gz files found, using the first: %s",
            [entry["name"] for entry in sql_gz_entries],
        )
    entry = sql_gz_entries[0]
    log.info("Current dump: %s (%.1f MB)", entry["name"], entry["size"] / (1024**2))
    return entry


def download_file(url: str, destination: Path) -> Path:
    destination.parent.mkdir(parents=True, exist_ok=True)
    log.info("Downloading %s -> %s ...", url, destination)
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=300) as response, open(destination, "wb") as out_file:
        shutil.copyfileobj(response, out_file)
    log.info("Downloaded %.1f MB", destination.stat().st_size / (1024**2))
    return destination


def decompress_gz(gz_path: Path, destination: Path) -> Path:
    log.info("Decompressing %s -> %s ...", gz_path, destination)
    with gzip.open(gz_path, "rb") as gz_file, open(destination, "wb") as out_file:
        shutil.copyfileobj(gz_file, out_file)
    log.info("Decompressed to %.1f MB", destination.stat().st_size / (1024**2))
    return destination


def fetch_cmangos_sql(downloads_dir: Path, skip_download: bool = False) -> Path:
    """Returns the path to the decompressed .sql file, downloading it first unless skip_download."""
    entry = None
    if not skip_download:
        entry = find_current_sql_gz_entry()
        gz_name = entry["name"]
    else:
        existing = sorted(downloads_dir.glob("*.sql.gz"))
        if not existing:
            raise RuntimeError(
                "--skip-download was passed but no .sql.gz file exists in pipeline/downloads/ yet"
            )
        gz_name = existing[-1].name
        log.info("Skipping download, reusing %s", gz_name)

    gz_path = downloads_dir / gz_name
    sql_path = downloads_dir / gz_name[: -len(".gz")]

    if not skip_download:
        if gz_path.exists() and gz_path.stat().st_size == entry["size"]:
            log.info("%s already downloaded and matches expected size, skipping re-download", gz_path)
        else:
            download_file(entry["download_url"], gz_path)

    if sql_path.exists():
        log.info("%s already decompressed, skipping", sql_path)
    else:
        decompress_gz(gz_path, sql_path)

    return sql_path
