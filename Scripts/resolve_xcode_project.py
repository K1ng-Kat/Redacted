#!/usr/bin/env python3
"""Safely reconcile Xcode project changes when GitHub changed ONLY version/build.

Usage: resolve_xcode_project.py BASE LOCAL REMOTE RESULT
Used by red-sync during a conflicted merge of project.pbxproj.
Will exit without creating RESULT if the remote changed any other setting.
"""
from pathlib import Path
import re
import sys

if len(sys.argv) != 5:
    sys.exit("Expected: BASE LOCAL REMOTE RESULT")

base, local, remote, output = map(Path, sys.argv[1:])
original, working, upstream = [p.read_bytes() for p in (base, local, remote)]

version_lines = (
    rb"(?m)^[ \t]*(?:CURRENT_PROJECT_VERSION|MARKETING_VERSION)"
    rb"[ \t]*=[ \t]*[^;\r\n]+;[ \t]*\r?\n"
)
if re.sub(version_lines, b"", original) != re.sub(version_lines, b"", upstream):
    sys.exit("GitHub made non-version Xcode changes; refusing automatic resolution.")

for setting in ("CURRENT_PROJECT_VERSION", "MARKETING_VERSION"):
    key = setting.encode()
    pattern = rb"(?m)^[ \t]*" + key + rb"[ \t]*=[ \t]*([^;\r\n]+);[ \t]*$"
    local_values = [value.strip() for value in re.findall(pattern, working)]
    remote_values = [value.strip() for value in re.findall(pattern, upstream)]
    if (
        not local_values
        or not remote_values
        or len(local_values) != len(remote_values)
        or len(set(local_values)) != 1
        or len(set(remote_values)) != 1
    ):
        sys.exit("Unexpected Xcode version layout; refusing automatic resolution.")

    try:
        if setting == "CURRENT_PROJECT_VERSION":
            chosen = str(max(int(local_values[0]), int(remote_values[0]))).encode()
        else:
            parse = lambda value: tuple(map(int, value.decode().split(".")))
            chosen = max((local_values[0], remote_values[0]), key=parse)
    except ValueError:
        sys.exit("Non-numeric Xcode version; refusing automatic resolution.")

    find_setting = rb"(?m)^([ \t]*" + key + rb"[ \t]*=[ \t]*)[^;\r\n]+;"
    working, count = re.subn(
        find_setting,
        lambda match: match.group(1) + chosen + b";",
        working,
    )
    if count != len(local_values):
        sys.exit("Unexpected count updating Xcode versions; refusing resolution.")

if b"<<<<<<<" in working or b">>>>>>>" in working:
    sys.exit("Conflict markers found in local Xcode project; refusing resolution.")

output.write_bytes(working)
print("✅ Kept local Xcode/app-icon settings and the newer app version/build.")
