#!/bin/bash

cd "$(dirname -- "$0")"
pwd -P

source scr_source_begin.sh

date +%Y%m%d_%H%M%S

echo "Dieses Skript dient zum holen der backup-files von einem Remote-System"
#Also possible ${0##*/} 
#echo "./$(basename $0) <Backup-Archive-with-Path>"

echo

filepattern="*.tar.gz.enc"
destmachine="naspu"

function getBackups {

#remotemachine="oci-fi2"
#sourcedir="/tmp"
#destinationdir="oci-fi"

remotemachine="$1"
sourcedir="$2"
destinationdir="$3"

echo
echo "$1 getting last backup"

scpfile=$(ssh $remotemachine "basename \$(ls -1 $sourcedir/$filepattern | tail -n 1)")
scpfileDest=$(ssh $destmachine "basename \$(ls -1 /share/CACHEDEV1_DATA/Backup_Sync/$destinationdir/scp_backup/$scpfile | tail -n 1)")
if [[ $scpfile ==  $scpfileDest ]]
then
	echo "File already transmitted"
else
	echo "File copy"
	scp $remotemachine:$sourcedir/$scpfile $destmachine:/share/CACHEDEV1_DATA/Backup_Sync/$destinationdir/scp_backup/$scpfile
fi

}

getBackups "oci-fi2" "/tmp" "oci-fi"
getBackups "oci-nc" "/tmp" "oci-nc"
getBackups "oci-kasm" "/tmp" "oci-kasm"
getBackups "oci-nb" "/tmp" "oci-nb"


source scr_source_end.sh