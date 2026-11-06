$ErrorActionPreference = 'Stop'

$appHome = if ($env:HERDR_APP_HOME) { $env:HERDR_APP_HOME } else { Join-Path $HOME '.config\herdr-app' }
if (-not (Test-Path -LiteralPath (Join-Path $appHome 'AGENTS.md'))) {
    throw "Herdr app home not found: $appHome"
}

$stamp = Get-Date -Format 'yyyyMMddHHmmssfff'
$backupRoot = Join-Path $appHome "backups\herdr-git-history\$stamp"
function Install-Copy {
    param([string]$Source, [string]$Target, [string]$BackupName)
    if (Test-Path -LiteralPath $Target) {
        New-Item -ItemType Directory -Force -Path $backupRoot > $null
        Copy-Item -LiteralPath $Target -Destination (Join-Path $backupRoot $BackupName) -Recurse
    }
    $parent = Split-Path -Parent $Target
    New-Item -ItemType Directory -Force -Path $parent > $null
    if (Test-Path -LiteralPath $Source -PathType Container) {
        New-Item -ItemType Directory -Force -Path $Target > $null
        Copy-Item -Path (Join-Path $Source '*') -Destination $Target -Recurse -Force
    } else {
        Copy-Item -LiteralPath $Source -Destination $Target -Force
    }
}

$graphTarget = Join-Path $appHome 'mods\git-graph'
$tabsTarget = Join-Path $appHome 'mods\tabs-graph'
$layoutTarget = Join-Path $appHome 'layouts\main-graph.json'
$cwdTarget = Join-Path $appHome 'integration\herdr-cwd.ps1'
Install-Copy (Join-Path $PSScriptRoot 'mod') $graphTarget 'git-graph'
Install-Copy (Join-Path $PSScriptRoot 'tabs-graph') $tabsTarget 'tabs-graph'
Install-Copy (Join-Path $PSScriptRoot 'layouts\main-graph.json') $layoutTarget 'main-graph.json'
Install-Copy (Join-Path $PSScriptRoot 'powershell\herdr-cwd.ps1') $cwdTarget 'herdr-cwd.ps1'

$profilePath = $PROFILE.CurrentUserCurrentHost
$profileDir = Split-Path -Parent $profilePath
New-Item -ItemType Directory -Force -Path $profileDir > $null
if (-not (Test-Path -LiteralPath $profilePath)) {
    [IO.File]::WriteAllText($profilePath, '', [Text.UTF8Encoding]::new($false))
}
$profileText = [IO.File]::ReadAllText($profilePath)
if (-not $profileText.Contains('# BEGIN herdr-git-history')) {
    Copy-Item -LiteralPath $profilePath -Destination "$profilePath.before-herdr-git-history-$stamp"
    $hook = @'
# BEGIN herdr-git-history
$herdrGitHome = if ($env:HERDR_APP_HOME) { $env:HERDR_APP_HOME } else { Join-Path $HOME '.config\herdr-app' }
$herdrGitCwd = Join-Path $herdrGitHome 'integration\herdr-cwd.ps1'
if (Test-Path -LiteralPath $herdrGitCwd) { . $herdrGitCwd }
# END herdr-git-history
'@
    [IO.File]::AppendAllText($profilePath, "`r`n$hook`r`n", [Text.UTF8Encoding]::new($false))
}

$checker = (Get-Command herdr-app -ErrorAction Stop).Source
$graphCheck = Start-Process -FilePath $checker -ArgumentList @('check', ('"' + $graphTarget + '"')) -Wait -PassThru -WindowStyle Hidden
if ($graphCheck.ExitCode -ne 0) { throw "git-graph mod check failed (exit $($graphCheck.ExitCode))" }
$tabsCheck = Start-Process -FilePath $checker -ArgumentList @('check', ('"' + $tabsTarget + '"')) -Wait -PassThru -WindowStyle Hidden
if ($tabsCheck.ExitCode -ne 0) { throw "tabs-graph mod check failed (exit $($tabsCheck.ExitCode))" }
"Installed Git Graph, Git button, layout, and Windows cwd sync to $appHome"
"Open a new Herdr PowerShell tab, cd to a repository, and click Git."
