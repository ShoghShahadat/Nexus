@echo off
REM This script is a simple wrapper for the more powerful build.ps1 PowerShell script.
REM It attempts to execute the PowerShell script.
REM For full functionality (e.g., building for Android/Web), run build.ps1 directly.

ECHO =================================================
ECHO  Nexus Project Build Script (Wrapper)
ECHO =================================================
ECHO.
ECHO This script will now attempt to run the main build script (build.ps1).
ECHO If you encounter errors, please ensure PowerShell is installed and
ECHO you have the necessary permissions to run scripts.
ECHO.
ECHO You can run the script directly for more options:
ECHO   pwsh -Command "& {.\build.ps1 -Target windows}"
ECHO.

REM Check if PowerShell exists
where pwsh >nul 2>nul
if %errorlevel% 0 (
    ECHO PowerShell (pwsh) not found. Please install PowerShell 7+ or run the commands from build.ps1 manually.
    goto:eof
)

REM Execute the PowerShell script to build for Windows by default
pwsh -NoProfile -ExecutionPolicy Bypass -Command "& {.\build.ps1 -Target windows; if ($LASTEXITCODE -ne 0) { exit 1 }}"

if %errorlevel% neq 0 (
    ECHO.
    ECHO =================================
    ECHO      BUILD FAILED!
    ECHO =================================
    ECHO An error occurred during the build process.
    ECHO Please check the output above for more details.
    exit /b 1
)

ECHO.
ECHO =================================
ECHO      BUILD SUCCESSFUL!
ECHO =================================
ECHO The library for Windows has been built and copied.
ECHO You can now run 'flutter run'
ECHO.
