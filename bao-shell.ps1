# bao's profile
# you can run this script normally without admin

[CmdletBinding()]
param(
    [switch]$SkipFont,
    [switch]$NoBackup,
    [switch]$Force,
    [switch]$Uninstall,
    [switch]$BaoRelaunched
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

try { Unblock-File -LiteralPath $PSCommandPath -ErrorAction SilentlyContinue } catch {}
try { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue } catch {}

try {
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    chcp 65001 > $null
} catch {}

$Palette = @('#EAF7FF', '#D9F0FF', '#C7E8FF', '#B8E7FF', '#A9D9FF', '#90C8FF', '#70B5F5', '#579DEB')
$Accent = '#A0C4FF'
$Dim = '#6E93B8'
$Esc = [char]27
$Reset = "$Esc[0m"

$Script:FgCache = @{}
function Write-Fg($hex) {
    if (-not $Script:FgCache.ContainsKey($hex)) {
        $clean = $hex.TrimStart('#')
        $r = [Convert]::ToInt32($clean.Substring(0,2), 16)
        $g = [Convert]::ToInt32($clean.Substring(2,2), 16)
        $b = [Convert]::ToInt32($clean.Substring(4,2), 16)
        $Script:FgCache[$hex] = "$Esc[38;2;$r;$g;${b}m"
    }
    return $Script:FgCache[$hex]
}

function Write-Gradient {
    param([string]$Text, [string[]]$Colors = $Palette)
    $lines = $Text -split "`r?`n"
    $count = $Colors.Count
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $color = $Colors[$i % $count]
        Write-Host "$(Write-Fg $color)$($lines[$i])$Reset"
    }
}

function Clear-Line {
    try {
        if ([Console]::IsOutputRedirected) {
            Write-Host "`r" -NoNewline
            return
        }
        $w = Get-ConsoleWidth
        Write-Host ("`r" + (' ' * [Math]::Max(1, $w - 1)) + "`r") -NoNewline
    } catch {
        try { Write-Host "`r" -NoNewline } catch {}
    }
}

function LogHeader($title) {
    Write-Host "  $(Write-Fg '#EAF7FF')$([char]0x25C6)  $(Write-Fg '#B8E7FF')$title$Reset"
}

function Log($msg, $color = '#C7E8FF') {
    Write-Host "  $(Write-Fg $color)$msg$Reset"
}

function Ok($msg) {
    if ($msg -match '^(.*?\s+->\s+)(.*)$') {
        $action = $matches[1]
        $path   = $matches[2]
        Write-Host "  $(Write-Fg '#70B5F5')$([char]0x2713)$Reset  $(Write-Fg '#EAF7FF')$action$Reset$(Write-Fg '#6E93B8')$path$Reset"
    } else {
        Write-Host "  $(Write-Fg '#70B5F5')$([char]0x2713)$Reset  $(Write-Fg '#EAF7FF')$msg$Reset"
    }
}

function Note($msg) {
    if ($msg -match '^(.*?\s+->\s+)(.*)$') {
        $action = $matches[1]
        $path   = $matches[2]
        Write-Host "  $(Write-Fg '#579DEB')$([char]0x2192)$Reset  $(Write-Fg '#C7E8FF')$action$Reset$(Write-Fg '#6E93B8')$path$Reset"
    } else {
        Write-Host "  $(Write-Fg '#579DEB')$([char]0x2192)$Reset  $(Write-Fg '#C7E8FF')$msg$Reset"
    }
}

function Get-ConsoleWidth {
    try {
        $w = $Host.UI.RawUI.WindowSize.Width
        if ($w -gt 10) { return $w }
    } catch {}
    return 80
}

function Write-Centered {
    param([string]$Text, [string[]]$Colors = $Palette, [switch]$Plain)
    $width = Get-ConsoleWidth
    $lines = $Text -split "`r?`n"
    $maxLen = ($lines | Measure-Object -Property Length -Maximum).Maximum
    $pad = [Math]::Max(0, [Math]::Floor(($width - $maxLen) / 2))
    $count = $Colors.Count
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = (' ' * $pad) + $lines[$i]
        if ($Plain) { Write-Host $line }
        else { Write-Host "$(Write-Fg $Colors[$i % $count])$line$Reset" }
    }
}

function Write-CenteredLine {
    param([string]$Text, [string]$Color = $Accent)
    $width = Get-ConsoleWidth
    $pad = [Math]::Max(0, [Math]::Floor(($width - $Text.Length) / 2))
    Write-Host "$(' ' * $pad)$(Write-Fg $Color)$Text$Reset"
}

function Write-ResultCard {
    param(
        [Parameter(Mandatory)][string]$Title,
        [string]$Subtitle = 'press enter to return to main menu'
    )
    Write-Host ''
    $bColor   = Write-Fg '#579DEB'
    $tColor   = Write-Fg '#EAF7FF'
    $sColor   = Write-Fg '#A9D9FF'
    $dimColor = Write-Fg '#70B5F5'

    Write-Host "  $bColor$([char]0x256D)$(([char]0x2500).ToString() * 58)$([char]0x256E)$Reset"
    Write-Host "  $bColor$([char]0x2502)$Reset  $tColor$([char]0x2713) $Title$Reset"
    if ($Subtitle) {
        Write-Host "  $bColor$([char]0x2502)$Reset  $dimColor$([char]0x2192) $sColor$Subtitle$Reset"
    }
    Write-Host "  $bColor$([char]0x2570)$(([char]0x2500).ToString() * 58)$([char]0x256F)$Reset"
    Write-Host ''
}

