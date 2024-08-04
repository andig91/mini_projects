#!/bin/bash

# Configuration
#base_url='http://your-paperless-ngx-instance/api/documents/'
#document_id='794'  # Replace with your actual document ID
paperlessdomain="https://paperless.<your.domain>"
csrftoken="<Your-CSRF-Token-from-BrowserDevTools>"
sessionid="<Your-sessionID-from-BrowserDevTools>"

#Make a text file. Line per line the document numbers to correct
for document_id in $(cat paperless_documents_list.txt)
do

	# Fetch the current data for the document
	response=$(curl --location ''"$paperlessdomain"'/api/documents/'$document_id'/' \
		--header 'accept: application/json; version=5' \
		--header 'accept-language: de-DE,de;q=0.9' \
		--header 'cookie: csrftoken='"$csrftoken"'; sessionid='"$sessionid"'; csrftoken='"$csrftoken"'' \
		--header 'priority: u=1, i' \
		--header 'referer: '"$paperlessdomain"'/documents/'$document_id'/details' \
		--header 'sec-ch-ua: "Not)A;Brand";v="99", "Brave";v="127", "Chromium";v="127"' \
		--header 'sec-ch-ua-mobile: ?0' \
		--header 'sec-ch-ua-platform: "macOS"' \
		--header 'sec-fetch-dest: empty' \
		--header 'sec-fetch-mode: cors' \
		--header 'sec-fetch-site: same-origin' \
		--header 'sec-gpc: 1' \
		--header 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36' \
		--header 'x-csrftoken: '"$csrftoken"'')
	if [[ $? -ne 0 ]]; then
		echo
		echo "Failed to fetch document data"
		exit 1
	fi
	#echo "$response"

	title=$(echo "$response" | ./jq-osx-amd64 '.title')
	newdate=${title:1:10}
	echo $document_id $title $newdate

	#exit
	#api_token='your_api_token'  # Replace with your actual API token
	#new_created_value='2021-05-31'  # New value for the created field

	echo
	echo
	# Use jq to update the 'created' field and remove unnecessary fields
	updated_data=$(echo "$response" | ./jq-osx-amd64 --arg new_created "$newdate" '
		.created = ($new_created + "T00:00:00Z") | .created_date = $new_created |
		del(.title, .modified, .added, .deleted_at, .archive_serial_number, .original_file_name, .archived_file_name, .owner, .permissions, .notes, .custom_fields, .content) 
	')

	echo $updated_data

	echo
	echo
	# Send the updated data back to the API
	update_response=$(curl --location --request PUT ''"$paperlessdomain"'/api/documents/'$document_id'/' \
		--header 'accept: application/json; version=5' \
		--header 'accept-language: de-DE,de;q=0.9' \
		--header 'content-type: application/json' \
		--header 'cookie: csrftoken='"$csrftoken"'; sessionid='"$sessionid"'; csrftoken='"$csrftoken"'' \
		--header 'origin: https://'"$paperlessdomain"'' \
		--header 'priority: u=1, i' \
		--header 'referer: '"$paperlessdomain"'/documents/'$document_id'/details' \
		--header 'sec-ch-ua: "Not)A;Brand";v="99", "Brave";v="127", "Chromium";v="127"' \
		--header 'sec-ch-ua-mobile: ?0' \
		--header 'sec-ch-ua-platform: "macOS"' \
		--header 'sec-fetch-dest: empty' \
		--header 'sec-fetch-mode: cors' \
		--header 'sec-fetch-site: same-origin' \
		--header 'sec-gpc: 1' \
		--header 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36' \
		--header 'x-csrftoken: '"$csrftoken"'' \
		--data "$updated_data")
	#update_response=$(curl -s -o /dev/null -w "%{http_code}" -X PUT -H "Authorization: Token $api_token" -H "Content-Type: application/json" -d "$updated_data" "${base_url}${document_id}/")
	if [[ "$update_response" -ne 200 ]]; then
  		echo
  		echo "Failed to update document data: HTTP status $update_response"
  		exit 1
	fi

	echo
	echo "Document updated successfully."
#exit
done