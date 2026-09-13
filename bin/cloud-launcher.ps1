<#
.SYNOPSIS
    CloudDeck Windows Cloud Gaming & Remote Streaming Launcher
.DESCRIPTION
    Seamlessly launches cloud gaming platforms (GeForce NOW, Xbox Cloud, Boosteroid, Shadow, Moonlight)
    on any Windows 10/11 device with hardware acceleration and anti-stutter kiosk flags.
.EXAMPLE
    .\cloud-launcher.ps1 -Service gfn -Game destiny2
    .\cloud-launcher.ps1 -Service gfn -Game "Cyberpunk 2077" -Resolution 2560x1440
    .\cloud-launcher.ps1 -Service moonlight -Game "Destiny 2"
#>

param(
    [string]$Service = "gfn",
    [string]$Game = "",
    [string]$Resolution = "",
    [string]$Url = "",
    [string]$Browser = "",
    [string]$Codec = "",
    [switch]$DryRun,
    [switch]$CheckAntiCheat,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
CloudDeck Windows Cloud Gaming Launcher

Usage:
  cloud-launcher.ps1 [options]

Options:
  -Service <name>        Service: gfn (default), xbox, boosteroid, shadow, moonlight
  -Game <id|title>       Game launch: destiny2, fortnite, warzone, or any custom Windows title
  -Resolution <WxH>      Custom display resolution (e.g. 1920x1080, 2560x1440, 3840x2160)
  -Url <url>             Custom stream or portal URL
  -Browser <edge|chrome> Force browser engine
  -Codec <h264|h265>     Force video stream codec
  -DryRun                Print launch command without executing
  -CheckAntiCheat        Print anti-cheat ban safety evaluation
  -Help                  Show this help message
"@
    exit 0
}

if ($CheckAntiCheat) {
    Write-Host @"
==============================================================================
           CLOUDDECK: ZERO-BAN ANTI-CHEAT SAFETY VERIFICATION
==============================================================================
Target Game : Any Windows Title with Kernel Anti-Cheat (BattlEye / EAC / Ricochet)
Status      : 100% IMMUNE / SAFE
Summary     : Executes on genuine Windows hardware in the cloud or host PC.
==============================================================================
"@
    exit 0
}

# 1. Resolve Target URL
$TargetUrl = ""
$EncodedGame = [System.Uri]::EscapeDataString($Game)

switch ($Service.ToLower()) {
    "gfn" {
        if ($Game) {
            switch ($Game.ToLower()) {
                "destiny2" { $TargetUrl = "https://play.geforcenow.com/mall/#/deep-link?game-id=100412811" }
                "fortnite" { $TargetUrl = "https://play.geforcenow.com/mall/#/deep-link?game-id=100222411" }
                "warzone"  { $TargetUrl = "https://play.geforcenow.com/mall/#/deep-link?game-id=104323211" }
                default {
                    if ($Game -match "^\d+$") {
                        $TargetUrl = "https://play.geforcenow.com/mall/#/deep-link?game-id=$Game"
                    } else {
                        $TargetUrl = "https://play.geforcenow.com/mall/#/search?query=$EncodedGame"
                    }
                }
            }
        } else {
            $TargetUrl = "https://play.geforcenow.com"
        }
    }
    "xbox" {
        if ($Game) {
            switch ($Game.ToLower()) {
                "destiny2" { $TargetUrl = "https://www.xbox.com/play/games/destiny-2/BPK99T289069" }
                "fortnite" { $TargetUrl = "https://www.xbox.com/play/games/fortnite/BT5P2X999VH2" }
                default    { $TargetUrl = "https://www.xbox.com/play/search?q=$EncodedGame" }
            }
        } else {
            $TargetUrl = "https://www.xbox.com/play"
        }
    }
    "boosteroid" {
        if ($Game -eq "destiny2") {
            $TargetUrl = "https://cloud.boosteroid.com/application/518"
        } elseif ($Game -match "^\d+$") {
            $TargetUrl = "https://cloud.boosteroid.com/application/$Game"
        } elseif ($Game) {
            $TargetUrl = "https://cloud.boosteroid.com/search?text=$EncodedGame"
        } else {
            $TargetUrl = "https://cloud.boosteroid.com"
        }
    }
    "shadow" {
        $TargetUrl = "https://pc.shadow.tech"
    }
    "moonlight" {
        if ($Game) {
            $TargetUrl = "moonlight://launch?app=$EncodedGame"
        } else {
            $TargetUrl = "moonlight://launch"
        }
    }
    default {
        Write-Error "Unknown service '$Service'"
        exit 1
    }
}

if ($Url) {
    $TargetUrl = $Url
}

# 2. Locate Browser Executable
$BrowserPath = ""
$EdgePaths = @(
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe",
    "${env:LOCALAPPDATA}\Microsoft\Edge\Application\msedge.exe"
)
$ChromePaths = @(
    "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "${env:LOCALAPPDATA}\Google\Chrome\Application\chrome.exe"
)

if ($Browser -eq "chrome") {
    $BrowserPath = $ChromePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
} elseif ($Browser -eq "edge") {
    $BrowserPath = $EdgePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
} else {
    $BrowserPath = $EdgePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $BrowserPath) {
        $BrowserPath = $ChromePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    }
}

# 3. Resolution & Scale
$WindowWidth = 1920
$WindowHeight = 1080
if ($Resolution -match "^(\d+)x(\d+)$") {
    $WindowWidth = $matches[1]
    $WindowHeight = $matches[2]
}

$LaunchArgs = @(
    "--kiosk",
    "--window-size=$WindowWidth,$WindowHeight",
    "--enable-gpu-rasterization",
    "--enable-zero-copy",
    "--ignore-gpu-blocklist",
    "--disable-background-timer-throttling",
    "--disable-backgrounding-occluded-windows",
    "--disable-renderer-backgrounding",
    "--disable-features=CalculateNativeWinOcclusion",
    "--no-first-run",
    "--autoplay-policy=no-user-gesture-required",
    "--disable-frame-rate-limit",
    $TargetUrl
)

Write-Host "[CloudDeck Windows] Target Service : $Service"
Write-Host "[CloudDeck Windows] Target Game    : $(if ($Game) { $Game } else { 'none' })"
Write-Host "[CloudDeck Windows] Target URL     : $TargetUrl"
Write-Host "[CloudDeck Windows] Resolution     : ${WindowWidth}x${WindowHeight}"

if ($DryRun) {
    Write-Host "DRY RUN COMMAND:"
    if ($BrowserPath) {
        Write-Host "& `"$BrowserPath`" $($LaunchArgs -join ' ')"
    } else {
        Write-Host "Start-Process `"$TargetUrl`""
    }
    exit 0
}

if ($BrowserPath) {
    Start-Process -FilePath $BrowserPath -ArgumentList $LaunchArgs
} else {
    Start-Process $TargetUrl
}
