@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>nul
if errorlevel 1 goto python
py -3 setup.py %*
goto done
:python
where python >nul 2>nul
if errorlevel 1 goto missing
python setup.py %*
goto done
:missing
echo Python 3.11+ is required. Install Python from python.org, then rerun setup.bat.
:done
pause
