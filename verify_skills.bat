@echo off
REM Skills CLI Verification Script for Windows
REM Generated: 2026-05-24
REM Purpose: Verify all installed Agent Skills

setlocal enabledelayedexpansion

REM Create logs directory
if not exist "logs" mkdir logs
set VERIFY_LOG=logs\verify_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log
set VERIFY_LOG=%VERIFY_LOG: =0%

echo [%date% %time%] Starting Skills Verification > %VERIFY_LOG%
echo [%date% %time%] Log file: %VERIFY_LOG% >> %VERIFY_LOG%
echo. >> %VERIFY_LOG%

echo === SKILLS VERIFICATION ===
echo.

REM Expected skills
set EXPECTED_SKILLS=find-skills mcp-builder frontend-design web-design-guidelines
set FOUND=0
set MISSING=0
set TOTAL=4

echo Checking for expected skills...
echo [%date% %time%] Checking for expected skills >> %VERIFY_LOG%
echo. >> %VERIFY_LOG%

REM Get installed skills (JSON output)
echo [%date% %time%] Getting list of installed skills >> %VERIFY_LOG%

for %%s in (%EXPECTED_SKILLS%) do (
    echo Checking: %%s
    echo [%date% %time%] Checking: %%s >> %VERIFY_LOG%

    REM Check if skill directory exists
    set SKILL_DIR=%USERPROFILE%\.agents\skills\%%s
    if exist "!SKILL_DIR!" (
        echo [PASS] Found: %%s
        echo [%date% %time%] FOUND: %%s >> %VERIFY_LOG%
        set /a FOUND+=1

        REM Check for SKILL.md
        if exist "!SKILL_DIR!\SKILL.md" (
            echo   [PASS] SKILL.md exists
            echo [%date% %time%]   SKILL.md exists >> %VERIFY_LOG%
        ) else (
            echo   [WARN] SKILL.md not found
            echo [%date% %time%]   WARN: SKILL.md not found >> %VERIFY_LOG%
        )

        REM List directory contents
        echo   [INFO] Directory: !SKILL_DIR!
        echo [%date% %time%]   Directory: !SKILL_DIR! >> %VERIFY_LOG%
    ) else (
        echo [FAIL] Missing: %%s
        echo [%date% %time%] MISSING: %%s >> %VERIFY_LOG%
        set /a MISSING+=1
    )
    echo.
    echo. >> %VERIFY_LOG%
)

REM Summary
echo === VERIFICATION SUMMARY ===
echo Total expected: %TOTAL%
echo Found: %FOUND%
echo [%date% %time%] Total expected: %TOTAL% >> %VERIFY_LOG%
echo [%date% %time%] Found: %FOUND% >> %VERIFY_LOG%

if %MISSING% gtr 0 (
    echo Missing: %MISSING%
    echo [%date% %time%] Missing: %MISSING% >> %VERIFY_LOG%
)
echo.

echo Listing all installed skills...
echo [%date% %time%] Listing all installed skills >> %VERIFY_LOG%
call npx skills@latest list --global >> %VERIFY_LOG% 2>&1

echo.
echo Verification complete! Check %VERIFY_LOG% for details.
echo [%date% %time%] Verification complete >> %VERIFY_LOG%

if %MISSING% gtr 0 (
    exit /b 1
)
exit /b 0
