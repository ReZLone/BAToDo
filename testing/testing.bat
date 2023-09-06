@echo off
chcp 65001 > NUL
setlocal ENABLEDELAYEDEXPANSION

set expire=26-03-2023

set "sdate1=%olddate:~-4%%olddate:~3,2%%olddate:~0,2%"
set "sdate2=%newdate:~-4%%newdate:~3,2%%newdate:~0,2%"
if %sdate1% GTR %sdate2% (goto there)  else echo here
pause>NUL

0,0046136101499423