@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>nul
if errorlevel 1 goto python
py -3 play.py %*
if errorlevel 1 pause
exit /b
:python
where python >nul 2>nul
if errorlevel 1 goto missing
python play.py %*
if errorlevel 1 pause
exit /b
:missing
echo Python 3.11+ is required. Install Python from python.org first.
pause
