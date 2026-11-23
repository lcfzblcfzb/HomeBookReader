@echo off
rem HomePdfReader Android launcher (double-click or run in terminal)
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_android.ps1" %*
if errorlevel 1 pause
endlocal
