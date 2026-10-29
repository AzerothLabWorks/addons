#Requires -Version 7.0
param([string]$Python = 'python')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$installer = Join-Path $repo 'scripts\Install-CoAAddons.ps1'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$testRoot = Join-Path $tempBase ('coa-addon-test-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
$global:CoAAddonInstallerTestState = @{Running=$false}
function Get-Process {
    [CmdletBinding()] param([string[]]$Name)
    if ($global:CoAAddonInstallerTestState.Running) { [pscustomobject]@{Name='Wow'} }
}
function Assert([bool]$Value,[string]$Message) { if (-not $Value) { throw $Message } }
function Fails([scriptblock]$Code,[string]$Pattern) {
    $caught = $null
    try { & $Code | Out-Null } catch { $caught = $_.Exception.Message }
    Assert ($null -ne $caught -and $caught -match $Pattern) ('Expected failure ' + $Pattern + ', got ' + $caught)
}
try {
    $client = Join-Path $testRoot 'Client'
    $addons = Join-Path $client 'Interface\AddOns'
    New-Item -ItemType Directory -Path $addons -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $client 'WTF'),(Join-Path $addons 'OtherAddon'),(Join-Path $addons 'COAResourceMonitor') | Out-Null
    [IO.File]::WriteAllText((Join-Path $client 'Wow.exe'),'test fixture, not executable')
    [IO.File]::WriteAllText((Join-Path $client 'WTF\untouched.txt'),'saved settings')
    [IO.File]::WriteAllText((Join-Path $addons 'OtherAddon\keep.lua'),'other addon')
    [IO.File]::WriteAllText((Join-Path $addons 'COAResourceMonitor\old.txt'),'old addon')
    $packages = Join-Path $testRoot 'Packages'
    & $Python (Join-Path $PSScriptRoot 'package.py') --output $packages
    Assert ($LASTEXITCODE -eq 0) 'Package generation failed.'
    & $installer -ClientPath $client -PackageDirectory $packages -Action Check | Out-Null
    Assert (-not (Test-Path -LiteralPath (Join-Path $testRoot 'CoAAddonBackups'))) 'Check wrote a backup.'
    Assert (Test-Path -LiteralPath (Join-Path $addons 'COAResourceMonitor\old.txt')) 'Check changed an addon.'
    & $installer -ClientPath $client -PackageDirectory $packages -Action Install -WhatIf | Out-Null
    Assert (-not (Test-Path -LiteralPath (Join-Path $testRoot 'CoAAddonBackups'))) 'WhatIf wrote a backup.'
    $global:CoAAddonInstallerTestState.Running = $true
    Fails { & $installer -ClientPath $client -PackageDirectory $packages -Action Install } 'Fully close'
    $global:CoAAddonInstallerTestState.Running = $false
    & $installer -ClientPath $client -PackageDirectory $packages -Action Install | Out-Null
    $receiptPath = @(Get-ChildItem -LiteralPath (Join-Path $testRoot 'CoAAddonBackups') -Recurse -Filter installed.json)[0].FullName
    $receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json -AsHashtable
    Assert ($receipt.addons.Count -eq 4) 'Not all selected addons installed.'
    foreach ($entry in $receipt.addons) {
        foreach ($name in $entry.after.Keys) {
            $hash = (Get-FileHash -LiteralPath (Join-Path $addons ($entry.id + '\' + $name))).Hash.ToLowerInvariant()
            Assert ($hash -ceq $entry.after[$name]) 'Installed package differs.'
        }
    }
    $changed = Join-Path $addons 'COAResourceMonitor\COAResourceMonitor.lua'
    $original = [IO.File]::ReadAllBytes($changed)
    [IO.File]::AppendAllText($changed,"`n-- user edit")
    Fails { & $installer -ClientPath $client -Action Rollback -ReceiptPath $receiptPath } 'Installed addon changed'
    [IO.File]::WriteAllBytes($changed,$original)
    & $installer -ClientPath $client -Action Rollback -ReceiptPath $receiptPath | Out-Null
    Assert ((Get-Content -LiteralPath (Join-Path $addons 'COAResourceMonitor\old.txt') -Raw) -ceq 'old addon') 'Original addon not restored.'
    Assert (-not (Test-Path -LiteralPath (Join-Path $addons 'CoAGatheringAlerts'))) 'New addon not rolled back.'
    Assert ((Get-Content -LiteralPath (Join-Path $client 'WTF\untouched.txt') -Raw) -ceq 'saved settings') 'WTF changed.'
    Assert ((Get-Content -LiteralPath (Join-Path $addons 'OtherAddon\keep.lua') -Raw) -ceq 'other addon') 'Other addon changed.'
    & $installer -ClientPath $client -PackageDirectory $packages -Addons 'CoAGatheringAlerts,COAResourceMonitor' -Action Install | Out-Null
    $selectiveReceipt = @(Get-ChildItem -LiteralPath (Join-Path $testRoot 'CoAAddonBackups') -Recurse -Filter installed.json | Where-Object FullName -ne $receiptPath)[0].FullName
    $selected = Get-Content -LiteralPath $selectiveReceipt -Raw | ConvertFrom-Json -AsHashtable
    Assert ($selected.addons.Count -eq 2 -and -not (Test-Path -LiteralPath (Join-Path $addons 'GMCommandCenter_CoA'))) 'Comma-separated selection installed unintended addons.'
    & $installer -ClientPath $client -Action Rollback -ReceiptPath $selectiveReceipt | Out-Null
    $release = Get-Content -LiteralPath (Join-Path $packages 'release.json') -Raw | ConvertFrom-Json -AsHashtable
    $archive = Join-Path $packages $release.packages[0].archive
    $archiveBytes = [IO.File]::ReadAllBytes($archive)
    [IO.File]::AppendAllText($archive,'corruption')
    Fails { & $installer -ClientPath $client -PackageDirectory $packages -Action Check } 'Package hash mismatch'
    [IO.File]::WriteAllBytes($archive,$archiveBytes)
    $malicious = [IO.Compression.ZipFile]::Open($archive,[IO.Compression.ZipArchiveMode]::Update)
    try {
        $entry = $malicious.CreateEntry($release.packages[0].id + '/../escape.lua')
        $stream = $entry.Open()
        try { $stream.WriteByte(65) } finally { $stream.Dispose() }
    } finally { $malicious.Dispose() }
    $release.packages[0].files['../escape.lua'] = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([byte[]]@(65))).ToLowerInvariant()
    $release.packages[0].sha256 = (Get-FileHash -LiteralPath $archive).Hash.ToLowerInvariant()
    [IO.File]::WriteAllText((Join-Path $packages 'release.json'),($release | ConvertTo-Json -Depth 12))
    Fails { & $installer -ClientPath $client -PackageDirectory $packages -Action Install } 'unsafe archive path'
    Assert (-not (Test-Path -LiteralPath (Join-Path $client 'escape.lua'))) 'Archive traversal escaped into client.'
    Write-Output 'INSTALLER TESTS PASSED: preview, WhatIf, running-client refusal, four-addon and selective install, integrity, changed-file refusal, rollback, preservation, tamper rejection and traversal rejection. Disposable fixtures only.'
} finally {
    $resolved = [IO.Path]::GetFullPath($testRoot)
    Assert ($resolved.StartsWith($tempBase,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $resolved) -match '^coa-addon-test-[a-f0-9]{32}$') 'Cleanup path escaped the disposable test directory.'
    Remove-Item -LiteralPath $resolved -Recurse -Force
    Remove-Variable -Name CoAAddonInstallerTestState -Scope Global
}
