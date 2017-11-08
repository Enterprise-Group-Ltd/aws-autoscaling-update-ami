#!/bin/bash
#
#
# ------------------------------------------------------------------------------------
#
# MIT License
# 
# Copyright (c) 2017 Enterprise Group, Ltd.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ------------------------------------------------------------------------------------
# 
# File: autoscaling-update-ami.sh
#
script_version=1.2.25  
#
#  Dependencies:
#  - bash shell
#  - jq - JSON wrangler https://stedolan.github.io/jq/
#  - AWS CLI tools (pre-installed on AWS AMIs) 
#  - AWS CLI profile with IAM permissions for the following AWS CLI commands:
#    - aws autoscaling create-launch-configuration
#    - aws autoscaling delete-launch-configuration
#    - aws autoscaling describe-auto-scaling-groups
#    - aws autoscaling describe-launch-configurations
#    - aws autoscaling update-auto-scaling-group
#    - aws ec2 describe-images (used to test AMI)
#    - aws iam list-account-aliases (used to pull AWS account alias)
#    - aws sts get-caller-identity (used to pull AWS acount)
#
# Tested on: 
#   Windows Subsystem for Linux (WSL) 
#     OS Build: 15063.540
#     bash.exe version: 10.0.15063.0
#     Ubuntu 16.04
#     GNU bash, version 4.3.48(1)
#     jq 1.5-1-a5b5cbe
#     aws-cli/1.11.134 Python/2.7.12 Linux/4.4.0-43-Microsoft botocore/1.6.1
#   
#   AWS EC2
#     Amazon Linux AMI release 2017.03 
#     Linux 4.9.43-17.38.amzn1.x86_64 
#     GNU bash, version 4.2.46(2)
#     jq-1.5
#     aws-cli/1.11.133 Python/2.7.12 Linux/4.9.43-17.38.amzn1.x86_64 botocore/1.6.0
#
#
# By: Douglas Hackney
#     https://github.com/dhackney   
# 
# Type: AWS utility
# Description: 
#   This shell script is used to update autoscaling Launch Configurations (LC) and associated autoscaling groups with a new AMI
#   For every launch config using a target AMI, a new clone launch config is created with all existing parameters 
#   All clone launch configs are updated to use the new AMI
#   All Autoscaling Groups (AG) using an updated launch config are updated to use the new launch config with the new AMI
#   For every launch config using the new AMI, the X most recent launch config versions are retained 
#
#
# Roadmap:
# - report: LCs deleted 
# - delete run after ASG update to support 0 retained versions
# - -r region
# - -r all regions
# - delete LC name text -x parameter
# - info level logging
#
#
###############################################################################
# 
#
# 
#
###############################################################################
# 
#
# Set the language to prevent time lost to unicode processing
#
export LC_ALL=C
#
###############################################################################
# 
# set the environmental variables 
#
set -o pipefail 
#
###############################################################################
# 
# initialize the script variables 
#
ami_new_id=""
ami_new_id_report=""
ami_new_name=""
ami_new_name_report=""
ami_new_string=""
ami_new_trim=""
ami_new_type=""
ami_old_id=""
ami_old_id_report=""
ami_old_name=""
ami_old_name_report=""
ami_old_string=""
ami_old_trim=""
ami_old_type=""
choices=""
cli_profile=""
count_ag=""
count_ag_report=0
count_ami_new_id=0
count_ami_old_id=0
count_ami_old_id_owned=0
count_ami_old_id_shared=0
count_aws_error_lc_limit_exceeded=0
count_cli_profile=0
count_data_lines=0
count_error_lines=0
count_lc=0
count_lc_ag_name=0
count_lc_append_name_index=0
count_lc_arn=0
count_lc_create_name=0
count_lc_duplicate_names=0
count_lc_index=0
count_lc_name_dup_line=0
count_lc_name_list_duplicated_names_sorted=0
count_lc_name_list_raw=0
count_lc_name_list_raw_duplicated=0
count_lc_name_list_raw_unique=0
count_lc_names=0
count_lc_report=0
count_lc_report_index=0
count_lc_target=0
count_lc_target_appended_text_arn_sorted=0
count_lc_target_appended_text_names_sorted=0
count_lc_version_deleted_lines=0
count_lc_versions_all=0
count_lc_versions_post_delete=0
count_name_line=0
count_post_lc_name_update_lines=0
count_script_version_length=0
count_text_header_length=0
count_text_block_length=0
count_text_width_menu=0
count_text_width_header=0
count_text_side_length_menu=0
count_text_side_length_header=0
count_text_bar_menu=0
count_text_bar_header=0
count_this_file_tasks=0
count_ver=0
count_ver_line=0
count_write_mapping_ag=0
count_write_mapping_lc=0
count_write_mapping_name_new_arn=0
count_write_mapping_name_old_arn=0
count_year=0
count_year_line=0
counter_ag_name_json_populate=0
counter_arn=0
counter_arn_json_populate=0
counter_count_lc=0
counter_count_lc_append_name=0
counter_file=0
counter_lc_create=0
counter_lc_name_file=0
counter_lcname_new_arn_json_populate=0
counter_lc_name_new_file=0
counter_lc_old_name_json_populate=0
counter_lc_report=0
counter_lc_target_appended_text_names_sorted=0
counter_name_append_loop=0
counter_name_unique_append=0
counter_name_unique_loop=0
counter_source_file=0
counter_target_file=0
counter_this_file_tasks=0
counter_update_ag_lc_name_new=0
counter_version_deleted=0
counter_write_mapping_ag=0
counter_write_mapping_lc=0
counter_write_mapping_name_new_arn=0
counter_write_mapping_name_old_arn=0
date_file="$(date +"%Y-%m-%d-%H%M%S")"
date_now="$(date +"%Y-%m-%d-%H%M%S")"
detailed_monitoring_state=""
_empty=""
_empty_task=""
error_aws_flag=""
exportLC_ALL=""
feed_write_log=""
_fill=""
_fill_task=""
full_path=""
function_LCNameNewWrite_parameter_1_stripped=""
integer_re_pattern=""
lc_array=""
lc_create_json=""
lc_create_json_aws=""
lc_create_json_edited_01=""
lc_create_json_edited_02=""
lc_create_json_edited_03=""
lc_create_json_edited_04=""
lc_create_json_edited_05=""
lc_duplicate_name_write=""
lc_name_append_string=""
lc_name_append_string_clean=""
lc_name_list_duplicated_names=""
lc_name_list_raw=""
lc_name_new=""
lc_name_new_mapping=""
lc_name_new_report=""
lc_name_new_stripped=""
lc_name_new_unique=""
lc_name_new_unique_stripped=""
lc_name_old=""
lc_name_old_arn=""
lc_name_old_mapping=""
lc_name_old_report=""
lc_name_old_stripped=""
lc_name_unique_text_clean=""
lc_name_version_number=""
lc_name_version_number_check=""
lc_name_version_prefix=""
lc_new_names_raw=""
lc_new_names_sorted=""
lc_old_names_raw=""
lc_old_names_sorted=""
lc_target=""
lc_target_appended_text=""
lc_target_appended_text_names_sorted_line=""
lc_target_monitoring_set=""
lc_target_new_ami_id=""
lc_target_security_group_add=""
lc_versions_all=""
lc_versions_delete=""
lc_versions_post_delete=""
let_done=""
let_done_task=""
let_left=""
let_left_task=""
let_progress=""
let_progress_task=""
logging=""
parameter1=""
paramter2=""
security_group_add_id=""
text_header=""
text_bar_menu_build=""
text_bar_header_build=""
text_side_menu=""
text_side_header=""
text_menu=""
text_menu_bar=""
text_header=""
text_header_bar=""
this_aws_account=""
this_aws_account_alias=""
this_file=""
this_file_tasks=""
this_log=""
thislogdate=""
this_log_file=""
this_log_file_errors=""
this_log_file_errors_full_path=""
this_log_file_full_path=""
this_log_temp_file_full_path=""
this_path=""
this_summary_report=""
this_summary_report_full_path=""
this_user=""
user_data_base64_decode=""
verbose=""
#
###############################################################################
# 
#
# Initialize the baseline variables
#
this_utility_acronym="lc"
this_utility_filename_plug="autoscaling-update-ami"
this_path="$(pwd)"
this_file="$(basename "$0")"
full_path="${this_path}"/"$this_file"
this_log_temp_file_full_path="$this_path"/"$this_utility_filename_plug"-log-temp.log 
this_user="$(whoami)"
date_file="$(date +"%Y-%m-%d-%H%M%S")"
logging="n" 
#
#
#
#
###############################################################################
# 
#
# Initialize the temp log file
#
echo "" > "$this_log_temp_file_full_path"
#
#
#
#
##############################################################################################################33
#                           Function definition begin
##############################################################################################################33
#
#
# Functions definitions
#
#######################################################################
#
#######################################################################
#
#
# function to display the Usage  
#
#
function fnUsage()
{
    echo ""
    echo " --------------------------------------- Autoscaling update AMI utility usage ----------------------------------------"
    echo ""
    echo " This utility updates targeted AWS Autoscale EC2 Launch Configurations and Autoscaling Groups with a new AMI "  
    echo ""
    echo " This script will: "
    echo " * Update AWS Autoscaling Launch Configurations to use a new AMI "
    echo " * Update Launch Configuration names to reflect the new version "
    echo " * Create new Launch Configurations using the updated configurations "
    echo " * Delete prior Launch Configuration versions "
    echo " * Update all related Autoscaling Groups to use the new Launch Configurations "
    echo ""
    echo "----------------------------------------------------------------------------------------------------------------------"
    echo ""
    echo " Usage:"
    echo "       autoscaling-update-ami.sh -p AWS_CLI_profile -n new_AMI_ID_or_name -t old_target_AMI_ID_or_name -a append-text "
    echo ""  
    echo "       Optional parameters: -d 3 -m f -v y "
    echo ""
    echo " Where: "
    echo "  -p - Name of the AWS CLI cli_profile (i.e. what you would pass to the --profile parameter in an AWS CLI command)"
    echo "         Example: -p myAWSCLIprofile "
    echo ""
    echo "  -n - New AMI ID or the name unique string. For the name: A string that uniquely identifies the new AMI name. "
    echo "       This can be the entire new AMI name or any subset of the name that uniquely identifies it. "
    echo ""
    echo "  -t - Old, target AMI ID or the name unique string. For the name: A string that uniquely identifies the old, target " 
    echo "       AMI name that you need to update. This can be the entire old, target AMI name or any subset of the name "
    echo "       that uniquely identifies it."
    echo ""
    echo "       Note: The new and old AMI inputs must both be AMI names or AMI IDs "
    echo ""
    echo "       Examples using AMI names:"
    echo "         Example: -n act123456789999_worker_v432_2017_11_23_1302_utc "
    echo "         Example: -t act123456789999_worker_v321_2016_04_30_1845_utc "
    echo ""
    echo "       Examples using AMI IDs:"
    echo "         Example: -n ami-ab7874d1 "
    echo "         Example: -t ami-c5636fde "
    echo ""
    echo "  -a - Text to append to the new launch config name. The append text will begin after the first occurance of "
    echo "       the dash character '-' when it is followed by a v and a number or when it is followed by a year number. "
    echo "       The append text will begin at the v in this example: -vNNNN (where NNNN is any number). "
    echo "       The append text will begin at the Y in this example -YYYY (where YYYY is a year, e.g. 2017) "
    echo "       The utility will default to append the current date as: -YYYY-MM-DD-HHMM-utc"
    echo -e "       >> Note: The append text cannot contain the characters:  \` ~ ' ! # ^ \* \" () {} [] <> $ % @ & = + \\ /  <<"
    echo "         Example: -a v32-2017-08-21-1845-utc   produces: my-launch-config-existing-text-v32-2017-08-21-1845-utc "
    echo "         Example: -a 2017-08-21-1845-utc       produces: my-launch-config-existing-text-2017-08-21-1845-utc "
    echo ""
    echo "  -s - Security Group ID to add to all launch configurations."
    echo "         Example: -s sg-9612f4e3 "
    echo ""
    echo "  -d - Delete versions older than X. Set to the number of versions to retain. Setting to 3 will retain three prior versions."
    echo "       Note: this flag assumes the following Launch Configuration Name syntax: My-Launch-Configuration-Name-vXX-Anything-Else"
    echo "       Where 'XX' is equal to any number of decimals, e.g. 45, 456, 4567890. Decimal places are not supported, e.g. 10.00.23"
    echo "         Example: -d 3 "
    echo ""
    echo "  -m - Detailed monitoring enabled true/false. Set this to either 't' or 'f' to enable or disable EC2 detailed monitoring."
    echo "         Example: -m f "
    echo ""
    echo "  -b - Verbose console output. Set to 'y' for verbose console output. Note: this mode is very slow."
    echo "         Example: -b y "
    echo ""
    echo "  -g - Logging on / off. Default is off. Set to 'y' to create a debug log. Note: logging mode is slower. "
    echo "         Example: -g y "
    echo ""
    echo "  -h - Display this message"
    echo "         Example: -h "
    echo ""
    echo "  ---version - Display the script version"
    echo "         Example: --version "
    echo ""
    echo ""
    exit 1
}
#
#######################################################################
#
#
# function to echo the progress bar to the console  
#
# source: https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
#
# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
function fnProgressBar() 
{
# Process data
        let _progress=(${1}*100/"${2}"*100)/100
        let _done=(${_progress}*4)/10
        let _left=40-"$_done"
# Build progressbar string lengths
        _fill="$(printf "%${_done}s")"
        _empty="$(printf "%${_left}s")"
#
# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:
# 1.2.1.1  Progress : [########################################] 100%
printf "\r          Overall Progress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
}
#
#######################################################################
#
#
# function to update the task progress bar   
#
# source: https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
#
# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
function fnProgressBarTask() 
{
# Process data
        let _progress_task=(${1}*100/"${2}"*100)/100
        let _done_task=(${_progress_task}*4)/10
        let _left_task=40-"$_done_task"
# Build progressbar string lengths
        _fill_task="$(printf "%${_done_task}s")"
        _empty_task="$(printf "%${_left_task}s")"
#
# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:
# 1.2.1.1  Progress : [########################################] 100%
printf "\r             Task Progress : [${_fill_task// /#}${_empty_task// /-}] ${_progress_task}%%"
}
#
#######################################################################
#
#
# function to display the task progress bar on the console  
#
# parameter 1 = counter
# paramter 2 = count
# 
function fnProgressBarTaskDisplay() 
{
    fnWriteLog ${LINENO} level_0 " ---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 "" 
    fnProgressBarTask "$1" "$2"
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 " ---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
}
#
#######################################################################
#
#
# function to echo the header to the console  
#
function fnHeader()
{
    clear
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} "--------------------------------------------------------------------------------------------------------------------"    
    fnWriteLog ${LINENO} "--------------------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "$text_header"
    fnWriteLog ${LINENO} level_0 "" 
    fnProgressBar ${counter_this_file_tasks} ${count_this_file_tasks}
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "$text_header_bar"
    fnWriteLog ${LINENO} level_0 ""
}
#
#######################################################################
#
#
# function to echo to the console and write to the log file 
#
function fnWriteLog()
{
    # clear IFS parser
    IFS=
    # write the output to the console
    fnOutputConsole "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
    # if logging is enabled, then write to the log
    if [[ ("$logging" = "y") || ("$logging" = "z") ]] ;
        then
            # write the output to the log
            fnOutputLog "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
    fi 
    # reset IFS parser to default values 
    unset IFS
}
#
#######################################################################
#
#
# function to echo to the console  
#
function fnOutputConsole()
{
    #
    # console output section
    #
    # test for verbose
    if [ "$verbose" = "y" ] ;  
        then
            # if verbose console output then
            # echo everything to the console
            #
            # strip the leading 'level_0'
                if [ "$2" = "level_0" ] ;
                    then
                        # if the line is tagged for display in non-verbose mode
                        # then echo the line to the console without the leading 'level_0'     
                        echo " Line: "$1" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "
                    else
                        # if a normal line echo all to the console
                        echo " Line: "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "
                fi
    else
        # test for minimum console output
        if [ "$2" = "level_0" ] ;
            then
                # 
                # "console output no -v: the logic test for level_0 was true"
                # 
                # if the line is tagged for display in non-verbose mode
                # then echo the line to the console without the leading 'level_0'     
                echo " "$3" "$4" "$5" "$6" "$7" "$8" "$9" "
        fi
    fi
    #
    #

}  

