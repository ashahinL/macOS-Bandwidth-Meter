# Releasing

How a version of Bandwidth Meter gets from `main` to the Releases page.

## The rule

**Pushing a `v*` tag publishes a release.** There is no draft step.
`.github/workflows/release.yml` runs on the tag push, builds the zips, and
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
version from `CFBundleShortVersionString` and puts it in the zip names.

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
6. **Build it locally:** `make dist`, then install the combined zip with its
   `install.sh` and check the app and `bandwidth-meter`.
7. **Commit** as "Prepare version x.y.z" and push `main`. Wait for CI.

## Ship

```sh
git tag -a vx.y.z -m "Bandwidth Meter x.y.z"
git push origin vx.y.z
```

The release workflow then:

1. runs `make test` and `make dist` on macOS
2. removes leftover zips with old names if the release already exists
3. builds the release body from `docs/release-notes/x.y.z.md`, falling back to
   the `## [x.y.z]` section of `CHANGELOG.md`, and appends
   `.github/release-downloads.md` (the download table and install steps). It
   fails if it finds neither notes file nor changelog section.
4. publishes the release "Bandwidth Meter x.y.z" with the three zips

After it finishes, open the release page and check that the notes, the
screenshot, and all three zips are there.

## Fixing a release

- **Wrong notes:** edit the release on GitHub, and fix the notes file in a
  normal commit so they match.
- **Broken build:** don't move the tag. Fix it on `main` and ship the next
  patch version.
