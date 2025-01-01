import requests
import json
import os
import telebot
from datetime import datetime

script_dir = os.path.dirname(__file__)
os.chdir(script_dir)

def field_value(doc, field_number):
    for f in doc.get('custom_fields', []):
        #print(f)
        if f["field"] == field_number and f.get('value') not in [None, '']:
            #print(f)
            return f["value"]
    print(f"{doc["title"]}: Something wrong")
    return False
    #return any(f['field'] == field_number and f.get('value') not in [None, ''] for f in doc.get('custom_fields', []))

with open('./cred.json', 'r') as openfile:
    # Reading from json file
    credentials = json.load(openfile)

with open("./lastdata.json", "r") as oldfile:
    dataOld = json.load(oldfile)

telegramToken = credentials["TELEGRAM_TOKEN"]
telegramReceiver = credentials["TELEGRAM_RECEIVER"]
paperlessToken = credentials["PAPERLESS_TOKEN"]

# Define the URL and headers for the API request
url = "http://localhost:8000/api/documents/?page=1&page_size=250&ordering=-created&truncate_content=true&document_type__id__in=5"
headers = {
    'accept': 'application/json; version=5',
    'accept-language': 'de-DE,de;q=0.9',
    'Authorization': f'Token {paperlessToken}'
}

# Define a mapping for correspondent names
correspondent_names = {
    1: "Andreas",
    2: "Sandra"
}

# Send the API request
response = requests.get(url, headers=headers)
data = response.json()

# Group documents by correspondent
documents_by_correspondent = {}
for doc in data['results']:
    correspondent = doc['correspondent']
    if correspondent not in documents_by_correspondent:
        documents_by_correspondent[correspondent] = []
    #if field_exists(doc, 2):
    #for field in doc['custom_fields']:
    literField = field_value(doc, 2)
    kilometerField = field_value(doc, 3)
    # Here also documents with zero will be filtered. This special case is not supported.
    if literField == False or kilometerField == False:
        continue
    doc["literField"] = literField
    doc["kilometerField"] = kilometerField
    #print(kilometerField)
    #print(doc)
    documents_by_correspondent[correspondent].append(doc)

print()
print()

exportstring = ""
# Process each correspondent's documents
results = {
    "timestamp": f"{datetime.now().date()}",
    "data": {}
}

for correspondent, documents in documents_by_correspondent.items():
    # Sort documents by creation date
    documents.sort(key=lambda d: d['created'])
    correspondent_name = correspondent_names.get(correspondent, f"Unknown ({correspondent})")
    data = {}
    print(correspondent_name)
    # Extract values for field 3 and field 2
    kilometerField_values = [doc['kilometerField'] for doc in documents]
    literField_values = [doc['literField'] for doc in documents]
    print("Liter (First should be ignored!)")
    print(literField_values)
    print("Mileage (Only first and last needed for Difference!)")
    print(kilometerField_values)
    # Calculate the difference for field 3 (last - first)
    kilometerField_diff = kilometerField_values[-1] - kilometerField_values[0]
    data["Kilometerdifferenz"] = kilometerField_diff
    # Calculate the sum of field 2 (excluding the first value)
    literField_sum = sum(literField_values[1:])
    data["Treibstoffmenge"] = literField_sum

    print()
    detailstring = f"{correspondent_name}: Diff-Kilometer {kilometerField_diff}km Sum-Liter {literField_sum}l"
    #exportstring = f"{exportstring}{detailstring}\n"
    #print(detailstring)

    # Calculate the result
    result = (literField_sum / kilometerField_diff) * 100 if literField_sum != 0 else 0
    data["Durchschnittsverbrauch"] = result
    results["data"][correspondent_name] = data
    print()
    print()


send = False

# Print results
for correspondent, values in results["data"].items():
    resultstring = f"{correspondent}: Diff-Kilometer {values["Kilometerdifferenz"]}km Sum-Liter {values["Treibstoffmenge"]}l\n{correspondent}: {values["Durchschnittsverbrauch"]:.2f} l/100km"
    print(resultstring)
    if dataOld["data"][correspondent]["Kilometerdifferenz"] != values["Kilometerdifferenz"]:
        send = True
    # resultstring = f"{correspondent}: {result:.2f} l/100km"
    exportstring = f"{exportstring}{resultstring}\n"
    # print(resultstring)

print()
#print(exportstring)
if send == True:
    bot = telebot.TeleBot(telegramToken, parse_mode=None) # You can set parse_mode by default. HTML or MARKDOWN
    print("Sending Telegram Message")
    bot.send_message(telegramReceiver, text=str(exportstring))
else:
    print("No changes, no message")
# Example usage: print results as dictionary
#print(results)

with open("./lastdata.json", "w") as outfile:
    outfile.write(json.dumps(results, indent=4))