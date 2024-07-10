#!/bin/bash

cd "$(dirname -- "$0")"
pwd -P

echo "Dieses Skript dient zum entschlusseln der Backup-Files"
#Also possible ${0##*/} 
echo "./$(basename $0) <Backup-Archive-with-Path>"

if [ -z "$1" ]
then
	read -p "Keine Archiv angegeben, bitte jetzt den Pfad zum Archiv angeben: " inputfile
else
	inputfile=$1
fi

filename=$(basename $inputfile | cut -d "." -f 1)

#echo $filename
read -s -p "The Archive Password: " passwordInput
echo
echo

#openssl enc -d -aes-256-cbc -salt -pbkdf2 -pass file:keyfile.txt -out outputfile.tar.gz < 20240704_160658_mariadb-vm.tar.gz.enc
#-k <Key-In-Clear-Text>
openssl enc -d -aes-256-cbc -salt -pbkdf2 -k $passwordInput -out 0_extract/"$filename".tar.gz < $inputfile

echo "Die Datei wurde auf 0_extract/"$filename".tar.gz entschluesselt!"
echo