@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ==============================================================================
rem  BriskOS 1.0 LTS (Feather) - QEMU Virtual Machine Test Harness (Windows)
rem  Lightweight desktop test environment for Windows CMD and PowerShell
rem  Debian 13 (Trixie) amd64 | VirtIO VGA | Intel HDA Audio Emulation
rem ==============================================================================

title BriskOS 1.0 (Feather) - QEMU Virtual Machine Test Harness

echo ======================================================================
echo          BriskOS 1.0 (Feather) - QEMU Virtual Machine Test Harness    
echo         Debian 13 Trixie amd64 ^| Stacking Wayland (Labwc Desktop)     
echo ======================================================================
echo.

rem ------------------------------------------------------------------------------
rem  Path Discovery
rem ------------------------------------------------------------------------------
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%.."
set "PROJECT_ROOT=%CD%"
popd

rem ------------------------------------------------------------------------------
rem  Step 1: Locate QEMU x86_64 Emulator
rem ------------------------------------------------------------------------------
set "QEMU_EXE="

rem Check PATH first
where qemu-system-x86_64.exe >nul 2>&1
if %ERRORLEVEL% equ 0 (
    for /f "delims=" %%I in ('where qemu-system-x86_64.exe') do (
        if not defined QEMU_EXE set "QEMU_EXE=%%I"
    )
)

rem Check standard Windows installation directories
if not defined QEMU_EXE (
    if exist "C:\Program Files\qemu\qemu-system-x86_64.exe" (
        set "QEMU_EXE=C:\Program Files\qemu\qemu-system-x86_64.exe"
    ) else if exist "%ProgramFiles%\qemu\qemu-system-x86_64.exe" (
        set "QEMU_EXE=%ProgramFiles%\qemu\qemu-system-x86_64.exe"
    ) else if exist "%ProgramW6432%\qemu\qemu-system-x86_64.exe" (
        set "QEMU_EXE=%ProgramW6432%\qemu\qemu-system-x86_64.exe"
    ) else if exist "%LOCALAPPDATA%\Programs\qemu\qemu-system-x86_64.exe" (
        set "QEMU_EXE=%LOCALAPPDATA%\Programs\qemu\qemu-system-x86_64.exe"
    ) else if exist "C:\Program Files (x86)\qemu\qemu-system-x86_64.exe" (
        set "QEMU_EXE=C:\Program Files (x86)\qemu\qemu-system-x86_64.exe"
    )
)

rem If still missing, provide clean guidance and exit
if not defined QEMU_EXE (
    echo [ERROR] QEMU x86_64 emulator was not found on this system.
    echo.
    echo Please install QEMU for Windows from the official download page:
    echo   https://www.qemu.org/download/#windows
    echo.
    echo Alternatively, install via Windows Package Managers:
    echo   winget install SoftwareFreedomConservancy.QEMU
    echo   choco install qemu
    echo.
    echo After installation, verify that QEMU is in your PATH or installed at:
    echo   C:\Program Files\qemu\
    echo.
    exit /b 1
)

echo [INFO] QEMU Emulator : %QEMU_EXE%

rem ------------------------------------------------------------------------------
rem  Step 2: Locate BriskOS ISO Image
rem ------------------------------------------------------------------------------
set "ISO_PATH="

rem Check if passed as parameter
if not "%~1"=="" (
    if exist "%~1" (
        set "ISO_PATH=%~f1"
    ) else if "%~1"=="--iso" (
        if not "%~2"=="" (
            if exist "%~2" (
                set "ISO_PATH=%~f2"
            )
        )
    )
)

rem Check canonical file in project root and current working directory
if not defined ISO_PATH (
    if exist "%PROJECT_ROOT%\BriskOS-1.0-amd64.iso" (
        set "ISO_PATH=%PROJECT_ROOT%\BriskOS-1.0-amd64.iso"
    ) else if exist "%CD%\BriskOS-1.0-amd64.iso" (
        set "ISO_PATH=%CD%\BriskOS-1.0-amd64.iso"
    ) else if exist "%SCRIPT_DIR%BriskOS-1.0-amd64.iso" (
        set "ISO_PATH=%SCRIPT_DIR%BriskOS-1.0-amd64.iso"
    )
)

rem Wildcard search if still not found
if not defined ISO_PATH (
    for %%F in ("%PROJECT_ROOT%\BriskOS-*.iso") do (
        if not defined ISO_PATH if exist "%%F" set "ISO_PATH=%%~fF"
    )
    for %%F in ("%CD%\BriskOS-*.iso") do (
        if not defined ISO_PATH if exist "%%F" set "ISO_PATH=%%~fF"
    )
)

rem If ISO not located, show clean error message
if not defined ISO_PATH (
    echo [ERROR] BriskOS ISO image was not found.
    echo.
    echo Expected artifact: BriskOS-1.0-amd64.iso
    echo Search locations checked:
    echo   - %PROJECT_ROOT%\BriskOS-1.0-amd64.iso
    echo   - %CD%\BriskOS-1.0-amd64.iso
    echo.
    echo Build the ISO first or specify the ISO path manually:
    echo   test-qemu.bat "C:\path\to\BriskOS-1.0-amd64.iso"
    echo.
    exit /b 1
)

echo [INFO] Target ISO    : %ISO_PATH%

rem ------------------------------------------------------------------------------
rem  Step 3: Configuration Summary
rem ------------------------------------------------------------------------------
echo [INFO] Memory (RAM)  : 2048 MB (2 GB)
echo [INFO] CPU Cores     : 2 vCPUs
echo [INFO] Graphics      : VirtIO VGA (-vga virtio)
echo [INFO] Audio         : Intel HDA (-device intel-hda -device hda-duplex)
echo [INFO] Acceleration : Windows Hypervisor Platform (WHPX) with TCG fallback
echo [INFO] Network       : VirtIO Net (User NAT, SSH forwarded to localhost:2222)
echo ----------------------------------------------------------------------
echo Spawning BriskOS virtual machine...
echo Press Ctrl+Alt+G to release mouse capture if needed.
echo.

rem ------------------------------------------------------------------------------
rem  Step 4: Launch QEMU
rem ------------------------------------------------------------------------------
"%QEMU_EXE%" ^
  -accel whpx ^
  -accel tcg ^
  -cpu max ^
  -m 2048M ^
  -smp 2 ^
  -vga virtio ^
  -device virtio-tablet-pci ^
  -audiodev dsound,id=snd0 ^
  -device intel-hda ^
  -device hda-duplex,audiodev=snd0 ^
  -netdev user,id=net0,hostfwd=tcp::2222-:22 ^
  -device virtio-net-pci,netdev=net0 ^
  -boot d ^
  -cdrom "%ISO_PATH%"

if %ERRORLEVEL% neq 0 (
    echo.
    echo [WARN] QEMU exited with code %ERRORLEVEL%.
)

exit /b %ERRORLEVEL%
