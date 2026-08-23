@echo off
set PATH=%LOCALAPPDATA%\node-portable\node-v22.14.0-win-x64;%PATH%
cd /d "%~dp0"
npx astro dev --port 4322
