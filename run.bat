@echo off
setlocal

rem Launch SyndromeOS pipeline via PowerShell
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1" %*
