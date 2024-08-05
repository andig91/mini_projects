#!/bin/bash
#date -v -2d +%F

#
# runs on Ubuntu or Alpine with curl and jq installed or docker image "andi91/curl_jq_alpine" or "curl_jq_ubuntu"
# telegram credentials in cred.txt (first line token, second receiver_id) or with environment variables (token & empfanger)
# -> see cred.txt.example
#
# Crontab configuration
# 19 19 * * * <workdir>/<skriptname>.sh > /tmp/<logname>.log
# or with docker image
# */8 * * * * docker run --rm -v "<workdir>:/mnt/Arbeitsverzeichnis" --entrypoint --entrypoint "/mnt/Arbeitsverzeichnis/<skriptname>.sh" -e token="<bot_token>" -e empfanger="<receiver_id>" andi91/curl_jq_alpine >> /tmp/<logname>.log
#

cd "$(dirname -- "$0")"
pwd -P

if [ -f "cred.txt" ]
then
	token=$(sed -n 1p cred.txt)
	empfanger=$(sed -n 2p cred.txt)
	directustoken=$(sed -n 3p cred.txt)
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

# if [ -d "tarifblatt_strom" ]; then
#   # Take action if $DIR exists. #
#   echo "Ordner existiert"
#   else
#   echo "Ordner anlegen strom"
#   mkdir "tarifblatt_strom"
# fi
if [ -d "tarifblaetter" ]; then
	# Take action if $DIR exists. #
	echo "Ordner existiert"
	else
	echo "Ordner anlegen tarifblaetter"
	mkdir "tarifblaetter"
fi

null="0"
function download_extract() {
	
	echo
	echo
	#Added a ";" to grep, because there was "GasFloat" and "GasFloatBio". Now longer Names with the same begin work also correctly
	preisalt=$(cat Entwicklung_Preise.txt | grep "$1;" | tail -n 1 | cut -d ";" -f 3)

	curl "$2" --compressed > "./EVN-Seite.html"
	preis=$(xmllint --html -xpath "(//span[@class='tariff-option-card__price-value'])[1]/text()" ./EVN-Seite.html 2>/dev/null)
	if [ "$3" ]
	then
		preis2=$(xmllint --html -xpath "(//span[@class='tariff-option-card__price-value'])[2]/text()" ./EVN-Seite.html 2>/dev/null)
	fi
	tarifbl=$(xmllint --html -xpath "string((//a[contains(@class,'large-button--meta')])[1]/@href)" ./EVN-Seite.html 2>/dev/null)
	echo "$1 $preis $preis2 Preisalt $preisalt"
	if [ $preisalt == $preis ]
	then
		aenderung="unveraendert"
		ChangesBool=false
	else
		aenderung="geaendert"
		ChangesBool=true
		aenderungstext="$aenderungstext%0APreisaenderung $1: Jetzt $preis Vorher $preisalt Preisblatt $tarifbl"
	fi
	echo "Preis $aenderung"
	echo "$(date +%F);$1;$preis;$preis2;$aenderung" >> Entwicklung_Preise.txt
	echo "$1 $tarifbl"
	echo "$(date +%F);$1;$tarifbl" >> Tarifblaetter.txt
	curl -o ./tarifblaetter/$(date +%F)_$1.pdf "$tarifbl"

	preis1point=$(echo $preis | sed "s/,/./" )
	echo $preis1point
	if [ "$preis2" ]
	then
		#echo hallo
		preis2point=$(echo $preis2 | sed "s/,/./" )
	else
		preis2point=null
	fi
	echo Senden daten $preis1point $preis2point
	curl --location 'http://'$(sed -n 4p cred.txt)'/items/EVN_Preistracker?access_token='$directustoken'' \
	--header 'Content-Type: application/json' \
	--data '{
			"Tarif": "'$1'",
			"TarifDay": '$preis1point',
			"TarifNight": '$preis2point',
			"ChangesBool": '$ChangesBool'
	}'
	#'$(sed 's/,/./' $preis2)'
}

download_extract Gas_Float https://www.evn.at/home/gas/optimafloatgas
download_extract Gas_FloatBio https://www.evn.at/home/gas/optimafloatbiogas
download_extract Gas_Flex https://www.evn.at/home/gas/optimaflexgas # invisible but there
download_extract Gas_Garant https://www.evn.at/home/gas/optimagarantgas12
download_extract Strom_Garant https://www.evn.at/home/strom/optimagarantnatur12
download_extract Strom_Aktiv https://www.evn.at/home/strom/optimaaktivnatur 
##download_extract Strom_Flex https://www.evn.at/home/strom/optimaflexnatur #deleted
##download_extract Strom_Smart https://www.evn.at/home/strom/optimasmartnaturbindung tagnacht #deleted

if [ -z "$aenderungstext" ]
then
	echo "Keine Aenderungen, Keine Nachricht"
else
	echo "$aenderungstext"
	#curl "https://api.telegram.org/bot$token/sendMessage?chat_id=$empfanger&text=Strominfo:$aenderungstext"
	curl "https://api.telegram.org/bot$token/sendMessage?chat_id=$empfanger" -d text="Strominfo: $aenderungstext"
fi

#curl "https://www.evn.at/home/gas/optimafloatgas" --compressed > "tarifblatt_gas/$(date +%F)_Tarifblatt_Gas.json"




exit
