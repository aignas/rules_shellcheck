@echo off
setlocal enabledelayedexpansion

set "output=%~1"
shift

if not "%~1"=="--" (
    echo aspect_runner: expected '--' after output path, got: %~1 1>&2
    exit /b 1
)
shift

break > "%output%"

set "cmd="
:loop
if "%~1"=="" goto :run
set "cmd=!cmd! %1"
shift
goto :loop

:run
%cmd%
exit /b %errorlevel%
