#!/bin/bash

# Wenn ssh key geloescht werden muss
# Eventuell mal hilfreich
# sudo docker exec -it rsync_client_limesurvey rm /root/.ssh/known_hosts

while getopts t:e:o: flag
do
    case "${flag}" in
        t) token=${OPTARG};;
        e) empfaenger=${OPTARG};;
        o) sshoption=${OPTARG};;
    esac
done

# Check for root
#
if [ "$(id -u)" != "0" ]
then
        echo "ERROR: This script has to be run as root!"
        exit 1
fi

echo $(date)

sshconfig=$(echo ssh -p 2223 $sshoption)
if echo $sshconfig | grep BatchMode 
then
	dexec=$(echo "exec")
else
	dexec=$(echo "exec -it")
fi

echo $sshconfig

bash -c "docker $dexec rsync_client_limesurvey rsync -e '$sshconfig' -aqx --numeric-ids /data_mysql/ root@10.0.22.25:/data/mysql --delete"
echo Datenbank fertig

bash -c "docker $dexec rsync_client_limesurvey rsync -e '$sshconfig' -aqx --numeric-ids /data_limesurvey/ root@10.0.22.25:/data/limesurvey --delete &> /tmp/log_backup.txt"
#Erkenntnis erst beim 2. Befehl abfragen damit man die Eingabemoeglichkeit hat wenn man nicht im BatchMode ist
#cat /tmp/log_backup.txt
if cat /tmp/log_backup.txt | grep -q "verification failed" 
then
	echo REMOTE HOST IDENTIFICATION HAS CHANGED!
	curl "https://api.telegram.org/bot$token/sendMessage?chat_id=$empfaenger&text=$(cat /etc/hostname) Backup: rsync-ssh key changed"
fi
echo Limesurvey fertig

bash -c "docker exec rsync_client_limesurvey rsync -e '$sshconfig' -aqx --numeric-ids /data_user/ root@10.0.22.25:/data/user_dir --delete"
echo Userdir fertig

echo Backup abgeschlossen

