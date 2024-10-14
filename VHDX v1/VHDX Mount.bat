@ECHO OFF
nircmd elevate PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0VHDX.ps1" %* -operation ""