function Write-StatusBox {
    param([object[]]$Rows)

    $maxLabelW  = 14
    $maxStatusW = 12
    $leftPad    = 3
    $midGap     = 3
    $rightPad   = 3

    $contentW   = $leftPad + $maxLabelW + $midGap + $maxStatusW + $rightPad
    $boxW       = $contentW + 2
    $consoleW   = Get-ConsoleWidth
    $pad        = [Math]::Max(0, [Math]::Floor(($consoleW - $boxW) / 2))
    $padStr     = ' ' * $pad
    $border     = Write-Fg '#A0C4FF'

    Write-Host "$padStr$border$([char]0x256D)$(([char]0x2500).ToString() * $contentW)$([char]0x256E)$Reset"
    foreach ($r in $Rows) {
        $done  = $r.Done
        $icon  = if ($done) { '●' } else { '○' }
        $color = if ($done) { '#A9D9FF' } else { '#5E7590' }
        $iconColor = if ($done) { '#A0C4FF' } else { '#4A627A' }
        $tagColor  = if ($done) { '#90BBE6' } else { '#4A627A' }

        $labelStr  = $r.Label.PadRight($maxLabelW)
        $tagStr    = $r.Tag
        $statusLen = 1 + $(if ($tagStr) { 2 + $tagStr.Length } else { 0 })
        # Fixed column math ensures top border, inner content, and bottom border match 100%
        $fillCount = [Math]::Max(0, $maxStatusW - $statusLen + $rightPad)
        $fillStr   = ' ' * $fillCount

        $line = "$border$([char]0x2502)$Reset" +
                "$(' ' * $leftPad)" +
                "$(Write-Fg $color)$labelStr$Reset" +
                "$(' ' * $midGap)" +
                "$(Write-Fg $iconColor)$icon$Reset" +
                "$(if ($tagStr) { "  $(Write-Fg $tagColor)$tagStr$Reset" } else { '' })" +
                "$fillStr" +
                "$border$([char]0x2502)$Reset"
        Write-Host "$padStr$line"
    }
    Write-Host "$padStr$border$([char]0x2570)$(([char]0x2500).ToString() * $contentW)$([char]0x256F)$Reset"
}

function Write-MessageBox {
    param([string[]]$Lines)

    $w = ($Lines | Measure-Object -Property Length -Maximum).Maximum
    $boxW     = $w + 6
    $consoleW = Get-ConsoleWidth
    $pad      = [Math]::Max(0, [Math]::Floor(($consoleW - $boxW) / 2))
    $padStr   = ' ' * $pad
    $border   = Write-Fg $Accent

    Write-Host "$padStr$border$([char]0x256D)$(([char]0x2500).ToString() * ($boxW - 2))$([char]0x256E)$Reset"
    foreach ($l in $Lines) {
        $line = $l.PadRight($w)
        Write-Host "$padStr$border$([char]0x2502)$Reset  $(Write-Fg '#EAF7FF')$line$Reset  $border$([char]0x2502)$Reset"
    }
    Write-Host "$padStr$border$([char]0x2570)$(([char]0x2500).ToString() * ($boxW - 2))$([char]0x256F)$Reset"
}

function Sync-Path {
    $env:PATH = @(
        [Environment]::GetEnvironmentVariable('PATH', 'Machine')
        [Environment]::GetEnvironmentVariable('PATH', 'User')
    ) -join ';'
}

$SpinnerFrames = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')

function Invoke-Task {
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][scriptblock]$Action,
        [string]$DoneLabel = $null
    )

    $textColor = Write-Fg '#C7E8FF'

    for ($i = 0; $i -lt 8; $i++) {
        $frame = $SpinnerFrames[$i % $SpinnerFrames.Count]
        $color = Write-Fg $Palette[$i % $Palette.Count]
        Clear-Line
        try { Write-Host "  $color$frame$Reset  $textColor$Label$Reset..." -NoNewline } catch {}
        Start-Sleep -Milliseconds 40
    }

    try {
        & $Action
        Clear-Line
        if ($DoneLabel) { Ok $DoneLabel } else { Ok $Label }
        return $true
    } catch {
        Clear-Line
        Log "$([char]0x2715)  $Label failed: $_" '#579DEB'
        return $false
    }
}

function Get-FailureReason {
    param([int]$ExitCode, [string]$StdText)
    # Match standard winget exit codes and output phrases
    if ($StdText -match 'administrator|admin|0x8a15002b|-1978335189') {
        return 'requires admin privileges'
    }
    if ($StdText -match 'already installed|existing package|No available upgrade|0x8a15004f|-1978335153') {
        return 'already installed'
    }
    if ($StdText -match 'No package found|No sources|source') {
        return 'winget source error'
    }
    if ($StdText -match 'Access is denied|0x80070005') {
        return 'access denied'
    }
    if ($StdText -match '(0x[0-9a-fA-F]{8})') {
        return "winget error $($Matches[1])"
    }
    if ($StdText) {
        $clean = ($StdText -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1).Trim()
        if ($clean.Length -gt 40) { $clean = $clean.Substring(0, 37) + '...' }
        if ($clean) { return $clean }
    }
    return "exit code $ExitCode"
}

function Invoke-ExternalTask {
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [string]$DoneLabel = $null
    )

    $textColor = Write-Fg '#C7E8FF'
    $stdOut = [System.IO.Path]::GetTempFileName()
    $stdErr = [System.IO.Path]::GetTempFileName()
    $exitCode = 1
    $capturedText = ''

    try {
        $proc = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList `
            -NoNewWindow -PassThru `
            -RedirectStandardOutput $stdOut -RedirectStandardError $stdErr

        $frameIdx = 0
        while (-not $proc.HasExited) {
            Start-Sleep -Milliseconds 80
            if ($proc.HasExited) { break }
            $frame = $SpinnerFrames[$frameIdx % $SpinnerFrames.Count]
            $color = Write-Fg $Palette[$frameIdx % $Palette.Count]
            $frameIdx++
            Clear-Line
            try { Write-Host "  $color$frame$Reset  $textColor$Label$Reset..." -NoNewline } catch {}
        }
        $proc.WaitForExit()
        $exitCode = $proc.ExitCode

        if (Test-Path -LiteralPath $stdErr) { $capturedText += (Get-Content -LiteralPath $stdErr -Raw -ErrorAction SilentlyContinue) }
        if (Test-Path -LiteralPath $stdOut) { $capturedText += ' ' + (Get-Content -LiteralPath $stdOut -Raw -ErrorAction SilentlyContinue) }
    } catch {
        $exitCode = 1
        $capturedText = $_.Exception.Message
    } finally {
        Remove-Item $stdOut, $stdErr -Force -ErrorAction SilentlyContinue
    }

    Clear-Line

    if ($exitCode -ne 0) {
        $reason = Get-FailureReason -ExitCode $exitCode -StdText $capturedText
        Log "$([char]0x2715)  $Label failed: $reason" '#579DEB'
        return $false
    } else {
        if ($DoneLabel) { Ok $DoneLabel } else { Ok $Label }
        return $true
    }
}

