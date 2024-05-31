#!/bin/bash

# Wird hier nicht gebraucht, sondern erst im unteren Skript, aber dann wuerde es den Fehler zig mal auswerfen und so nur einmal  
if [ -f "cred.txt" ]
then
	token_id=$(sed -n 1p cred.txt)
	token_secret=$(sed -n 2p cred.txt)
fi

if [ -z "$token_id" ]
then
	echo "Bitte Datei cred.txt im Verzeichnis ablegen. Zeile 1 Token_ID, Zeile 2 Token_Secret"
	exit
fi

if [ -z "$token_secret" ]
then
	echo "Bitte cred.txt im Verzeichnis ablegen. Zeile 1 Token_ID, Zeile 2 Token_Secret"
	exit
fi

if [ -z "$1" ]
then
	echo "Kein Ordnernamen (mit Markdownfiles) fuer den Import vorgegeben. \nBitte \"./skript Ordnernamen\" aufrufen." 
  	read ordnername_upload
	echo
else
	ordnername_upload=$(echo $1)
fi

for Variable in $(ls -1 "$ordnername_upload"/*.md)
do
echo
echo "Es wird das Skript mit der Datei $Variable ausgefuehrt."
#basename $Variable
./bookstack_upload_single.sh $Variable
done