#
#######################################################################
#
#
# function to write to the log file 
#
function fnOutputLog()
{
    # log output section
    #
    # load the timestamp
    thislogdate="$(date +"%Y-%m-%d-%H:%M:%S")"
    #
    # ----------------------------------------------------------
    #
    # normal logging
    # 
    # append the line to the log variable
    # the variable is written to the log file on exit by function fnWriteLogFile
    #
    # if the script is crashing then comment out this section and enable the
    # section below "use this logging for debug"
    #
        if [ "$2" = "level_0" ] ;
            then
                # if the line is tagged for logging in non-verbose mode
                # then write the line to the log without the leading 'level_0'     
                this_log+="$(echo "${thislogdate} Line: "$1" "$3" "$4" "$5" "$6" "$7" "$8" "$9" " 2>&1)" 
            else
                # if a normal line write the entire set to the log
                this_log+="$(echo "${thislogdate} Line: "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" " 2>&1)" 
        fi
        #
        # append the new line  
        # do not quote the following variable: $'\n'
        this_log+=$'\n'
        #
    #  
    # ---------------------------------------------------------
    #
    # 'use this for debugging' - debug logging
    #
    # if the script is crashing then enable this logging section and 
    # comment out the prior logging into the 'this_log' variable
    #
    # note that this form of logging is VERY slow
    # 
    # write to the log file with a prefix timestamp 
    # echo ${thislogdate} Line: "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" 2>&1 >> "$this_log_file_full_path"  
    #
    #
}
#
#######################################################################
#
#
# function to append the log variable to the temp log file 
#
function fnWriteLogTempFile()
{
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Appending the log variable to the temp log file"
    fnWriteLog ${LINENO} "" 
    echo "$this_log" >> "$this_log_temp_file_full_path"
    # empty the temp log variable
    this_log=""
}
#
#######################################################################
#
#
# function to write log variable to the log file 
#
function fnWriteLogFile()
{
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} "Writing temp log to log file"
    fnWriteLog ${LINENO} level_0 ""
    # write the contents of the variable to the temp file
    fnWriteLogTempFile
    # append the temp file onto the log file
    cat "$this_log_temp_file_full_path" >> "$this_log_file_full_path"
    echo "" >> "$this_log_file_full_path"
    echo "Log end" >> "$this_log_file_full_path"
    # delete the temp log file
    rm -f "$this_log_temp_file_full_path"
}
#
##########################################################################
#
#
# function to delete the work files 
#
function fnDeleteWorkFiles()
{
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "Creating timestamp version of file: 'launch-configs-mapping.json' "
    fnWriteLog ${LINENO} level_0 ""
    feed_write_log="$(mv -f launch-configs-mapping.json "$this_launch_configs_mapping_json_full_path" 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} level_0 ""
        if [ "$verbose" != "y" ] ;  
            then
                # if not verbose console output then delete the work files
                fnWriteLog ${LINENO} level_0 "Deleting work files"
                fnWriteLog ${LINENO} level_0 ""
                feed_write_log="$(rm -f "$this_utility_acronym"-* 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                feed_write_log="$(rm -f "$this_utility_acronym"_* 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                feed_write_log="$(rm -f launch-configs-mapping-temp-ami.json 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                # if no errors, then delete the error log file
                count_error_lines="$(cat "$this_log_file_errors_full_path" | wc -l)"
                if (( "$count_error_lines" < 3 ))
                    then
                        rm -f "$this_log_file_errors_full_path"
                fi  
            else
                # in verbose mode so preserve the work files 
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "In verbose mode, preserving work files "
                fnWriteLog ${LINENO} level_0 ""
        fi       
}
#
##########################################################################
#
#
# function to increment the task counter 
#
function fnCounterIncrementTask()
{
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} "increment the task counter"
    counter_this_file_tasks="$((counter_this_file_tasks+1))" 
    fnWriteLog ${LINENO} "value of variable 'counter_this_file_tasks': "$counter_this_file_tasks" "
    fnWriteLog ${LINENO} "value of variable 'count_this_file_tasks': "$count_this_file_tasks" "
    fnWriteLog ${LINENO} ""
}
#
##########################################################################
#
#
# function to log non-fatal errors 
#
function fnErrorLog()
{
            fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"       
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " Error message: "
            fnWriteLog ${LINENO} level_0 " "$feed_write_log" "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------" 
            echo "-----------------------------------------------------------------------------------------------------" >> "$this_log_file_errors_full_path"         
            echo "" >> "$this_log_file_errors_full_path" 
            echo " Error message: " >> "$this_log_file_errors_full_path" 
            echo " "$feed_write_log"" >> "$this_log_file_errors_full_path" 
            echo "" >> "$this_log_file_errors_full_path"
            echo "-----------------------------------------------------------------------------------------------------" >> "$this_log_file_errors_full_path" 
}
#
##########################################################################
#
#
# function to handle command or pipeline errors 
#
function fnErrorPipeline()
{
            fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"       
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " Command or Command Pipeline Error "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " System Error while running the previous command or pipeline "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " Please check the error message above "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " Error at script line number: "$error_line_pipeline" "
            fnWriteLog ${LINENO} level_0 ""
            if [[ "$logging" == "y" ]] ;
                then 
                    fnWriteLog ${LINENO} level_0 " The log will also show the error message and other environment, variable and diagnostic information "
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 " The log is located here: "
                    fnWriteLog ${LINENO} level_0 " "$this_log_file_full_path" "
            fi
            fnWriteLog ${LINENO} level_0 ""        
            fnWriteLog ${LINENO} level_0 " Exiting the script"
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"
            fnWriteLog ${LINENO} level_0 ""
            # append the temp log onto the log file
            fnWriteLogTempFile
            # write the log variable to the log file
            fnWriteLogFile
            exit 1
}
#
##########################################################################
#
#
# function for AWS CLI errors 
#
function fnErrorAws()
{
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " AWS Error while executing AWS CLI command"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Please check the AWS error message above "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Error at script line number: "$error_line_aws" "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " The log will also show the AWS error message and other diagnostic information "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " The log is located here: "
    fnWriteLog ${LINENO} level_0 " "$this_log_file_full_path" "
    fnWriteLog ${LINENO} level_0 ""        
    fnWriteLog ${LINENO} level_0 " Exiting the script"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    # append the temp log onto the log file
    fnWriteLogTempFile
    # write the log variable to the log file
    fnWriteLogFile
    exit 1
}
#
##########################################################################
#
#
# function to handle fatal errors 
#
function fnError()
{
    if [ "$?" -ne 0 ]
        then
            fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"       
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " Error message: "
            fnWriteLog ${LINENO} level_0 " "$feed_write_log""
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " System Error while running the previous command "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " Please check the error message above "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " The log will also show the error message and other environment, variable and diagnostic information "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " The log is located here: "
            fnWriteLog ${LINENO} level_0 " "$this_log_file_full_path""
            fnWriteLog ${LINENO} level_0 ""        
            fnWriteLog ${LINENO} level_0 " Exiting the script"
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"
            fnWriteLog ${LINENO} level_0 ""
            # delete the work files
            fnDeleteWorkFiles
            # write the log variable to the log file
            fnWriteLogFile
            exit 1
    fi
}
#
#######################################################################
#
#
# function to update the LC name  
#
function fnUpdateLcName()
{
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in fnUpdateLcName"
    fnWriteLog ${LINENO} "value of variable 'lc_name_old_line': "$lc_name_old_line" "
    fnWriteLog ${LINENO} "value of variable 'lc_name_new_stripped': "$lc_name_new_stripped" "
    fnWriteLog ${LINENO} ""
    #
    # update the LC name in the target variable and append the object to the file: 'lc_target_appended_text.json'  
    feed_write_log="$(echo "$lc_array" | jq -r --arg lc_name_old_line_jq "$lc_name_old_line" --arg lc_name_new_stripped_jq "$lc_name_new_stripped" ' .[] | select(.LaunchConfigurationName==$lc_name_old_line_jq) | .LaunchConfigurationName=$lc_name_new_stripped_jq ' >> lc_target_appended_text.json  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #
    fnWriteLog ${LINENO} "$feed_write_log"
    #
    # check to see if a comma is needed to separate the appended objects
    if (( "$counter_name_append_loop" < "$count_lc_names" ))
        then 
                feed_write_log="$(echo "," >> lc_target_appended_text.json  2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
    fi
    #
}
#
#######################################################################
#
#
# function to dedupe the LC name  
#
function fnDedupeLcName()
{
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in fnDedupeLcName"
    fnWriteLog ${LINENO} "value of function parameters: "
    fnWriteLog ${LINENO} "parameter 1 carries the deduped LC name"
    fnWriteLog ${LINENO} "value of function parameter 1:"$1" "
    fnWriteLog ${LINENO} "parameter 2 carries the old name arn"
    fnWriteLog ${LINENO} "value of function parameter 2: "$2" "
    fnWriteLog ${LINENO} ""
    #
    # update the LC name in the target variable and append the object to the file: 'lc_name_unique_text.json'  
    feed_write_log="$(echo "$lc_array" | jq -r --arg lc_arn_line_jq "$2" --arg lc_name_new_unique_stripped_jq "$1" ' .[] | select(.LaunchConfigurationARN==$lc_arn_line_jq) | .LaunchConfigurationName=$lc_name_new_unique_stripped_jq ' >> lc_name_unique_text.json  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #
    fnWriteLog ${LINENO} "$feed_write_log"
    #
    # check to see if a comma is needed to separate the appended objects
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'counter_arn': "$counter_arn" "
    fnWriteLog ${LINENO} "'count_lc_target_appended_text_arn_sorted': "$count_lc_target_appended_text_arn_sorted" "
    fnWriteLog ${LINENO} "testing for counter_arn < count_lc_target_appended_text_arn_sorted "
    fnWriteLog ${LINENO} ""
    if [[ "$counter_arn" -lt "$count_lc_target_appended_text_arn_sorted" ]]
        then 
                fnWriteLog ${LINENO} "counter arn is tested as < count_lc_target_appended_text_arn_sorted" 
                fnWriteLog ${LINENO} "adding comma between JSON LC objects " 
                feed_write_log="$(echo "," >> lc_name_unique_text.json  2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
    fi
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "contents of file: 'lc_name_unique_text.json' "
    feed_write_log="$(cat lc_name_unique_text.json 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
}
#
#######################################################################
#
#
# function to write the new LC name into the mapping json file
#
function fnLCNameNewWrite()
{
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "------------ begin function fnLCNameNewWrite : write new LC name to file: 'lc-mapping.json' -------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "Writing the new Launch Configuration name to the file: 'lc-mapping.json'... "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "initializing the counters"
    counter_source_file="$counter_file"
    counter_target_file="$((counter_source_file+1))"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
    fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "value of function parameters: "
    fnWriteLog ${LINENO} "value of function parameter 1: "$1" "
    fnWriteLog ${LINENO} "value of function parameter 2: "$2" "
    fnWriteLog ${LINENO} "value of function parameter 3: "$3" "
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "initializing the variables"
    fnWriteLog ${LINENO} "loading the variable: 'lc_name_old' "
    # test if this is a dedupe run and is called with the ARN in parameter 2
    if [[ "$2" = "" ]] ;
        then
            lc_name_old="$lc_name_old"
        else
            lc_name_old="$3"
    fi
    fnWriteLog ${LINENO} "value of variable 'lc_name_old': "$lc_name_old" "
    fnWriteLog ${LINENO} ""
    #
    lc_name_old_stripped="$(echo "$lc_name_old" | tr -d '\",' )"
    fnWriteLog ${LINENO} "value of variable 'lc_name_old_stripped': "$lc_name_old_stripped" "
    fnWriteLog ${LINENO} "loading into lc_name_old variable for the run"
    fnWriteLog ${LINENO} "command: lc_name_old_mapping="$lc_name_old_stripped" "
    lc_name_old_mapping="$lc_name_old_stripped"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "Loading the new LC name from the function parameter"
    fnWriteLog ${LINENO} "value of function parameter 1:"
    fnWriteLog ${LINENO} ""$1" "
    function_LCNameNewWrite_parameter_1_stripped="$(echo "$1" | tr -d '\",' )"
    fnWriteLog ${LINENO} "value of variable 'function_LCNameNewWrite_parameter_1_stripped':"
    fnWriteLog ${LINENO} ""$function_LCNameNewWrite_parameter_1_stripped" "
    fnWriteLog ${LINENO} "loading into variable: 'lc_name_new' "
    fnWriteLog ${LINENO} "command: lc_name_new_mapping= $ function_LCNameNewWrite_parameter_1_stripped "
    lc_name_new_mapping="$function_LCNameNewWrite_parameter_1_stripped"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "Loading the old LC name ARN from the function parameter"
    fnWriteLog ${LINENO} "value of function parameter 2:"
    fnWriteLog ${LINENO} ""$2" "
    fnWriteLog ${LINENO} "loading into variable: 'lc_name_old_arn' "
    lc_name_old_arn="$2"
    fnWriteLog ${LINENO} ""
    

    fnWriteLog ${LINENO} "LC name variables values:"
    fnWriteLog ${LINENO} "value of variable 'lc_name_old_mapping': "$lc_name_old_mapping" "
    fnWriteLog ${LINENO} "value of variable 'lc_name_new_mapping': "$lc_name_new_mapping" "
    fnWriteLog ${LINENO} "value of variable 'lc_name_old_arn': "$lc_name_old_arn" "

    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} level_0 "New Launch Configuration name: "$lc_name_new_mapping" "
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "initializing the files"
    fnWriteLog ${LINENO} "value of source file name variable : lc-mapping-old-temp-"$counter_lc_name_file".json"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "copying master json mapping file 'launch-configs-mapping.json' to 'lc-mapping.json' "
    feed_write_log="$(cp -f launch-configs-mapping.json lc-mapping.json 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "initialize the initial temp file"
    fnWriteLog ${LINENO} "command: cp lc-mapping.json lc-mapping-lc-name-new-temp-"$counter_source_file".json"
    feed_write_log="$(cp -f lc-mapping.json lc-mapping-lc-name-new-temp-"$counter_source_file".json 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    #
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} "  in function fnLCNameNewWrite 'Launch Config New Name mapping to JSON file' "
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "variable values at head of 'Launch Config New Name mapping to JSON file' - prior to load:"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'lc_name_old_mapping': "$lc_name_old_mapping" "
    fnWriteLog ${LINENO} "value of variable 'lc_name_new_mapping': "$lc_name_new_mapping" "
    fnWriteLog ${LINENO} "value of variable 'lc_name_old_arn': "$lc_name_old_arn" "  
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
    fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "source file name: lc-mapping-lc-name-new-temp-"$counter_source_file".json"
    fnWriteLog ${LINENO} "output file name: lc-mapping-lc-name-new-temp-"$counter_target_file".json"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "initialize output file - copying '' to file: 'lc-mapping-lc-name-new-temp-"$counter_target_file".json' "
    feed_write_log="$(echo "" >  lc-mapping-lc-name-new-temp-"$counter_target_file".json 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    #
    fnWriteLog ${LINENO} "contents of file lc-mapping-lc-name-new-temp-"$counter_source_file".json disabled for speed; enable for debugging"
    # fnWriteLog ${LINENO} "contents of source file: lc-mapping-lc-name-new-temp-"$counter_source_file".json"
    # feed_write_log="$(cat lc-mapping-lc-name-new-temp-"$counter_source_file".json 2>&1)"
    # fnWriteLog ${LINENO} "$feed_write_log"
    # fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""   
    #
    fnWriteLog ${LINENO} "Writing LC new name to: lc-mapping-lc-name-new-temp-"$counter_target_file".json"
    # test for presence of ARN, if so, then this is a dedupliciation run and requires the ARN index 
    if [[ "$lc_name_old_arn" = "" ]] ;
        then
            fnWriteLog ${LINENO} ""   
            fnWriteLog ${LINENO} "standard LC name write to file 'lc-mapping-lc-name-new-temp-"$counter_target_file".json' "  
            feed_write_log="$(cat lc-mapping-lc-name-new-temp-"$counter_source_file".json \
            | jq --arg lc_name_new_mapping_jq "$lc_name_new_mapping" --arg lc_name_old_mapping_jq "$lc_name_old_mapping" '[.mappings[] | if .oldLcName == $lc_name_old_mapping_jq then .newLcName = $lc_name_new_mapping_jq else . end]' \
            | jq '. | {mappings: . } ' >> lc-mapping-lc-name-new-temp-"$counter_target_file".json 2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} "$feed_write_log"
        else
            fnWriteLog ${LINENO} ""  
            fnWriteLog ${LINENO} "dedupe ARN index LC name write to file 'lc-mapping-lc-name-new-temp-"$counter_target_file".json' "  
            feed_write_log="$(cat lc-mapping-lc-name-new-temp-"$counter_source_file".json \
            | jq --arg lc_name_new_mapping_jq "$lc_name_new_mapping" --arg lc_name_old_arn_jq "$lc_name_old_arn" '[.mappings[] | if .oldLcArn == $lc_name_old_arn_jq then .newLcName = $lc_name_new_mapping_jq else . end]' \
            | jq '. | {mappings: . } ' >> lc-mapping-lc-name-new-temp-"$counter_target_file".json 2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} "$feed_write_log"
    fi         
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    # 
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "Copying file 'lc-mapping-lc-name-new-temp-"$counter_target_file".json' to file 'launch-configs-mapping.json' "
    feed_write_log="$(cp -f lc-mapping-lc-name-new-temp-"$counter_target_file".json launch-configs-mapping.json 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "contents of file 'launch-configs-mapping.json' disabled for speed; enable for debugging"
    # disabled for speed; enable for debugging
    # fnWriteLog ${LINENO} "contents of master json mapping file: 'launch-configs-mapping.json' "
    # feed_write_log="$(cat launch-configs-mapping.json 2>&1)"
    # fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "incrementing 'lc mapping json' do loop counter " 
    counter_source_file="$((counter_source_file+1))"
    counter_target_file="$((counter_target_file+1))"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "variable values at tail of 'Autoscaling Group name mapping to JSON file' do loop - after load and increment:"
    fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
    fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "done with 'Launch Config New Name mapping to JSON file' write "
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} ""
    # write out the temp log and empty the log variable
    fnWriteLogTempFile
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "--------------- end: function fnLCNameNewWrite : 'lc-mapping.json' load new LC name ----------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
}
#
##############################################################################################################33
#                           Function definition end
##############################################################################################################33
#
#
#
# 
###########################################################################################################################
#
#
# enable logging to capture initial segments
#
logging="z"
# 
#
# 
###########################################################################################################################
#
#
# build the menu and header text line and bars 
#
text_header='Autoscaling Update AMI Utility v'
count_script_version_length=${#script_version}
count_text_header_length=${#text_header}
count_text_block_length=$(( count_script_version_length + count_text_header_length ))
count_text_width_menu=104
count_text_width_header=83
count_text_side_length_menu=$(( (count_text_width_menu - count_text_block_length) / 2 ))
count_text_side_length_header=$(( (count_text_width_header - count_text_block_length) / 2 ))
count_text_bar_menu=$(( (count_text_side_length_menu * 2) + count_text_block_length + 2 ))
count_text_bar_header=$(( (count_text_side_length_header * 2) + count_text_block_length + 2 ))
# source and explanation for the following use of printf is here: https://stackoverflow.com/questions/5799303/print-a-character-repeatedly-in-bash
text_bar_menu_build="$(printf '%0.s-' $(seq 1 "$count_text_bar_menu")  )"
text_bar_header_build="$(printf '%0.s-' $(seq 1 "$count_text_bar_header")  )"
text_side_menu="$(printf '%0.s-' $(seq 1 "$count_text_side_length_menu")  )"
text_side_header="$(printf '%0.s-' $(seq 1 "$count_text_side_length_header")  )"
text_menu="$(echo "$text_side_menu"" ""$text_header""$script_version"" ""$text_side_menu")"
text_menu_bar="$(echo "$text_bar_menu_build")"
text_header="$(echo " ""$text_side_header"" ""$text_header""$script_version"" ""$text_side_header")"
text_header_bar="$(echo " ""$text_bar_header_build")"
#
###################################################
#
#
# initialize the function dependent variables 
#
count_this_file_tasks="$(cat "$full_path" | grep -c "\-\-\- begin\: " )"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
counter_this_file_tasks=0
this_file_tasks="$(cat "$full_path" | grep "\-\-\- begin\: " )"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
#
###################################################
#
#
# initialize the function dependent files 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "initialize the deleted names file "
feed_write_log="$(echo "" > lc-version-deleted.txt 2>&1)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
#
###################################################
#
#
# check command line parameters 
# check for -h
#
if [[ "$1" = "-h" ]] ; then
    clear
    fnUsage
fi
#
###################################################
#
#
# check command line parameters 
# check for --version
#
if [[ "$1" = "--version" ]] 
    then
        clear 
        echo ""
        echo "'AWS autoscaling update AMI' script version: "$script_version" "
        echo ""
        exit 
fi
#
###################################################
#
#
# check command line parameters 
# if less than 6, then display the Usage
#
if [[ "$#" -lt 6 ]] ; then
    clear
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  ERROR: You did not enter all of the required parameters " 
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  You must provide values for all three parameters: -p -n -t "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  Example: "$0" -p MyProfileName -n newAMI -t oldAMI "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnUsage
fi
#
###################################################
#
#
# check command line parameters 
# if too many parameters, then display the error message and useage
#
if [[ "$#" -gt 18 ]] ; then
    clear
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  ERROR: You entered too many parameters" 
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  You must provide only one value for all parameters: -p -n -t -a -d -m -b "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  Example: "$0" -p MyProfileName -n newAMI -t oldAMI -a appendText -d 3 -m true"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnUsage
fi
#
###################################################
#
#
# load the main loop variables from the command line parameters 
#
fnWriteLog ${LINENO} "loading the command parameters " 
while getopts "p:n:t:a:b:d:m:g:s:h" opt; do
    case $opt in
        p)
            cli_profile="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -p 'cli_profile': "$cli_profile" "
        ;;
        n)
            ami_new_string="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -n 'ami_new_string': "$ami_new_string" "
        ;;
        t)
            ami_old_string="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -t 'ami_old_string': "$ami_old_string" "
        ;;
        a)
            lc_name_append_string="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -a 'lc_name_append_string': "$lc_name_append_string" "
        ;;
        s)
            security_group_add_id="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -s 'security_group_add_id': "$security_group_add_id" "
        ;;
        b)
            verbose="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -b 'verbose': "$verbose" "
        ;;  
        g)
            logging="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -g 'logging': "$logging" "
        ;;  
        d)
            lc_versions_delete="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -d 'lc_versions_delete': "$lc_versions_delete" "
        ;;  
        m)
            detailed_monitoring_state="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -m 'detailed_monitoring_state': "$detailed_monitoring_state" "
        ;;  
        h)
            fnUsage
        ;;   
        \?)
            clear
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "  ERROR: You entered an invalid option." 
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "  Invalid option: -"$OPTARG""
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
            fnWriteLog ${LINENO} level_0 ""
            fnUsage
        ;;
    esac
done
#
#
###################################################
#
#
# check logging variable 
#
#
###################################################
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable '@': "$@" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'logging': "$logging" "
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# disable logging if not set by the -g parameter 
#
fnWriteLog ${LINENO} "if logging not enabled by parameter, then disabling logging "
if [[ "$logging" != "y" ]] ;
    then
        logging="n"
fi
#
# parameter values 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'cli_profile' "$cli_profile" "
fnWriteLog ${LINENO} "value of variable 'verbose' "$verbose" "
fnWriteLog ${LINENO} "value of variable 'logging' "$logging" "
fnWriteLog ${LINENO} "value of -r 'aws_region': "$aws_region" "

