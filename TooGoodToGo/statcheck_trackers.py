#!/usr/bin/env python3
# https://stackoverflow.com/questions/2429511/why-do-people-write-usr-bin-env-python-on-the-first-line-of-a-python-script

# Get your login credentials with:
# from tgtg import TgtgClient
# client = TgtgClient(email="<your_email>")
# credentials = client.get_credentials()
#
# Need a file "cred.txt" with following content from tgtg and telegram
# <tgtg your_access_token>
# <tgtg your_refresh_token>
# <tgtg your_user_id>
# <tgtg cookie>
# <Telegram Token>
# <Telegram receiver>
# <Directus-API-Key>
# <Directus-Domain>

import sys
import subprocess

# Let the script run in the directory where the script file is located
# https://stackoverflow.com/questions/14653161/running-a-program-from-its-directory-using-cron
import os
scriptdir =  os.path.dirname(os.path.abspath(__file__))
os.chdir(scriptdir)

# https://www.activestate.com/resources/quick-reads/how-to-install-python-packages-using-a-script/
# implement pip as a subprocess:
#subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'pyTelegramBotAPI'])
#subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'tgtg'])

# https://github.com/eternnoir/pyTelegramBotAPI#a-simple-echo-bot
import telebot
# For API Calls
import requests
import json
# https://github.com/ahivert/tgtg-python
from tgtg import TgtgClient
# https://www.w3schools.com/python/python_datetime.asp
import datetime as dt

zeitpunkt = dt.datetime.now()
print(zeitpunkt.strftime("%Y-%m-%d_%H:%M"))

logfile = open("tgtg_logfile.txt", "r")
loglines = logfile.readlines()
logfile.close()

logfile = open("tgtg_logfile.txt", "a")
logfile.write(zeitpunkt.strftime("%Y-%m-%d_%H:%M") + ";Lauf gestartet!\n")


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
telegram_token=credfileLine[4][0:-1]
#print(telegram_token)
telegram_receiver=credfileLine[5][0:-1]
#print(telegram_receiver)
directus_token=credfileLine[6][0:-1]
directus_domain=credfileLine[7][0:-1]
directus_url = "http://" + directus_domain + "/items/TooGoodToGo?access_token=" + directus_token

#client = TgtgClient(access_token=str(credfileLine[0][0:-1]), refresh_token=str(credfileLine[1][0:-1]), user_id=str(credfileLine[2][0:-1]), cookie=str(credfileLine[3][0:-1]))
client = TgtgClient(access_token=str(tgtg_accesstoken), refresh_token=str(tgtg_refreshtoken), user_id=str(tgtg_userid), cookie=str(tgtg_cookie))

itemfile = open("items.txt", "r")
itemfileLines = itemfile.readlines()

messagetext = ""

for item in itemfileLines:
  x = client.get_item(item_id=item)
  #print(x["item"]["item_id"] + ";" + x["item"]["name"] + ";" + x["store"]["store_name"] + ";" + x["store"]["branch"] + ";" + str(x["items_available"]) + ";" ) 
  #x["items_available"] = x["items_available"] + 1
  if (x["items_available"] > 0):
    itemfound = 0
    for logline in loglines[-120:]:
      searchstring = x["item"]["name"] + ";" + x["store"]["branch"]
      if (zeitpunkt.strftime("%Y-%m-%d") in logline) and (searchstring in logline):
        print(logline)
        print(searchstring + ";Bereits geloggt")
        itemfound = 1
        break
    if itemfound == 0: 
      messagetext_single = x["item"]["name"] + ";" + x["store"]["branch"] + ";" + str(x["items_available"]) + ";"
      print(messagetext_single)
      logfile.write(zeitpunkt.strftime("%Y-%m-%d_%H:%M") + ";" + messagetext_single + "\n")
      messagetext = messagetext + "\n" + messagetext_single
      # Upload to Directus
      payload = json.dumps({
        "Item": x["item"]["name"],
        "Store": x["store"]["branch"],
        "Amount": x["items_available"]
      })
      headers = {
        'Content-Type': 'application/json'
      }
      response = requests.request("POST", directus_url, headers=headers, data=payload)
      print(response.text)


if (len(messagetext) > 0):
  bot = telebot.TeleBot(str(telegram_token), parse_mode=None) # You can set parse_mode by default. HTML or MARKDOWN
  bot.send_message(telegram_receiver, text=str(messagetext))
  logfile.write(zeitpunkt.strftime("%Y-%m-%d_%H:%M") + ";Nachricht versandt.\n")
  
else:
  print("Keine neuen Angebote.")
  logfile.write(zeitpunkt.strftime("%Y-%m-%d_%H:%M") + ";Keine neuen Angebote.\n")

#x = client.get_item(item_id=867027)
#print(x["item"]["item_id"] + ";" + x["item"]["name"] + ";" + x["store"]["store_name"] + ";" + x["store"]["branch"] + ";" + str(x["items_available"]) + ";" ) 
#print(singleitem)

logfile.write(zeitpunkt.strftime("%Y-%m-%d_%H:%M") + ";Lauf beendet!\n")
logfile.close()

exit()

favfile = open("favorites.json", "r")
#print(favfile.read())

favjson = json.loads(favfile.read())
print(json.dumps(favjson[2]))

i=0
for x in favjson:
  print(i)
  print(x["item"]["item_id"] + ";" + x["item"]["name"] + ";" + x["store"]["store_name"] + ";" + x["store"]["branch"] + ";" + str(x["items_available"]) + ";" ) 
  i=i+1