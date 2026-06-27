@echo off
echo Installing Python dependencies...
echo ====================================
echo.

REM Проверяем наличие Python
python --version > nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found!
    echo Please install Python from https://python.org
    echo Make sure to check "Add Python to PATH"
    pause
    exit /b 1
)

echo [OK] Python found:
python --version
echo.

REM Устанавливаем pyserial
echo Installing pyserial...
python -m pip install pyserial --quiet

if errorlevel 1 (
    echo [ERROR] Failed to install pyserial
    echo Trying with --user...
    python -m pip install pyserial --user --quiet
)

echo.
echo [OK] Dependencies installed!
echo.
pause
