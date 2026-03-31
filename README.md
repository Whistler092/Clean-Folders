# Default ignore list (.venv, venv, .git, .hg, .svn, .idea, .vs)
.\Clean-Folders.ps1 -Path "C:\workspace" -DryRun

# Custom ignore list
.\Clean-Folders.ps1 -Path "C:\workspace" -IgnoreFolders @(".venv", "venv", ".git", "vendor", "TestResults") -DryRun

# No ignore folders at all
.\Clean-Folders.ps1 -Path "C:\workspace" -IgnoreFolders @() -DryRun

# Add extra target folders + extra ignore folders
.\Clean-Folders.ps1 -Path "C:\workspace" `
    -FolderNames @("bin", "obj", "node_modules", "packages", "dist", ".vs") `
    -IgnoreFolders @(".venv", "venv", ".git", "vendor") `
    -DryRun

# Delete without confirmation
.\Clean-Folders.ps1 -Path "C:\workspace" -NoConfirm
