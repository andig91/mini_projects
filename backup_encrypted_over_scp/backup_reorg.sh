#!/bin/bash

cd "$(dirname -- "$0")"
pwd -P
date +%Y%m%d_%H%M%S

echo "Dieses Skript dient zum ausmisten der Backup-Files"
#Also possible ${0##*/} 
echo "./$(basename $0) <Backup-Archive-with-Path>"

if [ -z "$1" ]
then
	echo "No argument given, no todo!"
	echo "weekly => move last backup to subfolder history/weekly"
	echo "monthly => move last backup to subfolder history/montly"
	echo "cleanup => delete old files (if more than 6) from scp_backup and history/weekly" # not finished
	echo "combinations are possilbe: weekly_cleanup, monthly_cleanup"
	exit
fi

echo

# Loop through all directories in the current directory
for dir in */; do
  dirrawname=$(basename $dir)
  echo "Directory: $dir"
  if [ -d $dirrawname/scp_backup ] && [ ! $dirrawname = "@Recycle" ] && [ ! "$dirrawname" = "0_old_scripts" ] && [ ! "$dirrawname" = "0_old_backups" ] && [ ! "$dirrawname" = "0_extract" ]
  then

  	sourcedir=$dirrawname/scp_backup
  	lastfile=$(ls -1 $sourcedir | tail -n 1)
  	
  	if [ -z "$lastfile" ] 
  	then
	  echo "No backupfiles. The directory will be skipped."
	  #exit 0
	else
		if [ "$1" = "weekly" ] || [ "$1" = "weekly_cleanup" ]
		then
			weeklydir=$dirrawname/history/weekly
			if [ ! -d $weeklydir ]
			then
				echo "Ordner wird angelegt: $weeklydir"
				mkdir -p $weeklydir
			fi
			if [ -f $weeklydir/$lastfile ]
			then
				echo "File already copied: $sourcedir/$lastfile"
			else
				echo "copy $sourcedir/$lastfile to $weeklydir/$lastfile"
				cp $sourcedir/$lastfile $weeklydir/$lastfile
			fi
		fi
		
		if [ "$1" = "monthly" ] || [ "$1" = "monthly_cleanup" ]
		then
			monthlydir=$dirrawname/history/monthly
			if [ ! -d $monthlydir ]
			then
				echo "Ordner wird angelegt: $monthlydir"
				mkdir -p $monthlydir
			fi
			if [ -f $monthlydir/$lastfile ]
			then
				echo "File already copied: $sourcedir/$lastfile"
			else
				echo "copy $sourcedir/$lastfile to $monthlydir/$lastfile"
				cp $sourcedir/$lastfile $monthlydir/$lastfile
			fi
		fi
		
		if [ "$1" = "cleanup" ] || [ "$1" = "monthly_cleanup" ] || [ "$1" = "weekly_cleanup" ]
		then
			# Number of files to keep
			KEEP=6
			
			# Cleanup weekly-Folder
			# List all files sorted by modification time in ascending order
			FILES=$(ls -tp $dirrawname/history/weekly | grep -v / | tail -n +$(($KEEP + 1)))
			
			# Check if there are files to delete
			if [ -z "$FILES" ]; then
			  echo "No weekly files to delete. The directory has $KEEP or fewer files."
			  #exit 0
			else
				# Delete the files
				for file in $FILES; do
				  echo "Deleting weekly-file: $file"
				  rm -- "$dirrawname/history/weekly/$file"
				done
			fi
			
			# Cleanup scp_backup-Folder
			# List all files sorted by modification time in ascending order
			FILES=$(ls -tp $sourcedir | grep -v / | tail -n +$(($KEEP + 1)))
			
			# Check if there are files to delete
			if [ -z "$FILES" ]; then
			  echo "No scp_backup-files to delete. The directory has $KEEP or fewer files."
			  #exit 0
			else
				# Delete the files
				for file in $FILES; do
				  echo "Deleting scp_backup-file: $file"
				  rm -- "$sourcedir/$file"
				done
			fi
		fi
		
	fi
  else
	echo "folder blacklisted or scp_backup not exists"
  fi
  echo
  # You can add any other commands you want to perform on each directory here
done

exit