$Banner = @'
██████   █████   ██████      ███████ ██   ██ ███████ ██      ██
██   ██ ██   ██ ██    ██     ██      ██   ██ ██      ██      ██
██████  ███████ ██    ██     ███████ ███████ █████   ██      ██
██   ██ ██   ██ ██    ██          ██ ██   ██ ██      ██      ██
██████  ██   ██  ██████      ███████ ██   ██ ███████ ███████ ███████

'@

$RepoRawBase = 'https://raw.githubusercontent.com/ruru-o/bao-shell/main'
$RepoFiles = @{
    'ascii.txt' = "$RepoRawBase/config/ascii.txt"
    'config.jsonc' = "$RepoRawBase/config/config.jsonc"
    'Microsoft.PowerShell_profile.ps1' = "$RepoRawBase/profile/Microsoft.PowerShell_profile.ps1"
}

function Get-RemoteBytes {
    param([Parameter(Mandatory)][string]$Uri)

    $wc = New-Object System.Net.WebClient
    $wc.Headers['User-Agent'] = 'bao-shell-profile-installer'
    try {
        return $wc.DownloadData($Uri)
    } finally {
        $wc.Dispose()
    }
}

function Get-Utf8TextFromBytes {
    param([byte[]]$Bytes)
    # Explicit UTF-8 decoding prevents Windows PowerShell 5.1 from parsing glyphs via active codepage
    $enc = New-Object System.Text.UTF8Encoding($false, $true)
    return $enc.GetString($Bytes)
}

function Write-Utf8NoBom {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Content)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

function Write-Utf8Bom {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Content)
    # UTF-8 BOM encoding ensures PowerShell 5.1 dot-sources profile files with unicode support
    $enc = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

function Backup-File {
    param([Parameter(Mandatory)][string]$Path)

    if ((Test-Path -LiteralPath $Path -PathType Leaf) -and -not $NoBackup) {
        $content = Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue
        if ($content -and ($content -match 'fastfetch' -or $content -match 'oh-my-posh' -or $content -match 'BaoFastfetch')) {
            return
        }
        $bak = "$Path.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -LiteralPath $Path -Destination $bak -Force
        Note "backed up existing file -> $bak"
    }
}

function Get-PortableRepoText {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$ActualHome
    )
    $portableHome = $ActualHome -replace '\\', '/'
    return $Text.Replace('C:/Users/User', $portableHome)
}

