@ECHO OFF

echo "" > "%SHELLCHECK_ASPECT_OUTPUT%"
call %*
exit /b %ERRORLEVEL%
