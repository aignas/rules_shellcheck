@ECHO OFF
setlocal enableextensions enabledelayedexpansion

@REM Runner for `shellcheck_test` on Windows. The rule passes its inputs as
@REM rlocation paths through `SHELLCHECK_TEST_*` environment variables; see
@REM `rules.bzl`.

@REM --- begin runfiles.bat initialization v3 ---
set "_rf=batch/runfiles/runfiles.bat"
if not defined RUNFILES_DIR if exist "%~f0.runfiles\" set "RUNFILES_DIR=%~f0.runfiles"
set "_rf_mf="
if defined RUNFILES_MANIFEST_FILE if exist "!RUNFILES_MANIFEST_FILE!" set "_rf_mf=!RUNFILES_MANIFEST_FILE!"
if not defined _rf_mf if defined RUNFILES_DIR for %%m in ("!RUNFILES_DIR!\MANIFEST" "!RUNFILES_DIR!_manifest") do if not defined _rf_mf if exist "%%~m" set "_rf_mf=%%~m"
if not defined _rf_mf for %%m in ("%~f0.runfiles_manifest" "%~f0.exe.runfiles_manifest") do if not defined _rf_mf if exist "%%~m" set "_rf_mf=%%~m"
if defined _rf_mf (set "_rf_mf=!_rf_mf:/=\!" & set "RUNFILES_MANIFEST_FILE=!_rf_mf!")
@REM Map the apparent repo name rules_batch to its canonical runfiles directory.
set "_rf_rm="
if defined RUNFILES_DIR if exist "!RUNFILES_DIR!\_repo_mapping" set "_rf_rm=!RUNFILES_DIR!\_repo_mapping"
if not defined _rf_rm if defined _rf_mf for /F "usebackq tokens=1,*" %%i in (`%SYSTEMROOT%\system32\findstr.exe /b /l /c:"_repo_mapping " "!_rf_mf!" 2^>nul`) do set "_rf_rm=%%j"
set "_rf_c="
if defined _rf_rm for /F "usebackq delims=" %%L in ("!_rf_rm:/=\!") do if not defined _rf_c (
    set "_rf_l=%%L"
    if not "!_rf_l:,rules_batch,=!"=="!_rf_l!" (set "_rf_c=!_rf_l:*,=!" & set "_rf_c=!_rf_c:*,=!")
)
if not defined _rf_c set "_rf_c=rules_batch"
set "_rf=!_rf_c!/!_rf!"
set "RLOCATION="
if defined RUNFILES_DIR if exist "!RUNFILES_DIR!\!_rf:/=\!" set "RLOCATION=!RUNFILES_DIR!\!_rf:/=\!"
if not defined RLOCATION if defined _rf_mf for /F "usebackq tokens=1,*" %%i in (`%SYSTEMROOT%\system32\findstr.exe /b /l /c:"!_rf! " "!_rf_mf!" 2^>nul`) do if not defined RLOCATION set "RLOCATION=%%j"
if not defined RLOCATION (echo>&2 ERROR: cannot find !_rf! in runfiles & exit /b 1)
set "RLOCATION=!RLOCATION:/=\!"
set "_rf=" & set "_rf_mf=" & set "_rf_rm=" & set "_rf_c=" & set "_rf_l="
@REM --- end runfiles.bat initialization v3 ---

call "%RLOCATION%" "%SHELLCHECK_TEST_BIN%" shellcheck || exit /b 1
call "%RLOCATION%" "%SHELLCHECK_TEST_RCFILE%" rcfile || exit /b 1
set "args=%SHELLCHECK_TEST_OPTS% --rcfile="!rcfile!""

@REM The drive and path modifier (~dp) ends with a backslash, which would
@REM escape the closing quote; a dot is appended to avoid that.
if defined SHELLCHECK_TEST_SOURCE_FILES for %%F in (%SHELLCHECK_TEST_SOURCE_FILES%) do (
    call "%RLOCATION%" "%%F" file || exit /b 1
    for %%D in ("!file!") do set "args=!args! --source-path="%%~dpD.""
)

if defined SHELLCHECK_TEST_FILES for %%F in (%SHELLCHECK_TEST_FILES%) do (
    call "%RLOCATION%" "%%F" file || exit /b 1
    set "args=!args! "!file!""
)

if "%SHELLCHECK_TEST_EXPECT_FAIL%"=="1" (
    "!shellcheck!" !args! && (echo>&2 ERROR: expected shellcheck to fail & exit /b 1)
    exit /b 0
)

"!shellcheck!" !args!
exit /b %ERRORLEVEL%
