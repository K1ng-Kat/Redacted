#!/usr/bin/env python3
"""Import CC0 music tracks for REDACTED from their OpenGameArt download URLs.

Bossa Nova by Joth: https://opengameart.org/content/bossa-nova
Shop Theme by Cleyton Kauffman: https://opengameart.org/content/shop-theme
Both source pages list CC0 1.0. The final binary resources belong in Redacted/Audio/.
"""
from __future__ import annotations

import io
import shutil
import subprocess
import sys
import tempfile
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
        url,
        headers={"User-Agent": "Mozilla/5.0 (compatible; RedactedMusicImporter/1.0)"},
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=70) as response:
                data = response.read(MAX_BYTES + 1)
                if len(data) > MAX_BYTES:
                    raise ValueError("Audio download exceeded the expected maximum size")
                if len(data) < 1000:
                    raise ValueError("Audio download unexpectedly small")
                return data
        except Exception:
            if attempt == 3:
                raise
            time.sleep(2 * (attempt + 1))
    raise RuntimeError("Could not retrieve audio")


def choose_shop_track(data: bytes) -> tuple[str, bytes]:
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        entries = [
            file for file in archive.infolist()
            if not file.is_dir()
            and file.filename.lower().endswith((".mp3", ".ogg", ".wav"))
            and 0 < file.file_size <= MAX_BYTES
        ]
        if not entries:
            raise ValueError("No suitable music files inside Shop Theme ZIP")
        # The archive offers normal and radio-filtered versions;
        # we want the normal version with the clean background-music sound.
        entries.sort(key=lambda file: (
            any(word in file.filename.lower() for word in ("radio", "speaker")),
            not file.filename.lower().endswith(".mp3"),
            len(file.filename),
        ))
        track = entries[0]
        return track.filename, archive.read(track)


def convert(source: Path, destination: Path) -> None:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise RuntimeError("ffmpeg is required. On macOS: brew install ffmpeg")
    subprocess.run(
        [
            ffmpeg, "-hide_banner", "-loglevel", "error", "-nostdin", "-y",
            "-i", str(source),
            "-vn", "-map_metadata", "-1", "-c:a", "aac",
            "-b:a", "112k", "-ar", "44100", "-ac", "2",
            str(destination),
        ],
        check=True,
    )
    if not destination.exists() or destination.stat().st_size < 10_000:
        raise RuntimeError("Audio conversion failed: " + str(destination))


def main() -> int:
    DEST.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as folder:
        temp = Path(folder)

        print("Fetching Bossa Nova by Joth...", flush=True)
        menu_file = temp / "MenuBossa.mp3"
        menu_file.write_bytes(download(BOSSA_URL))

        print("Fetching Shop Theme by Cleyton Kauffman...", flush=True)
        shop_name, shop_data = choose_shop_track(download(SHOP_URL))
        print("Selected Shop Theme track: " + shop_name, flush=True)
        level_file = temp / ("LevelShop" + Path(shop_name).suffix.lower())
        level_file.write_bytes(shop_data)

        convert(menu_file, DEST / "MenuBossa.m4a")
        convert(level_file, DEST / "LevelShop.m4a")

    for track in sorted(DEST.glob("*.m4a")):
        print("Ready: {} ({:,} bytes)".format(track.relative_to(ROOT), track.stat().st_size))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:
        print("Audio import failed: " + str(error), file=sys.stderr)
        sys.exit(1)
