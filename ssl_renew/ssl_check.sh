#!/bin/bash

echo $(date +%Y%m%d_%H%M%S)
cd "$(dirname -- "$0")"
pwd -P

#getRestzeit () {
#	timeout 5 bash -c "openssl s_client -servername $(sed -n 6p cred.txt) -connect $(sed -n 7p cred.txt):443 | openssl x509 -dates > SSL.txt"
#	datecert=$(date -d "$(cat SSL.txt | grep notAfter | cut -d "=" -f 2)" +%Y%m%d)
#	restzeit=$((datecert - $(date +%Y%m%d)))
#	echo $restzeit
#}
getRestzeit () {
	timeout 5 bash -c "openssl s_client -servername $(sed -n 6p cred.txt) -connect $(sed -n 7p cred.txt):443 | openssl x509 -dates > SSL.txt"
	datecert=$(date -d "$(cat SSL.txt | grep notAfter | cut -d "=" -f 2)" +%s)
	#restzeit=$(($datecert - $(date +%s)))
	restzeit=$(( ($datecert - $(date +%s)) / (60*60*24) ))
	echo $(date -d "$(cat SSL.txt | grep notAfter | cut -d "=" -f 2)" +%Y-%m-%d)
	echo $restzeit
}

updateSend () {
	#curl "https://dynamicdns.park-your-domain.com/update?domain=$(sed -n 5p cred.txt)&password=$(sed -n 3p cred.txt)&host=$(sed -n 4p cred.txt)&ip=$1"
	curl "https://api.telegram.org/bot$(sed -n 1p cred.txt)/sendMessage?chat_id=$(sed -n 2p cred.txt)&text=$3"
	curl --location "http://$(sed -n 9p cred.txt)/items/SSL_Check_BWINT?access_token=$(sed -n 8p cred.txt)" \
		--header 'Content-Type: application/json' \
		--data '{
		"OpenClose": "'$2'", "Restzeit": "'$1'","Comment": "'"$3"'"
		}'
}


#IP_now=$(ping $(sed -n 6p cred.txt) -W 1 -c 1 | sed -n 1p | cut -d "(" -f 2 | cut -d ")" -f 1)
IP_now=$(getent ahostsv4 $(sed -n 6p cred.txt) | sed -n 1p | cut -d " " -f 1)

if [ ! $IP_now = "172.16.72.255" ]; then
	
	getRestzeit

	if [ $restzeit -gt 25 ]; then
		echo "Zertifikat update"
		curl "https://dynamicdns.park-your-domain.com/update?domain=$(sed -n 5p cred.txt)&password=$(sed -n 3p cred.txt)&host=$(sed -n 4p cred.txt)&ip=172.16.72.255"
		comment="$(sed -n 4p cred.txt): Zertifikat wieder $restzeit Tage gueltig"
		echo $comment
		updateSend "$restzeit" "Extended/Closed" "$comment"
		#curl "https://api.telegram.org/bot$(sed -n 1p cred.txt)/sendMessage?chat_id=$(sed -n 2p cred.txt)&text=$comment"
		#curl --location "http://'$(sed -n 9p cred.txt)'/items/SSL_Check_BWINT?access_token=$(sed -n 8p cred.txt)" --header 'Content-Type: application/json' --data '{"OpenClose": "Extended/Closed", "Restzeit": "'$restzeit'","Comment": "'"$comment"'"}'
	else
		echo "Zertifikat noch nicht neu"
	fi
else
	echo $(($(sed -n 1p lastdate.txt) - $(date +%Y%m%d)))
	if [ $(($(sed -n 1p lastdate.txt) - $(date +%Y%m%d))) = 0 ]; then
		echo $(date -d "$(cat SSL.txt | grep notAfter | cut -d "=" -f 2)" +%Y-%m-%d)
		echo "Heute schon gelaufen"	
	else
		echo "Heute das erste Mal"
		date +%Y%m%d > lastdate.txt

		getRestzeit

		if [ $restzeit -gt 25 ]; then
			echo "Groesser 25 -> nichts zu tun"
		else
			echo "Zertifikat lauft bald ab"
			curl "https://dynamicdns.park-your-domain.com/update?domain=$(sed -n 5p cred.txt)&password=$(sed -n 3p cred.txt)&host=$(sed -n 4p cred.txt)"
			comment="$(sed -n 4p cred.txt): Zertifikat nur mehr $restzeit Tage gueltig"
			echo $comment
			updateSend "$restzeit" "Opened" "$comment"
			#curl "https://api.telegram.org/bot$(sed -n 1p cred.txt)/sendMessage?chat_id=$(sed -n 2p cred.txt)&text=$comment"
			#curl --location "http://'$(sed -n 9p cred.txt)'/items/SSL_Check_BWINT?access_token=$(sed -n 8p cred.txt)" --header 'Content-Type: application/json' --data '{"OpenClose": "Opened", "Restzeit": '$restzeit',"Comment": "'"$comment"'"}'
		fi
	fi
fi






