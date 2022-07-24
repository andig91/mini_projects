# Corona Tracker
Looking for new or changed covid data in austria and sends to me with telegram  

## Install Curl and JQ  
`sudo apt install curl jq -y`  
Docker images "andi91/curl_jq_alpine", "andi91/curl_jq_debian" and "andi91/curl_jq_ubuntu" are built for that  

## Customize cred.txt  
First line bot-token, second line receiver  
See and rename cred.txt.example  

## Making executable  
`chmod +x corona_tracker.sh`  

## Execute the script  
### One time  
`./corona_tracker.sh`
`docker run --rm -v "$(pwd):/mnt/Arbeitsverzeichnis" --entrypoint --entrypoint "/mnt/Arbeitsverzeichnis/corona_tracker.sh" andi91/curl_jq_alpine`

### As Cronjob  
```
crontab -e  
*/8 * * * * <workdir>/corona_tracker.sh > /tmp/covid_last.log  
```
or with docker image  
`*/8 * * * * docker run --rm -v "<workdir>:/mnt/Arbeitsverzeichnis" --entrypoint --entrypoint "/mnt/Arbeitsverzeichnis/corona_tracker.sh" andi91/curl_jq_alpine >> /tmp/covid_last.log`  