function Install-RepoFiles {
    $actualHome = $env:USERPROFILE
    if ([string]::IsNullOrWhiteSpace($actualHome)) {
        throw 'USERPROFILE is not available; cannot determine the current user home directory.'
    }

    $fastfetchDir = Join-Path $actualHome '.config\fastfetch'
    New-Item -ItemType Directory -Path $fastfetchDir -Force | Out-Null

    Invoke-Task -Label 'fetching ascii.txt' -Action {
        $bytes = (New-Object System.Net.WebClient).DownloadData($RepoFiles['ascii.txt'])
        [System.IO.File]::WriteAllBytes((Join-Path $fastfetchDir 'ascii.txt'), $bytes)
    } -DoneLabel "ascii.txt" | Out-Null

    Invoke-Task -Label 'fetching config.jsonc' -Action {
        $wc = New-Object System.Net.WebClient
        $bytes = $wc.DownloadData($RepoFiles['config.jsonc'])
        $enc = New-Object System.Text.UTF8Encoding($false, $true)
        $text = $enc.GetString($bytes)
        $portableHome = $actualHome -replace '\\', '/'
        $text = $text.Replace('C:/Users/User', $portableHome)
        $outEnc = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText((Join-Path $fastfetchDir 'config.jsonc'), $text, $outEnc)
    } -DoneLabel "config.jsonc" | Out-Null

    $docs = [Environment]::GetFolderPath('MyDocuments')
    $targets = @(
        (Join-Path $docs 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
        (Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1')
    )

    $profileBytes = Get-RemoteBytes $RepoFiles['Microsoft.PowerShell_profile.ps1']
    $profileText = Get-Utf8TextFromBytes $profileBytes
    $profileText = Get-PortableRepoText -Text $profileText -ActualHome $actualHome

    # Upstream profile check is expanded into two lines for Windows PowerShell 5.1 parser compatibility
    $profileText = $profileText.Replace(
        'if (Get-Command fastfetch -ErrorAction SilentlyContinue) {',
        '$BaoFastfetch = Get-Command -Name fastfetch -ErrorAction SilentlyContinue' + "`r`n" +
        'if ($null -ne $BaoFastfetch) {'
    )

    foreach ($target in $targets) {
        $leaf = Split-Path -Leaf (Split-Path -Parent $target)
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        Backup-File -Path $target
        Invoke-Task -Label "writing $leaf profile" -Action {
            Write-Utf8Bom -Path $target -Content $profileText
        } -DoneLabel "$leaf profile" | Out-Null
    }
}

$Script:BaoTargetsCache = $null
function Get-BaoTargets {
    if ($null -ne $Script:BaoTargetsCache) { return $Script:BaoTargetsCache }
    $actualHome = $env:USERPROFILE
    $docs = [Environment]::GetFolderPath('MyDocuments')
    $Script:BaoTargetsCache = @{
        FastfetchDir = Join-Path $actualHome '.config\fastfetch'
        ProfileTargets = @(
            (Join-Path $docs 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
            (Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1')
        )
    }
    return $Script:BaoTargetsCache
}

function Test-BaoInstalled {
    $t = Get-BaoTargets
    foreach ($p in $t.ProfileTargets) {
        if (Test-Path -LiteralPath $p -PathType Leaf) {
            $content = Get-Content -LiteralPath $p -Raw -ErrorAction SilentlyContinue
            if ($content -and ($content -match 'fastfetch' -or $content -match 'oh-my-posh' -or $content -match 'BaoFastfetch')) {
                return $true
            }
        }
    }
    if (Test-Path -LiteralPath (Join-Path $t.FastfetchDir 'config.jsonc') -PathType Leaf) { return $true }

    $wtPaths = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    )
    foreach ($p in $wtPaths) {
        if (Test-Path -LiteralPath $p) {
            $raw = Get-Content -LiteralPath $p -Raw -ErrorAction SilentlyContinue
            if ($raw -and ($raw -match 'One Half Dark' -or $raw -match 'Catppuccin' -or $raw -match '"opacity":\s*40')) {
                return $true
            }
        }
    }

    return $false
}

function Revert-ProfilesAndConfigs {
    $t = Get-BaoTargets

    foreach ($target in $t.ProfileTargets) {
        $targetPath = $target
        if (Test-Path -LiteralPath $targetPath -PathType Leaf) {
            Invoke-Task -Label "reverting profile -> $targetPath" -Action {
                Remove-Item -LiteralPath $targetPath -Force -ErrorAction SilentlyContinue

                $baks = Get-ChildItem -LiteralPath (Split-Path -Parent $targetPath) `
                    -Filter "$(Split-Path -Leaf $targetPath).bak-*" -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending

                $cleanBak = $null
                foreach ($b in $baks) {
                    $c = Get-Content -LiteralPath $b.FullName -Raw -ErrorAction SilentlyContinue
                    if ($c -and ($c -match 'fastfetch' -or $c -match 'oh-my-posh' -or $c -match 'BaoFastfetch')) {
                        Remove-Item -LiteralPath $b.FullName -Force -ErrorAction SilentlyContinue
                    } else {
                        if (-not $cleanBak) { $cleanBak = $b }
                    }
                }

                if ($cleanBak) {
                    Copy-Item -LiteralPath $cleanBak.FullName -Destination $targetPath -Force
                }
            } -DoneLabel "profile restored -> $targetPath" | Out-Null
        } else {
            Invoke-Task -Label "checking profile -> $targetPath" -Action {
                Start-Sleep -Milliseconds 200
            } -DoneLabel "profile already clean -> $targetPath" | Out-Null
        }
    }

    $fastfetchDir = $t.FastfetchDir
    if (Test-Path -LiteralPath $fastfetchDir -PathType Container) {
        Invoke-Task -Label "removing fastfetch config -> $fastfetchDir" -Action {
            Remove-Item -LiteralPath $fastfetchDir -Recurse -Force -ErrorAction SilentlyContinue
        } -DoneLabel "fastfetch config removed -> $fastfetchDir" | Out-Null
    } else {
        Invoke-Task -Label "checking fastfetch config -> $fastfetchDir" -Action {
            Start-Sleep -Milliseconds 200
        } -DoneLabel "fastfetch config already clean" | Out-Null
    }
}

$OneHalfDark = @{
    name = "One Half Dark"
    cursorColor = "#528BFF"
    selectionBackground = "#474E5D"
    background = "#282C34"
    foreground = "#DCDFE4"
    black = "#282C34"
    blue = "#61AFEF"
    cyan = "#56B6C2"
    green = "#98C379"
    purple = "#C678DD"
    red = "#E06C75"
    white = "#DCDFE4"
    yellow = "#E5C07B"
    brightBlack = "#5A6374"
    brightBlue = "#61AFEF"
    brightCyan = "#56B6C2"
    brightGreen = "#98C379"
    brightPurple = "#C678DD"
    brightRed = "#E06C75"
    brightWhite = "#DCDFE4"
    brightYellow = "#E5C07B"
}

function Configure-BaoTerminalSettings {
    $wtPaths = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    )

    $configured = $false
    foreach ($wtPath in $wtPaths) {
        if (Test-Path -LiteralPath $wtPath -PathType Leaf) {
            $configured = $true
            Invoke-Task -Label "configuring Windows Terminal theme (40% opacity, One Half Dark, semi-bold font)" -Action {
                $raw = Get-Content -LiteralPath $wtPath -Raw -ErrorAction SilentlyContinue
                if ($raw) {
                    $json = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($json) {
                        if (-not $json.profiles) {
                            $json | Add-Member -MemberType NoteProperty -Name 'profiles' -Value ([PSCustomObject]@{ defaults = [PSCustomObject]@{} }) -Force
                        }
                        if (-not $json.profiles.defaults) {
                            $json.profiles | Add-Member -MemberType NoteProperty -Name 'defaults' -Value ([PSCustomObject]@{}) -Force
                        }

                        #note properties inject default opacity, font weighting, and scheme across all profile instances
                        $json.profiles.defaults | Add-Member -MemberType NoteProperty -Name 'opacity' -Value 40 -Force
                        $json.profiles.defaults | Add-Member -MemberType NoteProperty -Name 'useAcrylic' -Value $true -Force
                        $json.profiles.defaults | Add-Member -MemberType NoteProperty -Name 'colorScheme' -Value 'One Half Dark' -Force

                        $fontObj = [PSCustomObject]@{
                            face = 'JetBrainsMono Nerd Font Mono'
                            weight = 'semi-bold'
                        }
                        $json.profiles.defaults | Add-Member -MemberType NoteProperty -Name 'font' -Value $fontObj -Force

                        if (-not $json.schemes) {
                            $json | Add-Member -MemberType NoteProperty -Name 'schemes' -Value @() -Force
                        }
                        $hasScheme = [bool]($json.schemes | Where-Object { $_.name -eq 'One Half Dark' })
                        if (-not $hasScheme) {
                            $schemeObj = [PSCustomObject]$OneHalfDark
                            $json.schemes = @($json.schemes) + $schemeObj
                        }

                        $newJson = $json | ConvertTo-Json -Depth 100
                        [System.IO.File]::WriteAllText($wtPath, $newJson, [System.Text.Encoding]::UTF8)
                    }
                }
            } -DoneLabel "Windows Terminal configured (40% opacity, One Half Dark, semi-bold font)" | Out-Null
        }
    }
}

function Revert-TerminalAndConsoleSettings {
    $wtPaths = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    )

    $foundWt = $false
    foreach ($wtPath in $wtPaths) {
        if (Test-Path -LiteralPath $wtPath -PathType Leaf) {
            $foundWt = $true
            Invoke-Task -Label "reverting Windows Terminal settings -> $wtPath" -Action {
                $raw = Get-Content -LiteralPath $wtPath -Raw -ErrorAction SilentlyContinue
                if ($raw) {
                    $json = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($json -and $json.profiles) {
                        if ($json.profiles.defaults) {
                            $json.profiles.defaults.PSObject.Properties.Remove('font')
                            $json.profiles.defaults.PSObject.Properties.Remove('opacity')
                            $json.profiles.defaults.PSObject.Properties.Remove('colorScheme')
                            $json.profiles.defaults.PSObject.Properties.Remove('useAcrylic')
                        }
                        if ($json.profiles.list) {
                            foreach ($p in $json.profiles.list) {
                                if ($p.font -and $p.font.face -match 'JetBrains') {
                                    $p.PSObject.Properties.Remove('font')
                                }
                                if ($p.opacity) {
                                    $p.PSObject.Properties.Remove('opacity')
                                }
                            }
                        }
                        if ($json.schemes) {
                            $json.schemes = @($json.schemes | Where-Object { $_.name -ne 'Catppuccin Mocha' -and $_.name -ne 'One Half Dark' })
                        }
                        $newJson = $json | ConvertTo-Json -Depth 100
                        [System.IO.File]::WriteAllText($wtPath, $newJson, [System.Text.Encoding]::UTF8)
                    }
                }
            } -DoneLabel "Windows Terminal font & opacity reverted to defaults" | Out-Null
        }
    }
    if (-not $foundWt) {
        Invoke-Task -Label "checking Windows Terminal settings state" -Action {
            Start-Sleep -Milliseconds 200
        } -DoneLabel "Windows Terminal settings already clean" | Out-Null
    }

    Invoke-Task -Label "reverting console registry settings (HKCU:\Console)" -Action {
        Remove-ItemProperty -Path 'HKCU:\Console' -Name 'FaceName' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path 'HKCU:\Console' -Name 'FontSize' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path 'HKCU:\Console' -Name 'WindowAlpha' -ErrorAction SilentlyContinue
    } -DoneLabel "Console registry reverted to defaults" | Out-Null
}

function Revert-Packages {
    $toRemove = @(
        @{ Name = 'oh-my-posh'; Id = 'JanDeDobbeleer.OhMyPosh' }
        @{ Name = 'fastfetch';  Id = 'Fastfetch-cli.Fastfetch' }
    )
    foreach ($pkg in $toRemove) {
        $name = $pkg.Name
        if (Get-Command ($name) -ErrorAction SilentlyContinue) {
            Invoke-ExternalTask -Label "uninstalling $name" -FilePath 'winget' `
                -ArgumentList @('uninstall', '--id', $pkg.Id, '--disable-interactivity', '--accept-source-agreements') `
                -DoneLabel "$name uninstalled" | Out-Null
        } else {
            Invoke-Task -Label "checking $name package" -Action {
                Start-Sleep -Milliseconds 200
            } -DoneLabel "$name package already clean" | Out-Null
        }
    }
}

function Invoke-Uninstall {
    param([string]$Mode = 'All')

    try { Clear-Host } catch { Write-Host "$Esc[2J$Esc[H" -NoNewline }
    Write-Host ''
    LogHeader 'reverting bao shell'

    switch ($Mode) {
        'ProfilesOnly' {
            Revert-ProfilesAndConfigs
        }
        'TerminalOnly' {
            Revert-TerminalAndConsoleSettings
        }
        'All' {
            Revert-ProfilesAndConfigs
            Revert-TerminalAndConsoleSettings
            Revert-Packages
        }
    }

    Sync-Path
    Write-Host ''
    Write-ResultCard -Title 'revert complete. open a new terminal to see changes.'
}

$Packages = @(
    @{ Name = 'PowerShell 7'; Id = 'Microsoft.PowerShell';      Cmd = 'pwsh' }
    @{ Name = 'oh-my-posh';   Id = 'JanDeDobbeleer.OhMyPosh';   Cmd = 'oh-my-posh' }
    @{ Name = 'fastfetch';    Id = 'Fastfetch-cli.Fastfetch';   Cmd = 'fastfetch' }
)

function Install-WinGet {
    if (Get-Command winget -ErrorAction SilentlyContinue) { Ok 'winget'; return }

    if (-not $Force) {
        Write-Host ''
        Note 'winget is not installed on this system.'
        $choice = Read-Host "  do you want to download and install winget now? (y/n) [default: y]"
        if ($choice -and $choice.Trim() -match '^(n|no)$') {
            Note 'skipped winget installation.'
            return
        }
    }

    Note 'winget missing - bootstrapping from GitHub releases...'
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        Import-Module Appx -UseWindowsPowerShell -ErrorAction SilentlyContinue | Out-Null
    }

    $tmp  = Join-Path $env:TEMP "bao-winget-$(Get-Random)"
    $arch = @{ AMD64 = 'x64'; ARM64 = 'arm64' }[$env:PROCESSOR_ARCHITECTURE]
    if (-not $arch) { $arch = 'x86' }
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null

    try {
        $depsZip = Join-Path $tmp 'deps.zip'
        Invoke-Task -Label 'downloading winget dependencies' -Action {
            Invoke-WebRequest -UseBasicParsing -OutFile $depsZip `
                'https://github.com/microsoft/winget-cli/releases/latest/download/DesktopAppInstaller_Dependencies.zip'
        } -DoneLabel 'winget dependencies downloaded' | Out-Null
        Expand-Archive $depsZip (Join-Path $tmp 'deps') -Force

        Get-ChildItem (Join-Path $tmp 'deps') -Recurse -Include '*.appx', '*.msix' |
            Where-Object FullName -match "\\$arch\\" |
            ForEach-Object {
                Add-AppxPackage -Path $_.FullName -ErrorAction SilentlyContinue
            }

        $bundle = Join-Path $tmp 'bundle.msixbundle'
        Invoke-Task -Label 'downloading winget package' -Action {
            Invoke-WebRequest -UseBasicParsing -OutFile $bundle `
                'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
        } -DoneLabel 'winget package downloaded' | Out-Null

        Add-AppxPackage -Path $bundle
        Ok 'winget bootstrapped successfully'
    } catch {
        Log "$([char]0x2715)  winget bootstrapping failed: $_" '#579DEB'
    } finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Ensure-WinGetSourcesReady {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            $p = Start-Process winget -ArgumentList @('source', 'update', '--disable-interactivity') `
                -NoNewWindow -PassThru -Wait -ErrorAction SilentlyContinue
            if ($p -and $p.ExitCode -ne 0) {
                Start-Process winget -ArgumentList @('source', 'reset', '--force', '--disable-interactivity') `
                    -NoNewWindow -PassThru -Wait -ErrorAction SilentlyContinue | Out-Null
                Start-Process winget -ArgumentList @('source', 'update', '--disable-interactivity') `
                    -NoNewWindow -PassThru -Wait -ErrorAction SilentlyContinue | Out-Null
            }
        } catch {}
    }
}

function Install-Packages {
    Sync-Path
    Ensure-WinGetSourcesReady
    foreach ($pkg in $Packages) {
        if (Get-Command $pkg.Cmd -ErrorAction SilentlyContinue) {
            Ok "$($pkg.Name) (already installed)"
        } else {
            $ok = Invoke-ExternalTask -Label "installing $($pkg.Name)" -FilePath 'winget' `
                -ArgumentList @('install', '--id', $pkg.Id, '--exact', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity') `
                -DoneLabel $pkg.Name
            if (-not $ok) {
                Ensure-WinGetSourcesReady
                Sync-Path
            }
        }
    }
    Sync-Path
}

$Script:FontCache = $null
function Test-JetBrainsFontInstalled {
    if ($null -ne $Script:FontCache) { return $Script:FontCache }
    try {
        $hkcu = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' -ErrorAction SilentlyContinue
        $hklm = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts' -ErrorAction SilentlyContinue
        $props = @()
        if ($hkcu) { $props += $hkcu.PSObject.Properties.Name }
        if ($hklm) { $props += $hklm.PSObject.Properties.Name }
        if ($props -match 'JetBrains') {
            $Script:FontCache = $true
            return $true
        }
    } catch {}
    $Script:FontCache = $false
    return $false
}

function Install-NerdFont {
    if ($SkipFont) { Note 'Nerd Font skipped (-SkipFont)'; return }
    if (Test-JetBrainsFontInstalled) {
        Ok "Nerd Font (JetBrainsMono already installed)"
        return
    }
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        Invoke-ExternalTask -Label 'installing Nerd Font (JetBrainsMono)' -FilePath 'oh-my-posh' `
            -ArgumentList @('font', 'install', 'JetBrainsMono') `
            -DoneLabel "Nerd Font - set 'JetBrainsMono Nerd Font Mono' as your terminal font" | Out-Null
    } else {
        Note 'oh-my-posh not on PATH yet - reopen terminal and run: oh-my-posh font install JetBrainsMono'
    }
}

function Set-PowerShellExecutionPolicy {
    try {
        $policy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
        if ($policy -eq 'Restricted' -or $policy -eq 'Undefined' -or [string]::IsNullOrEmpty($policy)) {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        }
    } catch {
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        } catch {}
    }
}

function Invoke-Install {
    Write-Host ''
    Set-PowerShellExecutionPolicy
    $Script:ProgressStep  = 0
    $Script:ProgressTotal = 5

    LogHeader 'winget';              Install-WinGet
    LogHeader 'packages';            Install-Packages
    LogHeader 'font';                Install-NerdFont
    LogHeader 'bao-profile';          Install-RepoFiles
    LogHeader 'terminal theme';      Configure-BaoTerminalSettings

    $Script:ProgressStep  = 0
    $Script:ProgressTotal = 0
    Write-Host ''
    Write-ResultCard -Title 'all set. open a new terminal to see changes.'
}

function Test-ProfileInstalled {
    $t = Get-BaoTargets
    foreach ($p in $t.ProfileTargets) {
        if (Test-Path -LiteralPath $p -PathType Leaf) {
            $c = Get-Content -LiteralPath $p -Raw -ErrorAction SilentlyContinue
            if ($c -and ($c -match 'fastfetch' -or $c -match 'oh-my-posh' -or $c -match 'BaoFastfetch')) {
                return $true
            }
        }
    }
    if (Test-Path -LiteralPath (Join-Path $t.FastfetchDir 'config.jsonc') -PathType Leaf) { return $true }
    return $false
}

function Test-TerminalThemeInstalled {
    $wtPaths = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    )
    foreach ($p in $wtPaths) {
        if (Test-Path -LiteralPath $p) {
            $raw = Get-Content -LiteralPath $p -Raw -ErrorAction SilentlyContinue
            if ($raw -and ($raw -match 'One Half Dark' -or $raw -match 'Catppuccin' -or $raw -match '"opacity":\s*40')) {
                return $true
            }
        }
    }
    return $false
}

function Get-PlanItems {
    $items = New-Object System.Collections.Generic.List[object]

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $items.Add(@{ Label = 'winget'; Done = $true; Tag = '' })
    } else {
        $items.Add(@{ Label = 'winget'; Done = $false; Tag = '' })
    }

    foreach ($pkg in $Packages) {
        $done = [bool](Get-Command $pkg.Cmd -ErrorAction SilentlyContinue)
        $items.Add(@{ Label = $pkg.Name; Done = $done; Tag = '' })
    }

    $fontDone = $SkipFont -or (Test-JetBrainsFontInstalled)
    $fontTag = if ($SkipFont) { 'skip' } else { '' }
    $items.Add(@{ Label = 'Nerd Font'; Done = $fontDone; Tag = $fontTag })

    $themeDone = Test-TerminalThemeInstalled
    $themeTag = if ($themeDone) { 'bao-shell' } else { 'defaults' }
    $items.Add(@{ Label = 'terminal theme'; Done = $themeDone; Tag = $themeTag })

    return $items
}

