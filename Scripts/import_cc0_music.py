#!/usr/bin/env python3
"""Bundle the CC0 originals used by REDACTED.

Bossa Nova by Joth: https://opengameart.org/content/bossa-nova
Shop Theme by Cleyton Kauffman: https://opengameart.org/content/shop-theme
Both upload pages list CC0 1.0.
"""
from __future__ import annotations

import io
import sys
import time
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "Redacted" / "Audio"
BOSSA_URL = "https://opengameart.org/sites/default/files/8bit%20Bossa.mp3"
SHOP_URL = "https://opengameart.org/sites/default/files/shop_theme.zip"
MAX_BYTES = 60_000_000


def download(url: str) -> bytes:
    request = urllib.request.Request(
        url, headers={"User-Agent": "Mozilla/5.0 (compatible; RedactedMusicImporter/1.0)"}
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=70) as response:
                payload = response.read(MAX_BYTES + 1)
                if len(payload) > MAX_BYTES or len(payload) < 1000:
                    raise ValueError("Download size invalid")
                return payload
        except Exception:
            if attempt == 3:
                raise
            time.sleep(2 * (attempt + 1))
    raise RuntimeError("Unable to fetch track")


def select_normal_shop_track(archive_bytes: bytes) -> tuple[str, bytes]:
    with zipfile.ZipFile(io.BytesIO(archive_bytes)) as archive:
        entries = [
            file for file in archive.infolist()
            if not file.is_dir()
            and file.filename.lower().endswith(".mp3")
            and 0 < file.file_size <= MAX_BYTES
        ]
        if not entries:
            raise ValueError("Shop Theme archive contains no MP3 file")

        # Prefer the original music, not the separately included radio filter.
        entries.sort(key=lambda item: (
            any(word in item.filename.lower() for word in ("radio", "speaker")),
            len(item.filename)
        ))
        chosen = entries[0]
        return chosen.filename, archive.read(chosen)


def check_mp3(data: bytes) -> None:
    if not (
        data.startswith(b"ID3")
        or data[:2] in (b"\xff\xfb", b"\xff\xf3", b"\xff\xf2")
    ):
        raise ValueError("File is not a recognizable MP3 stream")


def main() -> int:
    DEST.mkdir(parents=True, exist_ok=True)
    print("Downloading main-menu Bossa Nova by Joth...", flush=True)
    menu_bytes = download(BOSSA_URL)
    check_mp3(menu_bytes)

    print("Downloading in-level Shop Theme by Cleyton Kauffman...", flush=True)
    original_name, level_bytes = select_normal_shop_track(download(SHOP_URL))
    check_mp3(level_bytes)
    print("Original (not radio) Shop Theme file: " + original_name, flush=True)

    menu_path = DEST / "MenuBossa.mp3"
    level_path = DEST / "LevelShop.mp3"
    menu_path.write_bytes(menu_bytes)
    level_path.write_bytes(level_bytes)

    for track in (menu_path, level_path):
        print("Bundled: {} ({:,} bytes)".format(track.relative_to(ROOT), track.stat().st_size))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:
        print("Music import failed: " + str(error), file=sys.stderr)
        sys.exit(1)
