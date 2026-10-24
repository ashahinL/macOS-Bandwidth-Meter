# Releasing

How a version of Bandwidth Meter gets from `main` to the Releases page.

## The rule

**Pushing a `v*` tag publishes a release.** There is no draft step.
`.github/workflows/release.yml` runs on the tag push, builds the disk image, and
publishes the GitHub release straight away. Only push a tag when the version is
ready for people to download.

- One version, one tag, one GitHub release, all on the same day.
- `main` is the release branch. CI (`.github/workflows/ci.yml`) runs
  `make test`, `make app`, and `make dist` on every push to `main` and every
  pull request.

## Between releases

- Every change adds a line under `## [Unreleased]` at the top of
  `CHANGELOG.md`, in the Keep a Changelog groups (Added, Changed, Fixed,
  Removed).
- The version in `Resources/Info.plist` changes only when preparing a release.

## The number

The version follows [Semantic Versioning](https://semver.org/).

- Only bug fixes: next patch. `1.0.1` to `1.0.2`.
- New things or changed behaviour: next minor. `1.0.1` to `1.1.0`.
- A change that breaks the CLI's output or the `usage.json` format in a way
  scripts or older builds can't read: next major.

The tag is `v` plus the version, for example `v1.0.1`. The Makefile reads the
version from `CFBundleShortVersionString` and puts it in the disk image's
name, `Bandwidth-Meter-x.y.z.dmg`.

## Preparing a release

1. **Check `main`.** Clean `git status`, `make test` passes, and the last CI
   run on `main` is green.
2. **Bump the version** in `Resources/Info.plist`:
   `CFBundleShortVersionString` to the new version, and `CFBundleVersion` up
   by one.
3. **Move the changelog.** Rename `## [Unreleased]` to
   `## [x.y.z] - YYYY-MM-DD`, add a fresh empty `## [Unreleased]` above it, and
   add the compare link at the bottom.
4. **Write the release notes** in `docs/release-notes/x.y.z.md`. This is the
   text people see on the Releases page, so write it for them, not for
   contributors: a short opening paragraph, then bold groups such as
   **Fixes**, **Safer**, and **Panel**, with one plain sentence per bullet.
   Leave out the download table; the workflow adds it.
5. **Refresh the screenshots** if the UI changed: `make shots`, then look at
   every image in `docs/screenshots/`.
6. **Build it locally:** `make dmg`. Open `dist/Bandwidth-Meter-x.y.z.dmg`,
   run **Install Bandwidth Meter**, and check that the app opens and that
   `bandwidth-meter` works in a new Terminal window. Then try **Uninstall
   Bandwidth Meter** and install again.
7. **Commit** as "Prepare version x.y.z" and push `main`. Wait for CI.

## Ship

```sh
git tag -a vx.y.z -m "Bandwidth Meter x.y.z"
git push origin vx.y.z
```

The release workflow then:

1. runs `make test` and `make dist` on macOS
2. removes every other asset if the release already exists (for example the
   zips a re-cut release used to have)
3. builds the release body from `docs/release-notes/x.y.z.md`, falling back to
   the `## [x.y.z]` section of `CHANGELOG.md`, and appends
   `.github/release-downloads.md` (the download table and install steps). It
   fails if it finds neither notes file nor changelog section.
4. publishes the release "Bandwidth Meter x.y.z" with the disk image

After it finishes, open the release page and check that the notes, the
screenshot, and the disk image are there.

## What `make dmg` builds

`scripts/build-dmg.sh` takes the app from `make app` and builds, under
`.build/package/`:

- **Install Bandwidth Meter.pkg**, a product archive (`pkgbuild` plus
  `productbuild`, id `dev.ashahin.BandwidthMeter.pkg`) with a welcome page, the
  MIT license, and a closing page. The payload is the app, installed to
  `/Applications`. The CLI rides inside the app at
  `Contents/Helpers/bandwidth-meter`, and `postinstall` copies it to
  `/usr/local/bin`, so the package never changes that folder's owner or
  permissions. `preinstall` quits a running copy. `postinstall` opens the app
  for the signed-in user unless the install came from `sudo installer`.
- **Uninstall Bandwidth Meter.app**, an AppleScript applet that runs
  `packaging/uninstaller/uninstall.sh`.

Both go into `dist/Bandwidth-Meter-x.y.z.dmg` (ULFO, HFS+, volume name
"Bandwidth Meter"). dmgbuild, pinned to 1.6.7 in a venv under `.build/tools/`,
writes the window layout and background without driving Finder. If it can't be
installed, the script warns and falls back to a plain `hdiutil` image;
`DMG_LAYOUT=plain` forces that. The script then mounts the image and checks the
pkg payload and the uninstaller's signature.

The background comes from `packaging/dmg/background.png` and `@2x`. Run
`make dmg-background` after changing `packaging/dmg/render-background.swift`.

### Signing and notarization

The default build is unsigned. Set these to sign and notarize instead:

| Variable | Value | Signs |
|---|---|---|
| `DEVELOPER_ID_APP` | `Developer ID Application: Name (TEAMID)` | the app and its CLI (hardened runtime), the uninstaller, and the disk image |
| `DEVELOPER_ID_INSTALLER` | `Developer ID Installer: Name (TEAMID)` | the pkg |
| `NOTARY_PROFILE` | a profile saved with `xcrun notarytool store-credentials` | submits the disk image, waits, and staples the ticket |

```sh
xcrun notarytool store-credentials bandwidth-meter \
  --apple-id you@example.com --team-id TEAMID
DEVELOPER_ID_APP="Developer ID Application: Name (TEAMID)" \
DEVELOPER_ID_INSTALLER="Developer ID Installer: Name (TEAMID)" \
NOTARY_PROFILE=bandwidth-meter make dmg
```

`NOTARY_PROFILE` needs both identities. In CI, import the certificates into a
temporary keychain and create the profile before `make dist`. The signed path
hasn't been run yet; check `spctl -a -vv -t install` on the mounted pkg the
first time. Once releases are notarized, drop the Open Anyway steps from the
README and `.github/release-downloads.md`.

## Fixing a release

- **Wrong notes:** edit the release on GitHub, and fix the notes file in a
  normal commit so they match.
- **Broken build:** don't move the tag. Fix it on `main` and ship the next
  patch version.
