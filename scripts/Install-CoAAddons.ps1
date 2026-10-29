#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$ClientPath,
    [ValidateSet('Check','Install','Rollback')][string]$Action = 'Check',
    [string]$PackageDirectory,
    [string[]]$Addons = @('GMCommandCenter_CoA','CoAGatheringAlerts','CoALfgTracker','COAResourceMonitor'),
    [string]$ReceiptPath
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$Known = @('GMCommandCenter_CoA','CoAGatheringAlerts','CoALfgTracker','COAResourceMonitor')
$Addons = @($Addons | ForEach-Object { $_.Split(',') | ForEach-Object { $_.Trim() } })

function Require([bool]$Value,[string]$Message) { if (-not $Value) { throw $Message } }
function Plain([string]$Path) {
    $entry = Get-Item -LiteralPath $Path -Force
    while ($null -ne $entry) {
        Require (-not ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint)) ('Linked path refused: ' + $Path)
        $entry = if ($entry -is [IO.FileInfo]) { $entry.Directory } else { $entry.Parent }
    }
}
function Closed {
    Require (@(Get-Process -Name Ascension,Wow,Wow-64,MMgr64 -ErrorAction SilentlyContinue).Count -eq 0) 'Fully close the game and launcher before installing or rolling back.'
}
function FileHash([string]$Path) { Plain $Path; return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function BytesHash([byte[]]$Bytes) { return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant() }
function Inventory([string]$Path) {
    Plain $Path
    $result = @{}
    foreach ($item in Get-ChildItem -LiteralPath $Path -Recurse -Force) {
        Plain $item.FullName
        if (-not $item.PSIsContainer) {
            $result[[IO.Path]::GetRelativePath($Path,$item.FullName).Replace('\','/')] = FileHash $item.FullName
        }
    }
    return $result
}
function EqualFiles($Left,$Right,[string]$Message) {
    Require ($Left.Count -eq $Right.Count) $Message
    foreach ($name in $Left.Keys) { Require ($Right.ContainsKey($name) -and $Left[$name] -ceq $Right[$name]) $Message }
}
function SaveNew([string]$Path,$Object) {
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($Object | ConvertTo-Json -Depth 12) + "`n")
    $stream = [IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { $stream.Write($bytes,0,$bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
}
function SafeMove([string]$From,[string]$To,[string]$Id,[string]$Backup) {
    Require ($Id -cin $Known) 'Unknown addon in move request.'
    Plain $From
    Plain (Split-Path -Parent $To)
    $target = Join-Path $AddonRoot $Id
    foreach ($path in @([IO.Path]::GetFullPath($From),[IO.Path]::GetFullPath($To))) {
        Require ($path -ceq $target -or $path.StartsWith($Backup + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) 'Move escaped the selected addon and its backup.'
    }
    Require (-not (Test-Path -LiteralPath $To)) 'Move destination exists.'
    Closed
    Move-Item -LiteralPath $From -Destination $To
}

$ClientPath = [IO.Path]::GetFullPath($ClientPath).TrimEnd('\','/')
Plain $ClientPath
Require ((Get-Item -LiteralPath $ClientPath).PSIsContainer) 'ClientPath must be a directory.'
$AddonRoot = Join-Path $ClientPath 'Interface\AddOns'
Plain $AddonRoot
Require ((Test-Path -LiteralPath (Join-Path $ClientPath 'Ascension.exe')) -or (Test-Path -LiteralPath (Join-Path $ClientPath 'Wow.exe'))) 'Select an existing CoA client directory containing Ascension.exe or Wow.exe.'
$BackupBase = Join-Path (Split-Path -Parent $ClientPath) 'CoAAddonBackups'
if (Test-Path -LiteralPath $BackupBase) { Plain $BackupBase }

if ($Action -eq 'Rollback') {
    Closed
    Require (-not [string]::IsNullOrWhiteSpace($ReceiptPath)) 'Rollback requires the installed.json receipt printed by Install.'
    $ReceiptPath = [IO.Path]::GetFullPath($ReceiptPath)
    Plain $ReceiptPath
    $backup = Split-Path -Parent $ReceiptPath
    Require ((Split-Path -Parent $backup) -ceq $BackupBase -and (Split-Path -Leaf $backup) -match '^coa-addons-[a-f0-9]{32}$' -and (Split-Path -Leaf $ReceiptPath) -ceq 'installed.json') 'Unexpected backup receipt location.'
    $receipt = Get-Content -LiteralPath $ReceiptPath -Raw | ConvertFrom-Json -AsHashtable
    Require ($receipt.schema -eq 1 -and $receipt.status -ceq 'installed' -and $receipt.client -ceq $ClientPath) 'Receipt belongs to a different client or installation.'
    Require ($receipt.addons.Count -gt 0 -and $receipt.addons.Count -le 4) 'Invalid receipt addon inventory.'
    $seen = @{}
    foreach ($item in $receipt.addons) {
        Require ($item.id -cin $Known -and -not $seen.ContainsKey($item.id)) 'Unexpected or duplicate addon in receipt.'
        $seen[$item.id] = $true
        EqualFiles $item.after (Inventory (Join-Path $AddonRoot $item.id)) ('Installed addon changed; rollback refused: ' + $item.id)
        if ($item.had_original) { EqualFiles $item.before (Inventory (Join-Path $backup ('original-' + $item.id))) 'Backup changed; rollback refused.' }
    }
    if (-not $PSCmdlet.ShouldProcess($ClientPath,'Restore selected addon folders from the verified backup')) { return }
    foreach ($item in $receipt.addons) {
        $target = Join-Path $AddonRoot $item.id
        SafeMove $target (Join-Path $backup ('rolled-back-' + $item.id)) $item.id $backup
        if ($item.had_original) {
            SafeMove (Join-Path $backup ('original-' + $item.id)) $target $item.id $backup
            EqualFiles $item.before (Inventory $target) 'Restored addon differs.'
        }
    }
    SaveNew (Join-Path $backup 'rollback.json') @{schema=1;status='rolled-back';client=$ClientPath;utc=[DateTimeOffset]::UtcNow.ToString('o')}
    Write-Output 'Rollback complete. WTF and other addons were not modified.'
    return
}

Require (-not [string]::IsNullOrWhiteSpace($PackageDirectory)) 'Check and Install require PackageDirectory containing release.json and its ZIP files.'
$PackageDirectory = [IO.Path]::GetFullPath($PackageDirectory)
Plain $PackageDirectory
$manifestPath = Join-Path $PackageDirectory 'release.json'
Plain $manifestPath
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -AsHashtable
Require ($manifest.schema -eq 1 -and $manifest.release_id -ceq 'g1-20261029' -and $manifest.packages.Count -eq 4) 'Unsupported release manifest.'
Require ($Addons.Count -gt 0 -and $Addons.Count -le 4 -and @($Addons | Sort-Object -Unique).Count -eq $Addons.Count) 'Choose one or more unique addons.'
$packageIds = @($manifest.packages | ForEach-Object { $_.id })
Require (@($packageIds | Sort-Object -Unique).Count -eq 4 -and @($packageIds | Where-Object { $_ -cnotin $Known }).Count -eq 0) 'Unexpected release packages.'
$validated = @()
foreach ($id in $Addons) {
    Require ($id -cin $Known) ('Unknown addon: ' + $id)
    $package = @($manifest.packages | Where-Object { $_.id -ceq $id })[0]
    Require ($package.interface -eq 30300 -and $package.archive -match '^[A-Za-z0-9_.-]+\.zip$' -and $package.sha256 -match '^[a-f0-9]{64}$') 'Invalid package metadata.'
    $archivePath = Join-Path $PackageDirectory $package.archive
    Require ((FileHash $archivePath) -ceq $package.sha256) ('Package hash mismatch: ' + $id)
    Require ($package.files.Count -gt 0 -and $package.files.Count -lt 100) 'Invalid file inventory.'
    $payload = @{}
    $archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        Require ($archive.Entries.Count -eq $package.files.Count) 'Archive inventory differs.'
        $total = 0
        foreach ($entry in $archive.Entries) {
            Require ($entry.FullName.StartsWith($id + '/', [StringComparison]::Ordinal)) 'Archive contains another addon.'
            $relative = $entry.FullName.Substring($id.Length + 1)
            Require ($relative -match '^[A-Za-z0-9_.-]+$' -and $relative -notin @('.','..') -and $package.files.ContainsKey($relative) -and -not $payload.ContainsKey($relative)) 'Unexpected or unsafe archive path.'
            Require ($entry.Length -le 5MB -and $entry.Length -ge 0) 'Archive entry too large.'
            $total += $entry.Length
            Require ($total -le 16MB) 'Archive too large.'
            $stream = $entry.Open()
            $memory = [IO.MemoryStream]::new()
            try { $stream.CopyTo($memory); $bytes = $memory.ToArray() } finally { $stream.Dispose(); $memory.Dispose() }
            Require ((BytesHash $bytes) -ceq $package.files[$relative]) 'Archive file hash mismatch.'
            $payload[$relative] = $bytes
        }
    } finally { $archive.Dispose() }
    Require ($payload.ContainsKey($id + '.toc')) 'TOC missing.'
    $toc = [Text.Encoding]::UTF8.GetString($payload[$id + '.toc'])
    Require ($toc -match '(?m)^## Interface:\s*30300\s*$') 'Unexpected client interface.'
    foreach ($line in $toc -split '\r?\n') {
        if ($line.Trim() -and -not $line.StartsWith('#')) { Require ($payload.ContainsKey($line.Trim())) 'TOC references an absent file.' }
    }
    $target = Join-Path $AddonRoot $id
    $before = if (Test-Path -LiteralPath $target) { Inventory $target } else { @{} }
    $validated += @{id=$id;payload=$payload;had_original=(Test-Path -LiteralPath $target);before=$before;after=$package.files}
    Write-Output ($id + ' ' + $package.version + ' verified. Server: ' + $(if ($package.requires_server) { $package.requires_server } else { 'none' }))
}
if ($Action -eq 'Check') { Write-Output 'Check passed. No client files were changed.'; return }
Closed
if (-not $PSCmdlet.ShouldProcess($ClientPath,'Back up and install the selected verified CoA addons')) { return }
if (-not (Test-Path -LiteralPath $BackupBase)) { New-Item -ItemType Directory -Path $BackupBase | Out-Null }
$backup = Join-Path $BackupBase ('coa-addons-' + [Guid]::NewGuid().ToString('N'))
Require ((Split-Path -Parent ([IO.Path]::GetFullPath($backup))) -ceq $BackupBase -and -not (Test-Path -LiteralPath $backup)) 'Unexpected backup path.'
New-Item -ItemType Directory -Path $backup | Out-Null
$receiptItems = @()
foreach ($item in $validated) {
    $staged = Join-Path $backup ('staged-' + $item.id)
    New-Item -ItemType Directory -Path $staged | Out-Null
    foreach ($name in $item.payload.Keys) { [IO.File]::WriteAllBytes((Join-Path $staged $name),$item.payload[$name]) }
    EqualFiles $item.after (Inventory $staged) 'Staged addon differs.'
    $receiptItems += @{id=$item.id;had_original=$item.had_original;before=$item.before;after=$item.after}
}
$receipt = @{schema=1;status='prepared';client=$ClientPath;release_id=$manifest.release_id;manifest_sha256=(FileHash $manifestPath);addons=$receiptItems;utc=[DateTimeOffset]::UtcNow.ToString('o')}
SaveNew (Join-Path $backup 'intent.json') $receipt
try {
    foreach ($item in $validated) {
        $target = Join-Path $AddonRoot $item.id
        if ($item.had_original) {
            EqualFiles $item.before (Inventory $target) 'Addon changed during installation.'
            SafeMove $target (Join-Path $backup ('original-' + $item.id)) $item.id $backup
        }
        SafeMove (Join-Path $backup ('staged-' + $item.id)) $target $item.id $backup
        EqualFiles $item.after (Inventory $target) 'Installed addon differs.'
    }
    $receipt.status = 'installed'
    SaveNew (Join-Path $backup 'installed.json') $receipt
} catch {
    $failure = $_
    foreach ($item in $validated) {
        $target = Join-Path $AddonRoot $item.id
        $original = Join-Path $backup ('original-' + $item.id)
        $staged = Join-Path $backup ('staged-' + $item.id)
        if (-not (Test-Path -LiteralPath $staged) -and (Test-Path -LiteralPath $target)) {
            EqualFiles $item.after (Inventory $target) 'Unexpected destination after failure; retained for recovery.'
            SafeMove $target (Join-Path $backup ('failed-' + $item.id)) $item.id $backup
        }
        if (Test-Path -LiteralPath $original) { SafeMove $original $target $item.id $backup }
    }
    throw $failure
}
Write-Output ('Installed. Restart the client. Receipt: ' + (Join-Path $backup 'installed.json'))
