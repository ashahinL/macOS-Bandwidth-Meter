
## Downloads

| File | What you get |
|---|---|
| `Bandwidth-Meter-*-full-macos-arm64.zip` | **Both**: the app, the CLI, and `install.sh` |
| `Bandwidth-Meter-*.app.zip` | The menu bar app only |
| `Bandwidth-Meter-*-cli-macos-arm64.zip` | The CLI only |

Apple Silicon, macOS 14 or later. Keep [Bandwidth+](https://apps.apple.com/app/bandwidth/id490461369)
running so each day is recorded. You don't need Xcode.

The builds are ad-hoc signed, not notarized. The combined zip's `./install.sh`
clears the quarantine flag. Otherwise right-click the app and choose Open, or
run `xattr -cr` on the files you copied.

### Both

```sh
unzip Bandwidth-Meter-*-full-macos-arm64.zip
cd Bandwidth-Meter-*-full-macos-arm64
./install.sh
```

### App only

Unzip and drag **Bandwidth Meter.app** to `/Applications`.

### CLI only

```sh
unzip Bandwidth-Meter-*-cli-macos-arm64.zip
mkdir -p ~/.local/bin
cp bandwidth-meter ~/.local/bin/
chmod +x ~/.local/bin/bandwidth-meter
xattr -cr ~/.local/bin/bandwidth-meter
```

See the [changelog](https://github.com/ashahinL/macOS-Bandwidth-Meter/blob/main/CHANGELOG.md)
for every change, and [PRIVACY.md](https://github.com/ashahinL/macOS-Bandwidth-Meter/blob/main/PRIVACY.md)
for what the app reads and stores.
