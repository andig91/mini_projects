#!/bin/bash

# Verzeichnis festlegen
folder="/path/to/series/S04"
# Schlagwort definieren
keyword="Trennwort"

# Durchlaufe alle Dateien im Verzeichnis
for file in "$folder"/*; do
    # Prüfe, ob es sich um eine Datei handelt
    if [[ -f "$file" ]]; then
    	# https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
        # Extrahiere den Dateinamen ohne Pfad und die Dateiendung
        filename=$(basename "$file")
        extension="${filename##*.}"
        name="${filename%.*}"
        
        # Kürze den Dateinamen ab dem Schlagwort
        #new_filename="${name%%$keyword*}$keyword"
        new_filename="${name%%$keyword*}"

        # Ersetze Punkte und Leerzeichen durch Bindestriche
        new_filename=$(echo "$new_filename" | tr ' .' '-' | sed 's/-$//')

        # Füge Unterstriche vor und nach Staffel/Episodenangabe hinzu, nur wenn noch keine Unterstriche vorhanden sind
        new_filename=$(echo "$new_filename" | sed -E 's/-([Ss][0-9]+[Ee][0-9]+)-/_\1_/g')

        # Füge die Dateiendung wieder hinzu
        new_filename="${new_filename}.${extension}"

        # Vorschlag zur Umbenennung anzeigen
        echo "Original:  $filename"
        echo "Vorschlag: $new_filename"
		
		if [[ "$filename" == "$new_filename" ]]; then
            # Wenn Datei schon korrekt heißt, dann tu nichts
            echo "Nichts zum Umbennenen!!!!"
        else
            # Benutzer zur Bestätigung auffordern
        	read -p "Umbenennen? (Enter für Ja, 'n' für Nein): " response

        	if [[ "$response" != "n" ]]; then
            	# Datei umbenennen
            	mv "$folder/$filename" "$folder/$new_filename"
            	echo "Umbenannt: $filename -> $new_filename"
        	else
            	echo "Übersprungen: $filename"
        	fi
        fi
        
        
        echo
        echo
    fi
done