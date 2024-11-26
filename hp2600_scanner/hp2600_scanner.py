import requests
import time
import sys
from datetime import datetime
import xml.etree.ElementTree as ET

##################################
# HP DeskJet 2630 
# Scan single pages without the need of the webinterface
# python3 <skriptname.py> <optional-filename>
# python3 hp2600_scanner.py Test

# Set your printer domain/ip here
domain = "http://10.0.22.27"

# HTTP-call reverse engineering by myself
# Script written with AI(-Support)
##################################


def scan_document(document_name="ScanDocument"):
    # URL und Header für den ersten Scan-Job POST-Request
    scan_url = f"{domain}/eSCL/ScanJobs"
    headers = {
        "accept": "*/*",
        "accept-language": "de-DE,de;q=0.8",
        "content-type": "text/xml",
        "priority": "u=1, i",
        "sec-ch-ua": "\"Chromium\";v=\"130\", \"Brave\";v=\"130\", \"Not?A_Brand\";v=\"99\"",
        "sec-ch-ua-mobile": "?0",
        "sec-ch-ua-platform": "\"macOS\"",
        "sec-fetch-dest": "empty",
        "sec-fetch-mode": "cors",
        "sec-fetch-site": "same-origin",
        "sec-gpc": "1"
    }
    
    ################################
    # In this XML you can modify the print settings
    # Brightness and Contrast => 1800 Brighter, 200 Darker/More Contrast, 1000 Medium 
	# XResolution and YResolution = DPI => 300 Standard Text, 600 High, 200 Foto
    # Scan Region = Input Format => All special formats are better over WebIF
    ################################
    body = """
    <scan:ScanSettings xmlns:scan="http://schemas.hp.com/imaging/escl/2011/05/03" xmlns:dd="http://www.hp.com/schemas/imaging/con/dictionaries/1.0/" xmlns:dd3="http://www.hp.com/schemas/imaging/con/dictionaries/2009/04/06" xmlns:fw="http://www.hp.com/schemas/imaging/con/firewall/2011/01/05" xmlns:scc="http://schemas.hp.com/imaging/escl/2011/05/03" xmlns:pwg="http://www.pwg.org/schemas/2010/12/sm">
        <pwg:Version>2.1</pwg:Version>
        <scan:Intent>Document</scan:Intent>
        <pwg:ScanRegions>
            <pwg:ScanRegion>
                <pwg:Height>3507</pwg:Height>
                <pwg:Width>2481</pwg:Width>
                <pwg:XOffset>0</pwg:XOffset>
                <pwg:YOffset>0</pwg:YOffset>
            </pwg:ScanRegion>
        </pwg:ScanRegions>
        <pwg:InputSource>Platen</pwg:InputSource>
        <scan:DocumentFormatExt>application/pdf</scan:DocumentFormatExt>
        <scan:XResolution>300</scan:XResolution>
        <scan:YResolution>300</scan:YResolution>
        <scan:ColorMode>RGB24</scan:ColorMode>
        <scan:CompressionFactor>25</scan:CompressionFactor>
        <scan:Brightness>1000</scan:Brightness>
        <scan:Contrast>1000</scan:Contrast>
    </scan:ScanSettings>
    """

    # Führe den Scan-Job aus
    response = requests.post(scan_url, headers=headers, data=body)
    if response.status_code == 201:
        print("Scan-Job erfolgreich gestartet.")
    else:
        print("Fehler beim Starten des Scan-Jobs:", response.status_code)
        return

    # Warte 0.1 Sekunden
    time.sleep(0.1)

    # URL zum Abrufen des Scanner-Status
    status_url = "https://drucker.gruber.live/eSCL/ScannerStatus"
    status_response = requests.get(status_url)

    if status_response.status_code == 200:
        # Parse XML, um die erste JobUuid zu extrahieren
        root = ET.fromstring(status_response.content)
        namespaces = {'scan': 'http://schemas.hp.com/imaging/escl/2011/05/03', 'pwg': 'http://www.pwg.org/schemas/2010/12/sm'}

        # Extrahiere die erste JobUuid
        job_info = root.find(".//scan:Jobs/scan:JobInfo", namespaces)
        if job_info is not None:
            job_uuid = job_info.find("pwg:JobUuid", namespaces).text
            print("JobUuid gefunden:", job_uuid)
            
            # Lade das PDF-Dokument herunter
            download_url = f"{domain}/eSCL/ScanJobs/{job_uuid}/NextDocument"
            pdf_response = requests.get(download_url)
            
            if pdf_response.status_code == 200:
                # Erstelle den Dateinamen mit Datum und Uhrzeit
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"{timestamp}_{document_name}.pdf"
                
                # Speichere das Dokument als PDF
                with open(filename, "wb") as file:
                    file.write(pdf_response.content)
                print(f"PDF-Dokument erfolgreich heruntergeladen und gespeichert als '{filename}'.")
            else:
                print("Fehler beim Herunterladen des PDF-Dokuments:", pdf_response.status_code)
        else:
            print("Keine JobUuid gefunden.")
    else:
        print("Fehler beim Abrufen des Scanner-Status:", status_response.status_code)

if __name__ == "__main__":
    document_name = sys.argv[1] if len(sys.argv) > 1 else "ScanDocument"
    try:
        while True:
            scan_document(document_name)
            weiter = input("Möchtest du ein weiteres Dokument scannen? (Enter für Ja, Strg+C zum Abbrechen): ")
            if weiter.strip() != "":
                print("Scanvorgang beendet.")
                break
    except KeyboardInterrupt:
        print("\nScanvorgang abgebrochen.")
