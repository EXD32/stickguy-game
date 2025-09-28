@echo off
title Emergency Godot Launcher - No Graphics Mode
echo.
echo ============================================
echo   EMERGENCY GODOT LAUNCHER - NO GRAPHICS
echo ============================================
echo.
echo This will try to launch your game in text-only mode
echo to verify that the scripts are working properly.
echo.

REM Find Godot
set GODOT_PATH=""
for %%i in (godot.exe) do set GODOT_PATH="%%~$PATH:i"

if %GODOT_PATH%=="" (
    echo ERROR: Godot not found in system PATH
    echo Please make sure Godot is installed and added to PATH
    echo or place godot.exe in this folder.
    echo.
    pause
    exit /b 1
)

echo Found Godot: %GODOT_PATH%
echo.

echo Attempting to run in server mode (no graphics)...
echo This will test if your scripts have any errors.
echo.

%GODOT_PATH% --headless --server --path "%~dp0"

echo.
echo If you saw script errors above, those need to be fixed.
echo If no errors appeared, the problem is graphics-related.
echo.
echo Next steps if no script errors:
echo 1. Try Godot 3.5.x instead of 4.x
echo 2. Update your graphics drivers
echo 3. Try running on a different computer
echo 4. Contact Godot community for DisplayServer help
echo.
pause