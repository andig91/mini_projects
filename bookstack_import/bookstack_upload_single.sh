#!/bin/bash

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
	echo Keine Dateiname fuer den Import vorgegeben. \nBitte \"./skript Dateiname.md\" aufrufen. 
  	read filename_upload
	echo
else
	filename_upload=$(echo $1)
fi


echo "$filename_upload ist dran"
# https://www.reddit.com/r/BookStack/comments/108co0z/how_to_import_markdown_via_cli/
#https://demo.bookstackapp.com/api/docs#pages-create

# read the markdown content into a variable
#filename_upload="Bedienungsanleitungen_downloaden.md"
#md=$(cat ./Python.md)
#md=$(sed -n '2,$p' $filename_upload)

cp $filename_upload ./tmp_import.md
echo "  
		
Quelldatei Import: $(basename $filename_upload)  " >> ./tmp_import.md
md=$(sed -n '2,$p' ./tmp_import.md)

title=$(sed -n '1p' $filename_upload | cut -d " " -f 2-)

# Book-ID ermitteln https://bookstack.gruber.live/api/books  

# assemble the JSON body
json="{
  \"book_id\": 8,
  \"name\": \"$title\",
  \"markdown\": $(echo "$md" | ./jq-osx-amd64 -Rsa)
}"
#json="{
#  \"book_id\": 1,
#  \"name\": \"Piwigo2\",
#  \"markdown\": \"Piwigo2\"
#  }"

# For Debugging  
#echo $json

# post the request
curl -isX POST --url https://bookstack.gruber.live/api/pages --header "Authorization: Token ${token_id}:${token_secret}" \
  -H 'Content-Type: application/json; charset=utf-8' \
  --data-binary "$json"

# Few lines for better reading in Terminal  
echo 
echo