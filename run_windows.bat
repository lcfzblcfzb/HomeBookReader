@echo off
rem HomePdfReader Windows launcher (double-click or run in terminal)
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_windows.ps1"
if errorlevel 1 pause
endlocal
