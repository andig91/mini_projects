import requests
import time
import sys
from datetime import datetime
import xml.etree.ElementTree as ET
from PyPDF2 import PdfMerger
import os

##################################
# HP DeskJet 2630 
# Scan single pages without the need of the webinterface
# python3 <skriptname.py> <optional-filename>
# python3 hp2600_scanner.py Test

# Set your printer domain/ip here
domain = "http://10.0.22.27"
# Set your stirlingpdf domain/ip here
domain_stirlingpdf = "https://stirlingpdf.your.domain"

# HTTP-call reverse engineering by myself
# Script written with AI(-Support)
##################################



def scan_document(document_name="ScanDocument"):
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

    response = requests.post(scan_url, headers=headers, data=body)
    if response.status_code == 201:
        print("Scan-Job erfolgreich gestartet.")
    else:
        print("Fehler beim Starten des Scan-Jobs:", response.status_code)
        return None

    time.sleep(0.1)

    status_url = f"{domain}/eSCL/ScannerStatus"
    status_response = requests.get(status_url)

    if status_response.status_code == 200:
        root = ET.fromstring(status_response.content)
        namespaces = {'scan': 'http://schemas.hp.com/imaging/escl/2011/05/03', 'pwg': 'http://www.pwg.org/schemas/2010/12/sm'}

        job_info = root.find(".//scan:Jobs/scan:JobInfo", namespaces)
        if job_info is not None:
            job_uuid = job_info.find("pwg:JobUuid", namespaces).text
            download_url = f"{domain}/eSCL/ScanJobs/{job_uuid}/NextDocument"
            pdf_response = requests.get(download_url)
            
            if pdf_response.status_code == 200:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"{timestamp}_{document_name}.pdf"
                with open(filename, "wb") as file:
                    file.write(pdf_response.content)
                print(f"PDF-Dokument gespeichert als '{filename}'.")
                return filename
            else:
                print("Fehler beim Herunterladen des PDF-Dokuments:", pdf_response.status_code)
    else:
        print("Fehler beim Abrufen des Scanner-Status:", status_response.status_code)
    return None

def merge_pdfs(pdf_list, output_filename="merged_document.pdf"):
    merger = PdfMerger()
    for pdf in pdf_list:
        merger.append(pdf)
    merger.write(output_filename)
    merger.close()
    print(f"Dokumente zusammengeführt als '{output_filename}'")
    return output_filename

def add_ocr_layer(file_path):
    url = f"{domain_stirlingpdf}/api/v1/misc/ocr-pdf"
    payload = {
        'languages': 'deu',
        'ocrType': 'skip-text',
        'ocrRenderType': 'hocr'
    }
    files = [
        ('fileInput', (file_path, open(file_path, 'rb'), 'application/pdf'))
    ]
    headers = {
        'accept': '*/*',
        'accept-language': 'de-DE,de;q=0.8'
    }

    response = requests.post(url, headers=headers, data=payload, files=files)
    if response.status_code == 200:
        # Neuen Dateinamen mit `_OCR` vor der Dateiendung erstellen
        base, ext = os.path.splitext(file_path)
        filename = f"{base}_OCR{ext}"
        with open(filename, "wb") as file:
            file.write(response.content)
        print(f"PDF-Dokument mit OCR gespeichert als '{filename}'.")
    else:
        print("Fehler beim Hinzufügen des OCR-Layers:", response.status_code)

if __name__ == "__main__":
    document_name = sys.argv[1] if len(sys.argv) > 1 else "ScanDocument"
    scanned_files = []

    try:
        while True:
            filename = scan_document(document_name)
            if filename:
                scanned_files.append(filename)

            weiter = input("Möchtest du ein weiteres Dokument scannen? (Enter für Ja, Eingabe von 'n' für Nein): ")
            if weiter.strip().lower() == "n":
                break

        if len(scanned_files) > 1:
            merge_option = input("Möchtest du die Dokumente zusammenführen? (Enter für Ja, 'n' für Nein): ")
            if merge_option.strip().lower() != "n":
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                merged_filename = merge_pdfs(scanned_files, f"{timestamp}_{document_name}_merged.pdf")
                scanned_files = [merged_filename]

        ocr_option = input("Möchtest du einen OCR-Layer hinzufügen? (Enter für Ja, 'n' für Nein): ")
        if ocr_option.strip().lower() != "n":
            for file in scanned_files:
                add_ocr_layer(file)

    except KeyboardInterrupt:
        print("\nScanvorgang abgebrochen.")
