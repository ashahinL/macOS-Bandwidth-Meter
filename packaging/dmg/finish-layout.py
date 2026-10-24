"""Tidy a mounted read-write Bandwidth Meter disk image after dmgbuild.

    finish-layout.py <mount-point>

dmgbuild 1.6.7 always writes the background as .background.tiff at the
volume root. This moves it into the conventional .background/ folder, points
the window's background alias at the new path, and sets the hidden flag on
every dot item at the root. Run it with the dmgbuild venv's python, which has
ds_store and mac_alias.
"""

import os
import subprocess
import sys

from ds_store import DSStore
from mac_alias import Alias

# realpath: mktemp gives /var/..., statfs reports /private/var/..., and the
# alias stores the path relative to the volume.
mnt = os.path.realpath(sys.argv[1])
old = os.path.join(mnt, ".background.tiff")
folder = os.path.join(mnt, ".background")
new = os.path.join(folder, "background.tiff")

os.makedirs(folder, exist_ok=True)
os.rename(old, new)

with DSStore.open(os.path.join(mnt, ".DS_Store"), "r+") as d:
    icvp = d["."]["icvp"]
    icvp["backgroundType"] = 2
    icvp["backgroundImageAlias"] = Alias.for_file(new).to_bytes()
    d["."]["icvp"] = icvp

dot_items = sorted(n for n in os.listdir(mnt) if n.startswith("."))
subprocess.check_call(["/usr/bin/chflags", "hidden"] + [os.path.join(mnt, n) for n in dot_items])
subprocess.check_call(["/usr/bin/chflags", "hidden", new])
print("hid " + " ".join(dot_items))
