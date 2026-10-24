# Security

## Reporting a problem

If you find a security or privacy problem in Bandwidth Meter, please report it
privately first:

- **GitHub:** open a private report from this repository's **Security** tab
  (**Report a vulnerability**).

Say what you found, how to reproduce it, and which version you use. The
version is in the zip name, and in Finder's **Get Info** for
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
- A problem in `install.sh` from the combined zip, such as copying files
  somewhere other than `/Applications` and `~/.local/bin`.

A bug that only gives wrong totals, with no data exposed or lost, is a normal
issue.

## What to expect from the release zips

The zips on the Releases page are built by GitHub Actions from the tagged
commit. The app and the CLI are ad-hoc signed and not notarized, which is why
`install.sh` clears the quarantine flag. If you would rather not trust a
prebuilt binary, build from source with `make`.

## Supported versions

Only the latest release gets fixes.
