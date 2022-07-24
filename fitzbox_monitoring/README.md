# Firtzbox Monitoring  
Connect with the FritzBox, download and store the logs for analyse   
Sends to me a notification per telegram, if FritzBox is restarted  

## Install Curl and JQ  
`sudo apt install curl jq -y`  
Docker images "andi91/curl_jq_alpine", "andi91/curl_jq_debian" and "andi91/curl_jq_ubuntu" are built for that  

## Customize cred.txt  
First line bot-token, second line receiver, thrid for FritzBox-User, fourth for FritzBox-Password and fifth for FritzBox-IP-Address  
See and rename cred.txt.example  

## Making executable  
`chmod +x fritzbox.sh`  

## Execute the script  
### One time  
`./fritzbox.sh`
`docker run --rm -v "$(pwd):/mnt/Arbeitsverzeichnis" --entrypoint --entrypoint "/mnt/Arbeitsverzeichnis/fritzbox.sh" andi91/curl_jq_alpine`

### As Cronjob  
```
crontab -e  
19 19 * * * <workdir>/fritzbox.sh > /tmp/fritzbox_last.log  
```
or with docker image  
`19 19 * * * docker run --rm -v "<workdir>:/mnt/Arbeitsverzeichnis" --entrypoint --entrypoint "/mnt/Arbeitsverzeichnis/ubiquiti_notify.sh" andi91/curl_jq_alpine >> /tmp/fritzbox_last.log`  
