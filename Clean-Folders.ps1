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

# Validate
if (-not (Test-Path $Path)) {
    Write-Error "The path '$Path' does not exist."
    exit 1
}

$Path = (Resolve-Path $Path).Path

# Scan
Write-Host ""
Write-Host "[SCAN] Scanning '$Path'..." -ForegroundColor Cyan
Write-Host "       Target folders : $($FolderNames -join ', ')" -ForegroundColor Cyan
Write-Host "       Ignore folders : $($IgnoreFolders -join ', ')" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "       ** DRY RUN MODE - nothing will be deleted **" -ForegroundColor Yellow
}
Write-Host "========================================================" -ForegroundColor DarkGray

$allFolders = @()

foreach ($folderName in $FolderNames) {
    $found = Get-ChildItem -Path $Path -Directory -Recurse -Filter $folderName -ErrorAction SilentlyContinue |
             Where-Object {
                 $fullPath = $_.FullName
                 $relativePath = $fullPath.Substring($Path.Length)
                 $pathParts = $relativePath.Split([IO.Path]::DirectorySeparatorChar) |
                              Where-Object { $_ -ne '' }

                 # Skip if any parent folder is in the ignore list
                 $isIgnored = $false
                 foreach ($part in $pathParts) {
                     # Don't check the last part (that's the target folder itself)
                     if ($part -eq $_.Name) { continue }
                     if ($IgnoreFolders -contains $part) {
                         $isIgnored = $true
                         break
                     }
                 }

                 # Skip nested matches (e.g. node_modules/x/node_modules)
                 $targetMatches = $pathParts | Where-Object { $FolderNames -contains $_ }
                 $isNested = $targetMatches.Count -gt 1

                 (-not $isIgnored) -and (-not $isNested)
             }
    if ($found) { $allFolders += $found }
}

# Also check: ignore if the folder itself is in the ignore list
# (handles edge case where a target name also appears in ignore list)
$allFolders = $allFolders | Where-Object {
    $parent = $_.Parent.Name
    $IgnoreFolders -notcontains $parent -or $FolderNames -contains $_.Name
}

if ($allFolders.Count -eq 0) {
    Write-Host ""
    Write-Host "[OK] No matching folders found. Nothing to do." -ForegroundColor Green
    exit 0
}

# Display what will be removed
$totalSize = 0
$ignoredCount = 0

Write-Host ""
Write-Host "Folders found:" -ForegroundColor White
foreach ($folder in $allFolders) {
    $size = (Get-ChildItem -Path $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue |
             Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    if ($null -eq $size) { $size = 0 }
    $sizeMB = [math]::Round($size / 1MB, 2)
    $totalSize += $size
    Write-Host "   [FOUND] $($folder.FullName)  ($sizeMB MB)" -ForegroundColor Gray
}

$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
Write-Host ""
Write-Host "   Total: $($allFolders.Count) folder(s), $totalSizeMB MB" -ForegroundColor White

# Confirm and Delete
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

    foreach ($folder in $allFolders) {
        try {
            Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction Stop
            Write-Host "   [REMOVED] $($folder.FullName)" -ForegroundColor Green
            $removed++
        }
        catch {
            Write-Host "   [ERROR]   $($folder.FullName) - $($_.Exception.Message)" -ForegroundColor Red
            $errors++
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