function Show-Plan {
    try { Clear-Host } catch { Write-Host "$Esc[2J$Esc[H" -NoNewline }
    Write-Host ''
    Write-Host ''
    Write-Centered $Banner
    Write-CenteredLine 'made by bao' '#A9D9FF'
    Write-Host ''
    Write-Host ''

    Write-StatusBox (Get-PlanItems)

    Write-Host ''
    $installed = Test-BaoInstalled
    $stateTag   = if ($installed) { "$([char]0x25CF) installed" } else { "$([char]0x25CB) not installed" }
    $stateColor = if ($installed) { '#A9D9FF' } else { '#8FA6BD' }
    Write-CenteredLine $stateTag $stateColor
    Write-Host ''
}

function Read-Menu {
    param(
        [string[]]$Items,
        [bool[]]$Disabled,
        [string[]]$StatusTags,
        [string]$Hint
    )

    $selected = 0
    $width = Get-ConsoleWidth
    $grey = Write-Fg '#3B4856'
    $greyTag = Write-Fg '#2A3542'

    while ($selected -lt $Items.Count -and $Disabled[$selected]) { $selected++ }
    if ($selected -ge $Items.Count) { $selected = 0 }

    $extraLines = if ($Hint) { 2 } else { 1 }

    $render = {
        $width = Get-ConsoleWidth
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $isSel = ($i -eq $selected)
            $isDim = $Disabled[$i]
            $selChar = if ($isSel) { "$([char]0x276F) " } else { "  " }
            $label = $Items[$i]
            $tag = if ($StatusTags) { $StatusTags[$i] } else { $null }

            $rawStr = if ($tag) { "$selChar$label  $tag" } else { "$selChar$label" }
            $pad = [Math]::Max(0, [Math]::Floor(($width - $rawStr.Length) / 2))
            $indent = ' ' * $pad

            $color = if ($isDim) { $grey } elseif ($isSel) { $Accent } else { $Dim }
            $tagColor = if ($isDim) { $greyTag } elseif ($isSel) { '#A9D9FF' } else { $Dim }

            $line = "$indent$(Write-Fg $color)$selChar$label$Reset"
            if ($tag) {
                $line += "  $(Write-Fg $tagColor)$tag$Reset"
            }
            Write-Host $line
        }
        if ($Hint) {
            Write-Host ''
            Write-CenteredLine $Hint $Dim
        }
    }

    & $render
    while ($true) {
        $key = $null
        try {
            $key = [Console]::ReadKey($true).Key
        } catch {
            return $selected
        }

        $next = $selected
        switch ($key) {
            'UpArrow'   { $next = ($selected - 1 + $Items.Count) % $Items.Count }
            'DownArrow' { $next = ($selected + 1) % $Items.Count }
            'LeftArrow' { $next = ($selected - 1 + $Items.Count) % $Items.Count }
            'RightArrow'{ $next = ($selected + 1) % $Items.Count }
            'Enter'     { if (-not $Disabled[$selected]) { return $selected } else { continue } }
            'Spacebar'  { if (-not $Disabled[$selected]) { return $selected } else { continue } }
            default     { continue }
        }
        $guard = 0
        while ($Disabled[$next] -and $guard -lt $Items.Count) {
            $next = if ($key -eq 'UpArrow' -or $key -eq 'LeftArrow') {
                ($next - 1 + $Items.Count) % $Items.Count
            } else {
                ($next + 1) % $Items.Count
            }
            $guard++
        }
        $selected = $next
        $totalLines = $Items.Count + $extraLines
        Write-Host "$Esc[${totalLines}A" -NoNewline
        & $render
    }
}

