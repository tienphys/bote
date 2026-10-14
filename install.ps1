# install.ps1 - sets up bote for PowerShell and Python (current user, no admin needed)
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
param([string]$Dest = (Join-Path $HOME '.bote'))
$ErrorActionPreference = 'Stop'

# 1. Copy files
New-Item -ItemType Directory -Force $Dest | Out-Null
'constants.json', 'bote.py', 'Bote.psm1' | ForEach-Object { Copy-Item -Force (Join-Path $PSScriptRoot $_) $Dest }
Get-ChildItem $Dest | Unblock-File
Write-Host "Files copied to $Dest"

# 2. Python: units library + env vars (startup file, importable module)
$py = @('python', 'py') | ForEach-Object { Get-Command $_ -CommandType Application -ErrorAction SilentlyContinue } | Select-Object -First 1
if ($py) {
    & $py.Source -m pip install --user --upgrade --quiet pint
    Write-Host "pint installed for $($py.Source)"
} else {
    Write-Warning 'Python not found on PATH - install it (winget install Python.Python.3.13), then rerun.'
}
[Environment]::SetEnvironmentVariable('PYTHONSTARTUP', (Join-Path $Dest 'bote.py'), 'User')
[Environment]::SetEnvironmentVariable('BOTE_HOME', $Dest, 'User')
$pp = [Environment]::GetEnvironmentVariable('PYTHONPATH', 'User')
if (-not $pp -or ($pp -split ';') -notcontains $Dest) {
    [Environment]::SetEnvironmentVariable('PYTHONPATH', (@($pp, $Dest) | Where-Object { $_ }) -join ';', 'User')
}
Write-Host 'PYTHONSTARTUP / PYTHONPATH set (user scope)'

# 3. PowerShell profiles (both Windows PowerShell 5.1 and PowerShell 7)
$docs = [Environment]::GetFolderPath('MyDocuments')
$line = "Import-Module '$(Join-Path $Dest 'Bote.psm1')'"
foreach ($dir in 'WindowsPowerShell', 'PowerShell') {
    $prof = Join-Path $docs "$dir\profile.ps1"
    New-Item -ItemType Directory -Force (Split-Path $prof) | Out-Null
    if (-not (Test-Path $prof) -or -not (Select-String -Path $prof -SimpleMatch 'Bote.psm1' -Quiet)) {
        Add-Content -Path $prof -Value "`n$line"
        Write-Host "Added to $prof"
    }
}

# 4. Profiles only run if scripts are allowed for the current user
if ((Get-ExecutionPolicy -Scope CurrentUser) -in 'Undefined', 'Restricted', 'AllSigned') {
    Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
    Write-Host 'Execution policy set to RemoteSigned (CurrentUser)'
}
Write-Host "`nDone. Open a NEW terminal, then try:  `$c * 1e-9   |   const mass   |   bote `"sqrt(2*G*Mearth/Rearth)`""