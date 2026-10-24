# dmgbuild settings for the Bandwidth Meter disk image.
# scripts/build-dmg.sh passes the paths with -D:
#   pkg=...  uninstaller=...  background=...
# Icon centres match the tile drawn by render-background.swift.

import os

pkg = defines["pkg"]
uninstaller = defines["uninstaller"]

files = [pkg, uninstaller]
format = "ULFO"
filesystem = "HFS+"

background = defines["background"]
window_rect = ((200, 140), (640, 400))
default_view = "icon-view"
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

icon_locations = {
    os.path.basename(pkg): (190, 200),
    os.path.basename(uninstaller): (450, 200),
}
# Only the pkg. Hiding an extension sets com.apple.FinderInfo on the item,
# which breaks strict code signature checks on the uninstaller. Finder hides
# .app on its own unless "Show all filename extensions" is on.
hide_extensions = [os.path.basename(pkg)]
