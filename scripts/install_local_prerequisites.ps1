# ==============================================================================
# 1-Click Local Build Environment Setup for Chika Messenger (Windows)
# ==============================================================================

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Installing Prerequisites for Local Chika Mobile Builds   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Install Git
Write-Host "`n[1/3] Installing Git..." -ForegroundColor Yellow
winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements

# 2. Install Java Development Kit 17 (Zulu JDK 17)
Write-Host "`n[2/3] Installing Microsoft OpenJDK 17..." -ForegroundColor Yellow
winget install --id Microsoft.OpenJDK.17 -e --accept-source-agreements --accept-package-agreements

# 3. Install Flutter SDK
Write-Host "`n[3/3] Installing Flutter SDK..." -ForegroundColor Yellow
winget install --id Google.Flutter -e --accept-source-agreements --accept-package-agreements

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host " Setup Completed! Please restart your terminal/IDE." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
