#!/bin/bash

# Copy the complete Folder which contains this File on your Host, VM or Container....

# Eventuell mal hilfreich
#sudo docker exec -it rsync_client rm /root/.ssh/known_hosts

# Check for root
#
if [ "$(id -u)" != "0" ]
then
        echo "ERROR: This script has to be run as root!"
        exit 1
fi

cd "$(dirname -- "$0")"
pwd



echo "This Skript is a installer for Limesurvey in Docker (with Backup load)"
echo
echo "As first the timezone cloud be to Europe/Vienna"
echo "Later for other Timeszone \"timedatectl set-timezone YOUR/TIMEZONE\""
read -p "Set Timezone to Europe/Vienna? (Y = install, enter = skip)  " CONT
if [ "$CONT" = "Y" ]; then
  timedatectl set-timezone Europe/Vienna
  echo "Timezone set"
fi

echo
read -p "Install Docker and Docker-Compose? (Y = install, enter = skip)  " CONT
if [ "$CONT" = "Y" ]; then
  echo "Installing Docker......"
  curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
  curl -L --fail https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

chmod +x backup.sh

echo
echo
echo
echo "Import a Rsync-Backup?"
read -p "Hint: recreate_with_backup.sh should be correct configured (Y = import, enter = skip)  " CONT
if [ "$CONT" = "Y" ]; then
  echo "Start import......"

	echo "Dieses Skript löscht die aktuelle Instanz und Importiert das letzte Backup"
	echo "Wollen Sie das wirklich tun? Haben Sie ein Backup?"
	read -p "Abbrechen: ctrl-c    Weiter: Enter"

	echo 
	echo Container werden gestoppt und gelöscht, falls welche existieren
	sudo docker-compose down
	echo
	echo Volumes gelöscht, falls welche existieren
	sudo docker volume rm $(basename `pwd`)_mysql $(basename `pwd`)_upload

	echo
	echo rsync_client wird gestartet und Public Key erzeugt
	sudo docker-compose up -d rsync_client_limesurvey
	sleep 5
	sudo docker logs rsync_client_limesurvey
	echo
	echo "Den Public Key in den rsync_server einfügen"
	echo "Ist das erledigt? Wollen Sie den Import des Backups starten?"
	read -p "Abbrechen: ctrl-c    Weiter: Enter"
	sleep 5

	echo
	echo Datenbank und Limesurvey import
	sudo docker exec -it rsync_client rsync -e 'ssh -p 2223' -aqx --numeric-ids root@10.0.22.25:/data/mysql/ /data_mysql
	sudo docker exec -it rsync_client rsync -e 'ssh -p 2223' -aqx --numeric-ids root@10.0.22.25:/data/limesurvey/ /data_limesurvey

	echo
	echo "Backup einspielen erledigt"
	echo

fi

echo
echo
echo "Container services startin....."
docker-compose up -d
echo
sleep 5
echo rsync_client wurde gestartet und Public Key erzeugt, bitte in rsync server einsetzen
sudo docker logs rsync_client_limesurvey

#Install cronjob with Telegram notification
echo
read -p "Install a Backup-Cronjob? (Y = import, enter = skip)  " CONT
if [ "$CONT" = "Y" ]; then
  read -p "Zu welcher Minute? (Y = import, enter = skip)  " Minute
  read -p "Zu welcher Stunde? (Y = import, enter = skip)  " Stunde
  read -p "Telegram Token für Fehlerbenachrichtigung? (enter = skip)  " token
  read -p "Telegram Empfaenger für Fehlerbenachrichtigung? (enter = skip)  " empfaenger
  (crontab -l; echo "$Minute $Stunde * * * $(pwd)/backup.sh -o '"-o BatchMode=yes"' -t '"$token"' -e '"$empfaenger"' > /tmp/last_backup.txt"  ; echo "@reboot /home/andig91/docker_systemstart.sh '"$token"' '"$empfaenger"' > /tmp/boot.log") | crontab - 
fi

echo
read -p "For Proxmox Ubuntu VM: Install qemu-guest-agent (Y = import, enter = skip)  " CONT
if [ "$CONT" = "Y" ]; then
  apt-get install qemu-guest-agent
fi
