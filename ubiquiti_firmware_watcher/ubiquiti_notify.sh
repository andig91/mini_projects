#!/bin/sh

#
# runs on Ubuntu or Alpine with curl and jq installed or docker image "andi91/curl_jq_alpine" or "curl_jq_ubuntu"
# telegram credentials in cred.txt (first line token, second receiver_id) or with environment variables (token & empfanger)
#
# Crontab configuration
# 19 19 * * * <workdir>/ubiquiti_notify.sh > /tmp/ubiquiti_last.log
# or with docker image
# 19 19 * * * docker run --rm -v "<workdir>:/mnt/Arbeitsverzeichnis" --entrypoint "/mnt/Arbeitsverzeichnis/ubiquiti_notify.sh" -e token="<bot_token>" -e empfanger="<receiver_id>" andi91/curl_jq_alpine >> /tmp/ubiquiti_last.log
#


cd "$(dirname -- "$0")"
pwd -P

if [ -f "cred.txt" ]
then
	token=$(sed -n 1p cred.txt)
	empfanger=$(sed -n 2p cred.txt)
fi

if [ -z "$token" ]
then
echo "Bitte die Variable token setzen oder Datei cred.txt im Verzeichnis ablegen. Zeile 1 Token, Zeile 2 Empfaenger"
exit
fi

if [ -z "$empfanger" ]
then
echo "Bitte die Variable empfanger setzen oder Datei cred.txt im Verzeichnis ablegen. Zeile 1 Token, Zeile 2 Empfaenger"
exit
fi


#curl 'https://www.ui.com/download/?product=uap-ac-lr' -H 'x-requested-with: XMLHttpRequest' --compressed > work.json
curl 'https://download.svc.ui.com/v1/downloads/products/slugs/uap-ac-pro' -H 'x-requested-with: XMLHttpRequest' --compressed > work.json

#neu=$(cat work.json | jq '.downloads[-1] | .rank')
neu=$(cat work.json | jq '[.downloads[] | select( .category.slug == "firmware" or .category.slug == "software")][0].id ')
echo $neu

alt=$(cat last.txt)
#alt=$(echo 10)
echo $alt

if echo $alt | grep -q $neu
then
	echo Keine Aenderung
	echo $(date) Keine Aenderung >> gesamt.txt
else
	echo "$(date "+%F %T") Neue Software, Alt: $alt, Neu: $neu" >> new_firmware_prot.txt
	echo Neue Software
	#cat work.json | jq --argjson alt "$alt" '[.downloads[] | select( .rank > $alt ) | select( .category__slug == "firmware") | {ID: .rank, Name: .name, Versions: .version, Changelog: .changelog, Produkte: .products} ]' | sed 's!    !!g;s!  !!g;s!\]!!g;s!\[!!g;s!\"!!g;s!{!!g;s!}!!g;/^[[:space:]]*$/d;' > neu.json
	#cat work.json | jq '.downloads[-1] | .rank' > last.txt
	cat work.json | jq --argjson alt "$alt" '[.downloads[] | select( .id > $alt ) | select( .category.slug == "firmware" or .category.slug == "software") | {ID: .id, Name: .name, Version: .version, Changelog: .changelog} ]' | sed 's!    !!g;s!  !!g;s!\]!!g;s!\[!!g;s!\"!!g;s!{!!g;s!}!!g;/^[[:space:]]*$/d;' > neu.json
    cat work.json | jq --argjson alt "$alt" '[.downloads[] | select( .id > $alt ) | select( .category.slug == "firmware" or .category.slug == "software") | {ID_UBNT: .id, Name: .name, Version: .version, Changelog: .changelog} ]' > neu2.json
	    #cat work.json | jq '.downloads[0] | .id' > last.txt
	echo $neu > last.txt

	if cat neu.json | grep -q "\[\]"
	then
		echo Nichts zum Versenden
		echo $(date) Nichts zum Versenden >> gesamt.txt
	else
		versenden=$(cat neu.json)
		echo $(date) $versenden >> gesamt.txt
		echo $versenden
		curl -X POST \
	     -H 'Content-Type: application/json' \
	     -d '{"chat_id": "'$empfanger'", "text": "Neue Ubiquiti Firmware/Software:
'"Neue ID: $neu Details: \n$versenden"' "}' \
	     https://api.telegram.org/bot$token/sendMessage
		curl --location 'http://'$(sed -n 4p cred.txt)'/items/Ubiquiti?access_token='$(sed -n 3p cred.txt)'' \
		--header 'Content-Type: application/json' \
		--data @neu2.json
		#curl "https://api.telegram.org/bot$token/sendMessage?chat_id=$empfanger&text=Neue Firmware von Ubiquiti:%0A$versenden"
	fi
fi
