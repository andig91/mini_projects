# EVN Strom- Gaspreis-Tracker
Looking for new or changed covid data in austria and sends to me with telegram  

## Install Curl and JQ  
`sudo apt install curl libxml2-utils -y`  

## Customize cred.txt  
First line bot-token, second line receiver  
See and rename cred.txt.example  

## Making executable  
`chmod +x evn_strom_gas_preis.sh`  

## Execute the script  
### One time  
`./evn_strom_gas_preis.sh`  

### As Cronjob  
```
crontab -e  
*/8 * * * * <workdir>/evn_strom_gas_preis.sh > /tmp/evn_preise_last.log  
```
