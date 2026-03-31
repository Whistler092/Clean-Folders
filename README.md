# 🧹 Clean-Folders.ps1

A PowerShell script to recursively find and remove build/dependency folders (`bin`, `obj`, `node_modules`, `packages`) from a specified path. Features real-time progress feedback, dry-run mode, folder ignore list, and confirmation prompts.

---

## 📋 Table of Contents

- [Features](#-features)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Parameters](#-parameters)
- [Usage](#-usage)
  - [Basic Usage](#basic-usage)
  - [Dry Run Mode](#dry-run-mode)
  - [Skip Confirmation](#skip-confirmation)
  - [Custom Target Folders](#custom-target-folders)
  - [Custom Ignore Folders](#custom-ignore-folders)
  - [Combine Parameters](#combine-parameters)
- [Example Output](#-example-output)
  - [Dry Run](#dry-run)
  - [Full Deletion](#full-deletion)
  - [No Matches Found](#no-matches-found)
- [Default Values](#-default-values)
- [How It Works](#-how-it-works)
- [FAQ](#-faq)
- [License](#-license)

---

## ✨ Features

| Feature                          | Description                                                               |
| -------------------------------- | ------------------------------------------------------------------------- |
| **Recursive scanning**           | Finds target folders at any depth in the directory tree                   |
| **Dry-run mode**                 | Preview what would be deleted without removing anything                   |
| **Ignore folders**               | Skip scanning inside specified directories (e.g., `.venv`, `.git`)       |
| **Real-time progress**           | npm-style single-line progress bar during scan, sizing, and deletion     |
| **Size reporting**               | Shows size of each folder and total space freed                          |
| **Nested folder deduplication**  | Avoids deleting `node_modules/x/node_modules` separately                 |
| **Confirmation prompt**          | Asks before deleting (can be skipped with `-NoConfirm`)                  |
| **Error handling**               | Reports per-folder success/failure and total error count                  |

---

## 💻 Requirements

- **Windows PowerShell 5.1+** or **PowerShell Core 7+**
- Appropriate file system permissions for the target path

---

## 📥 Installation

1. Download or copy `Clean-Folders.ps1` to your desired location.

2. If needed, allow script execution:

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

---

## ⚙ Parameters

| Parameter          | Type       | Required | Default                                                    | Description                                        |
| ------------------ | ---------- | -------- | ---------------------------------------------------------- | -------------------------------------------------- |
| `-Path`            | `string`   | **Yes**  | —                                                          | Root directory path to scan                        |
| `-FolderNames`     | `string[]` | No       | `@("bin", "obj", "node_modules", "packages")`              | Array of folder names to find and remove           |
| `-IgnoreFolders`   | `string[]` | No       | `@(".venv", "venv", ".git", ".hg", ".svn", ".idea", ".vs")` | Array of folder names to skip during scanning     |
| `-DryRun`          | `switch`   | No       | `$false`                                                   | Preview mode — lists folders without deleting them |
| `-NoConfirm`       | `switch`   | No       | `$false`                                                   | Skip the confirmation prompt before deletion       |

---

## 🚀 Usage

### Basic Usage

Scan and delete default folders with a confirmation prompt:

```powershell
.\Clean-Folders.ps1 -Path "C:\Projects\MySolution"
```

### Dry Run Mode

Preview what would be deleted — **nothing is removed**:

```powershell
.\Clean-Folders.ps1 -Path "C:\Projects" -DryRun
```

### Skip Confirmation

Delete immediately without asking:

```powershell
.\Clean-Folders.ps1 -Path "C:\Projects" -NoConfirm
```

### Custom Target Folders

Specify which folder names to remove:

```powershell
.\Clean-Folders.ps1 -Path "C:\Projects" -FolderNames @("bin", "obj", "dist", "out", ".vs")
```

### Custom Ignore Folders

Specify which folders to skip (won't scan inside them):

```powershell
.\Clean-Folders.ps1 -Path "C:\Projects" -IgnoreFolders @(".venv", "venv", ".git", "vendor", "TestResults")
```

### Disable Ignore List

Pass an empty array to scan everything:

```powershell
.\Clean-Folders.ps1 -Path "C:\Projects" -IgnoreFolders @()
```

### Combine Parameters

```powershell
.\Clean-Folders.ps1 `
    -Path "C:\workspace" `
    -FolderNames @("bin", "obj", "node_modules", "packages", "dist", ".vs") `
    -IgnoreFolders @(".venv", "venv", ".git", "vendor") `
    -DryRun
```

### Use Current Directory

```powershell
.\Clean-Folders.ps1 -Path "."
```

---

## 📸 Example Output

### Dry Run

```
PS C:\workspace> .\Clean-Folders.ps1 -Path "C:\workspace" -DryRun

[SCAN] Scanning 'C:\workspace'...
       Target folders : bin, obj, node_modules, packages
       Ignore folders : .venv, venv, .git, .hg, .svn, .idea, .vs
       ** DRY RUN MODE - nothing will be deleted **
========================================================
[SCAN] Found 5 folder(s) to remove.

Calculating sizes...
   [FOUND] C:\workspace\MyApp\bin  (12.45 MB)
   [FOUND] C:\workspace\MyApp\obj  (8.32 MB)
   [FOUND] C:\workspace\WebApp\node_modules  (245.67 MB)
   [FOUND] C:\workspace\WebApp\packages  (34.12 MB)
   [FOUND] C:\workspace\API\obj  (5.88 MB)

   Total: 5 folder(s), 306.44 MB

[DONE] Dry run complete. No files were deleted.
```

### Full Deletion

```
PS C:\workspace> .\Clean-Folders.ps1 -Path "C:\workspace"

[SCAN] Scanning 'C:\workspace'...
       Target folders : bin, obj, node_modules, packages
       Ignore folders : .venv, venv, .git, .hg, .svn, .idea, .vs
========================================================
[SCAN] Found 5 folder(s) to remove.

Calculating sizes...
   [FOUND] C:\workspace\MyApp\bin  (12.45 MB)
   [FOUND] C:\workspace\MyApp\obj  (8.32 MB)
   [FOUND] C:\workspace\WebApp\node_modules  (245.67 MB)
   [FOUND] C:\workspace\WebApp\packages  (34.12 MB)
   [FOUND] C:\workspace\API\obj  (5.88 MB)

   Total: 5 folder(s), 306.44 MB

Do you want to delete these folders? (y/N): y

[DELETE] Removing folders...
   [REMOVED] (1/5) C:\workspace\MyApp\bin  (12.45 MB)
   [REMOVED] (2/5) C:\workspace\MyApp\obj  (8.32 MB)
   [REMOVED] (3/5) C:\workspace\WebApp\node_modules  (245.67 MB)
   [REMOVED] (4/5) C:\workspace\WebApp\packages  (34.12 MB)
   [REMOVED] (5/5) C:\workspace\API\obj  (5.88 MB)

========================================================
[DONE] Removed: 5 | Errors: 0 | Freed: ~306.44 MB
```

### With Errors

```
[DELETE] Removing folders...
   [REMOVED] (1/3) C:\workspace\MyApp\bin  (12.45 MB)
   [ERROR]   (2/3) C:\workspace\LockedApp\obj
   [REMOVED] (3/3) C:\workspace\WebApp\node_modules  (245.67 MB)

========================================================
[DONE] Removed: 2 | Errors: 1 | Freed: ~258.12 MB
```

### No Matches Found

```
PS C:\workspace> .\Clean-Folders.ps1 -Path "C:\EmptyProject" -DryRun

[SCAN] Scanning 'C:\EmptyProject'...
       Target folders : bin, obj, node_modules, packages
       Ignore folders : .venv, venv, .git, .hg, .svn, .idea, .vs
       ** DRY RUN MODE - nothing will be deleted **
========================================================
[OK] No matching folders found. Nothing to do.
```

### User Cancellation

```
Do you want to delete these folders? (y/N): n
[ABORT] Cancelled by user.
```

---

## 📌 Default Values

### Default Target Folders

| Folder           | Typical Source       |
| ---------------- | -------------------- |
| `bin`            | .NET build output    |
| `obj`            | .NET intermediate    |
| `node_modules`   | npm / yarn / pnpm    |
| `packages`       | NuGet packages       |

### Default Ignore Folders

| Folder   | Reason                                  |
| -------- | --------------------------------------- |
| `.venv`  | Python virtual environment              |
| `venv`   | Python virtual environment (alternate)  |
| `.git`   | Git repository data                     |
| `.hg`    | Mercurial repository data               |
| `.svn`   | Subversion repository data              |
| `.idea`  | JetBrains IDE settings                  |
| `.vs`    | Visual Studio settings                  |

---

## 🔍 How It Works

```
Phase 1: SCAN
│   Recursively searches for target folder names
│   Filters out folders inside ignored directories
│   Deduplicates nested matches
│   Shows real-time scanning progress
│
Phase 2: SIZE
│   Calculates the size of each matched folder
│   Displays progress bar during calculation
│   Lists all folders with their sizes
│
Phase 3: DELETE (skipped in dry-run mode)
    Prompts for confirmation (unless -NoConfirm)
    Removes folders with progress bar
    Reports per-folder success/failure
    Shows total summary
```

### Folder Ignore Logic

The script skips any target folder whose **parent path** contains an ignored folder:

```
C:\workspace\
├── MyApp\
│   ├── bin\              ← FOUND (will be removed)
│   └── obj\              ← FOUND (will be removed)
├── .venv\
│   └── Lib\
│       └── packages\     ← SKIPPED (inside .venv)
├── .git\
│   └── obj\              ← SKIPPED (inside .git)
└── WebApp\
    └── node_modules\
        └── lodash\
            └── node_modules\  ← SKIPPED (nested duplicate)
```

---

## ❓ FAQ

**Q: Is it safe to run?**
A: Always run with `-DryRun` first to preview. The script also asks for confirmation by default.

**Q: Will it delete `.venv/bin`?**
A: No. `.venv` is in the default ignore list, so any folders inside it are skipped.

**Q: Can I use it in CI/CD pipelines?**
A: Yes. Use `-NoConfirm` to skip the interactive prompt:

```powershell
.\Clean-Folders.ps1 -Path "." -NoConfirm
```

**Q: What happens if a folder is locked?**
A: The script catches the error, reports it as `[ERROR]`, and continues with the remaining folders.

**Q: Does it follow symbolic links?**
A: It follows the default PowerShell `Get-ChildItem` behavior, which does not follow symlinks by default.

---

## 📄 License

This script is provided as-is under the [MIT License](https://opensource.org/licenses/MIT). Use at your own risk.
