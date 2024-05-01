@echo off
chcp 65001 > NUL
setlocal ENABLEDELAYEDEXPANSION

::Setting up the COSTANT variables
::FIXME - The TODOPATH and also the TODOFILES variables should be working even when their path has a folder with spaces in their name
set TODOPATH=%~dp0
set TODOFILES=%TODOPATH%lists
if exist *.td set TODOFILES=%CD%
set "PATH=%PATH%;%TODOPATH%libs"


::Scan the argument and set the default variables
set arg_number=0
:argScan
    set /a arg_number+=1
    set "arg!arg_number!=%~1"
    shift
if not [%1]==[] goto :argScan


::Loading the settings and the icons
call :loadSettings
call :loadIcons


::SECTION - Preliminar functions

::Check if the todo.td file is available and if not then it creates a new one
:checkToDoList
	if exist %TODOFILES%\todo.td (
		call :readTodoList
		goto :argChecker
	)
	rem echo. [91mTodo list not found.[0m
	rem echo. [4mCreating one now at %TODOFILES%[0m
	rem ::Happening if the todo.td file isn't available
	rem echo Done ✓…> %TODOFILES%\todo.td
	rem echo Not Done â�Œ>> %TODOFILES%\todo.td

   rem  call :readTodoList
goto :argChecker

:readTodoList
	set line_count=0
	set sect_count=0

	::Scan every line in the todo file 
	for /f "tokens=*" %%a in (%TODOFILES%\todo.td) do (
		set /a line_count+=1
		set todo[!line_count!]=%%a
	)
	::Save every section in the todo file
	for /f "tokens=1,2 delims=:" %%a in ('findstr /n /C:"@sect" %TODOFILES%\todo.td') do (
		set sect_line[!sect_count!]=%%a
		set sect_name[!sect_count!]=%%b
		set /a sect_count+=1
	)

	set /a sect_max_ind=%sect_count% - 1

	::Remove the @sect and the spaces from the section name
	for /l %%i in (0,1,%sect_max_ind%) do (
		set sect_name[%%i]=!sect_name[%%i]:@sect=!
		set sect_name[%%i]=!sect_name[%%i]: =!
	)

goto :EOF

:argChecker
	echo.

	::If no argument is given then set the argument to the default (show)
	if not defined arg1 (
		goto :showList
	)

	::Entry expiring condition of deletion
	for %%a in (%settingsArgs%) do if %arg1%==%%~a goto :settingsChanger
	call :deleteExpiredEntries
	

	::Check other arguments
	for %%a in (%aliasArgs%) do if %arg1%==%%~a goto :aliasFunc
	for %%a in (%showArgs%) do if %arg1%==%%~a goto :showList
	for %%a in (%addArgs%) do if %arg1%==%%~a goto :addToList
	for %%a in (%tickArgs%) do if %arg1%==%%~a goto :tickFromList
	for %%a in (%removeArgs%) do if %arg1%==%%~a goto :removeFromList
	for %%a in (%deleteArgs%) do if %arg1%==%%~a goto :deleteList
	for %%a in (-help --help -man -h /? /help /h help) do if %arg1%==%%~a goto :helpPage

	echo. Invalid argument.
goto :EOF

:helpPage
	echo Welcome to Todo.bat, the command line tool for managing your Todo list!

	echo Usage:
	echo todo ^<command^> [^<args^>]
	echo.
	echo The available commands are:
	echo.
	echo -show, -s, /s: Display the Todo list
	echo     Usage: todo ^| todo -s [^<starting_line^>] [^<finish_line^>] ^| todo -s --sect ^<section^>
	echo     Options:
	echo     - If no other arguments are passed displays the whole Todo list
	echo     ^<starting_line^> ^<finish_line^>: Display the Todo list in a range of lines
	echo     --sect ^<section^>: Display a specific ^<section^> of the Todo list
	echo.
	echo -add, -a: Add an entry or a section to the Todo list
	echo     Usage: todo -a "<entry>" ^<section^> ^| todo --sect ^<name^> [^<color^>]
	echo     Options:
	echo     ^<entry^> ^<section^>: Add an ^<entry^> to a specific ^<section^> of the Todo list
	echo     --sect ^<name^> [^<color^>]: Add a section to the end of the Todo list with the given ^<name^>.
	echo	 			     [^<color^>]: Specify the color of the section [red, white, yellow, green, magenta, blue(default), cyan].
	echo.
	echo -remove, -rem, -r, -rm: Remove an entry from the Todo list
	echo     Usage: todo -r ^<section^> ^<index/indexes^>
	echo     Options:
	echo     -r: Remove an entry or section from the Todo list
	echo     --sect: Specify the section to remove from
	echo     -rm: Remove an entry or section from the Todo list
	echo     -rem: Remove an entry or section from the Todo list
	echo.
	echo -done, -tick, -t: Toggle the status of an entry from not done to done
	echo     Usage: todo -t ^<section^> ^<index/indexes^>
	echo.
	echo -delete, -del, -d: Delete a specific todo list file
	echo     Usage: todo -d ^<todo filename^>
	echo.
	echo -alias, -al: Create an alias for a command or argument
	echo     Usage: todo -al ^<todo command^> ^<alias^>
	echo.
	echo -settings, -set, -st: Change the settings of Todo.bat
	echo     Usage: todo -st [^<setting_name^>] [^<setting_value^>]
	echo     Options:
	echo     -st: Display the settings menu
	echo     -option: Change a specific setting
	echo     -o: Change a specific setting
	echo     -set: Change a specific setting
	echo     -opt: Change a specific setting
	echo     Possible settings to change:
	echo     entryExpiring=true/false: If done entries should be auto delete after some days
	echo     expiringTime=^<input^> [default=25]: Days before an entry gets autodeleted
	echo     iconsType=set/custom: Choose between a set of predefined icons or a custom one
	echo     cstmTickIcon=^<input^>: The custom tick icon
	echo     cstmCrossIcon=^<input^>: The custom cross icon
	echo     iconsSet=^<number 1 to 4^>: The set of predefined icons to use
	echo.
	echo Examples:
	echo     todo -s 1 5: Display lines 1 to 5 of the Todo list
	echo     todo -a "Buy milk" Grocery blue: Add an entry "Buy milk" to the section "Grocery" with the color blue
	echo     todo -r Grocery 1,3: Remove entries 1 and 3 from the "Grocery" section
	echo     todo -t Work 2: Toggle the status of the second entry in the "Work" section
	echo     todo -d my_todo_list.td: Delete the "my_todo_list.td" file
	echo     todo -al -s ls: Create an alias "ls" for the "-s" command
	echo     todo -st expiringTime 30: Change the "expiringTime" setting to 30 days
	echo.
	echo   Thank you for using Todo.bat!
goto :EOF

:deleteExpiredEntries
    set todays_date=%date:~-4%%date:~3,2%%date:~0,2%

	set j=1
    :deleteExpiredEntries_loop
    set expiring_date=
    if !todo[%j%]:~-5!==@done (
        set expiring_date=!todo[%j%]:~-17!
        set expiring_date=!expiring_date:~0,10!
        set expiring_date=!expiring_date:~-4!!expiring_date:~3,2!!expiring_date:~0,2!
    )

    if defined expiring_date (
		set /a target_index=%j% - 1
		if %todays_date% GTR %expiring_date% list %TODOFILES%\todo.td /ra !target_index! & call :readTodoList & set /a j-=1
	)

    if %j% LSS %line_count% set /a j+=1 & goto :deleteExpiredEntries_loop
goto :EOF

::!SECTION

::SECTION - General use functions

:displayList
    ::args: <starting_line> <final_line>
    set current_line=%~1
    set end_line=%~2
    set sect_line=%~3
    set todo_index=1
    if defined sect_line set /a todo_index=%current_line% - %sect_line%
    if not defined current_line set current_line=1
    if not defined end_line set end_line=%line_count%
    :displayList_loop
	if !todo[%current_line%]:~-5!==@done (
        if %entryExpiring%==true (
            set dpl_expiring_date=!todo[%current_line%]:~-22!
            set dpl_expiring_date=!dpl_expiring_date:~0,-6!
           
        ) else (
            set dpl_expiring_date=
		    rem if !todo[%current_line%]:~-5!==@done echo.%todo_index%. [92;9m!todo[%current_line%]:~0,-6![0m[92m %tick_icon%[0m& set /a todo_index+=1
        )
		echo.%todo_index%. [92;9m!todo[%current_line%]:~0,-23![0m[92m %tick_icon%[93m !dpl_expiring_date![0m& set /a todo_index+=1
	)
    if !todo[%current_line%]:~-5!==@todo echo.%todo_index%. [91m!todo[%current_line%]:~0,-6! %cross_icon%[0m & set /a todo_index+=1
    if !todo[%current_line%]:~-5!==@sect echo. & echo. !todo[%current_line%]:~0,-6! & set todo_index=1
    if %current_line% LSS %end_line% set /a current_line+=1 & goto :displayList_loop
goto :EOF

:reloadTodoList
	echo. [93mNew content of todo.td:[0m
	call :readTodoList
	call :displayList
goto :EOF

:findSection
    ::args: <search_section>
	set search_sect=%~1
	set sect_founded=false
	set i=0
	
	:findSection_loop
		if defined sect_name[%i%] (
			echo !sect_name[%i%]! | find /i "%search_sect%" >NUL
			if not errorlevel 1 (
				set found_sect=!sect_name[%i%]!
				set sect_founded=true
				set found_sect_ind=!i!
				set found_sect_line=!sect_line[%i%]!
			)
			set /a i+=1
			goto :findSection_loop
		) else (
			if %sect_founded%==false call :error "trying to find the '[93m%search_sect%[91m' section. It might not exist" & exit /b 1
		)

exit /b 0

:error <description>
	echo [91mAn error occured while %~1
	echo [0m(use -h or /? for more information)
goto :EOF

::!SECTION

::SECTION - Show function - Shows the whole ToDo list or just a selected part

:validateShowArg2
	if %arg2% LSS %line_count% ( set start_limit=%arg2% ) else ( call :error "trying to use '[93m%arg2%[91m' as a starting line. The line might not exist." & exit /b 1 )
goto :EOF

:validateShowArg3
	if %arg3% LSS %line_count% ( set end_limit=%arg3% ) else ( call :error "trying to use '[93m%arg3%[91m' as a ending line. The line might not exist." & exit /b 1 )
goto :EOF

:showList todo -s <starting_line> <limit_line> | todo -s --sect <section>
	if not [%arg2%]==[] (
		::Check if the second argument is a string or a number
		set "temp=" & for /f "delims=012345689" %%i in ("%arg2%") do set temp=%%i
		if defined temp goto :showSection
		call :validateShowArg2
	) else (
		set start_limit=1
	)

	if not [%arg3%]==[] ( 
		::Check if the third argument is a string or a number
		set "temp=" & for /f "delims=012345689" %%i in ("%arg3%") do set temp=%%i
		if defined temp ( call :error "trying to use '[93m%arg3%[91m' as a ending line. It's not a valid number." & exit /b 1 )
		call :validateShowArg3
	) else ( 
		set end_limit=%line_count%
	)

	echo. [93mContent of todo.td:[0m
	call :displayList %start_limit% %end_limit%
goto :EOF

:showSection
	if %arg2%==--sect ( 
		if not [%arg3%]==[] ( call :findSection %arg3% || goto :EOF ) else ( goto :displaySections )
	) else (
		call :error "trying to use '[93m%arg2%[91m' as a starting line. It's not a valid number." & exit /b 1
	)
	if %sect_founded%==false call :error "trying to find '[93m%search_sect%[91m' section. It might not exist." & exit /b 1
	set /a found_sect_ind+=1
	if defined sect_line[%found_sect_ind%] ( set /a end_limit=!sect_line[%found_sect_ind%]! - 1 ) else ( set /a end_limit=%line_count% )
	echo. [93mContent of todo.td^>%found_sect%[93m:[0m
	call :displayList %found_sect_line% %end_limit%
goto :EOF

:displaySections
	echo [93mCurrent Sections:
	echo.
	set i=0
	:displaySections_loop
		if defined sect_name[%i%] (
			echo !sect_name[%i%]!
			set /a i+=1
			goto :displaySections_loop
		)
goto :EOF

::!SECTION

::SECTION - Add function - add a new section or a new entry

:addToList
    ::Usage: todo -a <entry> <section> | todo -a --sect <section>

	if not defined arg2 ( goto :inputNewEntry ) else ( goto :createEntryOrSection )

	:inputNewEntry
		call :displayList
		echo.
		set /p new_entry="Insert new entry for the todo list: "
		if not defined new_entry ( echo. & echo No entry was created. & goto :EOF )
		call :createEntry %new_entry%
	goto :EOF
	
	:createEntryOrSection
		if "%arg2%"=="--sect" ( 
			if not [%arg3%]==[] ( call :createSection "%arg3%" ) else ( call :error "naming the section. Invalid input." & exit /b 1 )
		) else (
			if [%arg3%]==[] ( call :createEntry "%arg2%" ) else ( call :scanSection "%arg3%" & call :createEntry "%arg2%" !entry_position! )
		)
	goto :EOF

	:validateEntSect <string> <out_var>
		set string=%~1
		set out_var=%~2
		::Removing the unaccepted characters
		set string=%string:[=%
		set string=%string:]=%
		set string=%string:@=%
		set %out_var%=%string%
	goto :EOF

	:scanSection <target_sect>
		set target_sect=%~1
		call :findSection %target_sect% || exit /b 1
		set /a found_sect_ind+=1
		if defined sect_line[%found_sect_ind%] (
			set /a entry_position=!sect_line[%found_sect_ind%]! - 1
		) else (
			set /a entry_position=%line_count%
		)
	goto :EOF

	:createEntry <string> <position>
		set og_string=%~1
		set entry_position=%~2
		if not defined entry_position call :selectEntrySect || goto :EOF
		call :validateEntSect "%og_string%" new_entry
		list %TODOFILES%\todo.td /ia %entry_position% "%new_entry% @todo"
		call :readTodoList
		echo. [93mNew content of todo.td:[0m
		call :displayList
	goto :EOF

	:selectEntrySect
		echo.
		call :displaySections
		set /p input_sect="Insert the section where to create the new entry: "
		call :scanSection %input_sect% || exit /b 1
	goto :EOF

	:createSection <string>
		set sect_color=94

		if defined arg4 (
			for %%a in (-r red -red -Red -RED -R) do if "%arg4%"=="%%~a" set sect_color=91
			for %%a in (-g green -green -Green -GREEN -G) do if "%arg4%"=="%%~a" set sect_color=92
			for %%a in (-y yellow -Yellow -YELLOW -Y) do if "%arg4%"=="%%~a" set sect_color=93
			for %%a in (-b blue -blue -Blue -BLUE -B) do if "%arg4%"=="%%~a" set sect_color=94
			for %%a in (-m magenta -magenta -Magenta -MAGENTA -M) do if "%arg4%"=="%%~a" set sect_color=95
			for %%a in (-c cyan -cyan -Cyan -CYAN -C) do if "%arg4%"=="%%~a" set sect_color=96
			for %%a in (-w white -white -White -WHITE -W) do if "%arg4%"=="%%~a" set sect_color=97
		)
		set new_sect=%~1
		call :validateEntSect "%new_sect%" new_sect
		list %TODOFILES%\todo.td /ab " [%sect_color%m[%new_sect%][0m @sect"
		call :reloadTodoList
	goto :EOF

goto :EOF

::!SECTION

::SECTION - Tick function - Tick an entry from the ToDo list 
:tickFromList
::Usage: todo -t <section> <index/indexes>

    if not defined arg2 call :error "trying to find a target section. The second argument was not used." & exit /b 1

    call :findSection %arg2% || goto :EOF
    set i=3

    :tickFromList_loop

        if defined arg%i% (
            set /a target_line=%found_sect_line% + !arg%i%!
        ) else (
            call :error "trying to access the third argument. It should be the index of the todo line." & exit /b 1
        )

        set /a found_sect_ind+=1
        if defined sect_line[%found_sect_ind%] (
            set limit_line=!sect_line[%found_sect_ind%]!
        ) else (
            set limit_line=%line_count%
        )

        if %target_line% LSS %limit_line% (
			if !todo[%target_line%]:~-5!==@todo (
				for /f "tokens=*" %%a in ('powershell -command "((Get-date).AddDays(%expirationTime%)).ToString('dd-MM-yyyy')"') do (
					set new_expiration_date=%%a
				)
				replaceline %TODOFILES%\todo.td %target_line% "!todo[%target_line%]:@todo=![exp:!new_expiration_date!] @done"
			)
			if !todo[%target_line%]:~-5!==@done replaceline %TODOFILES%\todo.td %target_line% "!todo[%target_line%]:~0,-22!@todo"
        ) else (
            call :error "trying to find the [93m'%arg3%'[91m index inside the [93m'%found_sect%'[91m section." & exit /b 1
        )

    if %i% LSS %arg_number% set /a i+=1 & goto :tickFromList_loop

	call :reloadTodoList
goto :EOF

::!SECTION

::SECTION - Remove function - Remove an entry from the ToDo list

:removeFromList
::Usage: todo -r <section> <index/indexes> | todo -r --sect <section>
	
	::Checking the existence of the second argument
	if not defined arg2 call :error "trying to find a [93mtarget section[91m. The second argument was not used." & exit /b 1

	::Checking if the second method is trying to be used
	if %arg2%==--sect ( 
		if not [%arg3%]==[] ( call :removeSection "%arg3%" & goto :EOF ) else ( call :error "trying to find a target section. No third argument used." & exit /b 1 )
	)

	if not defined arg3 call :error "trying to use this [93mindex/indexes[91m. No third argument passed. If you want to delete a section use [93m--sect[91m." & exit /b 1

	call :findSection %arg2% || goto :EOF
    set i=3
    set /a next_sect_ind=%found_sect_ind% + 1

	if defined sect_line[%next_sect_ind%] (
            set /a limit_line=!sect_line[%next_sect_ind%]!
        ) else (
            set /a limit_line=%line_count% + 1
        )

	for /l %%a in (3,1,%arg_number%) do (
		if defined arg%%a (
            set /a target_line=%found_sect_line% + !arg%%a!
			if !target_line! LSS %limit_line% (
				set targets_list=!targets_list! !target_line!
			) else (
				call :error "trying to find the [93m'!arg%%a!'[91m index inside the [93m'%found_sect%'[91m section." & exit /b 1
			)
		)
	)

	set targets_list=%targets_list:~1%

	echo [93mThis are the lines that will be deleted in %found_sect%:[0m
	echo.
	for %%a in (%targets_list%) do (
		call :displayList %%a %%a %found_sect_line%
	)
	echo.

	choice /C YN /M "Do you wish to continue?"
	if %ERRORLEVEL%==2 goto :EOF

	call :removeLineSet "%targets_list%"

	call :reloadTodoList
goto :EOF

:removeSection
	call :findSection %arg3% || goto :EOF

	set /a next_sect_ind=%found_sect_ind% + 1

	if defined section[%next_sect_ind%] (
		set /a limit_line=!sect_line[%next_sect_ind%]! - 1
	) else (
		set limit_line=%line_count%
	)

	for /l %%a in (%found_sect_line%,1,%limit_line%) do (
		set targets_list=!targets_list! %%a
	)
	echo [93mThis are the lines that will be deleted:[0m
	call :displayList %found_sect_line% %limit_line%
	echo.

	choice /C YN /M "Do you wish to continue?"
	if %ERRORLEVEL%==2 goto :EOF

	call :removeLineSet "%targets_list%"

	call :reloadTodoList
goto :EOF

:removeLineSet <linenumber_list>
	set target_set=%~1
	set counter=0

	(for /f "delims=" %%a in ('type "%TODOFILES%\todo.td"') do (
		set /a counter+=1
		set skipLine=
		for %%b in (%target_set%) do (
			if !counter! EQU %%b set "skipLine=1"
		)
		if not defined skipLine echo %%a
	)) > "%TODOFILES%\temp"

	move /y "%TODOFILES%\temp" "%TODOFILES%\todo.td" > NUL
goto :EOF

::!SECTION

::SECTION - Delete function - Delete the whole ToDo list file

:deleteList todo -d <file>
	del /P "%TODOFILES%\todo.td"
goto :EOF

::!SECTION

::SECTION - Alias function - Creating custom aliases for any command

:aliasFunc todo -al <command> <alias>

	set base_cmd=%~2
	if not defined base_cmd ( call :error "trying to use the second argument. You might have not wrote it..." & exit /b 1 )

	set new_alias=%~3
	if not defined new_alias ( call :error "trying to use the third argument. You might have not wrote it..." & exit /b 1 )

	::Check for the base command/function to be defined
	set found_command=false 
	for %%a in (%showArgs% %deleteArgs% %addArgs% %aliasArgs% %tickArgs% %removeArgs% %settingsArgs%) do if "%base_cmd%==%%~a" set found_command=true
	if %found_command%==false call :error "trying to find this command '[93m%base_cmd%[91m'. You might have wrote it wrong..." & exit /b 1

	::Check for new alias to be available
	for %%a in (%showArgs% %deleteArgs% %addArgs% %aliasArgs% %tickArgs% %removeArgs% %settingsArgs%) do if "%new_alias%==%%~a" call :error "trying to use this alias ([93m%new_alias%[91m). This argument might already exist..." & exit /b 1


:commandSelector 
	for %%a in (%showArgs%) do if %base_cmd%==%%~a call :aliasCreate showArgs "%showArgs%" & goto :EOF
	for %%a in (%addArgs%) do if %base_cmd%==%%~a call :aliasCreate addArgs "%addArgs%" & goto :EOF
	for %%a in (%removeArgs%) do if %base_cmd%==%%~a call :aliasCreate removeArgs "%removeArgs%" & goto :EOF
	for %%a in (%tickArgs%) do if %base_cmd%==%%~a call :aliasCreate settingsArgs "%settingsArgs%" & goto :EOF
	for %%a in (%deleteArgs%) do if %base_cmd%==%%~a call :aliasCreate deleteArgs "%deleteArgs%" & goto :EOF
	for %%a in (%aliasArgs%) do if %base_cmd%==%%~a call :aliasCreate aliasArgs "%aliasArgs%" & goto :EOF
	for %%a in (%settingsArgs%) do if %base_cmd%==%%~a call :aliasCreate settingsArgs "%settingsArgs%" & goto :EOF
goto :EOF


:aliasCreate <args_name> <original_args>
	set args_name=%~1
	set original_args=%~2

	call :changeSettings %args_name% "%original_args% %new_alias%"
	echo. [92mAlias added successfully to the arguments list.
	echo.
	echo. [93mThis are the current arguments for %base_cmd% now:[0m
	echo. !%args_name%!

goto :EOF

::!SECTION

::SECTION - Settings functions - Change the ToDo list's settings

:settingsChanger
::Usage:  todo -st | todo -st <setting_name> <setting_value>
    
	if defined arg2 (
		if defined arg3 (
			for %%a in (%settingsNames%) do (
				if "%arg2%"=="%%a" call :changeSettings %arg2% %arg3%
			)
			goto :EOF
		) else (
			call :error "trying to set the value. The '[93msetting_value[91m' argument wasn't passed." & exit /b 1
		)
	)


	call :loadIcons
	if %iconsSet%==true ( set "icosetLbl_color=92" & set "cstmicoLbl_color=38;5;88" ) else ( set "icosetLbl_color=38;5;88" & set "cstmicoLbl_color=92" )
    if %entryExpiring%==true ( set "entryexpLbl_color=92" ) else ( set "entryexpLbl_color=38;5;88" ) 
	set "current_icons=[92m%tick_icon% [91m%cross_icon%"
    echo. [93mSETTINGS
    echo.
	echo. Currently loaded icons: %current_icons%[0m
	echo. Choose one of the following options:
	echo. 1. [%icosetLbl_color%mICONS SET [0m/ [%cstmicoLbl_color%mCUSTOM ICONS[0m
	echo. 2. Change icons set
	echo. 3. Change custom icons
    echo. 4. [%entryexpLbl_color%mDONE ENTRYS EXPIRING[0m
    echo. 5. Change expiring time[93m (Current=%expirationTime% days)[0m
	echo. 6. Exit
	choice /C 123456 /N

	if %errorlevel%==1 goto :iconsTypeToggle
	if %errorlevel%==2 goto :iconsSetSelector
	if %errorlevel%==3 goto :cstmsettingsChanger
	if %errorlevel%==4 goto :entryExpiringToggle
	if %errorlevel%==5 goto :inputExpirationTime
	if %errorlevel%==6 goto :EOF

goto :settingsChanger

:iconsTypeToggle
	if %iconsSet%==true ( call :changeSettings iconsSet "false" ) else ( call :changeSettings iconsSet "true" )
goto :settingsChanger

:entryExpiringToggle
    if %entryExpiring%==true ( call :changeSettings entryExpiring "false" ) else ( call :changeSettings entryExpiring "true" )
goto :settingsChanger

:inputExpirationTime
    echo.
    set /p input="Insert new expiring time (days): "
    set "var="&for /f "delims=0123456789" %%i in ("%expirationTime%") do set var=%%i
    if defined var ( goto :inputExpirationTime ) else ( call :changeSettings expirationTime "%input%")
    echo.
    choice /C YN /M " Do you want to recreate the expiry date of all the done entries?"
    if %ERRORLEVEL%==1 call :recreateExpiryDates
goto :settingsChanger

:recreateExpiryDates
::TODO - Recreating the expiration dates after reactivation

goto :EOF

:iconsSetSelector

	set /a index_ico+=1
	echo. [93mChoose one of the following presets: [0m
	echo. * Note that the icons look way better on Windows Terminal *
	echo. 1.    2.    3.   4.
	echo. [92m✅    ✓    ✅    ✅
	echo. [91m ✘    ✘    ❎    ❌[0m

	choice /C 1234 /N

	call :changeSettings iconsSetId "%errorlevel%"

goto settingsChanger

:cstmsettingsChanger
	::FIXME - This function can't work with the "all-in-one" method since I can't write emojis/symbols with ReplaceLine or List might need to use the old one (getting values from a file)
	@REM echo [31m This fuction still doesn't exist/work but will be implemented ASAP[0m
	echo.
	echo.
	set /p tick_icon="Insert new tick icon: "
	call :changeSettings cstmTickIcon "%tick_icon%"
	set /p tick_icon="Insert new cross icon: "
	call :changeSettings cstmCrossIcon "%cross_icon%"

goto :settingsChanger

:changeSettings
::args: <setting_name> <setting_value>
    pushd %TODOPATH%

    ::Check if both arguments have been provided
    if [%1]==[] call :error "trying to find the setting. No '[93msetting_name[0m' argument was provided." & exit /b 1
    if [%2]==[] call :error "trying to set the value. No '[93msetting_value[0m' argument was provided." & exit /b 1

    ::Set variables for the line to be replaced and the new value
    set setting_name=%~1
    set search_terms=%setting_name%=%%%setting_name%%%
    set new_value=%~2

    ::Find the line number of the line to be replaced
    for /F "tokens=* usebackq" %%F in (`list ToDo.bat /fv "	set %search_terms%"`) do (
    set line_num=%%F
    )

    ::Make the line number the corret value (list command reads lines starting from 0)
    set /a line_num+=1

    ::Replace the line in the ToDo.bat main file with the new value
    replaceline ToDo.bat %line_num% "	set %setting_name%=%new_value%"

    popd

    ::Reloading settings to apply changes
    call :loadSettings

goto :EOF

:loadSettings
    set settingsNames=showArgs addArgs removeArgs tickArgs deleteArgs aliasArgs settingsArgs iconsSet iconsSetId cstmTickIcon cstmCrossIcon entryExpiring expirationTime

    ::Arguments
	set showArgs=-show -s /s show
	set addArgs=-add -a /a add
	set removeArgs=-remove -rem -r -rm /r remove
	set tickArgs=-done -tick /t -t tick
	set deleteArgs=-delete -del -d /d delete
	set aliasArgs=-alias -al /al alias
	set settingsArgs=-settings -set /set -st -option -o /o -opt -icons -ico /i -i settings
	
	::Icons Settings
	set iconsSet=true
	set iconsSetId=1
	set cstmTickIcon=✓
	set cstmCrossIcon=✖

    ::Todo extra funcitions
	set entryExpiring=true
	set expirationTime=7

goto :EOF

:loadIcons

	::Check the icon set switch
	if %iconsSet%==false goto :loadCstmIcons

	::Load the selected icon set if there is one
	if %iconsSetId%==1 set "tick_icon=✅" & set "cross_icon=✘"
	if %iconsSetId%==2 set "tick_icon=✓" & set "cross_icon=✘"
	if %iconsSetId%==3 set "tick_icon=✅" & set "cross_icon=❎"
	if %iconsSetId%==4 set "tick_icon=✅" & set "cross_icon=❌"

goto :EOF

:loadCstmIcons

	::Load custom tick icon
	set tick_icon=%cstmTickIcon%

	::Load custom cross icon
	set cross_icon=%cstmCrossIcon%

goto :EOF

pause > NUL
