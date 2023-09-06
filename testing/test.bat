    set bob=-ciao Sium VV hello world
setlocal ENABLEDELAYEDEXPANSION
goto :main

:loadVariable
    set a=89
    set b=78
    set c=5
goto :EOF

:changeVariable

rem Check if both arguments have been provided
if [%1]==[] goto :eof
if [%2]==[] goto :eof

rem Set variables for the line to be replaced and the new value
set setting_name=%~1
set search_terms=%setting_name%=%%%setting_name%%%
set new_value=%~2

rem Find the line number of the line to be replaced
for /F "tokens=* usebackq" %%F in (`list "test.bat" /fv "    set %search_terms%"`) do (
set line_num=%%F
)
echo %line_num%
pause

rem Replace the line in the file
set /a line_num+=1
replaceline test.bat %line_num% "    set %setting_name%=%new_value%"

goto :EOF

goto :EOF

:main
    call :loadVariable
    echo a:%a%
    echo b:%b%
    echo c:%c%
    set /p value="Insert new value for a: "
    @REM for /F "tokens=* usebackq" %%F in (`list "test.bat" /fv "    set a=%a%"`) do (
    @REM set line_num=%%F
    @REM )
    @REM set /a line_num+=1
    @REM replaceline test.bat %line_num% "    set a=%newvalue%"
    call :changeVariable b %value%
    goto :main
pause > NUL
goto :EOF