#
#
###################################################
#
#
# check command line parameters 
# check for valid AWS CLI profile 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "count the available AWS CLI profiles that match the -p parameter profile name "
count_cli_profile="$(cat /home/"$this_user"/.aws/config | grep -c "$cli_profile")"
# if no match, then display the error message and the available AWS CLI profiles 
if [[ "$count_cli_profile" -ne 1 ]]
    then
        clear
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  ERROR: You entered an invalid AWS CLI profile: "$cli_profile" " 
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  Available cli_profiles are:"
        cli_profile_available="$(cat /home/"$this_user"/.aws/config | grep "\[profile" 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} "value of variable 'cli_profile_available': "$cli_profile_available ""
        feed_write_log="$(echo "  "$cli_profile_available"" 2>&1)"
        fnWriteLog ${LINENO} level_0 "$feed_write_log"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  To set up an AWS CLI profile enter: aws configure --profile profileName "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  Example: aws configure --profile MyProfileName "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnUsage
fi 
#
#
###################################################
#
#
# pull the AWS account number
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "pulling AWS account"
this_aws_account="$(aws sts get-caller-identity --profile "$cli_profile" --output text --query 'Account')"
#
# check for errors from the AWS API  
if [ "$?" -ne 0 ]
then
    # AWS Error 
    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "AWS error message: "
    fnWriteLog ${LINENO} level_0 "$feed_write_log"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
    #
    # set the awserror line number
    error_line_aws="$((${LINENO}-14))"
    #
    # call the AWS error handler
    fnErrorAws
    #
fi # end AWS error check
#
fnWriteLog ${LINENO} "value of variable 'this_aws_account': "$this_aws_account" "
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# set the aws account dependent variables
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "setting the AWS account dependent variables"
write_path="$this_path"/aws-"$this_aws_account"-"$this_utility_filename_plug"-"$date_file"
this_log_file=aws-"$this_aws_account"-"$this_utility_filename_plug"-v"$script_version"-"$date_file"-debug.log 
this_log_file_errors=aws-"$this_aws_account"-"$this_utility_filename_plug"-v"$script_version"-"$date_file"-errors.log 
this_log_file_full_path="$write_path"/"$this_log_file"
this_log_file_errors_full_path="$write_path"/"$this_log_file_errors"
this_summary_report=aws-"$this_aws_account"-"$this_utility_filename_plug"-"$date_file"-summary-report.txt
this_summary_report_full_path="$write_path"/"$this_summary_report"
this_launch_configs_mapping_json=aws-"$this_aws_account"-"$this_utility_filename_plug"-"$date_file"-launch-configs-mapping.json
this_launch_configs_mapping_json_full_path="$write_path"/"$this_launch_configs_mapping_json"
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'write_path': "$write_path" "
fnWriteLog ${LINENO} "value of variable 'this_log_file': "$this_log_file" "
fnWriteLog ${LINENO} "value of variable 'this_log_file_errors': "$this_log_file_errors" "
fnWriteLog ${LINENO} "value of variable 'this_log_file_full_path': "$this_log_file_full_path" "
fnWriteLog ${LINENO} "value of variable 'this_log_file_errors_full_path': "$this_log_file_errors_full_path" "
fnWriteLog ${LINENO} "value of variable 'this_summary_report': "$this_summary_report" "
fnWriteLog ${LINENO} "value of variable 'this_summary_report_full_path': "$this_summary_report_full_path" "
fnWriteLog ${LINENO} "value of variable 'this_launch_configs_mapping_json': "$this_launch_configs_mapping_json" "
fnWriteLog ${LINENO} "value of variable 'this_launch_configs_mapping_json_full_path': "$this_launch_configs_mapping_json_full_path" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# create the directories
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "creating write path directories "
feed_write_log="$(mkdir -p "$write_path" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "status of write path directory "
feed_write_log="$(ls -ld */ "$this_path" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# pull the AWS account alias
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "pulling AWS account alias"
this_aws_account_alias="$(aws iam list-account-aliases --profile "$cli_profile" --output text --query 'AccountAliases' )"
#
# check for errors from the AWS API  
if [ "$?" -ne 0 ]
then
    # AWS Error 
    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "AWS error message: "
    fnWriteLog ${LINENO} level_0 "$feed_write_log"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
    #
    # set the awserror line number
    error_line_aws="$((${LINENO}-14))"
    #
    # call the AWS error handler
    fnErrorAws
    #
fi # end AWS error check
#    
fnWriteLog ${LINENO} "value of variable 'this_aws_account_alias': "$this_aws_account_alias" "
fnWriteLog ${LINENO} ""
#
###############################################################################
# 
#
# Initialize the log file
#
if [[ "$logging" = "y" ]] ;
    then
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "initializing the log file "
        echo "Log start" > "$this_log_file_full_path"
        echo "" >> "$this_log_file_full_path"
        echo "This log file name: "$this_log_file"" >> "$this_log_file_full_path"
        echo "" >> "$this_log_file_full_path"
fi 
#
###############################################################################
# 
#
# Initialize the error log file
#
echo "  Errors:" > "$this_log_file_errors_full_path"
echo "" >> "$this_log_file_errors_full_path"
#
#
#
#
###################################################
#
#
# check command line parameters 
# check for AMI ID vs text 
#
#
#
ami_new_trim="$(echo "$ami_new_string" | cut -c1-4)"
if [[ "$ami_new_trim" = "ami-" ]] ;
    then
        ami_new_type="id"
    else
        ami_new_type="name"
fi
#
ami_old_trim="$(echo "$ami_old_string" | cut -c1-4)"
if [[ "$ami_old_trim" = "ami-" ]] ;  then
        ami_old_type="id"
    else
        ami_old_type="name"
fi
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "ami input type: "
fnWriteLog ${LINENO} "value of variable 'ami_new_type': "$ami_new_type" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'ami_old_type': "$ami_old_type" "
fnWriteLog ${LINENO} ""
#
#
###########################################################################################################################
#
#
# Begin checks and setup 
#
# 
###########################################################################################################################
#
#
# display initializing message
#
clear
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_header"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " This utility updates targeted AWS Autoscale EC2 Launch Configurations "
fnWriteLog ${LINENO} level_0 " and Autoscaling Groups with a new AMI "  
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " This script will: "
fnWriteLog ${LINENO} level_0 " - Update AWS Autoscaling Launch Configurations (LCs) to use a new AMI "
fnWriteLog ${LINENO} level_0 " - Update Launch Configuration Names to reflect the new version "
fnWriteLog ${LINENO} level_0 " - Create new Launch Configurations using the updated configurations "
if (( "$lc_versions_delete" > 0 ))
    then
        fnWriteLog ${LINENO} level_0 " - Delete prior Launch Configuration versions "
fi
fnWriteLog ${LINENO} level_0 " - Update all related Autoscaling Groups (AGs) to use the new Launch Configurations "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_header_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "                            Please wait  "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "  Checking the input parameters and initializing the app " 
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "  Depending on connection speed and AWS API response, this can take " 
fnWriteLog ${LINENO} level_0 "  from a few seconds to a few minutes "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "  Status messages and opening menu will appear below"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_header_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
# 
#
#
###################################################
#
#
# check for AMI types
# both AMI types need to be the same
#
fnWriteLog ${LINENO} level_0   "Checking for AMI input type mismatch..."
if [[ ("$ami_new_type" = "id" && "$ami_old_type" = "name") || ("$ami_new_type" = "name" && "$ami_old_type" = "id") ]] 
    then
        clear
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  ERROR: Both the new and old AMI inputs must be the same type " 
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  New AMI: "$ami_new_string" "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  Old AMI: "$ami_old_string" "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  The new and old AMI inputs must both be AMI names or AMI IDs "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  Examples using AMI names:"
        fnWriteLog ${LINENO} level_0 "      Example: -n act123456789999_worker_v432_2017_11_23_1302_utc "
        fnWriteLog ${LINENO} level_0 "      Example: -t act123456789999_worker_v321_2016_04_30_1845_utc "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  Examples using AMI IDs:"
        fnWriteLog ${LINENO} level_0 "      Example: -n ami-aa7874d1 "
        fnWriteLog ${LINENO} level_0 "      Example: -t ami-c5636fbe "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnUsage
fi
#
###################################################
#
#
# check for duplicate AMI inputs
# 
fnWriteLog ${LINENO} level_0   "Checking for duplicate AMI inputs..."
if [[ "$ami_new_string" = "$ami_old_string" ]] 
    then
        clear
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  ERROR: The new and old AMI inputs are identical: " 
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  New AMI: "$ami_new_string" "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  Old AMI: "$ami_old_string" "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  The new and old AMI inputs must be different "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnUsage
fi
#
###################################################
#
#
# if AMI input = name, run name checks  
#
if [[ "$ami_new_type" = "name" && "$ami_old_type" = "name" ]] 
    then
        #
        ###################################################
        #
        #
        # load the AMI check variables 
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "Old AMI string: "$ami_old_string" "
        fnWriteLog ${LINENO} "New AMI string: "$ami_new_string" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} level_0 "Checking the new and old AMI strings..." 
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "This can take a few minutes..."
        fnWriteLog ${LINENO} level_0 ""
        #
        ###################################################
        #
        #
        # check command line parameters 
        # check for valid ami_old_string
        #
        # check the old, target AMI ID 
        # 
        #
        #
        #
        # ---------------------- begin jq job documentation -------------------------
        # 
        # jq job documentation - docs the following jq JSON filter job
        #
        # ------------
        # "aws ec2 describe-images" runs the AWS CLI command to pull the account AMIs
        # "--profile $cli_profile" uses the AWS CLI provided with the -p (profile) command line parameter
        # "--owners self" filters the results to only AMIs owned by the profile's account 
        # 
        # aws ec2 describe-images --profile "$cli_profile" --owners self 
        # ------------
        # 
        # ------------
        # | pipe the job to jq (no further pipes will be documented)
        # the "jq" starts a new job
        # see below for the '[ job wrap 
        # the leading '.' is the entire returned inbound data set
        # "Images" limits the results to the AMI images array key
        # [] creates an array of the ".Images" filter results  
        #
        # | jq '[.Images[] 
        # ------------
        # 
        # ------------
        # the {} create new objects for each returned AMI 
        # the ',' runs the entire data set through the filters on each side of the comma
        # the "ImageId" and "Name" limit the results to only those keys & their values
        # the entire job is wrapped in [] to create an array from of the results
        # the entire job is wrapped in '' to prevent bash from doing any expansions
        #
        # | {ImageId, Name}]' 
        # ------------
        # 
        # ------------
        # the "jq" starts a new job
        # "--arg jq-variable-name $bash-variable-name" creates and loads a jq variable that can be used in jq filters
        # see below for the '[ job wrap 
        # the leading "." is the entire data set results of all prior filters & pipes
        # the [] creates an array of inbound piped results
        #
        #| jq --arg ami_old_string_jq "$ami_old_string" '[.[] 
        # ------------
        #
        # ------------
        # the "select()" statement filters the results to only those that match the condition
        # in this case the select() is combined with a piped "contains()" filter: seelct( .key | contains (string))
        # the "." is the entire data set as piped to this command
        # the "Name" filters to only that key 
        #
        #| select(.Name 
        # ------------
        #
        # ------------
        # the "contains" is a filter to limit results to only values including the following text contained in the (string)
        # the "$ami_old_string_jq" is the jq variable loaded with the bash command line parameter for the target AMI
        # >> note that you can -only- use jq variables in jq filters such as select and contains
        # the entire job is wrapped in [] to create an array of the results
        # the entire job is wrapped in '' to prevent bash from doing any expansions
        #
        # | contains($ami_old_string_jq))]' 
        # ------------
        #
        # ------------
        # the "jq" starts a new job
        # the "-r" is raw results, meaning text only and no JSON wrap, structure or formatting
        # see below for the '' job wrap
        # the leading '.' is the full data set results of all preceeding filters and pipes
        # the [] creates an array of the incoming data set 
        #
        # | jq -r ' .[] 
        # ------------
        #
        # ------------
        # the leading '.' is the full data set results of all preceeding filters and pipes
        # the "ImageId" limits the results to only that key's values 
        # the entire job is wrapped in '' to prevent bash from doing any expansions
        #
        # | .ImageId' 
        # ------------
        # 
        # ------------
        # the grep "-c" parameter counts all of the lines in the results
        # the "ami-" filters the results to only lines that contain that text
        #
        # | grep -c "ami-"
        # ------------
        #
        # ------------
        #
        # the result is an integer count of all account AMIs that match the old, target AMI name string provided with the -t command line parameter
        #
        # this basic job is used to pull the AMI names and AMI IDs for the -n (new AMI) and -t (old, targeted AMI) AMI name strings
        # 
        # ------------
        #
        #
        # ---------------------- end jq job documentation -------------------------
        #
        # check the old, target string to see if it exists 
        fnWriteLog ${LINENO} level_0  "Checking old, target AMI string..."
        #
        count_ami_old_id="$( aws ec2 describe-images --profile "$cli_profile" --owners self | jq '[.Images[] | {ImageId, Name}]' \
        | jq --arg ami_old_string_jq "$ami_old_string" '[.[] | select(.Name | contains($ami_old_string_jq))]' | jq -r ' .[] | .ImageId' | grep -c "ami-")"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        if [[ "$count_ami_old_id" -eq 0 ]]
            then
                clear
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  ERROR: The AMI target string parameter is not valid " 
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  "$ami_old_string" "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  The -t parameter must match an existing AMI name "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  The -t parameter can be the entire target AMI name or a part of "
                fnWriteLog ${LINENO} level_0 "  the name but it must match an existing AMI"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  Example: -t act123456789999_worker_v321_2016_04_30_1845_utc "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 ""
                fnUsage
        fi
        #
        ###################################################
        #
        #
        # check command line parameters 
        # check for valid ami_new_string
        #
        # check the new AMI ID 
        # 
        fnWriteLog ${LINENO} level_0   "Checking new AMI string..."
        count_ami_new_id="$(aws ec2 describe-images --profile "$cli_profile" --owners self | jq '[.Images[] | {ImageId, Name}]' \
        | jq --arg ami_new_string_jq "$ami_new_string" '[.[] | select(.Name | contains($ami_new_string_jq))]' | jq -r ' .[] | .ImageId' | grep -c "ami-")"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        if [[ "$count_ami_new_id" -eq 0 ]]
            then
                clear
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  ERROR: The AMI new string parameter is not valid " 
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  "$ami_new_string" "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  The -t parameter must match an existing AMI name "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  The -t parameter can be the entire new AMI name or a part of "
                fnWriteLog ${LINENO} level_0 "  the name but it must match an existing AMI"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "      Example: -n act123456789999_worker_v432_2017_11_23_1302_utc "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 ""
                fnUsage
        fi
        #
        ###################################################
        #
        #
        # check command line parameters 
        # display AMI counts
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "To be valid, these counts should both be 1:"
        fnWriteLog ${LINENO} "Old, target AMI count: "$count_ami_old_id" "
        fnWriteLog ${LINENO} "New AMI count:         "$count_ami_new_id" "
        fnWriteLog ${LINENO} ""
        #
        ###################################################
        #
        #
        # check command line parameters 
        # check for unique ami_old_string
        #
        # check the old, target AMI ID 
        # 
        fnWriteLog ${LINENO} level_0   "Checking for unique string for the old, target AMI"
        if [[ "$count_ami_old_id" -gt 1 ]]
            then
                clear
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  ERROR: The AMI target string parameter is not unique " 
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  "$ami_old_string" "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  The -t parameter must be a unique AMI name identifier "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  The -t parameter can be the entire target AMI name or a part of "
                fnWriteLog ${LINENO} level_0 "  the name but it must be a unique identifier for only one AMI"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  Example: -t act123456789999_worker_v321_2016_04_30_1845_utc "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 ""
                fnUsage
        fi
        #
        ###################################################
        #
        #
        # check command line parameters 
        # check for unique ami_new_string
        #
        # check the new AMI ID 
        # 
        fnWriteLog ${LINENO} level_0 "Checking for unique string for the new AMI"
        if [[ "$count_ami_new_id" -gt 1 ]]
            then
                clear
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  ERROR: The AMI new string parameter is not unique " 
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  "$ami_new_string" "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  The -t parameter must be a unique AMI name identifier "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  The -t parameter can be the entire new AMI name or a part of "
                fnWriteLog ${LINENO} level_0 "  the name but it must be a unique identifier for only one AMI"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "      Example: -n act123456789999_worker_v432_2017_11_23_1302_utc "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 ""
                fnUsage
        fi
    else
        # the AMIs are IDs
             #
        # check the old, target AMI ID to see if it exists 
        fnWriteLog ${LINENO} level_0  "Checking old, target AMI ID..."
        #
        fnWriteLog ${LINENO} "counting old AMI ID if owned"
        count_ami_old_id_owned="$( aws ec2 describe-images --profile "$cli_profile" --owners self | jq '[.Images[] | {ImageId, Name}]' \
        | jq --arg ami_old_string_jq "$ami_old_string" '[.[] | select(.ImageId | contains($ami_old_string_jq))]' | jq -r ' .[] | .ImageId' | grep -c "ami-")"
        #
        fnWriteLog ${LINENO} "counting old AMI ID if shared with this account"
        count_ami_old_id_shared="$( aws ec2 describe-images --profile "$cli_profile" --executable-users self | jq '[.Images[] | {ImageId, Name}]' \
        | jq --arg ami_old_string_jq "$ami_old_string" '[.[] | select(.ImageId | contains($ami_old_string_jq))]' | jq -r ' .[] | .ImageId' | grep -c "ami-")"
        #
        fnWriteLog ${LINENO} "loading owned and shared counts into variable 'count_ami_old_id' "
        count_ami_old_id="$((count_ami_old_id_owned+count_ami_old_id_shared))"
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable: 'count_ami_old_id_owned': "$count_ami_old_id_owned" "
        fnWriteLog ${LINENO} "value of variable: 'count_ami_old_id_shared': "$count_ami_old_id_shared" "
        fnWriteLog ${LINENO} "value of variable: 'count_ami_old_id': "$count_ami_old_id" "
        fnWriteLog ${LINENO} ""
        #
        # check for valid ID
        #
        fnWriteLog ${LINENO} "checking for valid old AMI ID count "
        if [[ "$count_ami_old_id" -eq 0 ]]
            then
                clear
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  ERROR: The AMI target ID parameter is not valid " 
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  "$ami_old_string" "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  The -t ID parameter must match an existing AMI ID "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  Examples using AMI IDs:"
                fnWriteLog ${LINENO} level_0 "      Example: -n ami-aa7874d1 "
                fnWriteLog ${LINENO} level_0 "      Example: -t ami-c5636fbe "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 ""
                fnUsage
        fi
        #
        ###################################################
        #
        #
        # check command line parameters 
        # check for valid ami_new_string
        #
        # check the new AMI ID 
        # 
        fnWriteLog ${LINENO} level_0   "Checking new AMI ID..."
        count_ami_new_id="$(aws ec2 describe-images --profile "$cli_profile" --owners self | jq '[.Images[] | {ImageId, Name}]' \
        | jq --arg ami_new_string_jq "$ami_new_string" '[.[] | select(.ImageId | contains($ami_new_string_jq))]' | jq -r ' .[] | .ImageId' | grep -c "ami-")"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        if [[ "$count_ami_new_id" -eq 0 ]]
            then
                clear
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  ERROR: The AMI new ID parameter is not valid " 
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  "$ami_new_string" "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  The -t ID parameter must match an existing AMI name "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "  Examples using AMI IDs:"
                fnWriteLog ${LINENO} level_0 "      Example: -n ami-aa7874d1 "
                fnWriteLog ${LINENO} level_0 "      Example: -t ami-c5636fbe "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 ""
                fnUsage
        fi
# end AMI type section
fi
#
###################################################
#
#
# check command line parameters 
# clean the append text of any special characters
# 
fnWriteLog ${LINENO} level_0  "Cleaning the append text of special characters..."
lc_name_append_string_clean="$( echo  "$lc_name_append_string" | tr -dc '[:alnum:]-_')"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "Before append text clean: "$lc_name_append_string" "
fnWriteLog ${LINENO} "After append text clean:  "$lc_name_append_string_clean" "
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# pull the AMI names and IDs
#
fnWriteLog ${LINENO} " Value of variable 'ami_new_type': "$ami_new_type" "
fnWriteLog ${LINENO} " Value of variable 'ami_old_type': "$ami_old_type" "
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} level_0  "Pulling the AMI info from AWS..."
if [ "$ami_new_type" = 'name' ] && [ "$ami_old_type" = 'name' ]
    then  
        fnWriteLog ${LINENO} "In AMI input = name - Pulling the AMI info from AWS..."
        fnWriteLog ${LINENO} " Value of variable 'ami_new_type': "$ami_new_type" "
        fnWriteLog ${LINENO} " Value of variable 'ami_old_type': "$ami_old_type" "
        fnWriteLog ${LINENO} "value of variable 'ami_old_string': "$ami_old_string"  "
        fnWriteLog ${LINENO} "value of variable 'ami_new_string': "$ami_new_string"  "
        ami_old_name="$(aws ec2 describe-images  --profile "$cli_profile" --owners self \
        | jq '[.Images[] | {ImageId, Name}]' \
        | jq --arg ami_old_string_jq "$ami_old_string" '[.[] | select(.Name | contains($ami_old_string_jq))]' \
        | jq -r ' .[] | .Name')"  
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        ami_old_id="$(aws ec2 describe-images  --profile "$cli_profile" --owners self   \
        | jq '[.Images[] | {ImageId, Name}]' \
        | jq --arg ami_old_string_jq "$ami_old_string" '[.[] | select(.Name | contains($ami_old_string_jq))]' \
        | jq -r ' .[] | .ImageId')"  
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        ami_new_name="$(aws ec2 describe-images  --profile "$cli_profile" --owners self \
        | jq '[.Images[] | {ImageId, Name}]' \
        | jq --arg ami_new_string_jq "$ami_new_string" '[.[] | select(.Name | contains($ami_new_string_jq))]' \
        | jq -r ' .[] | .Name')"  
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        ami_new_id="$(aws ec2 describe-images  --profile "$cli_profile" --owners self   \
        | jq '[.Images[] | {ImageId, Name}]' \
        | jq --arg ami_new_string_jq "$ami_new_string" '[.[] | select(.Name | contains($ami_new_string_jq))]' \
        | jq -r ' .[] | .ImageId')"  
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    else 
        if [ "$ami_new_type" = 'id' ] && [ "$ami_old_type" = 'id' ]
            then 
                fnWriteLog ${LINENO} "In AMI input = ID - Pulling the AMI info from AWS..."
                fnWriteLog ${LINENO} "Value of variable 'ami_new_type': "$ami_new_type" "
                fnWriteLog ${LINENO} "Value of variable 'ami_old_type': "$ami_old_type" "
                fnWriteLog ${LINENO} "value of variable 'ami_old_string': "$ami_old_string"  "
                fnWriteLog ${LINENO} "value of variable 'ami_new_string': "$ami_new_string"  "
                ami_old_name="$(aws ec2 describe-images  --profile "$cli_profile" --owners self \
                | jq '[.Images[] | {ImageId, Name}]' \
                | jq --arg ami_old_string_jq "$ami_old_string" '[.[] | select(.ImageId | contains($ami_old_string_jq))]' \
                | jq -r ' .[] | .Name')"  
                #
                # check for command / pipeline error(s)
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                #
                fi
                #
                ami_old_id="$ami_old_string" 
                ami_new_name="$(aws ec2 describe-images  --profile "$cli_profile" --owners self \
                | jq '[.Images[] | {ImageId, Name}]' \
                | jq --arg ami_new_string_jq "$ami_new_string" '[.[] | select(.ImageId | contains($ami_new_string_jq))]' \
                | jq -r ' .[] | .Name')"  
                #
                # check for command / pipeline error(s)
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                #
                fi
                #
                ami_new_id="$ami_new_string"
            else 
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 " >> Fatal Internal Error <<"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 " The AMI input type is invalid "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 " Value of variable 'ami_new_type': "$ami_new_type" "
                fnWriteLog ${LINENO} level_0 " Value of variable 'ami_old_type': "$ami_old_type" "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 ""
                # delete the work files
                fnDeleteWorkFiles
                # write the log file
                fnWriteLogFile
                exit 1
        fi 
fi
#
###################################################
#
#
# pull the count of target LCs
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} level_0 "Pulling the count of target Launch Configurations from AWS..."
count_lc_target="$(aws autoscaling describe-launch-configurations --profile "$cli_profile" \
| jq .[] | jq --arg ami_old_id_jq "$ami_old_id" '[.[] | select(.ImageId == $ami_old_id_jq)]' \
| jq -r ' .[] | .ImageId' | wc -l)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} "value of variable 'count_lc_target': "$count_lc_target" "
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# clear the console
#
clear
# 
######################################################################################################################################################################
#
#
# Opening menu
#
#
######################################################################################################################################################################
#
#
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_menu"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " Update targeted Autoscaling Launch Configurations and Autoscaling Groups with a new AMI "  
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_menu_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "AWS account:............"$this_aws_account"  "$this_aws_account_alias" "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Old, target AMI name:..."$ami_old_name" "
fnWriteLog ${LINENO} level_0 "Old, target AMI ID:....."$ami_old_id" "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "New AMI name:..........."$ami_new_name" "
fnWriteLog ${LINENO} level_0 "New AMI ID:............."$ami_new_id" "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Text to append to the Launch Configuration name: "$lc_name_append_string_clean""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Count of affected old, target Launch Configurations: "$count_lc_target" "
fnWriteLog ${LINENO} level_0 ""
if (( "$lc_versions_delete" > 0 ))
    then
        fnWriteLog ${LINENO} level_0 "Number of prior Launch Configuration versions to retain: "$lc_versions_delete" "
fi
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_menu_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "All Launch Configurations and Autoscaling Groups using the old, target AMI will be updated"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " ############################################### " 
fnWriteLog ${LINENO} level_0 " >> Note: There is no undo for this operation << " 
fnWriteLog ${LINENO} level_0 " ############################################### "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " By running this utility script you are taking full responsibility for any and all outcomes"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Autoscaling update AMI utility"
fnWriteLog ${LINENO} level_0 "Run Utility Y/N Menu"
#
# Present a menu to allow the user to exit the utility and do the preliminary steps
#
# Menu code source: https://stackoverflow.com/questions/30182086/how-to-use-goto-statement-in-shell-script
#
# Define the choices to present to the user, which will be
# presented line by line, prefixed by a sequential number
# (E.g., '1) copy', ...)
choices=( 'Run' 'Exit' )
#
# Present the choices.
# The user chooses by entering the *number* before the desired choice.
select choice in ${choices[@]}; do
#   
    # If an invalid number was chosen, "$choice" will be empty.
    # Report an error and prompt again.
    [[ -n "$choice" ]] || { fnWriteLog ${LINENO} level_0 "Invalid choice." >&2; continue; }
    #
    # Examine the choice.
    # Note that it is the choice string itself, not its number
    # that is reported in "$choice".
    case "$choice" in
        Run)
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "Running Autoscaling update AMI utility"
                fnWriteLog ${LINENO} level_0 ""
                # Set flag here, or call function, ...
            ;;
        Exit)
        #
        #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "Exiting the utility..."
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 ""
                # delete the work files
                fnDeleteWorkFiles
                # write the log variable to the log file
                fnWriteLogFile
                exit 1
    esac
    #
    # Getting here means that a valid choice was made,
    # so break out of the select statement and continue below,
    # if desired.
    # Note that without an explicit break (or exit) statement, 
    # bash will continue to prompt.
    break
    #
    # end select - menu 
    # echo "at done"
