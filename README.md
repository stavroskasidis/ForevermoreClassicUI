# Forevermore Classic UI

Repository for the *Forevermore Classic UI* World of Warcraft addon
(published as "Forevermore Classic UI - Forever & Retail"; formerly *Classic
UI Restoration*, whose settings it copies over on first login while the old
`ClassicUIRestoration` folder is still installed). One
build serves every game flavor (retail and WoW Forever): the `.toc` lists
each flavor's Interface version, and the Forever-only modules return early on
retail.

```
src/             the addon folder (ForevermoreClassicUI.toc, Core, Options, Modules, Textures, README)
addon.json       addon name, version and flavors (with the game folder each deploys to)
build.ps1        copies src\ into build\ForevermoreClassicUI\ and zips it for CurseForge
deploy.ps1       builds and copies the addon into every installed flavor (-Flavor X for one)
publish.ps1      builds, writes the changelog and uploads the zip to CurseForge (run by CI)
CHANGELOG.md     release notes, one "## <version>" section per release
.github/         CI (master only): checks and builds every push, releases version bumps
build/           build output (git-ignored)
curseforge/      logo and project-page text for CurseForge
```

See [src/README.md](src/README.md) for what the addon does (including the
Forever-specific parts).

## Building

```powershell
.\build.ps1
```

This produces

```
build\ForevermoreClassicUI\                    the addon folder
build\ForevermoreClassicUI-<version>.zip       upload this to CurseForge
```

The zip has the addon folder as its root entry
(`ForevermoreClassicUI/ForevermoreClassicUI.toc`, ...), which is the layout
CurseForge requires. Releases are uploaded by CI (see Releasing); to upload
by hand, tick every supported game version (WoW Retail and WoW Forever) in
the file's Game Version field.

## Versioning

The version is defined once, in [addon.json](addon.json). The `.toc` says
`## Version: @project-version@`, and the build replaces that placeholder
(in any `.toc`, `.lua` or `.md` file) with the version from `addon.json`,
which also names the zip. To release: bump `"version"`, run `.\build.ps1`,
upload the zip.

`addon.json` also holds the addon folder name (`"name"`) and the flavors,
i.e. the game folders `deploy.ps1` copies the build into:

```json
{
	"name": "ForevermoreClassicUI",
	"version": "1.0.0",
	"curseforge": { "projectId": 1700272 },
	"flavors": {
		"Retail":  { "gameDir": "_retail_" },
		"Forever": { "gameDir": "_forever_" }
	}
}
```

`"gameDir"` is one folder name or a list of them; with a list, the addon is
deployed into each one that is installed.

## Releasing

Bump `"version"` in `addon.json`, add a `## <version>` section with the
release notes to [CHANGELOG.md](CHANGELOG.md) in the same commit, and push to
`master`. The CI workflow ([.github/workflows/build.yml](.github/workflows/build.yml))
then:

1. checks the Lua syntax (Lua 5.1) and that every file the `.toc` lists
   exists, and builds (this part runs on every push to `master`; the
   built addon folder is kept as the run's artifact);
2. because the push changed the version and `v<version>` is not tagged yet,
   runs `publish.ps1`, which builds the zip, writes the changelog and uploads
   the zip to CurseForge;
3. creates the GitHub release `v<version>` (which creates the tag) with the
   zip and the same notes.

Details:

- **Changelog:** the `## <version>` section of `CHANGELOG.md`; without one,
  the commit subjects since the previous release (merges and bare "version
  bump" commits left out).
- **Game versions:** each `## Interface:` entry of the `.toc` is tagged with
  CurseForge's newest patch of its major.minor (120100 -> 12.1.x,
  16001 -> 1.60.x). To pick them by hand, list CurseForge's version names in
  `addon.json`: `"curseforge": { "projectId": ..., "gameVersions": ["12.1.5", "1.60.1"] }`.
- **Release type:** a version whose suffix contains `alpha` or `beta`
  (`1.22.0-beta1`) goes to CurseForge as that type and is a pre-release on
  GitHub; any other version is a release.
- **Token:** the repository secret `CURSEFORGE_API_TOKEN` (a CurseForge API
  token from https://authors.curseforge.com/#/settings/api-tokens).
- **Retrying:** a version is released once (its `v<version>` tag marks it).
  If a release job fails, fix the cause and use *Run workflow* on the Build
  workflow in the Actions tab: a manual run releases the current version if
  it is not tagged yet. If the CurseForge upload went through but the GitHub
  release failed, create the release by hand instead (a re-run would upload
  the file to CurseForge twice).

Locally, `.\publish.ps1 -DryRun` builds and prints the changelog (and, with
`$env:CURSEFORGE_API_TOKEN` set, the game versions it would tag) without
uploading.

## Deploying to the game

```powershell
.\deploy.ps1                 # build + deploy to every flavor whose client is installed
.\deploy.ps1 -Flavor Retail  # just one flavor
.\deploy.ps1 -Flavor Forever # WoW Forever (the _forever_ folder)
.\deploy.ps1 -Reset          # forget the stored WoW location and ask again
```

The first run asks for the WoW install folder (the one that contains
`_retail_`) and stores it in `deploy.config.json`, which is git-ignored. The
script runs the build once and mirrors `build\ForevermoreClassicUI\` into
each flavor's game folder(s) (files removed here are removed there too); it
never touches anything outside the addon folders. Game folders that are not
installed are skipped with a note. Type `/reload` in
game afterwards.

Adding a flavor: add its Interface version to the `## Interface:` line of
`src\ForevermoreClassicUI.toc`, declare it in `addon.json` with the game
sub-folder it deploys to (`"gameDir"`), and guard any code only it needs the
way the Forever modules check `ns.IS_FOREVER`.
