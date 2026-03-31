param(
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [Parameter(Mandatory=$false)]
    [string[]]$FolderNames = @("bin", "obj", "node_modules", "packages"),

    [Parameter(Mandatory=$false)]
    [string[]]$IgnoreFolders = @(".venv", "venv", ".git", ".hg", ".svn", ".idea", ".vs"),

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [switch]$NoConfirm
)

function Write-Progress-Line {
    param(
        [string]$Message,
        [int]$MaxLength = 100
    )
    # Truncate message if too long for terminal
    $consoleWidth = [Math]::Max(40, $Host.UI.RawUI.WindowSize.Width - 2)
    if ($Message.Length -gt $consoleWidth) {
        $Message = $Message.Substring(0, $consoleWidth - 3) + "..."
    }
    # Pad with spaces to overwrite previous line, then carriage return
    $padded = $Message.PadRight($consoleWidth)
    Write-Host "`r$padded" -NoNewline -ForegroundColor DarkGray
}

function Clear-Progress-Line {
    $consoleWidth = [Math]::Max(40, $Host.UI.RawUI.WindowSize.Width - 2)
    Write-Host "`r$(' ' * $consoleWidth)`r" -NoNewline
}

function Write-Progress-Bar {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Label,
        [string]$Detail
    )
    $consoleWidth = [Math]::Max(40, $Host.UI.RawUI.WindowSize.Width - 2)
    $percent = if ($Total -gt 0) { [math]::Round(($Current / $Total) * 100) } else { 0 }
    $barWidth = 20
    $filled = [math]::Round(($percent / 100) * $barWidth)
    $empty = $barWidth - $filled
    $bar = "[" + ("#" * $filled) + ("-" * $empty) + "]"

    $msg = "$Label $bar $percent% ($Current/$Total) $Detail"
    if ($msg.Length -gt $consoleWidth) {
        $msg = $msg.Substring(0, $consoleWidth - 3) + "..."
    }
    $padded = $msg.PadRight($consoleWidth)
    Write-Host "`r$padded" -NoNewline -ForegroundColor DarkGray
}

# ── Validate ──────────────────────────────────────────────
if (-not (Test-Path $Path)) {
    Write-Error "The path '$Path' does not exist."
    exit 1
}

$Path = (Resolve-Path $Path).Path

# ── Header ────────────────────────────────────────────────
Write-Host ""
Write-Host "[SCAN] Scanning '$Path'..." -ForegroundColor Cyan
Write-Host "       Target folders : $($FolderNames -join ', ')" -ForegroundColor Cyan
Write-Host "       Ignore folders : $($IgnoreFolders -join ', ')" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "       ** DRY RUN MODE - nothing will be deleted **" -ForegroundColor Yellow
}
Write-Host "========================================================" -ForegroundColor DarkGray

# ── Phase 1: Scan for folders ─────────────────────────────
$allFolders = @()
$scannedCount = 0

foreach ($folderName in $FolderNames) {
    Write-Progress-Line "Searching for '$folderName' folders..."

    $found = Get-ChildItem -Path $Path -Directory -Recurse -Filter $folderName -ErrorAction SilentlyContinue |
             Where-Object {
                 $scannedCount++
                 if ($scannedCount % 5 -eq 0) {
                     Write-Progress-Line "Scanning: found $($allFolders.Count + 1) match(es)... $($_.FullName)"
                 }

                 $fullPath = $_.FullName
                 $relativePath = $fullPath.Substring($Path.Length)
                 $pathParts = $relativePath.Split([IO.Path]::DirectorySeparatorChar) |
                              Where-Object { $_ -ne '' }

                 # Skip if any parent folder is in the ignore list
                 $isIgnored = $false
                 foreach ($part in $pathParts) {
                     if ($part -eq $_.Name) { continue }
                     if ($IgnoreFolders -contains $part) {
                         $isIgnored = $true
                         break
                     }
                 }

                 # Skip nested matches
                 $targetMatches = $pathParts | Where-Object { $FolderNames -contains $_ }
                 $isNested = $targetMatches.Count -gt 1

                 (-not $isIgnored) -and (-not $isNested)
             }
    if ($found) { $allFolders += $found }
}

Clear-Progress-Line

if ($allFolders.Count -eq 0) {
    Write-Host "[OK] No matching folders found. Nothing to do." -ForegroundColor Green
    exit 0
}

Write-Host "[SCAN] Found $($allFolders.Count) folder(s) to remove." -ForegroundColor Cyan

# ── Phase 2: Calculate sizes ─────────────────────────────
Write-Host ""
Write-Host "Calculating sizes..." -ForegroundColor White

$totalSize = 0
$folderSizes = @{}
$current = 0

foreach ($folder in $allFolders) {
    $current++
    Write-Progress-Bar -Current $current -Total $allFolders.Count -Label "Sizing" -Detail $folder.Name

    $size = (Get-ChildItem -Path $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue |
             Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    if ($null -eq $size) { $size = 0 }
    $folderSizes[$folder.FullName] = $size
    $totalSize += $size
}

Clear-Progress-Line

# ── Display results ───────────────────────────────────────
foreach ($folder in $allFolders) {
    $sizeMB = [math]::Round($folderSizes[$folder.FullName] / 1MB, 2)
    Write-Host "   [FOUND] $($folder.FullName)  ($sizeMB MB)" -ForegroundColor Gray
}

$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
Write-Host ""
Write-Host "   Total: $($allFolders.Count) folder(s), $totalSizeMB MB" -ForegroundColor White

# ── Phase 3: Confirm and Delete ───────────────────────────
if (-not $DryRun) {
    if (-not $NoConfirm) {
        Write-Host ""
        $confirmation = Read-Host "Do you want to delete these folders? (y/N)"
        if ($confirmation -notin @('y', 'Y', 'yes', 'Yes')) {
            Write-Host "[ABORT] Cancelled by user." -ForegroundColor Red
            exit 0
        }
    }

    Write-Host ""
    Write-Host "[DELETE] Removing folders..." -ForegroundColor Yellow

    $removed = 0
    $errors  = 0
    $current = 0

    foreach ($folder in $allFolders) {
        $current++
        Write-Progress-Bar -Current $current -Total $allFolders.Count -Label "Deleting" -Detail $folder.Name

        try {
            Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction Stop
            $removed++
        }
        catch {
            $errors++
        }
    }

    Clear-Progress-Line

    # Final summary per folder
    $current = 0
    foreach ($folder in $allFolders) {
        $current++
        $sizeMB = [math]::Round($folderSizes[$folder.FullName] / 1MB, 2)
        if (Test-Path $folder.FullName) {
            Write-Host "   [ERROR]   ($current/$($allFolders.Count)) $($folder.FullName)" -ForegroundColor Red
        } else {
            Write-Host "   [REMOVED] ($current/$($allFolders.Count)) $($folder.FullName)  ($sizeMB MB)" -ForegroundColor Green
        }
    }

    Write-Host ""
    Write-Host "========================================================" -ForegroundColor DarkGray
    Write-Host "[DONE] Removed: $removed | Errors: $errors | Freed: ~$totalSizeMB MB" -ForegroundColor Cyan
}
else {
    Write-Host ""
    Write-Host "[DONE] Dry run complete. No files were deleted." -ForegroundColor Yellow
}
