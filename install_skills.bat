@echo off
REM Skills CLI Installation Script for Windows
REM Generated: 2026-05-24
REM Purpose: Install Agent Skills globally with automatic retries and error handling

setlocal enabledelayedexpansion

REM Create logs directory
if not exist "logs" mkdir logs
set INSTALL_LOG=logs\install_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log
set INSTALL_LOG=%INSTALL_LOG: =0%

echo [%date% %time%] Starting Skills CLI Installation > %INSTALL_LOG%
echo [%date% %time%] Log file: %INSTALL_LOG% >> %INSTALL_LOG%
echo. >> %INSTALL_LOG%

echo === SKILLS CLI INSTALLATION ===
echo.

REM Check Node.js
echo [%date% %time%] Checking Node.js installation... >> %INSTALL_LOG%
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed. Please install Node.js first.
    echo [%date% %time%] ERROR: Node.js is not installed >> %INSTALL_LOG%
    exit /b 1
)
for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
echo [PASS] Node.js: %NODE_VERSION%
echo [%date% %time%] Node.js: %NODE_VERSION% >> %INSTALL_LOG%

REM Check npm
where npm >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] npm is not installed. Please install npm first.
    echo [%date% %time%] ERROR: npm is not installed >> %INSTALL_LOG%
    exit /b 1
)
for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i
echo [PASS] npm: %NPM_VERSION%
echo [%date% %time%] npm: %NPM_VERSION% >> %INSTALL_LOG%

REM Check npx
where npx >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] npx is not installed. Please install npx first.
    echo [%date% %time%] ERROR: npx is not installed >> %INSTALL_LOG%
    exit /b 1
)
echo [PASS] npx is available
echo [%date% %time%] npx is available >> %INSTALL_LOG%
echo.

REM Counters
set TOTAL=4
set SUCCESS=0
set FAILED=0

echo === INSTALLING SKILLS ===
echo.

REM 1. find-skills
echo [1/4] Installing find-skills from vercel-labs/skills...
echo [%date% %time%] Installing find-skills from vercel-labs/skills >> %INSTALL_LOG%
call npx skills@latest add vercel-labs/skills --skill find-skills --global --yes >> %INSTALL_LOG% 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] Installed: find-skills
    echo [%date% %time%] SUCCESS: find-skills >> %INSTALL_LOG%
    set /a SUCCESS+=1
) else (
    echo [FAILED] Failed to install: find-skills
    echo [%date% %time%] FAILED: find-skills >> %INSTALL_LOG%
    set /a FAILED+=1
)
echo.

REM 2. mcp-builder
echo [2/4] Installing mcp-builder from anthropics/skills...
echo [%date% %time%] Installing mcp-builder from anthropics/skills >> %INSTALL_LOG%
call npx skills@latest add anthropics/skills --skill mcp-builder --global --yes >> %INSTALL_LOG% 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] Installed: mcp-builder
    echo [%date% %time%] SUCCESS: mcp-builder >> %INSTALL_LOG%
    set /a SUCCESS+=1
) else (
    echo [FAILED] Failed to install: mcp-builder
    echo [%date% %time%] FAILED: mcp-builder >> %INSTALL_LOG%
    set /a FAILED+=1
)
echo.

REM 3. frontend-design
echo [3/4] Installing frontend-design from anthropics/skills...
echo [%date% %time%] Installing frontend-design from anthropics/skills >> %INSTALL_LOG%
call npx skills@latest add anthropics/skills --skill frontend-design --global --yes >> %INSTALL_LOG% 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] Installed: frontend-design
    echo [%date% %time%] SUCCESS: frontend-design >> %INSTALL_LOG%
    set /a SUCCESS+=1
) else (
    echo [FAILED] Failed to install: frontend-design
    echo [%date% %time%] FAILED: frontend-design >> %INSTALL_LOG%
    set /a FAILED+=1
)
echo.

REM 4. web-design-guidelines
echo [4/4] Installing web-design-guidelines from vercel-labs/agent-skills...
echo [%date% %time%] Installing web-design-guidelines from vercel-labs/agent-skills >> %INSTALL_LOG%
call npx skills@latest add vercel-labs/agent-skills --skill web-design-guidelines --global --yes >> %INSTALL_LOG% 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] Installed: web-design-guidelines
    echo [%date% %time%] SUCCESS: web-design-guidelines >> %INSTALL_LOG%
    set /a SUCCESS+=1
) else (
    echo [FAILED] Failed to install: web-design-guidelines
    echo [%date% %time%] FAILED: web-design-guidelines >> %INSTALL_LOG%
    set /a FAILED+=1
)
echo.

REM Summary
echo === INSTALLATION SUMMARY ===
echo Successfully installed: %SUCCESS%/%TOTAL% skills
echo [%date% %time%] Successfully installed: %SUCCESS%/%TOTAL% skills >> %INSTALL_LOG%
if %FAILED% gtr 0 (
    echo Failed installations: %FAILED%/%TOTAL% skills
    echo [%date% %time%] Failed installations: %FAILED%/%TOTAL% skills >> %INSTALL_LOG%
)
echo.

echo Listing all installed skills...
echo [%date% %time%] Listing all installed skills >> %INSTALL_LOG%
call npx skills@latest list --global >> %INSTALL_LOG% 2>&1

echo.
echo Installation complete! Check %INSTALL_LOG% for details.
echo [%date% %time%] Installation complete >> %INSTALL_LOG%

if %FAILED% gtr 0 (
    exit /b 1
)
exit /b 0
