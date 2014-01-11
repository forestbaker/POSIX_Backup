# POSIX Backup

POSIX Backup is a simply but powerful **POSIX shell script** which can be used to backup files.

It's written with an extensive use of comments that helps to understand and easily modify its content.

**What programs need to run this script?**

This script uses 2 main tools to backup your files: TAR and RSYNC.

## Getting started

First, clone the repository using git (recommended):

```bash
git clone https://github.com/cybernova/POSIX_Backup/
```

or download the script manually.

Then set the execution permission to the script:

```bash
 $chmod +x POSIX_backup.sh
```

## Usage

The general syntax:

```
./POSIX_backup.sh [OPTION...] [ARGUMENT...]
```
For TAR: 

```
./POSIX_backup.sh -t [OPTION...] DEST SRC...
```

For RSYNC:

```
./POSIX_backup.sh -r [OPTION...] SRC... DEST
```

**Options**

```
Backup tools:
-t          #Using of the TAR tool
-r          #Using of the RSYNC tool

General options:
-l FILE     #Log file (argument required as FILE)		

Tar options:
-e USER ID  #GPG encryption (argument required as USER ID)	
-g FILE     #Incremental backup (argument required as FILE)
-c 	        #Standard gzip compression

Rsync options:
-n          #Perform a trial run with no changes made
```
    
* **0 Arguments:**

The script reads the files to backup from a configuration file `backup_include.conf` that must exist in the directory `.posix_backup/` in the user's home directory that launched the script.
An example of `backup_include.conf` could be something like this:

```
-t -c /media/USB/user/Backup.tar.gz /home/user/.posix_backup /home/user/Pictures /home/user/Documents
-r -l /home/andrea/Destination/MusicBackup.log /home/user/Music /home/user/Downloads/*.mp3 /media/Destination
```
Pathname expansion is supported.

An another configuration file `backup_exclude.conf` that specifies what files to exclude from the backup, with a **PATTERN** specified in rsync's man pages, but it's the same for tar too, at the section: **INCLUDE/EXCLUDE PATTERN RULES**, could be created in the same `.posix_backup/` directory.
An example of `backup_exclude.conf` could be something like this:
 
 ```
**/.gvfs/
**/.cache*/
**/.Trash*/
**/.thumbnail/
**/Downloads/
```
This configuration file is used, if present, in every invocation of the script.

* **1 Argument:**

The script checks the Real User Id of the user that launched the script and chooses a different backup strategy depending on that value:

  **root**: backup of /etc /home /root /var -> to the destination specified as argument.

  **others**: backup of the user's  home directory -> to the destination specified as argument.

* **2+ Arguments:**

Files to backup are specified as script's arguments.

## Tested Environments

* GNU/Linux

If you have successfully tested this script on others systems or platforms please let me know.
