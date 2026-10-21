<#
.SYNOPSIS
	Deploys the addon into the World of Warcraft AddOns folder(s).

.DESCRIPTION
	Runs build.ps1 (src\ copied into <repo>\build\ForevermoreClassicUI\) and
	mirrors that one build output into
	<WoW>\<gameDir>\Interface\AddOns\ForevermoreClassicUI\ of each flavor being
	deployed; every flavor gets the same files. A flavor whose "gameDir" is a
	list (Forever: its own _forever_ folder and the _classic_beta_ one) is
	deployed into each of those folders that is installed.

	Without -Flavor, every flavor declared in addon.json whose game folder
	exists in the WoW install is deployed; game folders whose client is not
	installed are skipped with a note. With -Flavor, that one flavor is
	deployed and an error is raised when none of its game folders exist.

	The WoW install location (the folder that contains _retail_, _classic_, ...)
	is asked for on the first run and stored in deploy.config.json next to this
	script. That file is git-ignored because it is machine specific.

.PARAMETER Flavor
	Deploy only this flavor. Flavors and the game sub-folder(s) each one
	deploys to ("gameDir", a name or a list of names) are declared in
	addon.json.

.PARAMETER Reset
	Forget the stored WoW location and ask for it again.

.EXAMPLE
	.\deploy.ps1                  # every flavor whose client is installed
	.\deploy.ps1 -Flavor Forever  # just one
	.\deploy.ps1 -Reset
#>
[CmdletBinding()]
param(
	[string]$Flavor,
	[switch]$Reset
)

$ErrorActionPreference = "Stop"

$RepoRoot    = $PSScriptRoot
$ConfigPath  = Join-Path $RepoRoot "deploy.config.json"
$BuildScript = Join-Path $RepoRoot "build.ps1"

# Addon name and flavor -> game folder(s) mapping ("gameDir") come from addon.json.
# (Forever ships both as its own product, _forever_, and as the
# "wow_classic_beta" product, _classic_beta_; it deploys to every one installed.)
$Addon     = Get-Content (Join-Path $RepoRoot "addon.json") -Raw | ConvertFrom-Json
$AddonName = $Addon.name
$FlavorDirs = [ordered]@{}
foreach ($property in $Addon.flavors.PSObject.Properties) {
	if (-not $property.Value.gameDir) {
		throw "Flavor '$($property.Name)' in addon.json has no 'gameDir'."
	}
	$FlavorDirs[$property.Name] = @($property.Value.gameDir)
}
$AllGameDirs = @($FlavorDirs.Values | ForEach-Object { $_ })

if ($Flavor -and -not $FlavorDirs.Contains($Flavor)) {
	throw "Unknown flavor '$Flavor'. Known flavors: $($FlavorDirs.Keys -join ', ')"
}

# --- WoW location -----------------------------------------------------------

function Read-WowPath {
	while ($true) {
		$path = Read-Host "Path to your World of Warcraft install (the folder containing _retail_, e.g. D:\Games\World of Warcraft)"
		$path = $path.Trim().Trim('"')
		if (-not $path) { continue }
		if (-not (Test-Path $path)) {
			Write-Warning "'$path' does not exist."
			continue
		}
		# Accept a flavor folder too and step up to the install root.
		$leaf = Split-Path $path -Leaf
		if ($AllGameDirs -contains $leaf) {
			$path = Split-Path $path -Parent
		}
		return (Resolve-Path $path).Path
	}
}

$config = $null
if (-not $Reset -and (Test-Path $ConfigPath)) {
	try {
		$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
	} catch {
		Write-Warning "deploy.config.json is unreadable; asking for the path again."
	}
}

if (-not $config -or -not $config.wowPath -or -not (Test-Path $config.wowPath)) {
	if ($config -and $config.wowPath) {
		Write-Warning "Stored WoW location '$($config.wowPath)' no longer exists."
	}
	$wowPath = Read-WowPath
	$config = [pscustomobject]@{ wowPath = $wowPath }
	$config | ConvertTo-Json | Set-Content $ConfigPath -Encoding UTF8
	Write-Host "Stored WoW location in $ConfigPath"
}

$WowPath = $config.wowPath

# --- Which flavors -----------------------------------------------------------

# "Flavor (gameDir)" -> its addon folder inside the game, for every installed
# game folder of every flavor to deploy.
$targets = [ordered]@{}
$flavorsToDeploy = if ($Flavor) { @($Flavor) } else { @($FlavorDirs.Keys) }
foreach ($name in $flavorsToDeploy) {
	foreach ($dir in $FlavorDirs[$name]) {
		$gameDir = Join-Path $WowPath $dir
		if (Test-Path $gameDir) {
			$targets["$name ($dir)"] = Join-Path $gameDir "Interface\AddOns\$AddonName"
		} else {
			Write-Host "Skipping $name ($dir): '$gameDir' is not installed."
		}
	}
}
if ($targets.Count -eq 0) {
	$dirs = if ($Flavor) { $FlavorDirs[$Flavor] } else { $AllGameDirs }
	throw "None of the game folders ($($dirs -join ', ')) exist under '$WowPath'. Run with -Reset to change the location."
}

# --- Build + deploy ---------------------------------------------------------

$buildOutput = Join-Path $RepoRoot "build\$AddonName"
& $BuildScript
if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $buildOutput "$AddonName.toc"))) {
	throw "build.ps1 did not produce '$buildOutput'."
}

foreach ($name in $targets.Keys) {
	$target = $targets[$name]

	Write-Host "Deploying $buildOutput -> $target"
	New-Item -ItemType Directory -Force (Split-Path $target -Parent) | Out-Null

	# /MIR keeps the target an exact copy of the build output (removes deleted files).
	$robocopyArgs = @($buildOutput, $target, "/MIR", "/NJH", "/NJS", "/NDL", "/NP", "/R:2", "/W:1")
	& robocopy @robocopyArgs
	$code = $LASTEXITCODE

	# Robocopy exit codes below 8 mean success (bits 1/2/4 = copied/extra/mismatched).
	if ($code -ge 8) {
		throw "robocopy failed with exit code $code while deploying $name"
	}
}

Write-Host "Done ($($targets.Keys -join ', ')). Type /reload in game to pick up the changes."

exit 0
