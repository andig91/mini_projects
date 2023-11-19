#!/bin/bash

#https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/AVM_Technical_Note_-_Session_ID_deutsch_2021-05-03.pdf
# irgendwann mal mit pbkdf2_hmac_sha256 beschaefitigen

cd "$(dirname -- "$0")"
pwd -P

if [ ! -f "cred.txt" ]; then
	echo
	echo "cred.txt existiert nicht"
	echo
	echo "Bitte eine Datei mit den Namen cred.txt anlegen, mit folgenden Inhalt/Zeilen: (Siehe cred.txt.example)"
	echo "<BOT-TOKEN>" 
	echo "<Receiver-ID>"
	echo "<FirtzBox-User (Diagnose-Sicherheit-FritzboxUser)>"
	echo "<FritzBox-Passwort>"
	echo "<FritzBox-IP-Address>"
	echo "<Directus-Token-Address>"
	echo
	exit
	mkdir response
else
	echo "cred.txt existiert"
fi


if [ ! -d "response" ]; then
	echo "Ordner anlegen"
	mkdir response
else
	echo "Ordner existiert bereits"
fi

if ping $(sed -n 5p cred.txt) -c 2 | grep "2 received"
then
	echo "$(date "+%F %T") Fritzbox erreichbar" >> response/fritzbox_aviable.txt
else
	echo "$(date "+%F %T") Fritzbox nicht erreichbar" >> response/fritzbox_aviable.txt
	exit
fi
#curl http://$(sed -n 5p cred.txt)/login_sid.lua?version=2 > response.txt
curl http://$(sed -n 5p cred.txt)/login_sid.lua > response/challenge.txt


cat response/challenge.txt 
challenge=$(cat response/challenge.txt | cut -d "<" -f 6 | cut -d ">" -f 2)
echo $challenge
response=$(echo -n $challenge-$(sed -n 4p cred.txt) | iconv --from-code=UTF-8 --to-code=UTF-16LE | md5sum | sed  -e 's/ .*//')

#echo -n 2$60000$bec75eed3b5da5976eea94e5c8c64b61$6000$2cb80789467dcb123ce1b3e97f5e538b-$(sed -n 3p cred.txt)
echo $response

curl --data  "response=$challenge-$response&username=$(sed -n 3p cred.txt)" http://$(sed -n 5p cred.txt)/login_sid.lua > response/sid.txt
sid=$(cat response/sid.txt | cut -d "<" -f 4 | cut -d ">" -f 2)

curl --data "sid=$sid&lang=de&page=log&no_sidrenew=&filter=2" http://$(sed -n 5p cred.txt)/data.lua > response/fritzlog_filter2.txt
curl --data "sid=$sid&lang=de&page=log&no_sidrenew=&filter=0" http://$(sed -n 5p cred.txt)/data.lua > response/fritzlog_filter0.txt
#curl --data  "response=$challenge-$response&username=$(sed -n 3p cred.txt)" http://$(sed -n 5p cred.txt)/login_sid.lua?version=2
#curl --data "response=2\$60000\$bec75eed3b5da5976eea94e5c8c64b61\$6000\$9aa6e4a1a50c3dca6a94d0b69fafb254-e4db8bbef163db9c9154415141067127&username=$(sed -n 3p cred.txt)" http://$(sed -n 5p cred.txt)/login_sid.lua?version=2

# Ist falsch, da Fritzbox oben den neuesten Eintrag hat
#dateLast=$(cat response/fritzlog_filter2.txt | awk -F"\"log\":" '{print $2}' | cut -d'"' -f2)
#timeLast=$(cat response/fritzlog_filter2.txt | awk -F"\"log\":" '{print $2}' | cut -d'"' -f4)

#dateLast=$(cat response/fritzlog_filter2.txt | jq -r ".data.log[-1][0]")
#timeLast=$(cat response/fritzlog_filter2.txt | jq -r ".data.log[-1][1]")
# New Format
dateLast=$(cat response/fritzlog_filter2.txt | jq -r ".data.log[-1].date")
# Reverse arrange fields with cut doesnt work, new solution with awk (line 70)
dateLastConverted=$(echo "20$(echo $dateLast | awk -F "." '{ print $3 "-" $2 "-" $1}')")
timeLast=$(cat response/fritzlog_filter2.txt | jq -r ".data.log[-1].time")

if [ -z "$dateLast" ]
then
	echo "Kein Datum"
	exit
fi
if [ -z "$timeLast" ]
then
	echo "Keine Zeit"
	exit
fi
echo
#ls -1 response/ 
echo ""$dateLastConverted"_"$timeLast"_fritzlog_filter2.txt"

echo "Wildcardtest"
#ls -1 response/ | grep -c ""$dateLast"_"${timeLast:0:6}".._fritzlog_filter2.txt"
echo ""$dateLastConverted"_"${timeLast:0:6}".._fritzlog_filter2.txt"
#echo 

echo
#if ls -1 response/ | grep ""$dateLast"_"$timeLast"_fritzlog_filter2.txt"
#Sekundenwerte werden mitgenommen und haben jedoch auf die Abfrage keinen Einfluss
#if ls -1 response/ | grep ""$dateLast"_"${timeLast:0:6}".._fritzlog_filter2.txt"
#Jetzt sollte es passen: Sekundenwerte werden ignoriert
if ls -1 response/ | grep ""$dateLastConverted"_"${timeLast:0:5}"_fritzlog_filter2.txt"
then
	echo "Datum bekannt"
else
	echo "Neue Datei, Fritzbox Neustart"
	# Reverse arrange fields with cut doesnt work, new solution with awk (line 70)
	#dateLastConverted=$(echo "20$(echo $dateLast | cut -d "." -f 3,2,1 | tr "." "-")")
#	Die Telegram-Token und Empfaenger liegen jetzt in einer Datei. Zeile 1 Token, Zeile 2 Empfaenger
	curl "https://api.telegram.org/bot$(sed -n 1p cred.txt)/sendMessage?chat_id=$(sed -n 2p cred.txt)&text=Fritzbox Ollern Neustart "$dateLastConverted" "${timeLast:0:5}""
	curl --location 'http://'$(sed -n 7p cred.txt)'/items/Fritzbox_Tracker?access_token='$(sed -n 6p cred.txt)'' \
	--header 'Content-Type: application/json' \
	--data '{
        "RestartDate": "'$dateLastConverted'",
        "RestartTime": "'${timeLast:0:5}'",
        "Comment": "Restart Fritzbox"
	}'
fi

mv response/fritzlog_filter2.txt "response/"$dateLastConverted"_"${timeLast:0:5}"_fritzlog_filter2.txt"
mv response/fritzlog_filter0.txt "response/"$dateLastConverted"_"${timeLast:0:5}"_fritzlog_filter0.txt"
