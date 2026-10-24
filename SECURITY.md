# Security

## Reporting a problem

If you find a security or privacy problem in Bandwidth Meter, please report it
privately first:

- **GitHub:** open a private report from this repository's **Security** tab
  (**Report a vulnerability**).

Say what you found, how to reproduce it, and which version you use. The
version is in the disk image's name, and in Finder's **Get Info** for
**Bandwidth Meter.app**. Please don't open a public issue for it until a fix is
out.

## What counts

- Anything that makes the app or the CLI send data over the network. It has no
  network code, so any traffic is a bug.
- Anything that reads or writes a file other than the ones
  [PRIVACY.md](PRIVACY.md) lists.
- A crafted Bandwidth+ archive, `History.csv`, or `usage.json` that makes
  Bandwidth Meter run code, crash in a way that loses saved totals, or write
  outside its own folder.
- A problem in the installer or the uninstaller from the disk image, such as
  writing anywhere other than `/Applications/Bandwidth Meter.app` and
  `/usr/local/bin/bandwidth-meter`, or removing anything else.

A bug that only gives wrong totals, with no data exposed or lost, is a normal
issue.

## What to expect from the release disk image

The disk image on the Releases page is built by GitHub Actions from the tagged
commit. The installer package is unsigned and not notarized, and the app and
the CLI inside it are ad-hoc signed, which is why macOS asks you to approve the
installer in **Privacy & Security** first. The installer runs two short scripts
as root: `packaging/pkg-scripts/preinstall` quits a running copy of the app,
and `postinstall` copies the CLI to `/usr/local/bin` and opens the app. If you
would rather not trust a prebuilt binary, build from source with `make`.

## Supported versions

Only the latest release gets fixes.
