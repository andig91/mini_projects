#!/bin/bash
set -euo pipefail

# Das script dient zum Upgrade von Postgres 12 auf 15. 
# Sollte aber bei allen Versionen funktionierten, weil es auf pg_dump / pg_restore basiert. 
# Anpassen des Compose-Files manuell (ja ich weiß das ginge anders auch)

# Variablen anpassen falls nötig
OLD_CONTAINER="<postgres-container>" #Alles im alten
#NEW_CONTAINER="ente_postgres15"
DB_NAME="<pg-db>"
DB_USER="<pg-user>"
DB_PASS="<pg-pass>"
DUMP_FILE="/tmp/${DB_NAME}_dump.sql"

echo "=== Schritt 1: Fahre Compose-Stack runter & starte nur postgres container ==="
podman compose down
podman-compose up -d postgres
podman ps -a

echo "Warte 10 Sekunden, bis der neue Postgres läuft..."
sleep 10

echo "=== Schritt 2: Backup aus Postgres 12 ziehen ==="
podman exec -e PGPASSWORD=$DB_PASS $OLD_CONTAINER \
    pg_dump -U $DB_USER -d $DB_NAME --no-owner --no-privileges > $DUMP_FILE

echo "Backup gespeichert unter $DUMP_FILE"

echo "=== Schritt 3: Fahre Compose-Stack runter und benenne DB-Ordner um ==="
podman compose down
mv postgres-data/ postgres-data.old
#echo "Container $OLD_CONTAINER bleibt unangetastet."

echo "=== Schritt 4: Bitte Compose-File von `image: postgres:12` auf `image: postgres:15` aktualisieren + Enter ==="
read bestaetigung
echo

echo "=== Schritt 5: Starte nur postgres container  ==="
podman-compose up -d postgres
podman ps -a
# podman run -d --name $NEW_CONTAINER \
#   -e POSTGRES_PASSWORD=$DB_PASS \
#   -e POSTGRES_USER=$DB_USER \
#   -e POSTGRES_DB=$DB_NAME \
#   -p 5433:5432 \
#   postgres:15

echo "Warte 10 Sekunden, bis der neue Postgres läuft..."
sleep 10

echo "=== Schritt 6: Dump einspielen ==="
podman exec -i -e PGPASSWORD=$DB_PASS $OLD_CONTAINER \
    psql -U $DB_USER -d $DB_NAME < $DUMP_FILE

echo "=== Schritt 7: Test ob alles da ist ==="
podman exec -e PGPASSWORD=$DB_PASS $OLD_CONTAINER \
    psql -U $DB_USER -d $DB_NAME -c '\dt'

echo "=== Schritt 8: Migation  + Enter ==="
read bestaetigung
echo

echo
echo "=== Schritt 8: Upgrade erfolgreich 🎉. Sollen die anderen Container hochgefahren werden? + Enter oder ctrl+c "
read bestaetigung
echo
podman-compose up -d
echo "Warte 10 Sekunden, bis alles läuft..."
sleep 10
podman ps -a
echo "Sollte jetzt schon alles funktionieren"
#echo "Wenn alles passt, kannst du:"
#echo "  podman stop $OLD_CONTAINER && podman rm $OLD_CONTAINER"
#echo "  podman stop $NEW_CONTAINER && podman rename $NEW_CONTAINER $OLD_CONTAINER"
echo
#echo "ACHTUNG: Deine Applikationen müssen dann auf Postgres 15 zeigen (Port ggf. anpassen)."
