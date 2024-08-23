#!/bin/sh

cd /home/pi/US_WAHL

curl https://d3ak46ifsn9mnh.cloudfront.net/pw_us/feed/s2020/election/live/results_ranking.json > us_wahlergebnis.json

var_biden="$(cat us_wahlergebnis.json | awk -F '"' '{print $48}')"
var_trump="$(cat us_wahlergebnis.json | awk -F '"' '{print $72}')"
#var_biden="253"
var_ende="270"
var_gesendet="0"

if cat US_Zwischenergebnis_Last.txt | grep -c "Biden: $var_biden Trump: $var_trump"
then
	echo "Zahlen unverändert"
	#curl "https://api.telegram.org/bot<Bot-ID>/sendMessage?chat_id=<Receiver-ID>&text=win2day: Super gewonnen!!!!%0A$var_username hat gewonnen."
else
	echo "Zahlen haben sich geändert"
	echo "Biden: $var_biden Trump: $var_trump" > US_Zwischenergebnis_Last.txt
	if echo $(($var_biden > $var_ende ? 1 : 0)) | grep -c "1"
	then
		echo "Gewinn für Biden"
		curl "https://api.telegram.org/bot<Bot-ID>/sendMessage?chat_id=<Receiver-ID>&text=US Wahl Aenderung:%0ABiden hat gewonnen%0ABiden: $var_biden Trump: $var_trump."
		var_gesendet="1"
	else
		echo "Kein Gewinn für Biden"
	fi
	
	if echo $(($var_trump > $var_ende ? 1 : 0)) | grep -c "1"
	then
		echo "Gewinn für Trump"
		curl "https://api.telegram.org/bot<Bot-ID>/sendMessage?chat_id=<Receiver-ID>&text=US Wahl Aenderung:%0ATrump hat gewonnen%0ABiden: $var_biden Trump: $var_trump."
		var_gesendet="1"
	else
		echo "Kein Gewinn für Trump"
	fi
	
	if echo "$var_gesendet" | grep -c "0"
	then
		echo "Kein Gewinner"
		curl "https://api.telegram.org/bot<Bot-ID>/sendMessage?chat_id=<Receiver-ID>&text=US Wahl Aenderung:%0ABiden: $var_biden Trump: $var_trump.%0Ahttps://d3ak46ifsn9mnh.cloudfront.net/customers/praesidentschaftswahl-usa2020/aws/dpa-shop/html/index.html?customer=derstandard%26id=dpa_app-160460534353851238%26env=prod%26path=https://d3ak46ifsn9mnh.cloudfront.net/pw_us/%26trackingPixel=true%26app=dpa-electionslive%26embedType=pym%26competitionId=pw_us%26language=de%26standalone=ranking%26phase=election%26view=small%26customClass=widget200%26widgetHeader=false"
	else
		var_gesendet="1"
	fi
fi

