# TooGoodToGo Watcher  
A helper to get informed, where TooGoodToGo-Items are avaiable  

## Installation  
Python3 + Pip3 required  
Extra Packages `pip3 install -r requirements.txt`    

## Customize cred.txt  
Get your tgtg credentials with a new python3 session:
```
from tgtg import TgtgClient
client = TgtgClient(email="<your_email>")
credentials = client.get_credentials()
```
Copy in cred.txt  
See and rename cred.txt.example  
Directus Upload has to be comment out if not neccessary  

## Making executable  
`chmod +x statcheck_*.sh`  

## Get the item IDs  
Add the items to your favourites in the mobile app  
Execute the first script `./statcheck_favorites.py`  
Copy the IDs in a file called `items.txt`  

## Check the items  
### One time  
`./statcheck_trackers.py`

### As Cronjob  
```
crontab -e  
03,38 19,20,21 * * * /<your>/<work>/<dir>/statcheck_trackers.py > /tmp/tgtg_check_last.log  
```