done
#
#
# *********************  begin script *********************
# 
#
#
##########################################################################
#
#
# write the start timestamp to the log 
#
fnHeader
#
date_now="$(date +"%Y-%m-%d-%H%M%S")"
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "run start timestamp: "$date_now" " 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
#
##########################################################################
#
#
# clear the console for the run 
#
fnHeader
#
##########################################################################
#
#
# display the log location 
#
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "Run log: "$this_log_file_full_path"" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
#
#
#
##########################################################################
#
#
# pull the list of LCs using the old AMI   
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "------------------------------ begin: pull the LCs using the old AMI ID ----------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "ami_old_id value: "$ami_old_id" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} level_0 "Pulling the Launch Configurations from AWS using the old AMI ID..."
lc_target="$(aws autoscaling describe-launch-configurations --profile "$cli_profile" | jq .[] | jq --arg ami_old_id_jq "$ami_old_id" '[.[] | select(.ImageId == $ami_old_id_jq)]' )"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'lc_target' "
fnWriteLog ${LINENO} "LCs using old, target AMI piped through jq :"
feed_write_log="$(echo "$lc_target" | jq . 2>&1)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "------------------------------- end: pull the LCs using the old AMI ID -----------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# pull the old LC names to use when matching to associated autoscale groups  
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------- begin: extract the old, target LC names from the file: 'lc_target.json' -----------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO} level_0 "Extracting the old, target Launch Configuration names from the file: 'lc_target.json'..."
fnWriteLog ${LINENO} "putting the results into text file for jq processing"
#
fnWriteLog ${LINENO} "creating lc_target.json"
feed_write_log="$(echo "$lc_target" > lc_target.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
#
fnWriteLog ${LINENO} "loading 'lc_old_name_list_raw' variable"
lc_old_names_raw="$(cat lc_target.json | jq -r '.[].LaunchConfigurationName' )"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
#
fnWriteLog ${LINENO} "creating text file: 'lc_old_names.txt'"
feed_write_log="$(cat lc_target.json | jq -r '.[].LaunchConfigurationName' > lc_old_names.txt 2>&1)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contends of file:'lc_old_names.txt': "
feed_write_log="$(cat lc_old_names.txt  2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "sort file: 'lc_old_names.txt'"
fnWriteLog ${LINENO} "create file: 'lc_old_names_sorted.txt' "
feed_write_log="$(sort "lc_old_names.txt" > lc_old_names_sorted.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of file 'lc_old_names_sorted.txt':"
feed_write_log="$(cat lc_old_names_sorted.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------- end: extract the old, target LC names from the file: 'lc_target.json' ------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# create the 'launch-configs-mapping.json' LC names JSON file   
# to hold the old LC to new LC to autoscaling group relationships
# 
# populate the 'launch-configs-mapping.json' file with the old LC name 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------- begin: write old lc names to the file: 'lc-mapping.json' -------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO} level_0 "Writing the old, target Launch Configuration names to the file: "
fnWriteLog ${LINENO} level_0 " 'lc-mapping.json'..."
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "initializing the files"
fnWriteLog ${LINENO} "initializing file 'lc-mapping.json'"
fnWriteLog ${LINENO} ""
#
# initial load of empty JSON in lc-mapping.json for first run
feed_write_log="$(echo "{\"mappings\":[{\"oldLcName\": \"\",\"newLcName\": \"\",\"oldLcArn\": \"\",\"newLcArn\": \"\",\"oldAmiId\": \"\",\"oldAmiName\": \"\",\"newAmiId\": \"\",\"newAmiName\": \"\",\"autoscaleGroups\":[]}]}" | jq . > lc-mapping.json 2>&1)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "initialize the initial temp file"
feed_write_log="$(echo "" > lc-mapping-old-temp-1.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of 'lc-mapping.json':"
feed_write_log="$(cat lc-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of 'lc_old_names_sorted.txt':"
feed_write_log="$(cat lc_old_names_sorted.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "populating variable with old names"
lc_old_names_sorted="$(cat lc_old_names_sorted.txt)"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "initializing 'lc mapping old name load' loop counter"
counter_lc_old_name_json_populate=0
counter_file="$counter_lc_old_name_json_populate"
counter_target_file="$((counter_file+1))"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "value of variable 'counter_lc_old_name_json_populate': "
fnWriteLog ${LINENO} "$counter_lc_old_name_json_populate"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "load the input file #: "$counter_file" " 
feed_write_log="$(cp -f lc-mapping.json lc-mapping-old-temp-"$counter_file".json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of lc-mapping-old-temp-"$counter_file".json"
feed_write_log="$(cat lc-mapping-old-temp-"$counter_file".json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "initize the job counters " 
counter_write_mapping_lc=1
count_write_mapping_lc="$(cat lc_old_names_sorted.txt | wc -l)"
#
fnWriteLog ${LINENO} "populating JSON with contents of 'lc_old_names_sorted.txt'"
fnWriteLog ${LINENO} "populating LC mapping JSON "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
# uses process substitution to preserve variables 
# input is at the 'done' line 
while read -r lc_old_names_sorted_line
    do
    # display the header    
    fnHeader
    # display the task progress bar
    fnProgressBarTaskDisplay "$counter_write_mapping_lc" "$count_write_mapping_lc"
    #
    fnWriteLog ${LINENO} level_0 "Writing the Launch Configuration names to the file: 'lc-mapping.json'..."
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "This task takes a while. Please wait..."
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 "Processing job "$counter_write_mapping_lc" of "$count_write_mapping_lc" "
    fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in 'lc mapping json' do loop"
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "'lc mapping json' do loop counter value for load: "$counter_lc_old_name_json_populate" "
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "LC name value for load to LC JSON file 'lc_old_names_sorted_line': "$lc_old_names_sorted_line""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variables before file write: "
    fnWriteLog ${LINENO} "value of variable: 'counter_lc_old_name_json_populate': "$counter_lc_old_name_json_populate" "
    fnWriteLog ${LINENO} "value of variable: 'counter_file': "$counter_file" "
    fnWriteLog ${LINENO} "value of variable: 'counter_target_file': "$counter_target_file" "
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "source file name: lc-mapping-old-temp-"$counter_file".json"
    fnWriteLog ${LINENO} "output file name: lc-mapping-old-temp-"$counter_target_file".json"
    #
    fnWriteLog ${LINENO} "initialize output file "
    feed_write_log="$(echo "" >  lc-mapping-old-temp-"$counter_target_file".json 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "contents of input file: lc-mapping-old-temp-"$counter_file".json"
    feed_write_log="$(cat lc-mapping-old-temp-"$counter_file".json 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "Writing old LC name to: lc-mapping-old-temp-"$counter_target_file".json"   
    feed_write_log="$(cat lc-mapping-old-temp-"$counter_file".json \
    | jq --arg counter_jq "$counter_lc_old_name_json_populate" --arg lc_old_name_jq "$lc_old_names_sorted_line" '. | .mappings[$counter_jq|tonumber].oldLcName = $lc_old_name_jq | . | .mappings[$counter_jq|tonumber].newLcName = "" | . | .mappings[$counter_jq|tonumber].oldLcArn = "" | . | .mappings[$counter_jq|tonumber].newLcArn = "" | . | .mappings[$counter_jq|tonumber].oldAmiId = "" | . | .mappings[$counter_jq|tonumber].oldAmiName = "" | . | .mappings[$counter_jq|tonumber].newAmiId = "" | . | .mappings[$counter_jq|tonumber].newAmiName = "" | . | .mappings[$counter_jq|tonumber].autoscaleGroups = [] ' >> lc-mapping-old-temp-"$counter_target_file".json 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "contents of output file: lc-mapping-old-temp-"$counter_target_file".json"
    feed_write_log="$(cat lc-mapping-old-temp-"$counter_target_file".json 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "incrementing 'lc mapping json' do loop counter " 
    counter_lc_old_name_json_populate="$((counter_lc_old_name_json_populate+1))"
    counter_file="$((counter_file+1))"
    counter_target_file="$((counter_target_file+1))"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "value of variables after file write and increment: "
    fnWriteLog ${LINENO} "value of variable: 'counter_lc_old_name_json_populate': "$counter_lc_old_name_json_populate" "
    fnWriteLog ${LINENO} "value of variable: 'counter_file': "$counter_file" "
    fnWriteLog ${LINENO} "value of variable: 'counter_target_file': "$counter_target_file" "
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "'lc mapping json' do loop counter value after increment: "$counter_lc_old_name_json_populate" "
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "increment the write counter: 'counter_write_mapping_lc'"
    counter_write_mapping_lc="$((counter_write_mapping_lc+1))"
    fnWriteLog ${LINENO} "post-increment value of variable 'counter_write_mapping_lc': "$counter_write_mapping_lc" "
    fnWriteLog ${LINENO} ""
    #
    done < <(cat lc_old_names_sorted.txt) 
    #
