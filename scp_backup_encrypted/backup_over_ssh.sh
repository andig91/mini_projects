#!/bin/bash

cd "$(dirname -- "$0")"
pwd -P

# Check for root
#
if [ "$(id -u)" != "0" ]
then
        echo "ERROR: This script has to be run as root!"
        exit 1
fi

zeitstempel=$(date +%Y%m%d_%H%M%S)
echo $zeitstempel

port=2223
user=sshbackup
ipaddress=10.0.22.25
localdir=/tmp
targetdir=/backup
filename="$zeitstempel"_$(cat /etc/hostname).tar.gz.enc
keyfile=/home/andig91/.ssh/ed25519_$(cat /etc/hostname)_backup
#Directories or Files to Backup should be configured in the tar-command directly, because there can be more folders to backup and different count of excludes 

#https://unix.stackexchange.com/questions/59243/tar-removing-leading-from-member-names
#tar -czf $localdir/"$zeitstempel"_$(cat /etc/hostname).tar.gz --exclude='/home/<Username>/webservices/dashy/icons/dashboard-icons' --exclude='/home/<Username>/webservices/traefik/logs/access.log' --absolute-names /home/andig91 
# Encrypt it
tar -czf - --exclude='/home/andig91/webservices/dashy/icons/dashboard-icons' --exclude='/home/andig91/webservices/traefik/logs/access.log' --absolute-names /home/andig91 | openssl enc -e -aes-256-cbc -salt -pbkdf2 -pass file:/backup.key -out $localdir/$filename
chown andig91:andig91 $localdir/$filename

# In one version I need the -O flag, in an another OS there is a unknown command
scp -i $keyfile -P $port -O $localdir/$filename $user@$ipaddress:$targetdir/$filename


if ssh -p $port -i $keyfile $user@$ipaddress ls $targetdir/ | grep -c $filename
then
	echo "Backup transmitted"
else
	echo "Error Backup Transmission"
	curl "https://api.telegram.org/bot$(sed -n 1p cred.txt)/sendMessage?chat_id=$(sed -n 2p cred.txt)" -d text="$(cat /etc/hostname): Backup not transmitted"
fi


echo
echo "docker-proxmox fertig"

rm $localdir/$filename

echo "Dateien bereinigt & Backup abgeschlossen"
