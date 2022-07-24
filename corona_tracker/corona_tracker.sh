#!/bin/bash
#date -v -2d +%F

#
# runs on Ubuntu or Alpine with curl and jq installed or docker image "andi91/curl_jq_alpine" or "curl_jq_ubuntu"
# telegram credentials in cred.txt (first line token, second receiver_id) or with environment variables (token & empfanger)
# -> see cred.txt.example
#
# Crontab configuration
# 19 19 * * * <workdir>/ubiquiti_notify.sh > /tmp/ubiquiti_last.log
# or with docker image
# */8 * * * * docker run --rm -v "<workdir>:/mnt/Arbeitsverzeichnis" --entrypoint --entrypoint "/mnt/Arbeitsverzeichnis/corona_tracker.sh" -e token="<bot_token>" -e empfanger="<receiver_id>" andi91/curl_jq_alpine >> /tmp/ubiquiti_last.log
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

if [ -d "covid_downloads" ]; then
  # Take action if $DIR exists. #
  echo "Ordner existiert"
  else
  echo "Ordner anlegen"
  mkdir "covid_downloads"
fi

null="0"
curl "https://covid19-dashboard.ages.at/data/JsonData.json" --compressed > "covid_downloads/$(date +%F)_corona.json"


datum=$(date -d "0 days ago" +%F)
zahlpro100T=$(cat "covid_downloads/$(date +%F)_corona.json" | jq --arg datum $datum '.CovidFaelle_Timeline[]| select( .BundeslandID | contains(10)) | select( .Time | contains($datum)) | .SiebenTageInzidenzFaelle')
versenden100T=$(echo Pro 100T: $datum ${zahlpro100T:0:6})

if [ -z "$zahlpro100T" ]
then
datum=$(date -d "1 days ago" +%F)
zahlpro100T=$(cat "covid_downloads/$(date +%F)_corona.json" | jq --arg datum $datum '.CovidFaelle_Timeline[]| select( .BundeslandID | contains(10)) | select( .Time | contains($datum)) | .SiebenTageInzidenzFaelle')
versenden100T=$(echo Pro 100T: $datum ${zahlpro100T:0:6})
fi

echo $versenden100T

geimpft=$(curl https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/vaccinations/country_data/Austria.csv | tail -n 1 | cut -d '"' -f 1,3 | cut -d , -f 2,6,7,8)
geimpft_nachricht=$(echo Impfungen: $(echo $geimpft | cut -d , -f 1) Erste $(echo $geimpft | cut -d , -f 2) Voll $(echo $geimpft | cut -d , -f 3) Booster $(echo $geimpft | cut -d , -f 4))

echo $geimpft_nachricht

for tage in 8 7 6 5 4 3 2 1 0
do

#https://www.cyberciti.biz/tips/linux-unix-get-yesterdays-tomorrows-date.html
#MacOS kennt "-v" und man kann mit einer Syntax arbeiten
#datum=$(date -v -"$tage"d +%F)
#Debain (und andere Linux) versteht sich auf eine "wörtliche Syntax"
datum=$(date -d ""$tage" days ago" +%F)
#datum="2020-11"

#cat "covid_downloads/$(date +%F)_corona.json" | ./jq-osx-amd64 --arg datum $datum '.CovidFaelle_Timeline[]| select( .BundeslandID | contains(10)) | select( .Time | contains($datum)) | {Betrifft: .Bundesland, Datum: .Time, Faelle: .AnzahlFaelle}'
#faelle=$(cat "covid_downloads/$(date +%F)_corona.json" | ./jq-osx-amd64 --arg datum $datum '.CovidFaelle_Timeline[]| select( .BundeslandID | contains(10)) | select( .Time | contains($datum)) | .AnzahlFaelle')
faelle=$(cat "covid_downloads/$(date +%F)_corona.json" | jq --arg datum $datum '.CovidFaelle_Timeline[]| select( .BundeslandID | contains(10)) | select( .Time | contains($datum)) | .AnzahlFaelle')
echo $datum $faelle

#echo $(($faelle > 0 ? 1 : 0))
#if echo $(($faelle > 0 ? 1 : 0)) | grep -c "1"
#if [ ! -z "$faelle" ] Wenn nicht leer
if [ -z "$faelle" ]
then
	echo "Keine Zahlen für $datum"
else
	if cat corona_bekannt.txt | grep $datum | grep -c $faelle
	then
		echo "$datum Zahlen bekannt"

	else
		if cat corona_bekannt.txt | grep -c $datum
		then
			faelle_alt=$(cat corona_bekannt.txt | grep $datum | cut -d " " -f 2)
			sed -i -e "/^$datum/c$datum $faelle" corona_bekannt.txt
			# -i Ändert aktuelle Datei
			# Doppelte " machen es möglich mit Variablen zu arbeiten (beispiel unterbei hat nur mit Text funktioniert)
			#sed -i -e '/^2020-10-31/c2020-10-31 111111111' corona_bekannt.txt
			echo "$datum Zahlen aktualisiert"
			nachricht=$(echo "$nachricht%0A$datum $faelle_alt -> $faelle")
		else
			echo $datum $faelle >> corona_bekannt.txt
			echo "$datum Zahlen eingetragen"
			nachricht=$(echo "$nachricht%0A$datum $faelle")
		fi
		#nachricht=$(echo $nachricht%0A$datum $faelle)
	fi
fi


done
echo $nachricht $versenden100T
if [ ! -z "$nachricht" ]
then
curl "https://api.telegram.org/bot$token/sendMessage?chat_id=$empfanger&text=Corona Änderung:$nachricht%0A$versenden100T%0A$geimpft_nachricht"
fi