fnWriteLog ${LINENO} "done with 'lc mapping json' do loop "
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "------------------------ end: write old lc names to the file: 'lc-mapping.json' --------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# populate the 'launch-configs-mapping.json' file with the Autoscaling Group name(s)    
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "-------------------------- begin: write AG names to the file: 'lc-mapping.json' --------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO} level_0 "Writing the associated Autoscaling Group names to the file: 'lc-mapping.json'..."
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "This task takes a while. Please wait..."
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "initializing the counters"
# decrement the final increment at the end of the final LC name load loop 
counter_lc_name_file="$counter_file"
counter_ag_name_json_populate=0
counter_source_file="$counter_file"
counter_target_file="$((counter_source_file+1))"
counter_write_mapping_ag=1
count_write_mapping_ag="$(cat lc_old_names_sorted.txt | wc -l)"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'counter_lc_name_file': "$counter_lc_name_file" "
fnWriteLog ${LINENO} "value of variable 'counter_ag_name_json_populate': "$counter_ag_name_json_populate" "
fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
fnWriteLog ${LINENO} "value of variable 'counter_write_mapping_ag': "$counter_write_mapping_ag" "
fnWriteLog ${LINENO} "value of variable 'count_write_mapping_ag': "$count_write_mapping_ag" "
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "initializing the files"
#
fnWriteLog ${LINENO} "load the first input data file with the results of the LC name load"
fnWriteLog ${LINENO} "value of source file name variable : lc-mapping-old-temp-"$counter_lc_name_file".json"
feed_write_log="$(cp -f lc-mapping-old-temp-"$counter_lc_name_file".json lc-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "initialize the initial temp file"
feed_write_log="$(echo "" >  lc-mapping-ag-temp-1.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
# echo "" >  lc-mapping-ag-temp-1.json
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of 'lc-mapping.json':"
feed_write_log="$(cat lc-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of 'lc_old_names_sorted.txt':"
feed_write_log="$(cat lc_old_names_sorted.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "populating variable with ag names"
lc_old_names_sorted="$(cat lc_old_names_sorted.txt)"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "value of variable 'counter_ag_name_json_populate': "
feed_write_log="$(echo "$counter_ag_name_json_populate" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "load the first input data file with the results of the LC name load"
fnWriteLog ${LINENO} "load the input file #: "$counter_source_file" " 
fnWriteLog ${LINENO} "value of target file name: lc-mapping-ag-temp-"$counter_source_file".json"
feed_write_log="$(cp -f lc-mapping.json lc-mapping-ag-temp-"$counter_source_file".json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of source file: lc-mapping-ag-temp-"$counter_source_file".json"
feed_write_log="$(cat lc-mapping-ag-temp-"$counter_source_file".json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "variable values prior to run:"
fnWriteLog ${LINENO} "value of variable 'counter_ag_name_json_populate': "$counter_ag_name_json_populate" "
fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
fnWriteLog ${LINENO} "value of variable 'counter_write_mapping_ag': "$counter_write_mapping_ag" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "populating JSON with the Autoscaling Group names associated with the LCs"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "beginning 'process LC old name list to pull AG names' do loop "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
# uses process substitution to preserve variables 
# input is at the 'done' line 
while read -r lc_old_names_sorted_line
    do 
    # display the header    
    fnHeader
    # display the task progress bar
    fnProgressBarTaskDisplay "$counter_write_mapping_ag" "$count_write_mapping_ag"
    #
    fnWriteLog ${LINENO} level_0 "Writing the associated Autoscaling Group names to the file: 'lc-mapping.json'..."
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "This task takes a while. Please wait..."
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 "Processing job "$counter_write_mapping_ag" of "$count_write_mapping_ag" "
    fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} "in 'process LC old name list to pull AG names' do loop"
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "variable values at head of 'pull AG names' do loop: "
    fnWriteLog ${LINENO} "value of variable 'counter_ag_name_json_populate': "$counter_ag_name_json_populate" "
    fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
    fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
    fnWriteLog ${LINENO} "value of variable 'counter_write_mapping_ag': "$counter_write_mapping_ag" "
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'lc_old_names_sorted_line': "$lc_old_names_sorted_line" "
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "running AWS CLI Autoscaling Group names query for LC name: "$lc_old_names_sorted_line" "
    feed_write_log="$(aws autoscaling describe-auto-scaling-groups --profile "$cli_profile" --query 'AutoScalingGroups[?LaunchConfigurationName=='"\`$lc_old_names_sorted_line\`"'].{asGroupName: AutoScalingGroupName, lcName: LaunchConfigurationName}' > lc-old-name-ag.json  2>&1)"
    #
    # check for errors from the AWS API  
    if [ "$?" -ne 0 ]
    then
        # AWS Error while pulling the AWS Services
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "AWS error message: "
        fnWriteLog ${LINENO} level_0 "$feed_write_log"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
        #
        # set the awserror line number
        error_line_aws="$((${LINENO}-14))"
        #
        # call the AWS error handler
        fnErrorAws
        #
    fi # end AWS error check
    #
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "contents of file 'lc-old-name-ag.json':"
    feed_write_log="$(cat lc-old-name-ag.json 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "putting the JSON results into a plain text list"
    feed_write_log="$(cat lc-old-name-ag.json | jq .[] | jq -r .asGroupName > lc-ag-name-list.txt 2>&1)" 
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    # 
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #  
    fnWriteLog ${LINENO} "contents of file 'lc-ag-name-list.txt':"
    feed_write_log="$(cat lc-ag-name-list.txt 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log" 
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "putting the JSON results into a sorted plain text list"
    feed_write_log="$(sort -u lc-ag-name-list.txt > lc-ag-name-list-sorted.txt 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "contents of file 'lc-ag-name-list-sorted.txt':"
    feed_write_log="$(cat lc-ag-name-list-sorted.txt 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "testing for empty set"
    count_lc_ag_name="$(cat lc-ag-name-list-sorted.txt | wc -l )"
    fnWriteLog ${LINENO} "value of variable 'count_lc_ag_name': "$count_lc_ag_name" "
    fnWriteLog ${LINENO} ""
    if [[ count_lc_ag_name -eq 0 ]] ;
        then 
            fnWriteLog ${LINENO} "no autoscaling groups found for LC name: "$lc_old_names_sorted_line" " 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "increment the write counter: 'counter_write_mapping_ag'"
            counter_write_mapping_ag="$((counter_write_mapping_ag+1))"
            fnWriteLog ${LINENO} "post-increment value of variable 'counter_write_mapping_ag': "$counter_write_mapping_ag" "
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "processing the next LC name "
            # skip to the next name
            continue
        else
            fnWriteLog ${LINENO} "autoscaling groups found for LC name: "$lc_old_names_sorted_line" "
    fi
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "results of AWS CLI query for Autoscaling Groups associated with LC: "$lc_old_names_sorted_line" "
    feed_write_log="$(cat lc-ag-name-list-sorted.txt 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"  
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "entering 'Autoscaling Group name mapping to JSON file' do loop"
    # uses process substitution to preserve variables 
    # input is at the 'done' line 
    while read -r ag_names_sorted_line
        do
        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} "in 'Autoscaling Group name mapping to JSON file' do loop"
        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "variable values at head of 'Autoscaling Group name mapping to JSON file' do loop - prior to load:"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'lc_old_names_sorted_line': "$lc_old_names_sorted_line" "
        fnWriteLog ${LINENO} "AG name value for load to LC JSON file:  "$ag_names_sorted_line" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'counter_ag_name_json_populate':"$counter_ag_name_json_populate" "
        fnWriteLog ${LINENO} "value of variable 'counter_source_file':"$counter_source_file" "
        fnWriteLog ${LINENO} "value of variable 'counter_target_file':"$counter_target_file" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "source file name: lc-mapping-ag-temp-"$counter_source_file".json"
        fnWriteLog ${LINENO} "output file name: lc-mapping-ag-temp-"$counter_target_file".json"
        #
        fnWriteLog ${LINENO} "initialize output file "
        feed_write_log="$(echo "" >  lc-mapping-ag-temp-"$counter_target_file".json 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "contents of source file: lc-mapping-ag-temp-"$counter_source_file".json"
        feed_write_log="$(cat lc-mapping-ag-temp-"$counter_source_file".json 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""   
        #
        fnWriteLog ${LINENO} "Writing AG name to: lc-mapping-ag-temp-"$counter_target_file".json" 
        feed_write_log="$(cat lc-mapping-ag-temp-"$counter_source_file".json | jq --arg ag_name_jq "$ag_names_sorted_line" --arg lc_old_names_sorted_line_jq "$lc_old_names_sorted_line" '[.mappings[] | if .oldLcName == $lc_old_names_sorted_line_jq then .autoscaleGroups += [$ag_name_jq] else . end]' | jq '. | {mappings: . } ' >> lc-mapping-ag-temp-"$counter_target_file".json 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} "$feed_write_log"
        #   
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "contents of output file: lc-mapping-ag-temp-"$counter_target_file".json"
        feed_write_log="$(cat lc-mapping-ag-temp-"$counter_target_file".json 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "'counter_ag_name_json_populate' do loop counter value prior to increment: "$counter_ag_name_json_populate" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "incrementing 'lc mapping json' do loop counter " 
        counter_ag_name_json_populate="$((counter_ag_name_json_populate+1))"
        counter_source_file="$((counter_source_file+1))"
        counter_target_file="$((counter_target_file+1))"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "variable values at tail of 'Autoscaling Group name mapping to JSON file' do loop - after load and increment:"
        fnWriteLog ${LINENO} "value of variable 'counter_ag_name_json_populate': "$counter_ag_name_json_populate" "
        fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
        fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "'counter_ag_name_json_populate' do loop counter value after increment: "$counter_ag_name_json_populate" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
    done < <(cat lc-ag-name-list-sorted.txt) 
    #
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "done with 'Autoscaling Group name mapping to JSON file' do loop "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "increment the write counter: 'counter_write_mapping_ag'"
counter_write_mapping_ag="$((counter_write_mapping_ag+1))"
fnWriteLog ${LINENO} "post-increment value of variable 'counter_write_mapping_ag': "$counter_write_mapping_ag" "
fnWriteLog ${LINENO} ""
#
done < <(cat lc_old_names_sorted.txt) 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "done with 'process LC old name list to pull AG names' do loop "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "variable values after exit of all load ag names while loops:"
fnWriteLog ${LINENO} "value of variable 'counter_ag_name_json_populate': "$counter_ag_name_json_populate" "
fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "copy results of LC name and AG name load into the 'launch-configs-mapping.json' file"
# use source counter because it's been incremented after the last load
feed_write_log="$(cp -f lc-mapping-ag-temp-"$counter_source_file".json launch-configs-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of file: 'launch-configs-mapping.json' "
feed_write_log="$(cat launch-configs-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "--------------------------- end: write AG names to the file: 'lc-mapping.json' ---------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# populate the 'launch-configs-mapping.json' file with the old LC name ARN  
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------- begin: write old LC name ARN to the file: 'lc-mapping.json' -----------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO} level_0 "Writing the old Launch Configuration name associated ARN to the file: "
fnWriteLog ${LINENO} level_0 " 'lc-mapping.json'..."
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "This task takes a while. Please wait..."
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "initializing the counters"
# decrement the final increment at the end of the final LC name load loop 
counter_lc_name_file="$counter_file"
counter_arn_json_populate=0
counter_source_file="$counter_file"
counter_target_file="$((counter_source_file+1))"
counter_write_mapping_name_old_arn=1
count_write_mapping_name_old_arn="$(cat lc_old_names_sorted.txt | wc -l)"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'counter_lc_name_file': "$counter_lc_name_file" "
fnWriteLog ${LINENO} "value of variable 'counter_arn_json_populate': "$counter_arn_json_populate" "
fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
fnWriteLog ${LINENO} "value of variable 'counter_write_mapping_name_old_arn': "$counter_write_mapping_name_old_arn" "
fnWriteLog ${LINENO} "value of variable 'count_write_mapping_name_old_arn': "$count_write_mapping_name_old_arn" "
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "initializing the files"
#
fnWriteLog ${LINENO} "load the first input data file with the results of the AG name load"

fnWriteLog ${LINENO} "copy file: 'launch-configs-mapping.json' to file: 'lc-mapping.json' "
feed_write_log="$(cp -f -f launch-configs-mapping.json lc-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "initialize the initial temp file"
feed_write_log="$(echo "" >  lc-mapping-arn-temp-1.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of 'lc-mapping.json':"
feed_write_log="$(cat lc-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of 'lc_old_names_sorted.txt':"
feed_write_log="$(cat lc_old_names_sorted.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "populating variable 'lc_old_names_sorted' "
lc_old_names_sorted="$(cat lc_old_names_sorted.txt)"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "value of variable 'counter_arn_json_populate': "
feed_write_log="$(echo "$counter_arn_json_populate" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "load the first input data file with the results of the LC name load"
fnWriteLog ${LINENO} "load the input file #: "$counter_source_file" " 
fnWriteLog ${LINENO} "value of target file name: lc-mapping-arn-temp-"$counter_source_file".json"
feed_write_log="$(cp -f lc-mapping.json lc-mapping-arn-temp-"$counter_source_file".json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of source file: lc-mapping-arn-temp-"$counter_source_file".json"
feed_write_log="$(cat lc-mapping-arn-temp-"$counter_source_file".json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "variable values prior to run:"
fnWriteLog ${LINENO} "value of variable 'counter_arn_json_populate': "$counter_arn_json_populate" "
fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "populating JSON with the ARN associated with the LCs"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "beginning 'process LC old name list to pull ARN' do loop "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
# uses process substitution to preserve variables 
# input is at the 'done' line 
while read -r lc_old_names_sorted_line
    do 
    # display the header    
    fnHeader
    # display the task progress bar
    fnProgressBarTaskDisplay "$counter_write_mapping_name_old_arn" "$count_write_mapping_name_old_arn"
    #
    fnWriteLog ${LINENO} level_0 "Writing the old Launch Configuration name associated ARN to the file: "
    fnWriteLog ${LINENO} level_0 " 'lc-mapping.json'..."
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "This task takes a while. Please wait..."
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 "Processing job "$counter_write_mapping_name_old_arn" of "$count_write_mapping_name_old_arn" "
    fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""   
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} "in 'process LC old name list to pull ARN' do loop"
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "variable values at head of 'pull ARN' do loop: "
    fnWriteLog ${LINENO} "value of variable 'counter_arn_json_populate': "$counter_arn_json_populate" "
    fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
    fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'lc_old_names_sorted_line': "$lc_old_names_sorted_line" "
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "running AWS CLI ARN query for LC name: "$lc_old_names_sorted_line" "
    feed_write_log="$(aws autoscaling describe-launch-configurations --profile "$cli_profile" --query 'LaunchConfigurations[?LaunchConfigurationName=='"\`$lc_old_names_sorted_line\`"'].{arn: LaunchConfigurationARN, lcName: LaunchConfigurationName}' > lc-old-name-arn.json  2>&1)"
    #
    # check for errors from the AWS API  
    if [ "$?" -ne 0 ]
    then
        # AWS Error 
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "AWS error message: "
        fnWriteLog ${LINENO} level_0 "$feed_write_log"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
        #
        # set the awserror line number
        error_line_aws="$((${LINENO}-14))"
        #
        # call the AWS error handler
        fnErrorAws
        #
    fi # end AWS error check
    #
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "contents of file 'lc-old-name-arn.json':"
    feed_write_log="$(cat lc-old-name-arn.json 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "putting the JSON results into a plain text list"
    feed_write_log="$(cat lc-old-name-arn.json | jq .[] | jq -r .arn > lc-arn-list.txt 2>&1)"  
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #    
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #  
    fnWriteLog ${LINENO} "contents of file 'lc-arn-list.txt':"
    feed_write_log="$(cat lc-arn-list.txt 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log" 
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "putting the JSON results into a sorted plain text list"
    feed_write_log="$(sort -u lc-arn-list.txt > lc-arn-list-sorted.txt 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "contents of file 'lc-arn-list-sorted.txt':"
    feed_write_log="$(cat lc-arn-list-sorted.txt 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "testing for empty set"
    count_lc_arn="$(cat lc-arn-list-sorted.txt | wc -l )"
    fnWriteLog ${LINENO} "value of variable 'count_lc_arn': "$count_lc_arn" "
    fnWriteLog ${LINENO} ""
    if [[ count_lc_arn -eq 0 ]] ;
        then 
            fnWriteLog ${LINENO} "no ARN found for LC name: "$lc_old_names_sorted_line" " 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "increment the write counter: 'counter_write_mapping_name_old_arn'"
            counter_write_mapping_name_old_arn="$((counter_write_mapping_name_old_arn+1))"
            fnWriteLog ${LINENO} "post-increment value of variable 'counter_write_mapping_name_old_arn': "$counter_write_mapping_name_old_arn" "
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "processing the next LC name "
            # skip to the next name
            continue
        else
            fnWriteLog ${LINENO} "ARN found for LC name: "$lc_old_names_sorted_line" "
    fi
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "results of AWS CLI query for ARN associated with LC: "$lc_old_names_sorted_line" "
    feed_write_log="$(cat lc-arn-list-sorted.txt 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"  
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "entering 'ARN mapping to JSON file' do loop"
    # uses process substitution to preserve variables 
    # input is at the 'done' line 
    while read -r arns_sorted_line
        do
        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} "in 'ARN mapping to JSON file' do loop"
        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "variable values at head of 'ARN mapping to JSON file' do loop - prior to load:"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'lc_old_names_sorted_line': "$lc_old_names_sorted_line" "
        fnWriteLog ${LINENO} "ARN value for load to LC JSON file: "$arns_sorted_line""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'counter_arn_json_populate': "$counter_arn_json_populate" "
        fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
        fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "source file name: lc-mapping-arn-temp-"$counter_source_file".json"
        fnWriteLog ${LINENO} "output file name: lc-mapping-arn-temp-"$counter_target_file".json"
        #
        fnWriteLog ${LINENO} "initialize output file "
        feed_write_log="$(echo "" >  lc-mapping-arn-temp-"$counter_target_file".json 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "contents of source file: lc-mapping-arn-temp-"$counter_source_file".json"
        feed_write_log="$(cat lc-mapping-arn-temp-"$counter_source_file".json 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""   
        #
        fnWriteLog ${LINENO} "Writing ARN to: lc-mapping-arn-temp-"$counter_target_file".json" 
        feed_write_log="$(cat lc-mapping-arn-temp-"$counter_source_file".json | jq --arg arn_jq "$arns_sorted_line" --arg lc_old_names_sorted_line_jq "$lc_old_names_sorted_line" '[.mappings[] | if .oldLcName == $lc_old_names_sorted_line_jq then .oldLcArn = $arn_jq else . end]' | jq '. | {mappings: . } ' >> lc-mapping-arn-temp-"$counter_target_file".json 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} "$feed_write_log"
        #   
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "contents of output file: lc-mapping-arn-temp-"$counter_target_file".json"
        feed_write_log="$(cat lc-mapping-arn-temp-"$counter_target_file".json 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "'counter_arn_json_populate' do loop counter value prior to increment: "$counter_arn_json_populate" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "incrementing 'lc mapping json' do loop counter " 
        counter_arn_json_populate="$((counter_arn_json_populate+1))"
        counter_source_file="$((counter_source_file+1))"
        counter_target_file="$((counter_target_file+1))"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "variable values at tail of 'ARN mapping to JSON file' do loop - after load and increment:"
        fnWriteLog ${LINENO} "value of variable 'counter_arn_json_populate': "$counter_arn_json_populate" "
        fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
        fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "'counter_arn_json_populate' do loop counter value after increment: "$counter_arn_json_populate" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
    done < <(cat lc-arn-list-sorted.txt) 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "done with 'ARN mapping to JSON file' do loop "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "increment the write counter: 'counter_write_mapping_name_old_arn'"
counter_write_mapping_name_old_arn="$((counter_write_mapping_name_old_arn+1))"
fnWriteLog ${LINENO} "post-increment value of variable 'counter_write_mapping_name_old_arn': "$counter_write_mapping_name_old_arn" "
fnWriteLog ${LINENO} ""
#
done < <(cat lc_old_names_sorted.txt) 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "done with 'process LC old name list to pull ARN' do loop "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "variable values after exit of all load ARN while loops:"
fnWriteLog ${LINENO} "value of variable 'counter_arn_json_populate': "$counter_arn_json_populate" "
fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "copy results of LC name and ARN load into the 'launch-configs-mapping.json' file"
# use source counter because it's been incremented after the last load
feed_write_log="$(cp -f lc-mapping-arn-temp-"$counter_source_file".json launch-configs-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of file: 'launch-configs-mapping.json' "
feed_write_log="$(cat launch-configs-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------- end: write old LC name ARN to the file: 'lc-mapping.json' ------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# populate the old and new AMI IDs and names into the 'launch-configs-mapping.json' file    
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------- begin: write AMI IDs and names to file: 'lc-mapping.json'  ------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------"
fnWriteLog ${LINENO} level_0 "Writing AMI IDs and AMI Names to the file: 'launch-configs-mapping.json'... "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "value of variable 'ami_old_id': "$ami_old_id" "
fnWriteLog ${LINENO} "value of variable 'ami_old_name': "$ami_old_name" "
fnWriteLog ${LINENO} "value of variable 'ami_new_id': "$ami_new_id" "
fnWriteLog ${LINENO} "value of variable 'ami_new_name': "$ami_new_name" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "job input feed:"
feed_write_log="$(cat launch-configs-mapping.json | jq '. | .mappings[] ' 2>&1)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "writing values to file: 'launch-configs-mapping-temp-ami.json' "
feed_write_log="$(cat launch-configs-mapping.json | jq --arg ami_old_id_jq "$ami_old_id" --arg ami_old_name_jq "$ami_old_name" --arg ami_new_id_jq "$ami_new_id" --arg ami_new_name_jq "$ami_new_name" ' . | .mappings[].oldAmiId=$ami_old_id_jq | . | .mappings[].oldAmiName=$ami_old_name_jq | . | .mappings[].newAmiId=$ami_new_id_jq | . | .mappings[].newAmiName=$ami_new_name_jq ' > launch-configs-mapping-temp-ami.json 2>&1)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "Writing the loaded values to the json file: 'launch-configs-mapping.json' "
feed_write_log="$(cp -f launch-configs-mapping-temp-ami.json launch-configs-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of the file: 'launch-configs-mapping.json':"
feed_write_log="$(cat launch-configs-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "------------------------ end: write AMI IDs and names to file: 'lc-mapping.json'  ------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# change the AMI in the LC to the new AMI ID  
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "-------------------- begin: update new AMI IDs in variable: 'lc_target_new_ami_id' -----------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} level_0 "Loading the new AMI ID into the old launch configs..."
lc_target_new_ami_id="$( echo  "$lc_target" | jq --arg ami_new_id_jq "$ami_new_id" '[.[] | .ImageId = $ami_new_id_jq]' )" 
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "old, target LCs loaded with new AMI ID:"
feed_write_log="$(echo "$lc_target_new_ami_id" | jq . 2>&1)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "--------------------- end: update new AMI IDs to variable: 'lc_target_new_ami_id' ------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# add the parameter -s security group    
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "--------- begin: add the parameter -s security group in variable: 'lc_target_add_security_group' ---------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "value of variable 'security_group_add_id': "$security_group_add_id" "
fnWriteLog ${LINENO} ""
if [[ "$security_group_add_id" != "" ]] ;
    then 
        fnWriteLog ${LINENO} "add security group parameter exists "        
        fnWriteLog ${LINENO} level_0 "Loading the new security group into the old launch configs..."
        lc_target_security_group_add="$( echo "$lc_target_new_ami_id" | jq --arg security_group_add_id_jq "$security_group_add_id" '[.[] | .SecurityGroups |= (. + [$security_group_add_id_jq] | unique)]' )"  
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    else
        fnWriteLog ${LINENO} "No add security group parameter "
        lc_target_security_group_add="$( echo "$lc_target_new_ami_id" )"
fi
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "old, target LCs loaded with added security group:"
feed_write_log="$(echo "$lc_target_security_group_add" | jq . 2>&1)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "--------- end: add the parameter -s security group in variable: 'lc_target_add_security_group' ---------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# change the detailed monitoring state 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------- begin: update detailed monitoring state in variable: 'lc_target_monitoring_set' --------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO}  ""
fnWriteLog ${LINENO}  "value of variable 'detailed_monitoring_state': "$detailed_monitoring_state" "
fnWriteLog ${LINENO}  ""
fnWriteLog ${LINENO}  ""
fnWriteLog ${LINENO}  "monitoring state -m value test for true or false "
fnWriteLog ${LINENO}  ""
if [[ "$detailed_monitoring_state" == "t" || "$detailed_monitoring_state" == "f" ]] 
    then
        fnWriteLog ${LINENO}  ""
        fnWriteLog ${LINENO}  "in monitoring state change"
        fnWriteLog ${LINENO}  ""
        fnWriteLog ${LINENO}  "----------------------------------------------------------"
        #
        fnWriteLog ${LINENO}  "JSON feed into monitoring state change"
        fnWriteLog ${LINENO}  ""
        feed_write_log="$(echo "$lc_target_new_ami_id" | jq .[] 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO}  "----------------------------------------------------------"
        fnWriteLog ${LINENO}  ""
        fnWriteLog ${LINENO}  "--------------------------------------------------------------------------------------"
        #
        fnWriteLog ${LINENO} level_0 "Setting the Detailed Monitoring state..."
        # test for the state and set the boolean value via jq 
        if [[ "$detailed_monitoring_state" == "t" ]] 
            then 
                lc_target_monitoring_set="$( echo "$lc_target_security_group_add" | jq '[.[] | .InstanceMonitoring.Enabled = true ]' )" 
                #
                # check for command / pipeline error(s)
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                #
                fi
                #
        elif [[ "$detailed_monitoring_state" == "f" ]] 
            then     
                lc_target_monitoring_set="$( echo "$lc_target_security_group_add" | jq '[.[] | .InstanceMonitoring.Enabled = false ]' )" 
                #
                # check for command / pipeline error(s)
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                #
                fi
                #
        else
            # this outcome should not logically be possible - this code is here as a failsafe
            # if no valid -m parameter, then set the variable to the prior section's output
            lc_target_monitoring_set="$lc_target_security_group_add"    
        fi     
        fnWriteLog ${LINENO}  "--------------------------------------------------------------------------------------"
        fnWriteLog ${LINENO}  ""
        fnWriteLog ${LINENO}  ""
        fnWriteLog ${LINENO}  "----------------------------------------------------------"
        #
        fnWriteLog ${LINENO}  "old, target LCs loaded with desired Monitoring state:"
        feed_write_log="$(echo "$lc_target_monitoring_set" | jq . 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO}  "----------------------------------------------------------"
        fnWriteLog ${LINENO}  ""
        fnWriteLog ${LINENO}  ""
    else
        # if no valid -m parameter, then set the variable to the prior section's output
        lc_target_monitoring_set="$lc_target_new_ami_id"
fi
#
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "------------ end: update detailed monitoring state to variable: 'lc_target_monitoring_set' ---------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# Append the text to the LC names    
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "------------- begin: write append text on LC name to file: 'lc_target_appended_text.json' ----------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO}  ""
fnWriteLog ${LINENO} level_0 "Appending the text to the Launch Configuration names... "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "pipe LCs loaded with new AMI ID through sed to add the append text"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "-----------------------------------------------------------------------"
fnWriteLog ${LINENO} "-----------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "load the lc_array variable with the LCs"
lc_array="$(echo "$lc_target_monitoring_set" | jq .)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "value of lc_array raw - prior to counts:"
feed_write_log="$(echo "$lc_array" | jq .[] 2>&1)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "value of lc_array piped through jq - prior to counts:"
feed_write_log="$(echo "$lc_array" | jq . 2>&1)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "load the counts"
#
# count the launch configurations
count_lc_names="$(echo "$lc_array" | jq . | sed -n "/LaunchConfigurationName.*$/p" | wc -l)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
#
# count the LCs with a version in the format of vN* where N is any number of digits 
# count -vN
count_ver="$(echo "$lc_array" | jq . | sed -n "/LaunchConfigurationName.*\(\b\|_\|-\)v[0-9]*\(\b\|_\|-\).*$/p" | wc -l)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
#
# count the LCs with a YYYY in the form of _YYYY_ or -YYYY-, leading and trailing spaces are also supported
# count -YYYY-
count_year="$(echo "$lc_array" | jq . | sed -n "/LaunchConfigurationName.*\(\b\|_\|-\)20[0-9][0-9]\(\b\|_\|-\).*$/p" | wc -l)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
#
# # count the lines in the data set for the counter
count_data_lines="$(echo "$lc_array" | jq . | grep -c '.*' )"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
#
# load the counters
counter_name_append_loop=1
counter_count_lc_append_name="$count_lc_names"
# subtract 1 to adjust for jq 0 start for index
count_lc_append_name_index="$((count_lc_names-1))"
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "Count of LCs is: "$count_lc_names" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "jq array index is: "$count_lc_append_name_index" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "LCs with version vN is: "$count_ver" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "LCs with YYYY is: "$count_year" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "count of lines in the data set is: "$count_data_lines" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "initialize the data file"
feed_write_log="$(echo "[ " >  lc_target_appended_text.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "process the LC JSON array and append the text on the name"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "contents of file: 'lc_old_names_sorted.txt'"
feed_write_log="$(cat lc_old_names_sorted.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "entering the while loop for updating the LC name "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "------------------------ begin 'while loop for append LC name' ------------------------"  
fnWriteLog ${LINENO} ""
while read -r lc_name_old_line
do
    fnWriteLog ${LINENO} "------------------------ head: 'loop append LC name' ------------------------"  
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------- begin section: 'append LC name' ------------------------"  
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "------------------------------------------------------------------------------------------------"
    # display the header    
    fnHeader
    # display the task progress bar
    fnProgressBarTaskDisplay "$counter_name_append_loop" "$count_lc_names"
    #
    fnWriteLog ${LINENO} level_0 "Update Launch Configuration name progress: "$counter_name_append_loop" of "$count_lc_names" "
    fnWriteLog ${LINENO} "------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "loading the line match test counts:" 
    # load the loop var and year count variables
    count_name_line="$(echo "$lc_name_old_line" | sed -n '/.*$/p' | wc -l)"
    count_ver_line="$(echo "$lc_name_old_line" | sed -n '/.*\(\b\|_\|-\)v[0-9]*\(\b\|_\|-\).*$/p' | wc -l)"
    count_year_line="$(echo "$lc_name_old_line" | sed -n '/.*\(\b\|_\|-\)20[0-9][0-9]\(\b\|_\|-\).*$/p' | wc -l)"
    fnWriteLog ${LINENO} "count_name_line value: "$count_name_line" " 
    fnWriteLog ${LINENO} "count_ver_line value: "$count_ver_line" " 
    fnWriteLog ${LINENO} "count_year_line value: "$count_year_line" "
    #
    # test for LC name line 
    if [[ count_name_line -eq 1  ]] ;
        then
            fnWriteLog ${LINENO} "in LC name line"
            # load the old LC name into the variable for populating the old LC name into the mapping json 
            lc_name_old="$lc_name_old_line"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of variable 'lc_name_old_line': "$lc_name_old_line""
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of variable 'lc_name_old': "$lc_name_old" "
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of variable 'lc_name_append_string_clean': "$lc_name_append_string_clean" "
            fnWriteLog ${LINENO} ""
            # test for version -vN
            if [[ count_ver_line -eq 1 ]] ; 
                then
                    fnWriteLog ${LINENO} "in version append"
                    fnWriteLog ${LINENO} "source line:"
                    fnWriteLog ${LINENO} "value of variable 'lc_name_old_line': "$lc_name_old_line""
                    #
                    # -vNNNN- version number append  
                    #
                    fnWriteLog ${LINENO} "appended line written to JSON mapping file:"
                    feed_write_log="$(echo "$lc_name_old_line" | sed "s/\(.*\(\b\|_\|-\)\)v[0-9].*\(\b\|_\|-\).*$/\1"$lc_name_append_string_clean"\",/" 2>&1)"
                    fnWriteLog ${LINENO} "$feed_write_log"
                    #
                    fnWriteLog ${LINENO} "loading LC name new variable"
                    lc_name_new="$(echo "$lc_name_old_line" | sed "s/\(.*\(\b\|_\|-\)\)v[0-9].*\(\b\|_\|-\).*$/\1"$lc_name_append_string_clean"\",/")"         
                    #
                    fnWriteLog ${LINENO} "stripping LC name new variable"
                    lc_name_new_stripped="$(echo "$lc_name_new" | tr -d '\",' )"
                    #
                    fnWriteLog ${LINENO} "value of variable 'lc_name_new': "$lc_name_new" "
                    fnWriteLog ${LINENO} ""        
                    #
                    fnWriteLog ${LINENO} "-vNNNN- version number append - appended LC name line written to Launch Configuration: "
                    fnWriteLog ${LINENO} "value of variable 'lc_name_new_stripped': "$lc_name_new_stripped" "
                    fnWriteLog ${LINENO} ""        
                        #
                    # update the LC name with "$lc_name_new_stripped"
                    fnUpdateLcName  
                    # write the new LC name formatted for JSON to the mapping JSON file    
                    fnLCNameNewWrite "$lc_name_new"
                    #
                else 
                    # test for YYYY
                    if [[ count_year_line -eq 1 ]] ; 
                        then
                            fnWriteLog ${LINENO} "in year append"
                            fnWriteLog ${LINENO} "source line:"
                            fnWriteLog ${LINENO} "value of variable 'lc_name_old_line': "$lc_name_old_line""
                            #
                            # -YYYY- year append  
                            #
                            fnWriteLog ${LINENO} "appended line written to file:"            
                            feed_write_log="$(echo "$lc_name_old_line" | sed 's/\(.*\(\b\|_\|-\)\)20[0-9][0-9]\(\b\|_\|-\).*$/\1'"$lc_name_append_string_clean"'\",/' 2>&1)"
                            fnWriteLog ${LINENO} "$feed_write_log"
                            #
                            fnWriteLog ${LINENO} "loading LC name new variable"
                            lc_name_new="$(echo "$lc_name_old_line" | sed 's/\(.*\(\b\|_\|-\)\)20[0-9][0-9]\(\b\|_\|-\).*$/\1'"$lc_name_append_string_clean"'\",/')"          
                            #
                            fnWriteLog ${LINENO} "stripping LC name new variable"
                            lc_name_new_stripped="$(echo "$lc_name_new" | tr -d '\",' )"
                            #
                            fnWriteLog ${LINENO} "value of variable 'lc_name_new': "$lc_name_new" "
                            fnWriteLog ${LINENO} ""        
                            #
                            fnWriteLog ${LINENO} "-YYYY- year append - appended LC name line written to Launch Configuration: "
                            fnWriteLog ${LINENO} "value of variable 'lc_name_new_stripped': "$lc_name_new_stripped" "
                            fnWriteLog ${LINENO} ""        
                            #
                            #
                            # update the LC name with "$lc_name_new_stripped"
                            fnUpdateLcName  
                            # write the new LC name formatted for JSON to the mapping JSON file    
                            fnLCNameNewWrite "$lc_name_new"
                            #
                        else
                                fnWriteLog ${LINENO} "in no ver & no year append" 
                                fnWriteLog ${LINENO} "source line:"
                                fnWriteLog ${LINENO} "value of variable 'lc_name_old_line': "$lc_name_old_line""
                                # there are no -vN version numbers and no -YYYY-
                                # so remove the last two characters ( ", ) and then append the text onto the the existing name
                                # note that the leading dash on the appended text is prepended to the appended text as it does not exist on the tail of the original text
                                #
                                fnWriteLog ${LINENO} "appended line written to file:"
                                feed_write_log="$(echo "$lc_name_old_line" | sed 's/..$//' | sed "s/\(.*\)$/\1-"$lc_name_append_string_clean"\",/"  2>&1)"
                                fnWriteLog ${LINENO} "$feed_write_log"
                                #
                                fnWriteLog ${LINENO} "loading LC name new variable"
                                lc_name_new="$(echo "$lc_name_old_line" | sed 's/..$//' | sed "s/\(.*\)$/\1-"$lc_name_append_string_clean"\",/")"
                                #
                                fnWriteLog ${LINENO} "stripping LC name new variable"
                                lc_name_new_stripped="$(echo "$lc_name_new" | tr -d '\",' )"
                                #
                                fnWriteLog ${LINENO} "value of variable 'lc_name_new': "$lc_name_new" "
                                fnWriteLog ${LINENO} ""        
                                #
                                fnWriteLog ${LINENO} "no -vN version numbers and no -YYYY- - appended LC name line written to Launch Configuration: "
                                fnWriteLog ${LINENO} "value of variable 'lc_name_new_stripped': "$lc_name_new_stripped" "
                                fnWriteLog ${LINENO} ""        
                                #
                                    #
                                # update the LC name with "$lc_name_new_stripped"
                                fnUpdateLcName  
                                # write the new LC name formatted for JSON to the mapping JSON file    
                                fnLCNameNewWrite "$lc_name_new"
                                #
                            fi
                fi     
    fi
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "incrementing & decrementing the counters"
counter_name_append_loop="$(($counter_name_append_loop + 1))"
counter_count_lc_append_name="$(($counter_count_lc_append_name - 1))"
count_lc_append_name_index="$(($count_lc_append_name_index - 1))"
#
fnWriteLog ${LINENO} "----------------------- end section: 'append LC name ' ------------------------"  
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "------------------------ tail: 'loop append LC name' ------------------------"  
fnWriteLog ${LINENO} ""
# 
#
done< <(cat lc_old_names_sorted.txt)
#
#
fnWriteLog ${LINENO} "close out the data file"
feed_write_log="$(echo " ]" >>  lc_target_appended_text.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "------------------------ end 'while loop for append LC name' ------------------------"  
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of file: 'lc_target_appended_text.json' "
feed_write_log="$(cat lc_target_appended_text.json  2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "Cleaning file of non-ascii characters"
feed_write_log="$(cat lc_target_appended_text.json | tr -cd '\11\12\15\40-\176' > lc_target_appended_text_clean.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "target LCs with cleaned appended text"
feed_write_log="$(cat lc_target_appended_text_clean.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "loading variable 'lc_target_appended_text variable' from work file: 'lc_target_appended_text_clean.json' "
lc_target_appended_text="$(cat lc_target_appended_text_clean.json)"
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} "-------------- end: write append text on LC name to file: 'lc_target_appended_text.json' -----------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# Check and make unique any duplicate LC names created through the append text process    
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------- begin: check for duplicate LC names -----------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
#
fnWriteLog ${LINENO} level_0 "Checking for duplicate Launch Configuration names created by text append "
fnWriteLog ${LINENO} "Pulling LC names"
fnWriteLog ${LINENO} "putting results into text file for jq processing"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "creating file: 'lc_target_appended_text.json' "
feed_write_log="$(echo "$lc_target_appended_text" > lc_target_appended_text.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
#
fnWriteLog ${LINENO} "creating file: 'lc_target_appended_text_names.txt' "
feed_write_log="$(cat lc_target_appended_text.json | jq -r '.[].LaunchConfigurationName' > lc_target_appended_text_names.txt 2>&1)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "loading 'lc_name_list_raw' variable"
lc_name_list_raw="$(cat lc_target_appended_text_names.txt )"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "value of the variable 'lc_name_list_raw': "
feed_write_log="$(echo "$lc_name_list_raw" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "sort file: 'lc_target_appended_text_names.txt'"
fnWriteLog ${LINENO} "create file: 'lc_target_appended_text_names_sorted.txt' "
feed_write_log="$(sort lc_target_appended_text_names.txt > lc_target_appended_text_names_sorted.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of file: 'lc_target_appended_text_names_sorted.txt':"
feed_write_log="$(cat lc_target_appended_text_names_sorted.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
# 
fnWriteLog ${LINENO} "counting resulting LC names"
fnWriteLog ${LINENO} "loading variable 'count_lc_name_list_raw' "
count_lc_name_list_raw="$(cat lc_target_appended_text_names_sorted.txt | wc -l )"
fnWriteLog ${LINENO} "value of variable 'count_lc_name_list_raw': "$count_lc_name_list_raw" "
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "counting unique resulting LC names"
fnWriteLog ${LINENO} "loading variable 'count_lc_name_list_raw_unique' "
count_lc_name_list_raw_unique="$(cat lc_target_appended_text_names_sorted.txt | sort -u | wc -l )"
fnWriteLog ${LINENO}  "value of variable 'count_lc_name_list_raw_unique': "$count_lc_name_list_raw_unique" "
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "calculating the number of duplicated names"
fnWriteLog ${LINENO} "loading variable 'count_lc_name_list_raw_duplicated' "
count_lc_name_list_raw_duplicated="$(( count_lc_name_list_raw - count_lc_name_list_raw_unique ))"
fnWriteLog ${LINENO}  "value of variable 'count_lc_name_list_raw_duplicated': "$count_lc_name_list_raw_duplicated" "
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "create text file: 'lc_name_list_duplicated_names.txt'"
# do not quote the variable in the awk command below
feed_write_log="$(cat lc_target_appended_text_names_sorted.txt | uniq -c | awk '$1 > 1 { print $2 }' > lc_name_list_duplicated_names.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "loading variable: 'lc_name_list_duplicated_names' "
lc_name_list_duplicated_names="$(cat lc_name_list_duplicated_names.txt)"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'lc_name_list_duplicated_names':"
feed_write_log="$(echo "$lc_name_list_duplicated_names" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of text file 'lc_name_list_duplicated_names.txt'"
feed_write_log="$(cat lc_name_list_duplicated_names.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "create text file: 'lc_name_list_duplicated_names_sorted.txt'"
feed_write_log="$(cat lc_name_list_duplicated_names.txt | sort > lc_name_list_duplicated_names_sorted.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "contents of text file 'lc_name_list_duplicated_names_sorted.txt'"
feed_write_log="$(cat lc_name_list_duplicated_names_sorted.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
#
fnWriteLog ${LINENO} "loading variable: 'count_lc_name_list_duplicated_names_sorted' "
count_lc_name_list_duplicated_names_sorted="$(cat lc_name_list_duplicated_names_sorted.txt | wc -l)"
fnWriteLog ${LINENO} "value of variable 'count_lc_name_list_duplicated_names_sorted': "$count_lc_name_list_duplicated_names_sorted" "
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} "----------------------------------- end: check for duplicate LC names ------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""




#
##########################################################################
#
#
# if duplicate LC names, then change their names to make them unique
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "--------------------------------- begin: make duplicate LC names unique ----------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
#
fnWriteLog ${LINENO} "load the duplicate LC name count for the logic check "
count_lc_duplicate_names="$count_lc_name_list_raw_duplicated"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "value of variable: 'count_lc_duplicate_names': "$count_lc_duplicate_names" "
fnWriteLog ${LINENO} ""
if (( count_lc_duplicate_names > 0)) 
    then
        fnHeader
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 " >> There are "$count_lc_duplicate_names" duplicate Launch Configuration names created by text append <<"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 " The Launch Configuration names must be unique to create the updated LCs in AWS"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "------------------ changing duplicate LC names to make unique ------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "----------------------------------------------------------"
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "reset the counters for the duplicate LC names loops "
        # arn job progress counter
        counter_arn=1
        # dedupe job progress counter 
        counter_name_unique_loop=1
        # dedupe unique LC name suffix counter  
        # used to create a unique LC name 
        counter_name_unique_append=1
        # total dedupe job count 
        count_lc_target_appended_text_names_sorted="$(cat lc_target_appended_text_names_sorted.txt | wc -l )"
        # total dedupe job counter
        counter_lc_target_appended_text_names_sorted=1
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "----------------------------------------------------------"
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "initialize the unique lc name loop data file: 'lc_name_unique_text.json' "
        fnWriteLog ${LINENO} "echo '[ ' to file: 'lc_name_unique_text.json' "
        feed_write_log="$(echo "[ " >  lc_name_unique_text.json 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "----------------------------------------------------------"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "Count of LC duplicate names to process:"
        feed_write_log="$(echo "$count_lc_duplicate_names" 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "---------------------------------------------------------------"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "process the new LC names and make the duplicate names unique"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "---------------------------------------------------------------"
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "creating text file: 'lc_target_appended_text_arn.txt'"
        feed_write_log="$(cat lc_target_appended_text.json | jq .[] | jq -r ' .LaunchConfigurationARN' > lc_target_appended_text_arn.txt 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} "$feed_write_log"
        #
        fnWriteLog ${LINENO} "contents of file: 'lc_target_appended_text_arn.txt':"
        feed_write_log="$(cat lc_target_appended_text_arn.txt 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        #
        fnWriteLog ${LINENO} "sort file: 'lc_target_appended_text_arn.txt'"
        fnWriteLog ${LINENO} "create file: 'lc_target_appended_text_arn_sorted.txt' "
        feed_write_log="$(sort lc_target_appended_text_arn.txt > lc_target_appended_text_arn_sorted.txt 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "contents of file: 'lc_target_appended_text_arn_sorted.txt':"
        feed_write_log="$(cat lc_target_appended_text_arn_sorted.txt 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        # 
        fnWriteLog ${LINENO} "loading variable 'count_lc_target_appended_text_arn_sorted'"
        count_lc_target_appended_text_arn_sorted="$(cat lc_target_appended_text_arn_sorted.txt | wc -l )"
        fnWriteLog ${LINENO} "count of resulting LC arn: "$count_lc_target_appended_text_arn_sorted"  "
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "resetting arn counter"
        counter_arn=1
        #
        #
        fnWriteLog ${LINENO} "----------------- entering loop: lc_target_appended_text_arn_sorted ----------------------"
        # for each duplicate name, read each ARN and create a new, unique LC name
        #
        #
        # uses process substitution to preserve variables 
        # input is at the 'done' line 
        while read -r lc_arn_line 
        do
            fnWriteLog ${LINENO} "----------------- loop head: lc_target_appended_text_arn_sorted ----------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "in loop: lc_target_appended_text_arn_sorted "
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "post-increment value of variable 'counter_arn': "$counter_arn"  " 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of variable 'lc_arn_line': "$lc_arn_line" "
            fnWriteLog ${LINENO} ""
            #
            #
            #
            #
            fnHeader
            fnWriteLog ${LINENO} "-----------------------------------------------------------------------------------------"
            fnWriteLog ${LINENO} "" 
            fnWriteLog ${LINENO} level_0 "Launch Configuration ARNs job progress: "$counter_arn" of "$count_lc_target_appended_text_arn_sorted" "
            fnWriteLog ${LINENO} level_0 "" 
            fnWriteLog ${LINENO} "" 
            fnWriteLog ${LINENO} "Processing appended text new LC name: "$lc_target_appended_text_names_sorted_line"  " 
            fnWriteLog ${LINENO} "" 
            fnWriteLog ${LINENO} "" 
            # check for previous loop
            if [[ "$counter_arn" -gt 1 ]] ;
                then
                    # create an incremental version of the file for debug
                    cp lc_name_unique_text.json lc_name_unique_text_"$counter_arn".json
            fi 
            #
            fnWriteLog ${LINENO} "reset the dedupe name counter to 1 for loop: 'lc_name_list_duplicated_names_sorted'"
            # used to count the dedupe name job progress within its loop  
            counter_name_unique_loop=1
            fnWriteLog ${LINENO} "value of variable 'counter_name_unique_loop': "$counter_name_unique_loop" " 
            fnWriteLog ${LINENO} "" 
           #
            # set the LC name for the loop
            # pull the LC name  for the ARN  
            fnWriteLog ${LINENO} "pulling the LC name for the ARN from variable 'lc_target_appended_text'"
            fnWriteLog ${LINENO} "loading variable 'lc_target_appended_text_names_sorted_line'  "            
            lc_target_appended_text_names_sorted_line="$(echo "$lc_target_appended_text" | jq -r --arg lc_arn_line_jq "$lc_arn_line" ' .[] | select(.LaunchConfigurationARN==$lc_arn_line_jq) | .LaunchConfigurationName '  2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            #
            fnWriteLog ${LINENO} "value of variable 'lc_target_appended_text_names_sorted_line':"
            fnWriteLog ${LINENO} "$lc_target_appended_text_names_sorted_line "
            fnWriteLog ${LINENO} ""
            #
            # reset the dupe name write flag
            lc_duplicate_name_write=""
            fnWriteLog ${LINENO} "value of variable 'lc_duplicate_name_write': "$lc_duplicate_name_write" " 
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} "---------- begin loop: lc_name_list_duplicated_names_sorted ---------------------"
            fnWriteLog ${LINENO} ""
            #
            while read -r lc_name_list_duplicated_names_sorted_line 
            do
                fnWriteLog ${LINENO} "-------------------- loop head: lc_name_list_duplicated_names_sorted -------------------"
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "duplicate name - value of variable 'lc_name_list_duplicated_names_sorted_line':"
                fnWriteLog ${LINENO} "$lc_name_list_duplicated_names_sorted_line"
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "new LC name - value of variable 'lc_target_appended_text_names_sorted_line':"
                fnWriteLog ${LINENO} "$lc_target_appended_text_names_sorted_line"
                fnWriteLog ${LINENO} ""
                # display the header    
                fnHeader
                # display the task progress bar
                fnProgressBarTaskDisplay "$counter_arn" "$count_lc_target_appended_text_arn_sorted"
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} level_0 "" 
                fnWriteLog ${LINENO} level_0 "Processing ARN: "
                fnWriteLog ${LINENO} level_0 "$lc_arn_line"      
                fnWriteLog ${LINENO} level_0  ""    
                fnWriteLog ${LINENO} level_0 "Processing launch configuration name: "
                fnWriteLog ${LINENO} level_0 "  "$lc_target_appended_text_names_sorted_line" " 
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "Checking for duplicate name: "
                fnWriteLog ${LINENO} level_0 "  "$lc_name_list_duplicated_names_sorted_line" " 
                fnWriteLog ${LINENO} level_0 "" 
                fnWriteLog ${LINENO} level_0 ""    
                fnWriteLog ${LINENO} level_0 "This task takes a long time. Please wait..."
                fnWriteLog ${LINENO} level_0 ""         
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 "Launch Configuration ARNs job progress: "$counter_arn" of "$count_lc_target_appended_text_arn_sorted" "
                fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------------------------"
                fnWriteLog ${LINENO} level_0 "Duplicate names job progress: "$counter_name_unique_loop" of "$count_lc_name_list_duplicated_names_sorted" "
                fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------------------------"  
                fnWriteLog ${LINENO} level_0 ""   
                #
                #                 
                fnWriteLog ${LINENO} " -- entering duplicate name -- "
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} ""
                #
                fnWriteLog ${LINENO} "loading the line match test counts:" 
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "resetting to 0 the counter variable 'count_lc_name_dup_line'  " 
                count_lc_name_dup_line=0                                                      
                fnWriteLog ${LINENO} "value of variable 'count_lc_name_dup_line': "$count_lc_name_dup_line" "
                fnWriteLog ${LINENO} "" 
                fnWriteLog ${LINENO} "checking for match between duplicate name and new LC name "                                           
                fnWriteLog ${LINENO} "$lc_name_list_duplicated_names_sorted_line"                
                fnWriteLog ${LINENO} "$lc_target_appended_text_names_sorted_line"
                fnWriteLog ${LINENO} ""
                count_lc_name_dup_line="$(echo "$lc_name_list_duplicated_names_sorted_line" | sed -n '/.*'"$lc_target_appended_text_names_sorted_line"'.*$/p' | wc -l )"
                fnWriteLog ${LINENO} "count of 1 = a match "
                fnWriteLog ${LINENO} "value of variable 'count_lc_name_dup_line': "$count_lc_name_dup_line" "
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'lc_target_appended_text_names_sorted_line': "
                fnWriteLog ${LINENO} "$lc_target_appended_text_names_sorted_line "
                fnWriteLog ${LINENO} "--------------------------------------------------"
                # test for LC name line 
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "---- in LC name line ----"
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'count_name_line': "$count_name_line" "
                fnWriteLog ${LINENO} "value of variable 'count_lc_name_dup_line': "$count_lc_name_dup_line" "
                fnWriteLog ${LINENO} "value of variable 'lc_target_appended_text_names_sorted_line': "$lc_target_appended_text_names_sorted_line" "
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} ""
                # test for duplicate LC name
                if [[ "$count_lc_name_dup_line" -eq 1 ]] 
                    then
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "---- in duplicate LC name line ----"
                        fnWriteLog ${LINENO} ""                                            
                        #
                        fnWriteLog ${LINENO} "value of variable 'count_lc_name_dup_line': "$count_lc_name_dup_line" "  
                        fnWriteLog ${LINENO} ""                                                                                                                                     
                        fnWriteLog ${LINENO} "value of variable 'counter_name_unique_append': "$counter_name_unique_append" "
                        fnWriteLog ${LINENO} ""                                                                                       
                        #
                        fnWriteLog ${LINENO} "original source line:"
                        feed_write_log="$(echo "$lc_target_appended_text_names_sorted_line" 2>&1)"
                        fnWriteLog ${LINENO} "$feed_write_log"
                        #
                        fnWriteLog ${LINENO} "loading LC name new variable: 'lc_name_new_unique' "
                        lc_name_new_unique="$(echo "$lc_target_appended_text_names_sorted_line" | sed 's/\(.*'"$lc_target_appended_text_names_sorted_line"'\).*$/\1-duplicate-name-'"$counter_name_unique_append"'\",/')"          
                        #
                        fnWriteLog ${LINENO} "stripping LC name new variable"
                        lc_name_new_unique_stripped="$(echo "$lc_name_new_unique" | tr -d '\",' )"
                        #
                        fnWriteLog ${LINENO} "deduped - unique LC name line written to Launch Configuration: "
                        fnWriteLog ${LINENO} "value of variable 'lc_name_new_unique_stripped': "$lc_name_new_unique_stripped" "
                        fnWriteLog ${LINENO} ""        
                        #
                        # update the LC name with "$lc_name_new_unique_stripped"
                        fnDedupeLcName "$lc_name_new_unique_stripped" "$lc_arn_line"
                        # write the new LC name formatted for JSON to the mapping JSON file    
                        fnLCNameNewWrite "$lc_name_new_unique_stripped" "$lc_arn_line" "$lc_target_appended_text_names_sorted_line"
                        #
                        fnWriteLog ${LINENO} "set the dupe name write flag to y"
                        lc_duplicate_name_write="y"
                        fnWriteLog ${LINENO} "value of variable 'lc_duplicate_name_write': "$lc_duplicate_name_write" " 
                        #
                        # increment the duplicate name append counter
                        # dedupe unique LC name suffix counter  
                        # used to create a unique LC name 
                        fnWriteLog ${LINENO} "pre-increment value of variable 'counter_name_unique_append': "$counter_name_unique_append" "
                        counter_name_unique_append="$((counter_name_unique_append + 1))"
                        fnWriteLog ${LINENO} "post-increment value of variable 'counter_name_unique_append': "$counter_name_unique_append" "
                        #  
                    else
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "---- duplicate LC name test failed ----"
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "value of variable 'count_lc_name_dup_line': "$count_lc_name_dup_line" "  
                        fnWriteLog ${LINENO} "getting the next duplicate name to test "
                        fnWriteLog ${LINENO} ""                                                                    
                fi                                    
                #
            # increment the dedupe loop counter  
            fnWriteLog ${LINENO} "" 
            fnWriteLog ${LINENO} "pre-increment value of variable 'counter_name_unique_loop': "$counter_name_unique_loop" "
            fnWriteLog ${LINENO} "increment the counter 'counter_name_unique_loop'"
            counter_name_unique_loop="$((counter_name_unique_loop + 1))"
            fnWriteLog ${LINENO} "post-increment value of variable 'counter_name_unique_loop': "$counter_name_unique_loop" "
            fnWriteLog ${LINENO} ""                                                                                                                                     

            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "-------------------- loop tail: lc_name_list_duplicated_names_sorted -------------------"


            done< <(cat lc_name_list_duplicated_names_sorted.txt)
            #
            fnWriteLog ${LINENO} "---------- done with loop: lc_name_list_duplicated_names_sorted ---------------------"
            fnWriteLog ${LINENO} ""
            #
            if [[ "$lc_duplicate_name_write" == "" ]] ;
                then 
                    fnWriteLog ${LINENO} "---- not a duplicate name ---- "
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "value of variable 'lc_duplicate_name_write': "$lc_duplicate_name_write" "
                    fnWriteLog ${LINENO} ""                   
                    fnWriteLog ${LINENO} "appending the non-duplicate name LC object to the output json "
                    fnWriteLog ${LINENO} "-- calling function 'fnDedupeLcName' for non-duplicate write -- "
                    fnDedupeLcName "$lc_target_appended_text_names_sorted_line" "$lc_arn_line"  
                    fnWriteLog ${LINENO} "-- returned from calling function 'fnDedupeLcName' for non-duplicate write -- "
                    fnWriteLog ${LINENO} ""
            fi
            #
            #
            fnWriteLog ${LINENO} "pre-increment value of variable 'counter_arn': "$counter_arn"  " 
            fnWriteLog ${LINENO} "incrementing the 'counter_arn' counter"
            counter_arn="$(($counter_arn + 1))"
            fnWriteLog ${LINENO} "post-increment value of variable 'counter_arn': "$counter_arn"  " 
            #
            fnWriteLog ${LINENO} "----------------- loop tail: lc_target_appended_text_arn_sorted ----------------------"
            #
        #
        done< <(cat lc_target_appended_text_arn_sorted.txt)
    #
    fnWriteLog ${LINENO} "----------------- done with loop: lc_target_appended_text_arn_sorted ----------------------"
    #
    #
    fnWriteLog ${LINENO} "close out the unique lc name loop data file: 'lc_name_unique_text.json' "
    feed_write_log="$(echo " ]" >> lc_name_unique_text.json 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} level_0 "Removing non-ascii characters from file: 'lc_name_unique_text_clean.json' "
    feed_write_log="$(cat lc_name_unique_text.json | tr -cd '\11\12\15\40-\176' > lc_name_unique_text_clean.json 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "loading 'lc_name_unique_text_clean' variable from 'lc_name_unique_text_clean.json' file"
    lc_name_unique_text_clean="$(cat lc_name_unique_text_clean.json)"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "deduped name LCs text raw"
    fnWriteLog ${LINENO} "value of variable 'lc_name_unique_text_clean': " 
    fnWriteLog ${LINENO} "$lc_name_unique_text_clean"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "deduped name LCs text piped through jq"
    fnWriteLog ${LINENO} "command:  $ lc_name_unique_text_clean | jq . "
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #
    fnWriteLog ${LINENO} "$lc_name_unique_text_clean" | jq . 
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------- end change duplicate LC names to make unique ------------------------"
    fnWriteLog ${LINENO} ""
else
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "-- in no duplicate LC names -- " 
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "value of variable 'lc_target_appended_text': "
    fnWriteLog ${LINENO} "command: $ lc_target_appended_text | jq . :"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #
    fnWriteLog ${LINENO} "$lc_target_appended_text" | jq .
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "move the appended names from the prior section into the staging data set "
    fnWriteLog ${LINENO} "command:  lc_name_unique_text_clean= $ (echo $ lc_target_appended_text | jq .) "
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #
    lc_name_unique_text_clean="$(echo "$lc_target_appended_text" | jq .)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
    #
    fi
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " >> There are "$count_lc_duplicate_names" duplicate Launch Configuration names created by text append <<"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " No need to de-duplicate names "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} ""
fi
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} "---------------------------------- end: make duplicate LC names unique -----------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
#
##########################################################################
#
#
# Sanity Check: check the row counts of the original data set vs post-processed data set     
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------- begin: check row counts ----------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} level_0 "Checking the line counts for the pre- and post-update LCs JSON "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'lc_name_unique_text_clean':"
fnWriteLog ${LINENO} "$lc_name_unique_text_clean "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "count the lines in the 'post-lc-name-update' data set"
fnWriteLog ${LINENO} "loading variable: 'count_post_lc_name_update_lines' "
count_post_lc_name_update_lines="$( echo  "$lc_name_unique_text_clean" | jq . | wc -l )"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} "value of variable 'count_post_lc_name_update_lines': "$count_post_lc_name_update_lines" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "data set line count check"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "target AMI data set line count: "$count_data_lines""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "post LC name update data set line count: "$count_post_lc_name_update_lines" "
fnWriteLog ${LINENO} ""
if (( "$count_post_lc_name_update_lines" != "$count_data_lines" ))
    then
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 " >> Fatal Error <<"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 " The number of lines of data after the LC name update does not match the start data  "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "Value of variable 'count_data_lines': "$count_data_lines" "
        fnWriteLog ${LINENO} level_0 "Value of variable 'count_post_lc_name_update_lines': "$count_post_lc_name_update_lines" "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 ""
        # do not delete the work files so they are available for diagnostics 
        # fnDeleteWorkFiles
        # write the log file
        fnWriteLogFile
        exit 1
    else
        fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 Line count check is OK
        fnWriteLog ${LINENO} level_0 "" 
        fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------"
fi
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "------------------------------------------ end: check row counts -----------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# create the new launch configs with the updated AMIs and Launch Configuration names
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------- begin: create new LCs  -----------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
#
fnWriteLog ${LINENO} "pull the LC names"
feed_write_log="$(echo "$lc_name_unique_text_clean" | jq .[] | jq .LaunchConfigurationName | sort > lc-create-names.txt  2>&1)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "LC names to create"
feed_write_log="$(cat lc-create-names.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
#
fnWriteLog ${LINENO} "set the counters "
counter_lc_create=1
count_lc_create_name="$(cat lc-create-names.txt | grep -c '.*' )" 
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "entering 'creating Launch Configuration' loop "
while read -r lc_create_name 
        do
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "-------------------------------------- head: create new LCs loop -----------------------------------------"
            fnWriteLog ${LINENO} ""
            #
            # display the header    
            fnHeader
            # display the task progress bar
            fnProgressBarTaskDisplay "$counter_lc_create" "$count_lc_create_name"
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "----------------------------------------------------------------"
            fnWriteLog ${LINENO} " creating Launch Configuration "$counter_lc_create" of "$count_lc_create_name" "
            fnWriteLog ${LINENO} "----------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} "Pulling LC JSON for LC name: "$lc_create_name" "
            fnWriteLog ${LINENO} "command output"
            feed_write_log="$(echo "$lc_name_unique_text_clean" | jq '.[] | select(.LaunchConfigurationName=='"$lc_create_name"')' 2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} "loading variable: 'lc_create_json' "
            lc_create_json="$(echo "$lc_name_unique_text_clean" | jq '.[] | select(.LaunchConfigurationName=='"$lc_create_name"')' )"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} "LC JSON for LC name: "$lc_create_name" "  
            feed_write_log="$(echo "$lc_create_json" | jq . 2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} "deleting unused objects"
            lc_create_json_edited_01="$(echo "$lc_create_json" | jq ' del(.LaunchConfigurationARN, .CreatedTime) ')"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} "JSON with deleted objects: lc_create_json_edited_01 "
            feed_write_log="$(echo "$lc_create_json_edited_01" 2>&1)"
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            #
            ##########################################################################
            #
            #  Begin delete unused elements of the LC JSON to enable LC create  
            #
            ##########################################################################
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "deleting zero length objects"
            lc_create_json_edited_02="$(echo "$lc_create_json_edited_01" | jq ' if (.KernelId | length) == 0 then del(.KernelId) else . end ')"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            lc_create_json_edited_03="$(echo "$lc_create_json_edited_02" | jq ' if (.RamdiskId | length) == 0 then del(.RamdiskId) else . end ')"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "deleting BlockDeviceMappings"
            lc_create_json_edited_04="$(echo "$lc_create_json_edited_03" | jq ' del(.BlockDeviceMappings) ')" 
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            #
            fnWriteLog ${LINENO} "JSON with no zero length objects and no BlockDeviceMappings: lc_create_json_edited_04 "
            feed_write_log="$(echo "$lc_create_json_edited_04" 2>&1)"
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} "decoding base64 user data "
            user_data_base64_decode="$(echo "$lc_create_json_edited_04" | jq ' .UserData' | tr -d \" | base64 --decode )"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} "value of variable 'user_data_base64_decode': "
            feed_write_log="$(echo "$user_data_base64_decode" 2>&1)"
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} "loading decoded user data via jq"
            fnWriteLog ${LINENO} "note: using jq --arg here instead of --argjson to force jq to encode the user data text into JSON "
            fnWriteLog ${LINENO} "this is required because the AWS CLI API otherwise rejects the string "
            lc_create_json_edited_05="$(echo "$lc_create_json_edited_04" | jq --arg user_data_base64_decode_jq "$user_data_base64_decode" ' .UserData=$user_data_base64_decode_jq '  )"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "launch configuration create JSON with base64 decoded user data encoded to JSON "
            fnWriteLog ${LINENO} "to pass the AWS CLI parser: value of variable 'lc_create_json_edited_05' "
            fnWriteLog ${LINENO}  "$lc_create_json_edited_05"
            fnWriteLog ${LINENO}  ""
            #
            #
            # >> Note: edit the "$lc_create_json_edited__XX" value here to load the final values into the AWS JSON file <<
            #
            fnWriteLog ${LINENO} "loading the aws json variable 'lc_create_jason_aws'"
            lc_create_json_aws="$(echo "$lc_create_json_edited_05" )"   
            #
            ##########################################################################
            #
            #  End delete unused elements of the LC JSON to enable LC create  
            #
            ##########################################################################
            #
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} "JSON to feed to AWS CLI 'lc_create_json_aws':"
            feed_write_log="$(echo "$lc_create_json_aws" | jq . 2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} "creating LC JSON text file for AWS CLI: 'lc_create_json_aws.json' "
            feed_write_log="$(echo "$lc_create_json_aws" | jq . > lc_create_json_aws.json 2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            #
            #
            # display the header    
            fnHeader
            # display the task progress bar
            fnProgressBarTaskDisplay "$counter_lc_create" "$count_lc_create_name"
            #
            fnWriteLog ${LINENO} "----------------------------------------------------------------"
            fnWriteLog ${LINENO} level_0 "Creating Launch Configuration "$counter_lc_create" of "$count_lc_create_name" "
            fnWriteLog ${LINENO} "----------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "------------------------------------------------------------------------------------------------------------------"
            fnWriteLog ${LINENO} " create begin for Launch Configuration: "$lc_create_name" "
            fnWriteLog ${LINENO} "------------------------------------------------------------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "clear AWS error flag prior to AWS CLI call "
            error_aws_flag=""
            fnWriteLog ${LINENO} "value of variable 'error_aws_flag': "$error_aws_flag"  "
            fnWriteLog ${LINENO} level_0 "Creating Launch Configuration: "$lc_create_name" "
            feed_write_log="$(aws autoscaling create-launch-configuration --profile "$cli_profile" --cli-input-json file://lc_create_json_aws.json 2>&1)"
            #
            # flag the error to handle if the LC already exists
            if [ "$?" -ne 0 ]
                then
                    fnWriteLog ${LINENO} "AWS Error while creating the Launch Configuration " 
                    fnWriteLog ${LINENO} "set AWS error flag to y "
                    error_aws_flag="y"
                    fnWriteLog ${LINENO} "value of variable 'error_aws_flag': "$error_aws_flag"  "
                    fnErrorLog
                    #
                    # check for LC limit exceeded; if so, then terminate as it is a fatal error 
                    fnWriteLog ${LINENO} "checking for 'AWS LC limit exceeded' error "
                    fnWriteLog ${LINENO} "loading variable: 'count_aws_error_lc_limit_exceeded' "                     
                    count_aws_error_lc_limit_exceeded="$(echo "$feed_write_log" | grep -c 'Launch Configuration limit exceeded')"
                    fnWriteLog ${LINENO} "value of variable: 'count_aws_error_lc_limit_exceeded': "$count_aws_error_lc_limit_exceeded" "                     
                    if [[ "$count_aws_error_lc_limit_exceeded" -gt 0 ]]
                        then
                            # AWS Error 
                            fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
                            fnWriteLog ${LINENO} level_0 ""
                            fnWriteLog ${LINENO} level_0 "AWS error message: "
                            fnWriteLog ${LINENO} level_0 "$feed_write_log"
                            fnWriteLog ${LINENO} level_0 ""
                            fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                            #
                            # set the awserror line number
                            error_line_aws="$((${LINENO}-23))"
                            #
                            # call the AWS error handler
                            fnErrorAws
                            #
                    fi # end check for AWS LC limit exceeded error 
             fi # end check for AWS error on LC create
            #
            fnWriteLog ${LINENO} "$feed_write_log"
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "------------------------------------------------------------------------------------------------------------------"
            fnWriteLog ${LINENO} " create complete for Launch Configuration: "$lc_create_name" "
            fnWriteLog ${LINENO} "------------------------------------------------------------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------- begin Delete LC Versions -----------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            #
            ###############################################################################
            # 
            #
            # test for a value in the -d parameter variable 
            # if the -d flag is set, then delete the older LC versions
            # 
            if [[ "$error_aws_flag" != "y" ]]
                then
                    # test for the number of prior versions to delete
                    # if -d parameter is set to more than 0 prior versions, delete them
                    if (( "$lc_versions_delete" > 0 ))
                        then 
                            fnWriteLog ${LINENO}  level_0 ""
                            fnWriteLog ${LINENO}  level_0 "Deleting Launch Configuration versions more than "$lc_versions_delete" prior..."
                            fnWriteLog ${LINENO}  level_0 ""
                            fnWriteLog ${LINENO}  level_0 "This task takes a while. Please wait..."
                            fnWriteLog ${LINENO}  level_0 ""
                            #
                            ###############################################################################
                            # 
                            #
                            # load the version variables
                            #
                            lc_name_version_number="$(echo "$lc_create_name" | sed 's/.*-v\([0-9][0-9]*\).*/\1/' )"
                            lc_name_version_prefix="$(echo "$lc_create_name" | sed 's/\(-v\)[0-9][0-9]*.*/\1/' | tr -d \"  )"
                            #
                            fnWriteLog ${LINENO} ""
                            fnWriteLog ${LINENO} "value of variable 'lc_versions_delete': "$lc_versions_delete" "
                            fnWriteLog ${LINENO} ""
                            fnWriteLog ${LINENO} "value of variable 'lc_create_name': "$lc_create_name" "
                            fnWriteLog ${LINENO} ""
                            fnWriteLog ${LINENO} "value of variable 'lc_name_version_number': "$lc_name_version_number" "
                            fnWriteLog ${LINENO} ""
                            fnWriteLog ${LINENO} "value of variable 'lc_name_version_prefix': "$lc_name_version_prefix" "
                            fnWriteLog ${LINENO} ""
                            fnWriteLog ${LINENO} ""
                            #
                            ###############################################################################
                            # 
                            #
                            # pull the prior to delete matching LC names
                            #
                            fnWriteLog ${LINENO} "Pulling Launch Configuration versions prior to delete from AWS " 
                            lc_versions_all="$(aws autoscaling describe-launch-configurations --profile "$cli_profile" \
                            | jq .[] \
                            | jq -r --arg lc_name_version_prefix_jq "$lc_name_version_prefix" '[.[] | select(.LaunchConfigurationName | contains($lc_name_version_prefix_jq))] | .[] | .LaunchConfigurationName '  )"
                            #
                            # check for command / pipeline error(s)
                            if [ "$?" -ne 0 ]
                                then
                                    #
                                    # set the command/pipeline error line number
                                    error_line_pipeline="$((${LINENO}-7))"
                                    #
                                    # call the command / pipeline error function
                                    fnErrorPipeline
                                    #
                            #
                            fi
                            #
                            fnWriteLog ${LINENO} ""
                            fnWriteLog ${LINENO} ""
                            #
                            fnWriteLog ${LINENO} "writing variable 'lc_versions_all' values to file: 'lc-versions-all.txt'"
                            feed_write_log="$(echo "$lc_versions_all" | tr ' ' '\n' > lc-versions-all.txt 2>&1)"
                            fnWriteLog ${LINENO} "$feed_write_log"
                            fnWriteLog ${LINENO} ""
                            #
                            # count the versions 
                            count_lc_versions_all="$(cat lc-versions-all.txt | wc -l )"
                            #
                            ###############################################################################
                            # 
                            #
                            # test for existing versions
                            # if existing versions exist, then run prior version delete
                            #
                            if (( "$count_lc_versions_all" > 0 ))
                                then
                                    #
                                    ###############################################################################
                                    # 
                                    #
                                    # display the prior to delete counts and versions
                                    #
                                    fnWriteLog ${LINENO} ""
                                    fnWriteLog ${LINENO} "Count of Launch Configuration versions prior to delete: "$count_lc_versions_all" "
                                    fnWriteLog ${LINENO} ""
                                    fnWriteLog ${LINENO} "Launch Configuration versions prior to delete: "
                                    fnWriteLog ${LINENO} "contents of file: 'lc-versions-all.txt'"
                                    feed_write_log="$(cat lc-versions-all.txt 2>&1)"
                                    fnWriteLog ${LINENO} "$feed_write_log"
                                    #
                                    ###############################################################################
                                    # 
                                    #
                                    # delete LC versions older than the -d parameter value
                                    #
                                    fnWriteLog ${LINENO} ""
                                    fnWriteLog ${LINENO} "$feed_write_log"
                                    fnWriteLog ${LINENO} ""
                                    # input is at the 'done' line 
                                    while read -r lc_version_name
                                        do
                                            fnWriteLog ${LINENO} "--------------------------------- loop head: Launch Configuration Versions read ---------------------------------------"
                                            fnWriteLog ${LINENO} "in Launch Configuration Versions read loop"
                                            fnWriteLog ${LINENO} "value of variable 'lc_version_name': "$lc_version_name" "
                                            lc_name_version_number_check="$(echo "$lc_version_name" | sed 's/.*-v\([0-9][0-9]*\).*/\1/' )"
                                            fnWriteLog ${LINENO} "value of variable 'lc_name_version_number': "$lc_name_version_number" "
                                            fnWriteLog ${LINENO} "value of variable 'lc_name_version_number_check': "$lc_name_version_number_check" "
                                            fnWriteLog ${LINENO} "value of variable 'lc_versions_delete': "$lc_versions_delete" "
                                            fnWriteLog ${LINENO} ""
                                            fnWriteLog ${LINENO} ""
                                            fnWriteLog ${LINENO} "checking for valid version integer"
                                            # use the =~ operator for a regular expression match
                                            # The ^ indicates the beginning of the input pattern
                                            # The + means "1 or more of the preceding ([0-9])"
                                            # The $ indicates the end of the input pattern
                                            fnWriteLog ${LINENO} ""
                                            fnWriteLog ${LINENO} "loading the variable 'integer_re_pattern' "
                                            integer_re_pattern='^[0-9]*$'
                                            fnWriteLog ${LINENO} ""
                                            fnWriteLog ${LINENO} "value of the variable 'integer_re_pattern': "$integer_re_pattern""
                                            #
                                            # do not quote the integer_re_pattern variable in the following statement 
                                            # doing so will break this test
                                            # 
                                            if [[ "$lc_name_version_number_check" =~ $integer_re_pattern ]] ; 
                                                then
                                                    fnWriteLog ${LINENO} ""
                                                    fnWriteLog ${LINENO} "version number check is a valid integer: "$lc_name_version_number_check" "                                                
                                                    fnWriteLog ${LINENO} "logic test: if (( ("$ lc_name_version_number" - "$ lc_name_version_number_check") > "$ lc_versions_delete" )) "
                                                    fnWriteLog ${LINENO} "logic test: if (( ("$lc_name_version_number" - "$lc_name_version_number_check") > "$lc_versions_delete" )) "
                                                    fnWriteLog ${LINENO} ""
                                                    if (( ("$lc_name_version_number" - "$lc_name_version_number_check") > "$lc_versions_delete" ))
                                                    then
                                                        fnWriteLog ${LINENO} ""
                                                        fnWriteLog ${LINENO} "----------------------------------------------------------------------------"
                                                        fnWriteLog ${LINENO} "in Launch Configuration delete"
                                                        fnWriteLog ${LINENO} ""
                                                        fnWriteLog ${LINENO} ""
                                                        fnWriteLog ${LINENO} "deleting Launch Configuration: "$lc_version_name" "
                                                        feed_write_log="$(aws autoscaling delete-launch-configuration --profile "$cli_profile" --launch-configuration-name "$lc_version_name" 2>&1)"
                                                        #
                                                        #
                                                        # flag the error to handle if the LC is tied to an autoscaling group
                                                        if [ "$?" -ne 0 ]
                                                            then
                                                                fnWriteLog ${LINENO} "AWS Error while deleting the Launch Configuration " 
                                                                fnWriteLog ${LINENO} "set AWS error flag to y "
                                                                error_aws_flag="y"
                                                                fnWriteLog ${LINENO} "value of variable 'error_aws_flag': "$error_aws_flag"  "
                                                                fnErrorLog
                                                            else 
                                                                # the delete was OK so add the name to the deleted names list
                                                                fnWriteLog ${LINENO} ""
                                                                fnWriteLog ${LINENO} "writing the variable: 'lc_version_name'  to the deleted names file: 'lc-version-deleted.txt' "
                                                                fnWriteLog ${LINENO} "value of variable 'lc_version_name': "$lc_version_name " "
                                                                feed_write_log="$(echo "$lc_version_name" >> lc-version-deleted.txt 2>&1)"
                                                                #
                                                                # check for command / pipeline error(s)
                                                                if [ "$?" -ne 0 ]
                                                                    then
                                                                        #
                                                                        # set the command/pipeline error line number
                                                                        error_line_pipeline="$((${LINENO}-7))"
                                                                        #
                                                                        # call the command / pipeline error function
                                                                        fnErrorPipeline
                                                                        #
                                                                #
                                                                fi
                                                                #
                                                                fnWriteLog ${LINENO} "$feed_write_log"
                                                                #
                                                                #
                                                                fnWriteLog ${LINENO} ""
                                                                fnWriteLog ${LINENO} "increment the counter 'counter_version_deleted' "
                                                                counter_version_deleted="$((counter_version_deleted+1))" 
                                                                fnWriteLog ${LINENO} "value of variable 'counter_version_deleted': "$counter_version_deleted" "
                                                                fnWriteLog ${LINENO} ""

                                                                #                                                               
                                                        fi
                                                        #
                                                        #
                                                        fnWriteLog ${LINENO} "$feed_write_log"
                                                        fnWriteLog ${LINENO} "----------------------------------------------------------------------------"
                                                        fnWriteLog ${LINENO} ""
                                                        fnWriteLog ${LINENO} ""
                                                        fnWriteLog ${LINENO} ""
                                                        fi
                                                    else
                                                        fnWriteLog ${LINENO} ""
                                                        fnWriteLog ${LINENO} "version number check is not a valid integer: "$lc_name_version_number_check" "
                                                        fnWriteLog ${LINENO} ""                 
                                                        fnWriteLog ${LINENO} "not processing this Launch Configuration version "                  
                                                        fnWriteLog ${LINENO} ""                 
                                            fi
                                            fnWriteLog ${LINENO} "--------------------------------- loop tail: Launch Configuration Versions read ---------------------------------------"
                                    done< <(cat lc-versions-all.txt)   
                                    #
                                    ###############################################################################
                                    # 
                                    #
                                    # pull the post-delete matching LC names
                                    #
                                    fnWriteLog ${LINENO} ""
                                    fnWriteLog ${LINENO} ""
                                    fnWriteLog ${LINENO} "Pulling Launch Configuration versions post-delete from AWS "
                                    lc_versions_post_delete="$(aws autoscaling describe-launch-configurations --profile "$cli_profile" \
                                    | jq .[] \
                                    | jq -r --arg lc_name_version_prefix_jq "$lc_name_version_prefix" '[.[] | select(.LaunchConfigurationName | contains($lc_name_version_prefix_jq))] | .[] | .LaunchConfigurationName '  )"
                                    #
                                    # check for command / pipeline error(s)
                                    if [ "$?" -ne 0 ]
                                        then
                                            #
                                            # set the command/pipeline error line number
                                            error_line_pipeline="$((${LINENO}-7))"
                                            #
                                            # call the command / pipeline error function
                                            fnErrorPipeline
                                            #
                                    #
                                    fi
                                    #
                                    fnWriteLog ${LINENO} ""
                                    fnWriteLog ${LINENO} ""
                                    fnWriteLog ${LINENO} "writing variable 'lc_versions_post_delete' values to file: 'lc-versions-post-delete.txt'"
                                    feed_write_log="$(echo "$lc_versions_post_delete" | tr ' ' '\n' > lc-versions-post-delete.txt 2>&1)"
                                    fnWriteLog ${LINENO} "$feed_write_log"
                                    #
                                    # count the post-delete versions
                                    count_lc_versions_post_delete="$(cat lc-versions-post-delete.txt | wc -l )"
                                    #
                                    ###############################################################################
                                    # 
                                    #
                                    # display the prior- and post-delete counts and versions
                                    #
                                    fnWriteLog ${LINENO} ""
                                    fnWriteLog ${LINENO} ""
                                    fnWriteLog ${LINENO}  level_0 "Count of Launch Configuration versions prior to delete: "$count_lc_versions_all" "
                                    fnWriteLog ${LINENO} ""
                                    fnWriteLog ${LINENO} "Launch Configuration versions prior to delete: "
                                    fnWriteLog ${LINENO} "contents of file: 'lc-versions-all.txt'"
                                    feed_write_log="$(cat lc-versions-all.txt 2>&1)"
                                    fnWriteLog ${LINENO} "$feed_write_log"
                                    fnWriteLog ${LINENO} ""
                                    fnWriteLog ${LINENO} ""
                                    fnWriteLog ${LINENO}  level_0 "Count of Launch Configuration versions post-delete: "$count_lc_versions_post_delete" "
                                    fnWriteLog ${LINENO} ""
                                    fnWriteLog ${LINENO} "Launch Configuration versions post-delete: "
                                    fnWriteLog ${LINENO} "contents of file: 'lc-versions-post-delete.txt'"
                                    feed_write_log="$(cat lc-versions-post-delete.txt 2>&1)"
                                    fnWriteLog ${LINENO} "$feed_write_log"
                                    fnWriteLog ${LINENO} ""
                                    #
                                    # pause for display
                                    sleep 1
                            fi
                    fi
                    fnWriteLog ${LINENO} ""  
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "---------------------------------------- end: Delete LC Versions -----------------------------------------"
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} ""
                #   
                else
                    fnWriteLog ${LINENO} ""  
                    fnWriteLog ${LINENO} ""
            fi    
#
# increment the loop counter
counter_lc_create="$(($counter_lc_create + 1))"
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "-------------------------------------- tail: create new LCs loop -----------------------------------------"
fnWriteLog ${LINENO} ""
#
done< <(cat lc-create-names.txt) || exit 1 
#
#
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "------------------------------------------ end: create new LCs  ------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# pull the new LC names to use when writing new LC name associated ARN  
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "-------------- begin: extract the new LC names from the file: 'launch-configs-mapping.json' --------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO} level_0 "Extracting the new Launch Configuration names from the file: 'launch-configs-mapping.json'..."
fnWriteLog ${LINENO} "putting the results into text file for jq processing"
#
fnWriteLog ${LINENO} "creating text file: 'lc_new_names.txt'"
feed_write_log="$(cat launch-configs-mapping.json | jq .[] | jq -r '.[].newLcName' > lc_new_names.txt 2>&1)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
#
fnWriteLog ${LINENO} "loading 'lc_new_name_list_raw' variable"
lc_new_names_raw="$(cat lc_new_names.txt )"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contends of file:'lc_new_names.txt': "
feed_write_log="$(cat lc_new_names.txt  2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "sort file: 'lc_new_names.txt'"
fnWriteLog ${LINENO} "create file: 'lc_new_names_sorted.txt' "
feed_write_log="$(sort "lc_new_names.txt" > lc_new_names_sorted.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of file 'lc_new_names_sorted.txt':"
feed_write_log="$(cat lc_new_names_sorted.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "--------------- end: extract the new LC names from the file: 'launch-configs-mapping.json' ---------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# populate the 'launch-configs-mapping.json' file with the new LC name ARN  
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------- begin: write new LC name ARN to the file: 'launch-configs-mapping.json' -----------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO} level_0 "Writing the new LC name associated ARN to the file: 'launch-configs-mapping.json'..."
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "This task takes a while. Please wait..."
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "initializing the counters"
# decrement the final increment at the end of the final LC name load loop 
counter_lc_name_new_file="$counter_file"
counter_lcname_new_arn_json_populate=0
counter_source_file="$counter_file"
counter_target_file="$((counter_source_file+1))"
counter_write_mapping_name_new_arn=1
count_write_mapping_name_new_arn="$(cat lc_old_names_sorted.txt | wc -l)"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'counter_lc_name_new_file': "$counter_lc_name_new_file" "
fnWriteLog ${LINENO} "value of variable 'counter_lcname_new_arn_json_populate': "$counter_lcname_new_arn_json_populate" "
fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
fnWriteLog ${LINENO} "value of variable 'counter_write_mapping_name_new_arn': "$counter_write_mapping_name_new_arn" "
fnWriteLog ${LINENO} "value of variable 'count_write_mapping_name_new_arn': "$count_write_mapping_name_new_arn" "
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "initializing the files"
#
fnWriteLog ${LINENO} "load the first input data file with the results of the LC name load"
fnWriteLog ${LINENO} "value of source file name variable : lc-mapping-new-temp-"$counter_lc_name_new_file".json"
feed_write_log="$(cp -f lc-mapping-new-temp-"$counter_lc_name_new_file".json launch-configs-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "initialize the initial temp file"
feed_write_log="$(echo "" >  lc-mapping-lcname-new-arn-temp-1.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of 'launch-configs-mapping.json':"
feed_write_log="$(cat launch-configs-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of 'lc_new_names_sorted.txt':"
feed_write_log="$(cat lc_new_names_sorted.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "populating variable 'lc_new_names_sorted' "
lc_new_names_sorted="$(cat lc_new_names_sorted.txt)"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "value of variable 'counter_lcname_new_arn_json_populate': "
feed_write_log="$(echo "$counter_lcname_new_arn_json_populate" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "load the first input data file with the results of the LC name load"
fnWriteLog ${LINENO} "load the input file #: "$counter_source_file" " 
fnWriteLog ${LINENO} "value of target file name: lc-mapping-lcname-new-arn-temp-"$counter_source_file".json"
feed_write_log="$(cp -f launch-configs-mapping.json lc-mapping-lcname-new-arn-temp-"$counter_source_file".json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of source file: lc-mapping-lcname-new-arn-temp-"$counter_source_file".json"
feed_write_log="$(cat lc-mapping-lcname-new-arn-temp-"$counter_source_file".json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "variable values prior to run:"
fnWriteLog ${LINENO} "value of variable 'counter_lcname_new_arn_json_populate': "$counter_lcname_new_arn_json_populate" "
fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "populating JSON with the ARN associated with the new LCs"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "beginning 'process LC new name list to pull ARN' do loop "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
# uses process substitution to preserve variables 
# input is at the 'done' line 
while read -r lc_new_names_sorted_line
    do
    #
    # display the header    
    fnHeader
    # display the task progress bar
    fnProgressBarTaskDisplay "$counter_write_mapping_name_new_arn" "$count_write_mapping_name_new_arn" 
    #
    fnWriteLog ${LINENO} level_0 "Writing the new LC name associated ARN to the file: 'launch-configs-mapping.json'..."
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "This task takes a while. Please wait..."
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 "Processing job "$counter_write_mapping_name_new_arn" of "$count_write_mapping_name_new_arn" "
    fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""   
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} "in 'process LC new name list to pull ARN' do loop"
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "variable values at head of 'pull ARN' do loop: "
    fnWriteLog ${LINENO} "value of variable 'counter_lcname_new_arn_json_populate': "$counter_lcname_new_arn_json_populate" "
    fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
    fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'lc_new_names_sorted_line': "$lc_new_names_sorted_line" "
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "running AWS CLI ARN query for LC name: "$lc_new_names_sorted_line" "
    feed_write_log="$(aws autoscaling describe-launch-configurations --profile "$cli_profile" --query 'LaunchConfigurations[?LaunchConfigurationName=='"\`$lc_new_names_sorted_line\`"'].{arn: LaunchConfigurationARN, lcName: LaunchConfigurationName}' > lc-new-name-arn.json  2>&1)"
    #
    # check for errors from the AWS API  
    if [ "$?" -ne 0 ]
    then
        # AWS Error 
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "AWS error message: "
        fnWriteLog ${LINENO} level_0 "$feed_write_log"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
        #
        # set the awserror line number
        error_line_aws="$((${LINENO}-14))"
        #
        # call the AWS error handler
        fnErrorAws
        #
    fi # end AWS error check
    #
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "contents of file 'lc-new-name-arn.json':"
    feed_write_log="$(cat lc-new-name-arn.json 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "putting the JSON results into a plain text list"
    feed_write_log="$(cat lc-new-name-arn.json | jq .[] | jq -r .arn > lc-arn-list.txt 2>&1)"  
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #  
    fnWriteLog ${LINENO} "contents of file 'lc-arn-list.txt':"
    feed_write_log="$(cat lc-arn-list.txt 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log" 
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "putting the JSON results into a sorted plain text list"
    feed_write_log="$(sort -u lc-arn-list.txt > lc-arn-list-sorted.txt 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "contents of file 'lc-arn-list-sorted.txt':"
    feed_write_log="$(cat lc-arn-list-sorted.txt 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "testing for empty set"
    count_lc_arn="$(cat lc-arn-list-sorted.txt | wc -l )"
    fnWriteLog ${LINENO} "value of variable 'count_lc_arn': "$count_lc_arn" "
    fnWriteLog ${LINENO} ""
    if [[ count_lc_arn -eq 0 ]] ;
        then 
            fnWriteLog ${LINENO} "no ARN found for LC name: "$lc_new_names_sorted_line" " 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "increment the write counter: 'counter_write_mapping_name_new_arn'"
            counter_write_mapping_name_new_arn="$((counter_write_mapping_name_new_arn+1))"
            fnWriteLog ${LINENO} "post-increment value of variable 'counter_write_mapping_name_new_arn': "$counter_write_mapping_name_new_arn" "
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "processing the next LC name "
            # skip to the next name
            continue
        else
            fnWriteLog ${LINENO} "ARN found for LC name: "$lc_new_names_sorted_line" "
    fi
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "results of AWS CLI query for ARN associated with LC: "$lc_new_names_sorted_line" "
    feed_write_log="$(cat lc-arn-list-sorted.txt 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"  
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "entering 'ARN mapping to JSON file' do loop"
    # uses process substitution to preserve variables 
    # input is at the 'done' line 
    while read -r arns_sorted_line
        do
        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} "in 'ARN mapping to JSON file' do loop"
        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "variable values at head of 'ARN mapping to JSON file' do loop - prior to load:"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'lc_new_names_sorted_line': "$lc_new_names_sorted_line" "
        fnWriteLog ${LINENO} "ARN value for load to LC JSON file: "$arns_sorted_line""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'counter_lcname_new_arn_json_populate': "$counter_lcname_new_arn_json_populate" "
        fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
        fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "source file name: lc-mapping-lcname-new-arn-temp-"$counter_source_file".json"
        fnWriteLog ${LINENO} "output file name: lc-mapping-lcname-new-arn-temp-"$counter_target_file".json"
        #
        fnWriteLog ${LINENO} "initialize output file "
        feed_write_log="$(echo "" >  lc-mapping-lcname-new-arn-temp-"$counter_target_file".json 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "contents of source file: lc-mapping-lcname-new-arn-temp-"$counter_source_file".json"
        feed_write_log="$(cat lc-mapping-lcname-new-arn-temp-"$counter_source_file".json 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""   
        #
        fnWriteLog ${LINENO} "Writing ARN to: lc-mapping-lcname-new-arn-temp-"$counter_target_file".json" 
        feed_write_log="$(cat lc-mapping-lcname-new-arn-temp-"$counter_source_file".json | jq --arg arn_jq "$arns_sorted_line" --arg lc_new_names_sorted_line_jq "$lc_new_names_sorted_line" '[.mappings[] | if .newLcName == $lc_new_names_sorted_line_jq then .newLcArn = $arn_jq else . end]' | jq '. | {mappings: . } ' >> lc-mapping-lcname-new-arn-temp-"$counter_target_file".json 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} "$feed_write_log"
        #   
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "contents of output file: lc-mapping-lcname-new-arn-temp-"$counter_target_file".json"
        feed_write_log="$(cat lc-mapping-lcname-new-arn-temp-"$counter_target_file".json 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "'counter_lcname_new_arn_json_populate' do loop counter value prior to increment: "$counter_lcname_new_arn_json_populate" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} "incrementing 'lc mapping json' do loop counter " 
        counter_lcname_new_arn_json_populate="$((counter_lcname_new_arn_json_populate+1))"
        counter_source_file="$((counter_source_file+1))"
        counter_target_file="$((counter_target_file+1))"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "variable values at tail of 'ARN mapping to JSON file' do loop - after load and increment:"
        fnWriteLog ${LINENO} "value of variable 'counter_lcname_new_arn_json_populate': "$counter_lcname_new_arn_json_populate" "
        fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
        fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "'counter_lcname_new_arn_json_populate' do loop counter value after increment: "$counter_lcname_new_arn_json_populate" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
    done < <(cat lc-arn-list-sorted.txt) 
    #
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "done with 'ARN mapping to JSON file' do loop "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "increment the write counter: 'counter_write_mapping_name_new_arn'"
counter_write_mapping_name_new_arn="$((counter_write_mapping_name_new_arn+1))"
fnWriteLog ${LINENO} "post-increment value of variable 'counter_write_mapping_name_new_arn': "$counter_write_mapping_name_new_arn" "
fnWriteLog ${LINENO} ""
#
done < <(cat lc_new_names_sorted.txt) 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "done with 'process LC new name list to pull ARN' do loop "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "variable values after exit of all load ARN while loops:"
fnWriteLog ${LINENO} "value of variable 'counter_lcname_new_arn_json_populate': "$counter_lcname_new_arn_json_populate" "
fnWriteLog ${LINENO} "value of variable 'counter_source_file': "$counter_source_file" "
fnWriteLog ${LINENO} "value of variable 'counter_target_file': "$counter_target_file" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "copy results of LC name and ARN load into the 'launch-configs-mapping.json' file"
# use source counter because it's been incremented after the last load
feed_write_log="$(cp -f lc-mapping-lcname-new-arn-temp-"$counter_source_file".json launch-configs-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "contents of file: 'launch-configs-mapping.json' "
feed_write_log="$(cat launch-configs-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------- end: write new LC name ARN to the file: 'launch-configs-mapping.json' ------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# update associated Autoscaling Groups (LGs) to use the new LC
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "-------------------------- begin: update Autoscaling Groups with new LC name -----------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "contents of file: launch-configs-mapping.json" 
feed_write_log="$(cat launch-configs-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
counter_update_ag_lc_name_new=1
count_lc="$(cat launch-configs-mapping.json | grep -c "oldLcName\":")"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "count the autoscaling groups, load variable: 'count_ag' "
# do not quote the variable in the awk command
count_ag="$(cat launch-configs-mapping.json | jq . | jq -r '.mappings[].autoscaleGroups | length ' | awk '{s+=$1} END {print s}' )"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "load the variable: 'counter_count_lc' from variable 'count_lc' "
counter_count_lc="$count_lc" 
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "load the variable: 'count_lc_index' from variable 'count_lc'-1 "
# subtract 1 to adjust for jq 0 start for index
count_lc_index="$((count_lc-1))"
fnWriteLog ${LINENO} "value of variable 'count_lc' : "$count_lc" "
fnWriteLog ${LINENO} "value of variable 'count_ag' : "$count_ag" "
fnWriteLog ${LINENO} "value of variable 'counter_count_lc' : "$counter_count_lc" "
fnWriteLog ${LINENO} "value of variable 'count_lc_index' indexed for 0 start: "$count_lc_index" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "----------- entering loop: LC names - update AG with new LC name ---------------------"
while [[ "$counter_count_lc" -gt 0 ]]
do

    fnWriteLog ${LINENO} "----------- loop head: LC names - update AG with new LC name ---------------------"
    fnWriteLog ${LINENO} "feed"
    feed_write_log="$(cat launch-configs-mapping.json | jq . 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""

    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "load LC new name variable"
    lc_name_new="$( cat launch-configs-mapping.json | jq -r --arg count_lc_index_jq "$count_lc_index" ' . | .mappings[$count_lc_index_jq | tonumber].newLcName ' )"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'lc_name_new': "$lc_name_new" "
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "write AG names direct to file 'lc-ag-names.txt' "
    feed_write_log="$(cat launch-configs-mapping.json | jq -r --arg count_lc_index_jq "$count_lc_index" ' . | .mappings[$count_lc_index_jq | tonumber].autoscaleGroups | .[]' > lc-ag-names.txt 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "contents of file: 'lc-ag-names.txt':"
    feed_write_log="$(cat lc-ag-names.txt 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""

    fnWriteLog ${LINENO} "----------- entering loop: AG names - update AG with new LC name ---------------------"
    # uses process substitution to preserve variables 
    # input is at the 'done' line 
    while read -r ag_names_line 
    do
        fnWriteLog ${LINENO} "---------- loop head: AG names - update AG with new LC name ---------------------"
        fnWriteLog ${LINENO} ""
        #
        # display the header    
        fnHeader
        # display the task progress bar
        fnProgressBarTaskDisplay "$counter_update_ag_lc_name_new" "$count_ag"
        #
        fnWriteLog ${LINENO} level_0
        fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 "Processing job 'update Autoscaling Group with new Launch Configuration name':"
        fnWriteLog ${LINENO} level_0 "Job "$counter_update_ag_lc_name_new" of "$count_ag"  " 
        fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "running AWS CLI Autoscaling Group update to new LC name: "$lc_name_new" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'ag_names_line' : "$ag_names_line" "
        fnWriteLog ${LINENO} "value of variable 'lc_name_new' : "$lc_name_new" "
        fnWriteLog ${LINENO} ""   
        fnWriteLog ${LINENO} "command: aws autoscaling update-auto-scaling-group --profile "$cli_profile" --auto-scaling-group-name "$ag_names_line" --launch-configuration-name "$lc_name_new""   
        fnWriteLog ${LINENO} ""   
        feed_write_log="$(aws autoscaling update-auto-scaling-group --profile "$cli_profile" --auto-scaling-group-name "$ag_names_line" --launch-configuration-name "$lc_name_new" 2>&1)"  
        #
        # check for errors from the AWS API  
        if [ "$?" -ne 0 ]
        then
            # AWS Error 
            fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "AWS error message: "
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
            #
            # set the awserror line number
            error_line_aws="$((${LINENO}-14))"
            #
            # call the AWS error handler
            fnErrorAws
            #
        fi # end AWS error check
        #
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "AWS Autoscaling Group: " 
        fnWriteLog ${LINENO} level_0 " "$ag_names_line" "
        fnWriteLog ${LINENO} level_0 ""    
        fnWriteLog ${LINENO} level_0 "Updated to Launch Configuration name: "
        fnWriteLog ${LINENO} level_0 " "$lc_name_new" "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "Pulling the Autoscaling Group's associated Launch Configuration from AWS..."
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "This task takes a while. Please wait..."
        fnWriteLog ${LINENO} level_0 ""   
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "AWS Autoscaling Group: "$ag_names_line" updated status:"
        fnWriteLog ${LINENO} "Running AWS CLI Autoscaling Group query to display AG updated LC name: "
        fnWriteLog ${LINENO} " "$lc_name_new" "
        fnWriteLog ${LINENO} ""
        feed_write_log="$(aws autoscaling describe-auto-scaling-groups --profile "$cli_profile" --query 'AutoScalingGroups[?AutoScalingGroupName=='"\`$ag_names_line\`"'].{AutoScalingGroupName: AutoScalingGroupName, LaunchConfigurationName: LaunchConfigurationName}' | jq .[] | tr -d '{}' 2>&1)"    
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "Launch Configuration name status of Autoscaling Group: "
        fnWriteLog ${LINENO} level_0 " "$ag_names_line":"
        fnWriteLog ${LINENO} level_0 "$feed_write_log"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------------------"
        #
        # pause for display
        sleep 1
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "increment the job counter"
        counter_update_ag_lc_name_new="$((counter_update_ag_lc_name_new+1))"
        fnWriteLog ${LINENO} "value of variable 'counter_update_ag_lc_name_new' after increment: "$counter_update_ag_lc_name_new" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "---------- loop tail: AG names - update AG with new LC name ---------------------"
    #  
    done < <(cat lc-ag-names.txt)
    #
    fnWriteLog ${LINENO} "---------- done with loop: AG names - update AG with new LC name ---------------------"
    #
    fnWriteLog ${LINENO} "decrement the counters"
    fnWriteLog ${LINENO} "value of variable 'counter_count_lc' prior to decrement: "$counter_count_lc" "
    counter_count_lc="$(($counter_count_lc-1))"
    count_lc_index="$((count_lc_index-1))"
    fnWriteLog ${LINENO} "value of variable 'counter_count_lc' after decrement: "$counter_count_lc" "
    fnWriteLog ${LINENO} "value of variable 'count_lc_index' after decrement: "$count_lc_index" "
    #
    fnWriteLog ${LINENO} "----------- loop tail: LC names - update AG with new LC name ---------------------"
#
done
fnWriteLog ${LINENO} "--------------- end loop: LC names - update AG with new LC name ---------------------"
#
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "--------------------------- end: update Autoscaling Groups with new LC name ------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# create the summary report 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------- begin: print summary report for each LC name --------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
# load the report AMI variables
ami_old_id_report="$(cat launch-configs-mapping.json | jq '.mappings[0].oldAmiId' | tr -d \" )"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
ami_old_name_report="$(cat launch-configs-mapping.json | jq '.mappings[0].oldAmiName' | tr -d \" )"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
ami_new_id_report="$(cat launch-configs-mapping.json | jq '.mappings[0].newAmiId' | tr -d \" )"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
ami_new_name_report="$(cat launch-configs-mapping.json | jq '.mappings[0].newAmiName' | tr -d \" )"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
# initialize the counters
fnWriteLog ${LINENO} ""
counter_update_ag_lc_name_new=1
count_lc_report="$(cat launch-configs-mapping.json | grep -c "oldLcName\":")"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
# do not quote the variable in the awk command
count_ag_report="$(cat launch-configs-mapping.json | jq . | jq -r '.mappings[].autoscaleGroups | length ' | awk '{s+=$1} END {print s}' )"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
counter_lc_report=1 
# subtract 1 to adjust for jq 0 start for index
count_lc_report_index="$((count_lc_report-1))"
fnWriteLog ${LINENO} "value of variable 'count_lc_report' : "$count_lc_report" "
fnWriteLog ${LINENO} "value of variable 'count_ag_report' : "$count_ag_report" "
fnWriteLog ${LINENO} "value of variable 'counter_lc_report' : "$counter_lc_report" "
fnWriteLog ${LINENO} "value of variable 'count_lc_report_index' indexed for 0 start: "$count_lc_report_index" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'ami_old_id_report': "$ami_old_id_report" "
fnWriteLog ${LINENO} "value of variable 'ami_old_name_report': "$ami_old_name_report" "
fnWriteLog ${LINENO} "value of variable 'ami_new_id_report': "$ami_new_id_report" "
fnWriteLog ${LINENO} "value of variable 'ami_new_name_report': "$ami_new_name_report" "
fnHeader
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Creating job summary report file "
fnWriteLog ${LINENO} level_0 ""
# initialize the report file and append the report lines to the file
echo "">"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Autoscaling Update AMI Summary Report">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Script Version: "$script_version" ">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Date: "$date_file"">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  AWS Account: "$this_aws_account"  "$this_aws_account_alias" ">>"$this_summary_report_full_path"
if (( "$lc_versions_delete" > 0 ))
    then
        echo "">>"$this_summary_report_full_path"
        echo "  Number of prior Launch Configuration versions to retain: "$lc_versions_delete" ">>"$this_summary_report_full_path"
fi
echo "">>"$this_summary_report_full_path"
if [[ "$logging" == "y" ]]
    then 
        echo "">>"$this_summary_report_full_path"
        echo "  Autoscaling Update AMI job log file: ">>"$this_summary_report_full_path"
        echo "  "$write_path"/ ">>"$this_summary_report_full_path"
        echo "  "$this_log_file" ">>"$this_summary_report_full_path"
fi
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Old AMI ID: "$ami_old_id_report" ">>"$this_summary_report_full_path"
echo "  Old AMI Name: "$ami_old_name_report" ">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  New AMI ID: "$ami_new_id_report" ">>"$this_summary_report_full_path"
echo "  New AMI Name: "$ami_new_name_report" ">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Number of Launch Configurations updated: "$count_lc_report" ">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Number of Autoscaling Groups updated: "$count_ag_report" ">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
count_error_lines="$(cat "$this_log_file_errors_full_path" | wc -l)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi
#
if (( "$count_error_lines" > 2 ))
    then
        echo "">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
        # add the errors to the report
        feed_write_log="$(cat "$this_log_file_errors_full_path">>"$this_summary_report_full_path" 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        echo "">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
        echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
fi
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
#
# test if there are deleted versions
if [[ "$counter_version_deleted" -gt 0 ]]
    then
        count_lc_version_deleted_lines="$(cat lc-version-deleted.txt | wc -l)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        # check if there are lc names in the deleted versions file 
        if (( "$count_lc_version_deleted_lines" > 0 ))
            then
                echo "">>"$this_summary_report_full_path"
                echo "  Launch Configuration versions deleted: ">>"$this_summary_report_full_path"
                echo "">>"$this_summary_report_full_path"
                # add the deleted versions to the report
                feed_write_log="$(cat lc-version-deleted.txt | sed -e 's/^/    /g'>>"$this_summary_report_full_path" 2>&1)"
                #
                # check for command / pipeline error(s)
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                #
                fi
                #
                fnWriteLog ${LINENO} "$feed_write_log"
                echo "">>"$this_summary_report_full_path"
                echo "">>"$this_summary_report_full_path"
                echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
        fi # end test if names exist in the deleted lines file  
fi # end test if deleted versions 
#
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "contents of file: launch-configs-mapping.json" 
feed_write_log="$(cat launch-configs-mapping.json 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
#
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "----------- entering loop: LC names - append to report for each LC name ---------------------"
#
while [[ "$counter_lc_report" -le "$count_lc_report" ]]
    do
        #
        # display the header    
        fnHeader
        # display the task progress bar
        fnProgressBarTaskDisplay "$counter_lc_report" "$count_lc_report"
        #
        fnWriteLog ${LINENO} "----------- loop head: LC names - append to report for each LC name ---------------------"
        fnWriteLog ${LINENO} "report feed"
        feed_write_log="$(cat launch-configs-mapping.json | jq . 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "load LC old name variable"
        lc_name_old_report="$( cat launch-configs-mapping.json | jq -r --arg count_lc_report_index_jq "$count_lc_report_index" ' . | .mappings[$count_lc_report_index_jq | tonumber].oldLcName ' )"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'lc_name_old_report': "$lc_name_old_report" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        echo "">>"$this_summary_report_full_path"
        echo "  Old, target Launch Configuration Name: ">>"$this_summary_report_full_path"
        echo "    "$lc_name_old_report" ">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "load LC new name variable"
        lc_name_new_report="$( cat launch-configs-mapping.json | jq -r --arg count_lc_report_index_jq "$count_lc_report_index" ' . | .mappings[$count_lc_report_index_jq | tonumber].newLcName ' )"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'lc_name_new_report': "$lc_name_new_report" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        echo "">>"$this_summary_report_full_path"
        echo "  New Launch Configuration Name: ">>"$this_summary_report_full_path"
        echo "    "$lc_name_new_report" ">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
        #
        fnWriteLog ${LINENO} level_0 "Creating report section for Launch Configuration: "
        fnWriteLog ${LINENO} level_0 "$lc_name_new_report"
        fnWriteLog ${LINENO} level_0 ""
        #
        echo "">>"$this_summary_report_full_path"
        echo "  Associated Autoscaling Groups updated to new Launch Configuration: ">>"$this_summary_report_full_path"
        #
        cat launch-configs-mapping.json \
        | jq -r --arg count_lc_report_index_jq "$count_lc_report_index" ' . | .mappings[$count_lc_report_index_jq | tonumber].autoscaleGroups | .[]' \
        | sed -e 's/^/    /g'>>"$this_summary_report_full_path"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        echo "">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
        echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
        #
        fnWriteLog ${LINENO} "increment the counters"
        fnWriteLog ${LINENO} "value of variable 'counter_lc_report' prior to increment: "$counter_lc_report" "
        counter_lc_report="$(($counter_lc_report+1))"
        count_lc_report_index="$((count_lc_report_index-1))"
        fnWriteLog ${LINENO} "value of variable 'counter_lc_report' after increment: "$counter_lc_report" "
        fnWriteLog ${LINENO} "value of variable 'count_lc_report_index' after decrement: "$count_lc_report_index" "
        #
        fnWriteLog ${LINENO} "----------- loop tail: LC names - append to report for each LC name ---------------------"
#
done
#
fnWriteLog ${LINENO} "--------------- end loop: LC names - append to report for each LC name ---------------------"
#
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
#
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Summary report complete. "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Report is located here: "
fnWriteLog ${LINENO} level_0 "$write_path"
fnWriteLog ${LINENO} level_0 "$this_summary_report"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------- end: print summary report for each LC name ---------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} level_0 "Contents of summary report: "$this_summary_report_full_path" "
feed_write_log="$(cat "$this_summary_report_full_path" 2>&1)" 
fnWriteLog ${LINENO} level_0 "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# delete the work files 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------- begin: delete work files ----------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnHeader
#
fnDeleteWorkFiles
#
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------- end: delete work files -----------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# done 
#
fnHeader
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "                            Job Complete "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
#
if [[ "$logging" = "y" ]] ;
    then
        fnWriteLog ${LINENO} level_0 " Log location: "
        fnWriteLog ${LINENO} level_0 " "$write_path"/ "
        fnWriteLog ${LINENO} level_0 " "$this_log_file" "
        fnWriteLog ${LINENO} level_0 ""
fi 
#
fnWriteLog ${LINENO} level_0 " Summary report location: "
fnWriteLog ${LINENO} level_0 " "$write_path"/ "
fnWriteLog ${LINENO} level_0 " "$this_summary_report" "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "----------------------------------------------------------------------"
if (( "$count_error_lines" > 2 ))
    then
    fnWriteLog ${LINENO} level_0 ""
    feed_write_log="$(cat "$this_log_file_errors_full_path" 2>&1)" 
    fnWriteLog ${LINENO} level_0 "$feed_write_log"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "----------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
fi
#
##########################################################################
#
#
# write the stop timestamp to the log 
#
#
date_now="$(date +"%Y-%m-%d-%H%M%S")"
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "run end timestamp: "$date_now" " 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
#
##########################################################################
#
#
# write the log file 
#
if [[ ("$logging" = "y") || ("$logging" = "z") ]] 
    then 
        # append the temp log onto the log file
        fnWriteLogTempFile
        # write the log variable to the log file
        fnWriteLogFile
    else 
        # delete the temp log file
        rm -f "$this_log_temp_file_full_path"        
fi
#
# exit with success 
exit 0
#
#
# ------------------ end script ----------------------
