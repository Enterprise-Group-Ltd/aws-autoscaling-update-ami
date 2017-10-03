# Shell

We follow the [Google style guide for Shell](https://google.github.io/styleguide/shell.xml) with the following notable exceptions.  


## Philosophy

We **always** choose readability, maintainability and simplification over elegance and speed. Always. 

To better understand why we make this counterintuitive tradeoff, read this: [Yes, Python is Slow, and I Don’t Care](https://hackernoon.com/yes-python-is-slow-and-i-dont-care-13763980b5a1)

Our goal is business productivity - which is often a different path than absolute code effeciency. 

That means we want utilities that are broadly available and accessible to a wide audience for  utilization, maintenence and further development. 

That also means we will trade spinning up a bigger EC2 instance for the duration of a utility's execution to throw CPU cycles and I/O at a slow-ish utility rather than build inscrutable, ultra-elegant code that few can quickly understand or maintain. 

That also means we will adopt whatever style conventions that are required to produce extremely verbose and detailed debug logs and console output to aid development and debugging. 


## Background 

### When to use Shell 

We use bash shell scripts for larger-than-small utilities. 

## Shell Files and Interpreter Invocation

### File Extensions

All shell files must include the '.sh' file extension.

Example: `aws-services-snapshot.sh`

## STDOUT vs STDERR

Redirect all output as follows: 2>&1 

Example: `feed_write_log="$(cat "$write_file_service_names" 2>&1)"` 

## Comments 

### General Code Comments 

All code must be verbosely commented. 

Always prefer to include the comment in the log versus only in the code. 

Example: 

    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading variable 'count_lines_service_snapshot_recursive' "               
    count_lines_service_snapshot_recursive="$(echo "$service_snapshot_recursive" | wc -l)" 
    fnWriteLog ${LINENO} ""

### Variable Value and File Contents Comments 

After setting a variable or loading a file, always reflect the variable value or file contents in the log 

Example: 

    #
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "value of variable 'service_snapshot':"
    fnWriteLog ${LINENO} level_0 "$service_snapshot"
    fnWriteLog ${LINENO} level_0 ""
    #
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-write-file-services-recursive-load.json:"
    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-services-recursive-load.json)"
    fnWriteLog ${LINENO} level_0 "$feed_write_log"
    fnWriteLog ${LINENO} level_0 ""
    #   

## Formatting 

### Leading '#'

All non-code lines must begin with '#'.

Example: 

    #
    # set the command/pipeline error line number
    error_line_pipeline="$((${LINENO}-7))"
    #
    #


### Indentation

Use 4 spaces -- never tabs -- for indentation.

### Line Length and Long Strings

There is no maximum line length but please avoid long lines wherever possible.  

### Loops 

Put 'do' on a new line after 'while'. 

Start a new line after 'do' and indent the code in the 'do' section by four spaces. 

Example: 

    while read -r aws_service aws_command aws_query_parameter aws_service_key 
    do
        fnWriteLog ${LINENO} ""

### If 

Use a '#' line to seperate 'if' sections from the surrounding code. 

Include a comment describing what is being tested.

Do not use a ';' after the '\[\[ \]\]' test. Start a new line.  

Put 'then' on a new line indented four spaces.

Put the code to execute on a new line below 'then' indented four spaces. 

Put a comment on the same line as the closing 'fi' for each 'if' section (this style has not yet been rigorously applied to the existing code). 

Example: 

    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "checking to see if the service name was added to the global list "  
    if [[ "$count_global_services_names" -lt "$count_global_services_names_check" ]] 
        then 
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "resetting the variable 'count_global_services_names_check' "
            count_global_services_names_check=0
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of variable 'count_global_services_names_check': "$count_global_services_names_check" "  
            #  
            fnWriteLog ${LINENO} "skipping to the next service via the 'continue' command "
            #
            continue
            #
    fi  # end check for global service 
    #

### Functions 

When calling a function, include a '#' line above and below the function name (this style has not yet been rigorously applied to the existing code).

Example: 

    #
    # display the header    
    fnHeader
    #
    fnDeleteWorkFiles
    #

### Statement Flow Direction

All statements read left-to-right.

The only exception is feeding variables and files into 'while' loops. 

Exception example: 

    # 
    done< <(echo "$driver_global_services")
    #

## Naming Conventions

### Name Heirarchy

All variable and function names are heirachical left-to-right  
Examples:

* this_log_file
* this_log_file_errors
* this_log_file_errors_full_path
* fnStatusBar
* fnStatusBarTask
* fnStatusBarTaskSub

### Function Names

All function names begin with 'fn' and are CamelCase.

Example: `fnFunctionNameSample`

### Function Declaration

All function declarations include the 'function' keyword.

Example: `function fnFunctionNameSample`  

### Source and Target Filenames

No spaces are allowed in filenames. 

All filenames are lowercase and dash '-' seperated. 

All filenames include an explicit dot '.' seperated file extension.

Example: `file-input-sample-name.txt`

### main 

A "main" function is not required. 

## Log and Console Output 

### General 

The EGL AWS utilities use a 'fnWriteLog' function to control output to the log(s) and the console. 

Except when setting a variable, each line of code must begin with: 'fnWriteLog ${LINENO}'.

Example: 

    fnWriteLog ${LINENO} "calling the recursive command file write function" 


###  Command 

When using a command, a line pair that loads the variable 'feed_write_log' must be used. 

Example: 

    feed_write_log="$(echo "$snapshot_source_recursive_command" 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"


### Console Echo  

To echo to the console, use 'level_0'. 

Example: 

    # in verbose mode so preserve the work files 
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "In verbose mode: Preserving work files "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "work files are here: "$this_path" "
    fnWriteLog ${LINENO} level_0 ""                

