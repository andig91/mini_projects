#!/bin/bash


foldername=/<Your>/<File>/<Path>
#filename=2021-07-02_Hofer_OCR.pdf
#Correspondent 3 = Gemeinsam, 1 = Andreas, 2 = Sandra, 4 = Mia, 5 = Sonstiges
#https://$paperlessdomain/api/correspondents/?page=1&last_correspondence=true&full_perms=true
correspondent=5
paperlessdomain="https://paperless.<your.domain>"
csrftoken="<Your-CSRF-Token-from-BrowserDevTools>"
sessionid="<Your-sessionID-from-BrowserDevTools>"

#for Variable in $(ls -1 $foldername/newm*.pdf)
find "$foldername" -maxdepth 1 -name '*.pdf' -print0 | while IFS= read -r -d '' Variable
do
	echo "$Variable"
	filename=$(basename "$Variable")
	datecreated=$(basename "$Variable" | cut -d "_" -f 1)
	echo "$datecreated;$filename"
	curl --location ''"$paperlessdomain"'/api/documents/post_document/' \
		--header 'accept: application/json; version=5' \
		--header 'accept-language: de-DE,de;q=0.9' \
		--header 'cookie: csrftoken='"$csrftoken"'; sessionid='"$sessionid"'' \
		--header 'origin: '"$paperlessdomain"'' \
		--header 'priority: u=1, i' \
		--header 'referer: '"$paperlessdomain"'/dashboard' \
		--header 'sec-ch-ua: "Not)A;Brand";v="99", "Brave";v="127", "Chromium";v="127"' \
		--header 'sec-ch-ua-mobile: ?0' \
		--header 'sec-ch-ua-platform: "macOS"' \
		--header 'sec-fetch-dest: empty' \
		--header 'sec-fetch-mode: cors' \
		--header 'sec-fetch-site: same-origin' \
		--header 'sec-gpc: 1' \
		--header 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36' \
		--header 'x-csrftoken: '"$csrftoken"'' \
		--form 'document=@"'"$foldername/$filename"'"' \
		--form 'created="'$datecreated' 02:00:00+02:00"' \
		--form 'correspondent="'$correspondent'"'
echo
echo
done

#exit
