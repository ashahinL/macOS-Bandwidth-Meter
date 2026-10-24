# Privacy

Effective 24 October 2026, from version 1.0.1.

Bandwidth Meter runs on your Mac and nowhere else. It has no network code, no
analytics, and no crash reporting. It does not send anything anywhere, and
there is no account.

## What it reads

| What | Where | Who reads it |
|---|---|---|
| Bandwidth+ daily history | `~/Library/Containers/au.id.haroldchu.mac.Bandwidth/Data/Library/Application Support/au.id.haroldchu.mac.Bandwidth/History` | App and CLI |
| Bandwidth+ today | `Data` in the same folder | App and CLI |
| A CSV you import | The file you pick, or pass to `--import` | App and CLI |
| A CSV on your Desktop | `~/Desktop/History.csv`, only when Bandwidth+ gives no records | App and CLI |
| Interface byte counters | The kernel's per-interface byte totals, through `sysctl` | App only |

From the Bandwidth+ files it takes the date, the network name, and the bytes
down and up for each day. It reads them and never changes them.

The interface counters are totals of bytes in and out per interface, such as
`en0`. They do not include addresses, hosts, or what the traffic was. The app
uses them for live speed, and for today's totals when Bandwidth+ is not
installed.

## What it stores

One file: `~/Library/Application Support/BandwidthMeter/usage.json`. It holds
one row per day per network (date, network name, bytes down, bytes up, and
which source the numbers came from) and your settings (week start, billing day,
menu bar period, quota, open at login, live speed in the menu bar).

Network names come from Bandwidth+, so they are usually your Wi-Fi names.

If `usage.json` cannot be read, it is copied to `usage.json.bak`, or to a
timestamped `.bak` file if that already exists, in the same folder.

**Export** in the panel writes a CSV of the selected period to the place you
choose. Nothing else is written.

## Open at login

When you turn on **Open at login**, the app registers itself as a login item
with macOS (`SMAppService`). Turning it off removes it.

## Deleting your data

```sh
rm -rf ~/Library/Application\ Support/BandwidthMeter
```

This does not touch Bandwidth+ or its history.

## Screenshots

The images in `docs/screenshots` are drawn from made-up demo data. They contain
no real network names or usage.