function Read-Choice {
    Write-Host ''
    $items = @('Install', 'Uninstall', 'Exit')
    $disabled = @($false, $false, $false)
    $choice = Read-Menu -Items $items -Disabled $disabled -StatusTags $null -Hint ("$([char]0x2191)$([char]0x2193) to move $([char]0xB7) enter to confirm")
    Write-Host ''
    return $items[$choice]
}

function Show-RevertOverlayCard {
    param([int]$Selected)

    try { Clear-Host } catch { Write-Host "$Esc[2J$Esc[H" -NoNewline }
    Write-Host ''
    Write-Host ''
    Write-Centered $Banner
    Write-CenteredLine 'made by bao' '#A9D9FF'
    Write-Host ''
    Write-Host ''

    $rows = @(
        @{ Num = '1'; Label = 'Profiles & Configs'; Tag = 'profiles + fastfetch' }
        @{ Num = '2'; Label = 'Terminal Defaults'; Tag = 'font + opacity + theme' }
        @{ Num = '3'; Label = 'Full System Purge'; Tag = 'revert everything' }
        @{ Num = '4'; Label = 'Back to Main Menu'; Tag = 'cancel' }
    )

    $maxLabelW  = 24
    $maxTagW    = 22
    $leftPad    = 3
    $midGap     = 3
    $rightPad   = 4

    $contentW   = $leftPad + 2 + $maxLabelW + $midGap + $maxTagW + $rightPad # 58
    $boxW       = $contentW + 2
    $consoleW   = Get-ConsoleWidth
    $pad        = [Math]::Max(0, [Math]::Floor(($consoleW - $boxW) / 2))
    $padStr     = ' ' * $pad
    $border     = Write-Fg '#A0C4FF'

    $headerTitle = " REVERT OPTIONS "
    $dashCount   = $contentW - $headerTitle.Length - 1
    $leftDash    = [char]0x2500
    $rightDash   = ([char]0x2500).ToString() * $dashCount

    Write-Host "$padStr$border$([char]0x256D)$leftDash$(Write-Fg '#EAF7FF')$headerTitle$Reset$border$rightDash$([char]0x256E)$Reset"

    for ($i = 0; $i -lt $rows.Count; $i++) {
        $isSel = ($i -eq $Selected)
        $r = $rows[$i]
        $fullL = "[$($r.Num)] $($r.Label)".PadRight($maxLabelW)

        $pointerStr  = if ($isSel) { "$([char]0x276F) " } else { "  " }
        $tagStr      = $r.Tag
        $fillCount   = $maxTagW - $tagStr.Length + $rightPad
        $fillStr     = ' ' * $fillCount

        $pColor = if ($isSel) { Write-Fg '#A0C4FF' } else { Write-Fg '#6E93B8' }
        $lColor = if ($isSel) { Write-Fg '#EAF7FF' } else { Write-Fg '#6E93B8' }
        $tColor = if ($isSel) { Write-Fg '#A0C4FF' } else { Write-Fg '#5E7590' }

        $line = "$border$([char]0x2502)$Reset" +
                "$(' ' * $leftPad)" +
                "$pColor$pointerStr$Reset" +
                "$lColor$fullL$Reset" +
                "$(' ' * $midGap)" +
                "$tColor$tagStr$Reset" +
                "$fillStr" +
                "$border$([char]0x2502)$Reset"
        Write-Host "$padStr$line"
    }

    Write-Host "$padStr$border$([char]0x2570)$(([char]0x2500).ToString() * $contentW)$([char]0x256F)$Reset"

    Write-Host ''
    Write-CenteredLine "press [1-4] or $([char]0x2191)$([char]0x2193) arrows $([char]0xB7) enter to confirm $([char]0xB7) esc to cancel" $Dim
    Write-Host ''
}

