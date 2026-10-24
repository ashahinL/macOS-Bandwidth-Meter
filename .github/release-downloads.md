
## Download

**`Bandwidth-Meter-*.dmg`** has everything. Open it and double-click
**Install Bandwidth Meter**. The installer puts the menu bar app in
`/Applications` and the `bandwidth-meter` command in `/usr/local/bin`, then
opens the app. You don't need Terminal.

Apple Silicon, macOS 14 or later. Keep [Bandwidth+](https://apps.apple.com/app/bandwidth/id490461369)
running so each day is recorded.

The installer isn't notarized yet, so macOS stops it the first time:

- **macOS 15 or later:** click **Done** on the warning, open **System Settings ›
  Privacy & Security**, scroll down to **Security**, click **Open Anyway** next
  to "Install Bandwidth Meter.pkg", and confirm with your password. Right-click
  › Open no longer skips the check.
- **macOS 14:** right-click **Install Bandwidth Meter**, choose **Open**, then
  **Open** again.

The same goes for **Uninstall Bandwidth Meter** on the disk image. It removes
the app and the command, and asks before it deletes your saved totals.

Updating: run the new installer. It replaces the app and keeps your history and
settings.

See the [changelog](https://github.com/ashahinL/macOS-Bandwidth-Meter/blob/main/CHANGELOG.md)
for every change, and [PRIVACY.md](https://github.com/ashahinL/macOS-Bandwidth-Meter/blob/main/PRIVACY.md)
for what the app reads and stores.
