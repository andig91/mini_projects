#!/bin/bash

cd "$(dirname -- "$0")"
pwd -P
date +%Y%m%d_%H%M%S

echo "Dieses Skript dient zum holen der backup-files von einem Remote-System"
#Also possible ${0##*/} 
#echo "./$(basename $0) <Backup-Archive-with-Path>"

echo

filepattern="*.tar.gz.enc"


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
if [ -f $destinationdir/scp_backup/$scpfile ]
then
	echo "File already transmitted"
else
	scp $remotemachine:$sourcedir/$scpfile $destinationdir/scp_backup/$scpfile
fi

}

getBackups "oci-fi2" "/tmp" "oci-fi"
getBackups "oci-nc" "/tmp" "oci-nc"
getBackups "oci-kasm" "/tmp" "oci-kasm"
getBackups "oci-nb" "/tmp" "oci-nb"