function Read-UninstallMode {
    $selected = 0
    $totalOptions = 4

    Show-RevertOverlayCard -Selected $selected

    # Labeled loop allows breaking out of loop from inside switch block
    :revertLoop while ($true) {
        $keyInfo = $null
        try {
            $keyInfo = [Console]::ReadKey($true)
        } catch {
            return 'Cancel'
        }

        $key = $keyInfo.Key
        $char = $keyInfo.KeyChar

        if ($char -eq '1' -or $key -eq 'NumPad1') { $selected = 0; break :revertLoop }
        if ($char -eq '2' -or $key -eq 'NumPad2') { $selected = 1; break :revertLoop }
        if ($char -eq '3' -or $key -eq 'NumPad3') { $selected = 2; break :revertLoop }
        if ($char -eq '4' -or $key -eq 'NumPad4' -or $key -eq 'Escape' -or $char -eq 'q' -or $char -eq 'Q') {
            $selected = 3
            break :revertLoop
        }

        if ($key -eq 'Enter' -or $key -eq 'Spacebar') {
            break :revertLoop
        }

        $next = $selected
        switch ($key) {
            'UpArrow'   { $next = ($selected - 1 + $totalOptions) % $totalOptions }
            'DownArrow' { $next = ($selected + 1) % $totalOptions }
            'LeftArrow' { $next = ($selected - 1 + $totalOptions) % $totalOptions }
            'RightArrow'{ $next = ($selected + 1) % $totalOptions }
            default     { continue :revertLoop }
        }

        $selected = $next
        Show-RevertOverlayCard -Selected $selected
    }

    switch ($selected) {
        0 { return 'ProfilesOnly' }
        1 { return 'TerminalOnly' }
        2 { return 'All' }
        default { return 'Cancel' }
    }
}

