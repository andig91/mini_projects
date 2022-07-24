# Ubiquity Firmware Watcher  
Looking for new Ubiquiti firmware for Accesspoint "uap-ac-lr" (controled per url-parameter)  
Sends to me a notification per telegram  

## Install Curl and JQ  
`sudo apt install curl jq -y`  
Docker images "andi91/curl_jq_alpine", "andi91/curl_jq_debian" and "andi91/curl_jq_ubuntu" are built for that  

## Customize cred.txt  
First line bot-token, second line receiver  
See and rename cred.txt.example  

## Making executable  
`chmod +x ubiquiti_notify.sh`  

## Execute the script  
### One time  
`./ubiquiti_notify.sh`
`docker run --rm -v "$(pwd):/mnt/Arbeitsverzeichnis" --entrypoint --entrypoint "/mnt/Arbeitsverzeichnis/ubiquiti_notify.sh" andi91/curl_jq_alpine`

### As Cronjob  
```
crontab -e  
19 19 * * * <workdir>/ubiquiti_notify.sh > /tmp/ubiquiti_last.log  
```
or with docker image  
`19 19 * * * docker run --rm -v "<workdir>:/mnt/Arbeitsverzeichnis" --entrypoint --entrypoint "/mnt/Arbeitsverzeichnis/ubiquiti_notify.sh" andi91/curl_jq_alpine >> /tmp/ubiquiti_last.log`  
