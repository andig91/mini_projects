#!/usr/bin/env python3
# https://stackoverflow.com/questions/2429511/why-do-people-write-usr-bin-env-python-on-the-first-line-of-a-python-script

import json
#https://github.com/ahivert/tgtg-python
from tgtg import TgtgClient

# Read from File
#favfile = open("favorites.json", "r")
#print(favfile.read())
#favjson = json.loads(favfile.read())


# Read from API
credfile = open("cred.txt", "r")
credfileLine = credfile.readlines()
tgtg_accesstoken=credfileLine[0][0:-1]
#print(tgtg_accesstoken)
tgtg_refreshtoken=credfileLine[1][0:-1]
#print(tgtg_refreshtoken)
tgtg_userid=credfileLine[2][0:-1]
#print(tgtg_userid)
tgtg_cookie=credfileLine[3][0:-1]
#print(tgtg_cookie)
#telegram_token=credfileLine[4][0:-1]
#print(telegram_token)
#telegram_receiver=credfileLine[5][0:-1]
#print(telegram_receiver)

#client = TgtgClient(access_token=str(credfileLine[0][0:-1]), refresh_token=str(credfileLine[1][0:-1]), user_id=str(credfileLine[2][0:-1]), cookie=str(credfileLine[3][0:-1]))
client = TgtgClient(access_token=str(tgtg_accesstoken), refresh_token=str(tgtg_refreshtoken), user_id=str(tgtg_userid), cookie=str(tgtg_cookie))

favjson = client.get_items()


#print(json.dumps(favjson))

i=1
for x in favjson:
  #print(i)
  print(str(i) + ";" + x["item"]["item_id"] + ";" + x["item"]["name"] + ";" + x["store"]["store_name"] + ";" + x["store"]["branch"] + ";" + str(x["items_available"]) + ";" ) 
  i=i+1