function Wait-BaoReturn {
    Start-Sleep -Milliseconds 300
    try {
        while ([Console]::KeyAvailable) {
            [void][Console]::ReadKey($true)
        }
        [void]([Console]::ReadKey($true))
    } catch {
        Start-Sleep -Seconds 1
    }
}

if ($Uninstall) {
    Show-Plan
    Invoke-Uninstall -Mode 'All'
} elseif ($Force) {
    Show-Plan
    Invoke-Install
} else {
    while ($true) {
        try {
            Show-Plan
            $choice = Read-Choice
            switch ($choice) {
                'Install'   {
                    Invoke-Install
                    Wait-BaoReturn
                }
                'Uninstall' {
                    $mode = Read-UninstallMode
                    if ($mode -ne 'Cancel') {
                        Invoke-Uninstall -Mode $mode
                        Wait-BaoReturn
                    }
                }
                'Exit'      {
                    Write-Host ''
                    Log 'exiting bao shell.' $Dim
                    Write-Host ''
                    Start-Sleep -Milliseconds 200
                    try { Clear-Host } catch {}
                    [Environment]::Exit(0)
                }
            }
        } catch {
            Write-Host ''
            Write-CenteredLine 'an error occurred' '#579DEB'
            Write-Host ''
            Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
            Write-Host ''
            Wait-BaoReturn
        }
    }
}
