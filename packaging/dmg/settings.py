# dmgbuild settings for the Bandwidth Meter disk image.
# scripts/build-dmg.sh passes the paths with -D:
#   pkg=...  uninstaller=...  background=...  format=...
# Icon centres match the tile drawn by render-background.swift.
#
# build-dmg.sh asks for a read-write image, then finish-layout.py moves the
# background into .background/ and hides the dot files before compressing.

import os

pkg = defines["pkg"]
uninstaller = defines["uninstaller"]

files = [pkg, uninstaller]
format = defines.get("format", "ULFO")
filesystem = "HFS+"

background = defines["background"]
window_rect = ((200, 140), (640, 400))
default_view = "icon-view"
# Finder applies its own path bar and status bar settings on top of these,
# so the background keeps the bottom of the window free.
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
show_icon_preview = False
include_icon_view_settings = True
arrange_by = None
icon_size = 80
text_size = 13
label_pos = "bottom"

# Items that Finder shows when "show hidden files" is on. Parked far outside
# the 640 x 400 window so they never land on the artwork.
OFF_WINDOW = [
    ".background",
    ".DS_Store",
    ".fseventsd",
    ".Trashes",
    ".VolumeIcon.icns",
    ".Spotlight-V100",
    ".TemporaryItems",
    ".DocumentRevisions-V100",
]

icon_locations = {
    os.path.basename(pkg): (190, 170),
    os.path.basename(uninstaller): (450, 170),
}
for i, name in enumerate(OFF_WINDOW):
    icon_locations[name] = (1200 + 100 * i, 1200)

# Short names (Install.pkg, Uninstall.app) fit on one label line even with
# "Show all filename extensions" on, which overrides a hidden extension.
# Hiding the .app extension would set com.apple.FinderInfo on the bundle and
# break strict code signature checks, so only the pkg gets the flag.
hide_extensions = [os.path.basename(pkg)]
