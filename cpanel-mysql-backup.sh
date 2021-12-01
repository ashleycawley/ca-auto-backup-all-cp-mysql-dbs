#!/bin/bash

# A tool to automate the backup of all MySQL databases within a given cPanel account and then make
# those backups available to the user via a sub-folder in their home directory.
# The script is designed to be ran as root on a server where root is not challenged for MySQL credentials.
#
# An example destination path might be at: /home/cpuser/backups
# This script will then generate its own subfolders (like 'databases') within that.
#
# To automate this and run daily, you could setup the following CRON job as root:
# 0 1 * * * /bin/bash /path/to/script/cpanel-mysql-backup.sh
#
# Script will automatically delete old backups which are greater than $DAYS_TO_RETAIN number of days.

# User configurable Settings
CPANEL_USERNAME="cpusername"
DB_USER_PREFIX="cpuserna_"
BACKUP_DESTINATION="/home/cpusername/backups" # No trailing slash please.
DAYS_TO_RETAIN="5" # Number of days to retain database backups for

# Script Variables
DATE_AND_TIME=$(date +"%d_%m_%Y_%I_%M_%p")
SAVEIFS=$IFS	# Backing up the delimiter used by arrays to differentiate between different data in the array (prior to changing it)
IFS=$'\n'	# Changing the delimiter used by arrays from a space to a new line, this allows a list of users (on new lines) to be stored in to an array

# Creates folder structure if directories do not exist already
if [ ! -d "$BACKUP_DESTINATION" ]
then
    mkdir -p $BACKUP_DESTINATION
    chown $CPANEL_USERNAME:$CPANEL_USERNAME $BACKUP_DESTINATION
fi

if [ ! -d "$BACKUP_DESTINATION/databases" ]
then
    mkdir -p $BACKUP_DESTINATION/databases
fi

# Warns user not to save any files in directory which could be automatically purged in the future
echo "WARNING: The contents of this directory could be purged automatically based on a schedule,
Please DO NOT STORE any of your own files that you wish to keep in here." > $BACKUP_DESTINATION/databases/READ-ME.txt

# Builds a list of the user's databases
mysql -s -e 'SHOW DATABASES LIKE '"'$DB_USER_PREFIX%'"';' > $BACKUP_DESTINATION/db_list.log

for DATABASE in $(cat $BACKUP_DESTINATION/db_list.log)
do
    mysqldump $DATABASE > $BACKUP_DESTINATION/databases/${DATABASE}_${DATE_AND_TIME}.sql
done

# Corrects user permissions:
chown -R $CPANEL_USERNAME:$CPANEL_USERNAME $BACKUP_DESTINATION

## Purging Routine
find $BACKUP_DESTINATION/databases/ -type f -name "*.sql" -mtime $DAYS_TO_RETAIN -delete

rm -f $BACKUP_DESTINATION/db_list.log

IFS=$SAVEIFS # Resets $IFS this changes the delimiter that arrays use from new lines (\n) back to just spaces (which is what it normally is)

exit 0