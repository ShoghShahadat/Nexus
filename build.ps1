#Requires -Version 5.1
<#
.SYNOPSIS
    Builds the Rust core library for the Nexus project for various target platforms.
.DESCRIPTION
    This script handles the compilation of the Rust code in `rust_core` for different
    targets (Windows, Android, Web) and copies the resulting artifacts to the
    correct locations for the Flutter application to use.
.PARAMETER Target
    Specifies the build target.
    Valid values are: 'windows', 'android', 'web'.
.EXAMPLE
    .\build.ps1 -Target windows
    Builds the rust_core.dll for Windows and copies it to the rust_lib/ directory.
.EXAMPLE
    .\build.ps1 -Target android
    Builds the .so libraries for all standard Android ABIs and places them in the
    android/app/src/main/jniLibs/ directory structure.
.EXAMPLE
    .\build.ps1 -Target web
    Builds the .wasm package for the web and places it in the web/ directory.
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('windows', 'android', 'web')]
    [string]$Target
)

# --- Helper Functions ---
function Write-Host-Colored($Message, $Color) {
    Write-Host $Message -ForegroundColor $Color
}

function Check-Command-Exists($Command) {
    $exists = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $exists) {
        Write-Host-Colored "Error: Command '$Command' not found. Please ensure it is installed and in your PATH." "Red"
        exit 1
    }
}

# --- MODIFIED FUNCTION ---
# This function now correctly splits the arguments string into an array
# before executing the command, fixing the "no such command" error.
function Invoke-Build-Command($Command, $Arguments) {
    Write-Host-Colored "Executing: $Command $Arguments" "Cyan"
    # Split the arguments string by spaces to pass them correctly to the executable.
    $ArgumentList = $Arguments.Split(' ')
    & $Command $ArgumentList
    if ($LASTEXITCODE -ne 0) {
        Write-Host-Colored "Error: Build command failed with exit code $LASTEXITCODE." "Red"
        exit 1
    }
}
# --- END MODIFICATION ---

# --- Main Script Logic ---
$ProjectRoot = Get-Location
$RustCoreDir = Join-Path $ProjectRoot "rust_core"

Write-Host-Colored "=========================================" "Green"
Write-Host-Colored "  Nexus Core Build Script" "Green"
Write-Host-Colored "=========================================" "Green"
Write-Host-Colored "Selected Target: $Target" "Yellow"
Write-Host-Colored "Project Root: $ProjectRoot" "Yellow"
Write-Host-Colored "Rust Directory: $RustCoreDir" "Yellow"
Write-Host ""

# Navigate to the Rust directory
Set-Location $RustCoreDir

# --- Target-Specific Build Logic ---

if ($Target -eq "windows") {
    Write-Host-Colored "--- Building for Windows (x86_64) ---" "Magenta"
    
    # 1. Check for cargo
    Check-Command-Exists "cargo"

    # 2. Build the Rust code in release mode
    Invoke-Build-Command "cargo" "build --release"

    # 3. Copy the compiled DLL
    $DestDir = Join-Path $ProjectRoot "example\attractor\rust_lib"
    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir | Out-Null
    }
    $SourceFile = Join-Path $RustCoreDir "target/release/rust_core.dll"
    $DestFile = Join-Path $DestDir "rust_core.dll"
    Write-Host-Colored "Copying '$SourceFile' to '$DestFile'" "Cyan"
    Copy-Item -Path $SourceFile -Destination $DestFile -Force
}
elseif ($Target -eq "android") {
    Write-Host-Colored "--- Building for Android ---" "Magenta"
    
    # 1. Check for cargo-ndk
    Check-Command-Exists "cargo"
    # A simple check for cargo-ndk by listing installed components
    $cargoNdkCheck = cargo --list | Select-String "ndk"
    if (-not $cargoNdkCheck) {
        Write-Host-Colored "Warning: 'cargo-ndk' might not be installed. Attempting to install..." "Yellow"
        Invoke-Build-Command "cargo" "install cargo-ndk"
    }

    # 2. Define Android targets
    $AndroidTargets = @{
        "aarch64-linux-android" = "arm64-v8a";
        "armv7-linux-androideabi" = "armeabi-v7a";
        "x86_64-linux-android" = "x86_64";
    }

    # 3. Build for each target
    foreach ($arch in $AndroidTargets.Keys) {
        Write-Host-Colored "Building for ABI: $($AndroidTargets[$arch])" "Cyan"
        # Note: The arguments string for cargo ndk is complex, but our modified function handles it.
        Invoke-Build-Command "cargo" "ndk --target $arch --platform 21 -- build --release"
        
        # 4. Copy the compiled .so file
        $JniLibsBase = Join-Path $ProjectRoot "android/app/src/main/jniLibs"
        $DestDir = Join-Path $JniLibsBase $AndroidTargets[$arch]
        if (-not (Test-Path $DestDir)) {
            New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
        }
        $SourceFile = Join-Path $RustCoreDir "target/$arch/release/librust_core.so"
        $DestFile = Join-Path $DestDir "librust_core.so"
        Write-Host-Colored "Copying '$SourceFile' to '$DestFile'" "Cyan"
        Copy-Item -Path $SourceFile -Destination $DestFile -Force
    }
}
elseif ($Target -eq "web") {
    Write-Host-Colored "--- Building for Web (WASM) ---" "Magenta"

    # 1. Check for wasm-pack
    Check-Command-Exists "wasm-pack"

    # 2. Build the WASM package
    # The output directory will be 'pkg' inside the rust_core directory
    Invoke-Build-Command "wasm-pack" "build --target web"

    # 3. Copy the generated package to the Flutter web directory
    $SourceDir = Join-Path $RustCoreDir "pkg"
    $DestDir = Join-Path $ProjectRoot "web/pkg"
    if (Test-Path $DestDir) {
        Remove-Item -Recurse -Force $DestDir
    }
    Write-Host-Colored "Copying '$SourceDir' to '$DestDir'" "Cyan"
    Copy-Item -Recurse -Path $SourceDir -Destination $DestDir
}

# Return to the project root
Set-Location $ProjectRoot

Write-Host-Colored "=========================================" "Green"
Write-Host-Colored "  Build for target '$Target' complete!" "Green"
Write-Host-Colored "=========================================" "Green"
