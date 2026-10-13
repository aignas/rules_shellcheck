@ECHO OFF
setlocal enabledelayedexpansion

@REM Usage: aspect_runner.bat <output> -- <shellcheck> [args...]
@REM
@REM Arguments are split from the full argument string because cmd.exe also
@REM splits numbered parameters on "=" (as in --rcfile=...). Forward slashes
@REM are replaced since cmd.exe cannot run a command whose path contains them.
set "args=%*"
for /F "usebackq tokens=1,2,3,*" %%A in ('!args!') do (
    set "output=%%~A"
    set "shellcheck=%%~C"
    set "shellcheck_args=%%D"
)

type nul > "!output:/=\!"
"!shellcheck:/=\!" !shellcheck_args!
exit /b !ERRORLEVEL!
