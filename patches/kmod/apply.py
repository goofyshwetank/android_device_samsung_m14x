#!/usr/bin/env python3
"""Apply 0001-depmod-cycles.patch onto external/kmod. No-op if already applied."""
import subprocess
import sys
from pathlib import Path

here = Path(__file__).resolve().parent
root = next(p for p in here.parents if (p / ".repo").is_dir())
depmod = root / "external" / "kmod" / "tools" / "depmod.c"
if not depmod.is_file():
    sys.exit(0)
if "Drop edges" in depmod.read_text(errors="replace"):
    sys.exit(0)
patch = here / "0001-depmod-cycles.patch"
r = subprocess.run(
    ["patch", "-p1", "--forward", "--batch", f"--directory={root / 'external' / 'kmod'}", "-i", str(patch)],
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
)
sys.exit(0 if r.returncode == 0 else r.returncode)
