# Bote.psm1 - back-of-the-envelope constants and helpers for PowerShell 5.1 / 7+
# Constants become global variables in SI units: $c $h $hbar $qe $kB $NA $G $me ...
# Note: PowerShell variable names are case-insensitive; names in constants.json are unique ignoring case.
# They are ordinary globals (not read-only) so loop variables like $c or $f in your own code still work.

$script:Table = Get-Content (Join-Path $PSScriptRoot 'constants.json') -Raw | ConvertFrom-Json

foreach ($k in $script:Table) {
    Set-Variable -Name $k.name -Value ([double]$k.value) -Scope Global -Force
}
Set-Variable -Name pi -Value ([math]::PI) -Scope Global -Force
Set-Variable -Name e  -Value ([math]::E)  -Scope Global -Force   # Euler; charge is $qe

# Python used by the `bote` bridge (python on PATH, else the py launcher)
$script:Py = @('python', 'python3', 'py') |
    ForEach-Object { Get-Command $_ -CommandType Application -ErrorAction SilentlyContinue } |
    Select-Object -First 1

function Get-Constant {
    <# .SYNOPSIS List/search constants.  const mass #>
    param([string]$Pattern = '')
    $script:Table | Where-Object { $_.name -like "*$Pattern*" -or $_.desc -like "*$Pattern*" } |
        Select-Object @{n='Name';e={$_.name}}, @{n='Value';e={([double]$_.value).ToString('G10', [Globalization.CultureInfo]::InvariantCulture)}},
                      @{n='Unit';e={$_.unit}}, @{n='Description';e={$_.desc}}
}

function Format-Eng {
    <# .SYNOPSIS Engineering notation.  eng 0.00123 A  ->  1.23 mA #>
    param([Parameter(Mandatory, ValueFromPipeline)][double]$Value, [string]$Unit = '', [int]$Sig = 3)
    process {
        if ($Value -eq 0 -or [double]::IsNaN($Value) -or [double]::IsInfinity($Value)) { return "$Value $Unit".Trim() }
        $inv = [Globalization.CultureInfo]::InvariantCulture
        $m = [double]::Parse($Value.ToString("G$Sig", $inv), $inv)
        $p = [int]([math]::Floor([math]::Floor([math]::Log10([math]::Abs($m))) / 3) * 3)
        $p = [math]::Max(-24, [math]::Min(24, $p))
        $mant = ($m / [math]::Pow(10, $p)).ToString("G$Sig", $inv)
        if ($Unit) {
            $pre = @{-24='y';-21='z';-18='a';-15='f';-12='p';-9='n';-6=[string][char]0xB5;-3='m';
                     0='';3='k';6='M';9='G';12='T';15='P';18='E';21='Z';24='Y'}[$p]
            "$mant $pre$Unit"
        } elseif ($p -eq 0) { $mant } else { '{0}e{1:+00;-00}' -f $mant, $p }
    }
}

function oom  { param([double]$x) [int][math]::Floor([math]::Log10([math]::Abs($x))) }
function sqrt { param([double]$x) [math]::Sqrt($x) }
function cbrt { param([double]$x) [math]::Sign($x) * [math]::Pow([math]::Abs($x), 1.0/3) }
function ln   { param([double]$x) [math]::Log($x) }
function log10{ param([double]$x) [math]::Log10($x) }
function exp  { param([double]$x) [math]::Exp($x) }

function Invoke-Bote {
    <# .SYNOPSIS Evaluate a Python expression with all constants, math and pint units.
       bote "sqrt(2*G*Mearth/Rearth)"      bote "(Q.c**2 * 1*u.g).to('kWh')" #>
    if (-not $script:Py) { throw 'Python not found on PATH.' }
    $old = $env:PYTHONUTF8; $env:PYTHONUTF8 = '1'
    try {
        $enc = [Console]::OutputEncoding; [Console]::OutputEncoding = [Text.Encoding]::UTF8
        & $script:Py.Source (Join-Path $PSScriptRoot 'bote.py') ($args -join ' ')
    } finally { [Console]::OutputEncoding = $enc; $env:PYTHONUTF8 = $old }
}

Set-Alias const Get-Constant
Set-Alias eng   Format-Eng
Set-Alias bote  Invoke-Bote

Export-ModuleMember -Function * -Alias *
