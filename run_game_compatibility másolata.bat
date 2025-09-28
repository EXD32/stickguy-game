@echo off
echo Starting Platformer Game with Multiple Compatibility Modes...
echo.

REM Try to find Godot executable in common locations
set GODOT_PATH=""

if exist "C:\Program Files\Godot\godot.exe" (
    set GODOT_PATH="C:\Program Files\Godot\godot.exe"
) else if exist "C:\Program Files (x86)\Godot\godot.exe" (
    set GODOT_PATH="C:\Program Files (x86)\Godot\godot.exe"
) else if exist "%USERPROFILE%\AppData\Local\Godot\godot.exe" (
    set GODOT_PATH="%USERPROFILE%\AppData\Local\Godot\godot.exe"
) else if exist "%USERPROFILE%\Downloads\Godot\godot.exe" (
    set GODOT_PATH="%USERPROFILE%\Downloads\Godot\godot.exe"
) else (
    echo Godot not found in common locations. Please run this from Godot editor instead.
    echo Or modify this batch file to point to your Godot installation.
    pause
    exit /b 1
)

echo Found Godot at: %GODOT_PATH%
echo.

REM Try multiple compatibility approaches
echo Attempting Method 1: GLES2 with software rendering...
%GODOT_PATH% --rendering-driver gles2 --disable-vsync --audio-driver Dummy
if not errorlevel 1 goto success

echo.
echo Method 1 failed. Attempting Method 2: OpenGL3 compatibility...
%GODOT_PATH% --rendering-driver opengl3 --rendering-method gl_compatibility --disable-vsync
if not errorlevel 1 goto success

echo.
echo Method 2 failed. Attempting Method 3: Headless mode test...
%GODOT_PATH% --headless --disable-render-loop
if not errorlevel 1 goto success

echo.
echo Method 3 failed. Attempting Method 4: Force software rendering...
%GODOT_PATH% --rendering-driver gles2 --disable-vsync --force-gl-vendor software
if not errorlevel 1 goto success

echo.
echo Method 4 failed. Attempting Method 5: Minimal graphics mode...
%GODOT_PATH% --rendering-driver gles2 --single-window --disable-vsync --audio-driver Dummy --disable-3d
if not errorlevel 1 goto success

echo.
echo All methods failed. This might be a deeper system compatibility issue.
echo Try:
echo 1. Update your graphics drivers
echo 2. Run as administrator
echo 3. Disable antivirus temporarily
echo 4. Use Godot 3.x instead of 4.x
goto end

:success
echo.
echo Game launched successfully!
goto end

:end
echo.
echo Press any key to exit...
pause > nul