#!/bin/sh

########
#LICENSE                                                   
########

# POSIX_Backup script. Please visit the project's website at: https://github.com/cybernova/POSIX_Backup
# Copyright (C) 2014 Andrea 'cybernova' Dari (andreadari91@gmail.com)                                   
#                                                                                                       
# This shell script is free software: you can redistribute it and/or modify                             
# it under the terms of the GNU General Public License as published by                                   
# the Free Software Foundation, either version 3 of the License, or                                     
# (at your option) any later version.                                                                   
#                                                                                                       
# This program is distributed in the hope that it will be useful,                                       
# but WITHOUT ANY WARRANTY; without even the implied warranty of                                        
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                                         
# GNU General Public License for more details.                                                          
#                                                                                                       
# You should have received a copy of the GNU General Public License                                     
# along with this shell script.  If not, see <http://www.gnu.org/licenses/>. 

####################
#CONFIGURATION FILES                                             
####################

#Directory where to search script's configuration files
CONFIGDIR="$HOME/.posix_backup"
[ ! -e "$CONFIGDIR" ] && mkdir "$CONFIGDIR"

#Configuration file that specifies what files to include in the backup (used only when the script is executed with no arguments)
INCLUDE='backup_include.conf'

#Configuration file that specifies what files to exclude from the backup (optional)
[ -r "$CONFIGDIR/backup_exclude.conf" ] && EXCLUDE="--exclude-from=$CONFIGDIR/backup_exclude.conf" || EXCLUDE=''

###############
#SCRIPT OPTIONS
###############

#Backup tools
TAR='disable' # -t
RSYNC='disable' # -r

#General options
LOG='disable' # -l Log file (argument required as FILE)

#TAR options 
ENCRYPTION='disable' # -e GPG encryption (argument required as USER ID)
INCBACKUP='' # -g Incremental backup (argument required as FILE)
COMPRESS='' # -c Standard gzip compression

#RSYNC options
NOACTION='' # -n Perform a trial run with no changes made

##########
#FUNCTIONS
##########

#Checks if rsync exists
rsyncCheck() {
    [ -x /usr/bin/rsync ] && return 0 || echo Error: rsync is not installed
    return 1
}

#Checks if tar exists
tarCheck() {
    [ -x /bin/tar ] && return 0 || echo Error: tar is not installed
    return 1
}

#0 arguments -> reads files to backup from configuration file 
#In the configuration file it is possible to use pathname expansion
loadConfig() {
    #Counts the number of lines
    local NUMLINES=$(wc -l "$CONFIGDIR/$INCLUDE" | cut -d " " -f 1)
    for i in $(seq 1 $NUMLINES); do
	#Calling himself with a line at a time as argument
	eval $0 $( head -n $i "$CONFIGDIR/$INCLUDE" | tail -n 1)
    done
}

#1 argument -> default action depending on ruid value
defaultAction() {
    if [ $(id -ur) -eq 0 ]; then
	#Root default action
	if [ $RSYNC = 'enable' ]; then
	    rsync -avh $NOACTION $EXCLUDE --log-file="$LOGFILE" --modify-window=1 "/etc" "/home" "/root" "/var" "$1"
	else
	    #Log file is used to save output and error messagges in a file specified by user, useful in case the script is executed by Cron/Anacron (must be enabled)
	    if [ ! $LOG = 'enable' ]; then
		tar -cv $COMPRESS $INCBACKUP $INCBACKUPFILE -f  "$1" "/etc" "/home" "/root" "/var"
	    else
		tar -cv $COMPRESS $INCBACKUP $INCBACKUPFILE -f  "$1" "/etc" "/home" "/root" "/var" >> "$LOGFILE" 2>&1
	    fi
	    #Encryption is done if enabled
	    [ $ENCRYPTION = 'enable' ] && gpg -evr $ENCRYPTIONRECIPIENT "$1"
	fi
    else
	#Others default action
	if [ $RSYNC = 'enable' ]; then
	    rsync -avh $NOACTION $EXCLUDE --log-file="$LOGFILE" --modify-window=1 "$HOME" "$1"
	else
	    if [ ! $LOG = 'enable' ];then
	    	tar -cv $COMPRESS $INCBACKUP $INCBACKUPFILE -f  "$1" "$HOME"
	    else
	    	tar -cv $COMPRESS $INCBACKUP $INCBACKUPFILE -f  "$1" "$HOME" >> "$LOGFILE" 2>&1
	    fi
	    #Encryption is done if enabled
	    [ $ENCRYPTION = 'enable' ] && gpg -evr $ENCRYPTIONRECIPIENT "$1"
	fi
    fi
}

#2+ arguments
nArguments() {
    if [ $RSYNC = 'enable' ]; then
	rsync -avh $NOACTION $EXCLUDE --log-file="$LOGFILE" --modify-window=1 "$@"
    else
	#Log file is used to save output and error messagges in a file specified by user, useful in case the script is executed by Cron/Anacron (must be enabled)
        [ ! $LOG = 'enable' ] && tar -cv $INCBACKUP $INCBACKUPFILE -f "$@" || tar -cv $INCBACKUP $INCBACKUPFILE -f "$@" >> "$LOGFILE" 2>&1
        #Encryption is done if enabled
        [ $ENCRYPTION = 'enable' ] && gpg -evr "$ENCRYPTIONRECIPIENT" "$1"
    fi
}

#############
#SCRIPT START
#############

#Commandline options are parsed by getopts command
 while getopts :trce:g:l:n OPTION; do
	case $OPTION in
	    t)  
                #Tar
		tarCheck || exit 1
		[ $RSYNC = 'enable' ] && echo "Options -r and -t cannot be used together " && exit 3
		TAR='enable'
		;;
	    r)  
                #Rsync
		rsyncCheck || exit 2
		[ $TAR = 'enable' ] && echo "Options -t and -r cannot be used together " && exit 3
		RSYNC='enable'
		;;
       	    c)  
		#Compression
		COMPRESS='-z'
		;;
	    e)  
		#Encryption
		ENCRYPTION='enable'
		ENCRYPTIONRECIPIENT="$OPTARG"
		shift
		;;
	    g) 
		#Incremental backup
		INCBACKUP='-g'
		INCBACKUPFILE="$OPTARG" 
		shift
		;;
	    l)
		#Log file destination
		LOG='enable'
		LOGFILE="$OPTARG"
		shift
		;;
	    n)  
		#Trial run
		NOACTION='-n'
		;;
	    \?) 
                #Invalid option
		echo "Invalid option: -$OPTARG"
		exit 4
		;;
	    :) 
                #Missing argument
		echo "Option -$OPTARG requires an argument"
		exit 5
		;;
	esac
	shift
    done
#Another error control
[ $TAR = 'disable' -a $RSYNC = 'disable' -a $# -gt 0 ] && echo "Error: -t (tar) or -r (rsync) option must be specified" && exit 6
#Checks the number of arguments and calls the appropriate functions
case $# in
    0)
	#Reads the configuration from $INCLUDE if exists and if readable
	if [ -r "$CONFIGDIR/$INCLUDE" ]; then
	    loadConfig
	else
	    echo "Error: $CONFIGDIR/$INCLUDE must exists" && exit 7
        fi
	;;
    1)
	#Default action depending on ruid value
        defaultAction "$1"
	;;
    *)
	#Like using tar or rysnc directly
	nArguments "$@"
	;;
esac

#Script exit
exit 0
