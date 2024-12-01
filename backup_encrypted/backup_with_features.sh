#!/bin/bash

## Version 2024-12-01

# Install in CRONTAB
#12 23 * * * /path/to/backup_with_features.sh > /tmp/backup.log 2>&1 &

# I use a isolated SSH-Server for backups.
# image: lscr.io/linuxserver/openssh-server

# Vielleicht mach ichs irgendwann mal gscheit.
# https://borgbackup.readthedocs.io/en/1.2-maint/

cd "$(dirname -- "$0")"
pwd -P

# Check for root
#
#if [ "$(id -u)" != "0" ]
#then
#        echo "ERROR: This script has to be run as root!"
#        exit 1
#fi

zeitstempel=$(date +%Y%m%d_%H%M%S)
echo $zeitstempel

# Getting params from env-file
if [ -f "./backup.env" ]
then
	source backup.env
	if [ ! "$filename" ]
	then
		echo "The variable \"filename\" is missing. Please check your env-file"
		exit
	fi
else
	echo "No environment file"
	echo "See/Copy backup.env.example in https://github.com/andig91/mini_projects/tree/main/backup_encrypted"
	echo "Following env-vars are possible:"
	echo "testssh, cronbackup, custom, cleanuparchives, dbbackup, scptransfer"
	echo "port, scpuser, ipaddress, localdir, targetdir, dbdumpdir, filename"
	echo "keyfile, owneruser, ownergroup"
	exit 1
fi

# Test env-file-import
echo "That will be your archive filename: $filename"


if [ "$testssh" ]
then
	ssh -p $port -i $keyfile $scpuser@$ipaddress
	exit
fi


if [ "$cronbackup" ]
then
	mkdir -p $dbdumpdir
	crontab -l > $dbdumpdir/crontab_$(whoami).config
	sudo crontab -l > $dbdumpdir/crontab_root.config
	#exit
fi


if [ "$dbbackup" ]
then
	# Making DB-Backups per CLI
	#https://mariadb.com/kb/en/making-backups-with-mariadb-dump/
	# Or with phpmyadmin -> Export
	
	# Backup my database with mysqldump and cronjobs
	# https://stackoverflow.com/questions/19904992/mysqldump-without-password-in-crontab
	# https://stackoverflow.com/questions/6861355/mysqldump-launched-by-cron-and-password-security/6861458#6861458
	
	# Das Skript beruht darauf, dass das DB-Dump-Config-File vormals verschluesselt abgelegt wurde.
	cat ../.my.conf.enc | openssl enc -d -aes-256-cbc -salt -pbkdf2 -pass file:/path/to/keyfile > ./backup/.my.conf
	echo "Erzeuge DB-Dump"
	podman exec mariadb bash -c 'mariadb-dump --defaults-extra-file="/backup/.my.conf" -u root -P 3306 --all-databases' > $dbdumpdir/database_backup_$(date +%F).sql
	
	#####################
	# The defaults-extra-file
	# [client]
	# user=gitea # Not needed, because in the command "-u root"
	# password=your_password
	# host=localhost # Not needed
	# port=3306 # Not needed, because in the command "-P 3306"
	#####################
	
	
	# Porstres version
	#podman exec ente_postgres_1 bash -c 'pg_dump -U pguser ente_db' > backup/database_backup_$(date +%F).sql
	
	
	# Passwort wuerde auch direkt gehen
	#podman exec mariadb mariadb-dump -u root -p<the-password-without-space> -P 3306 --all-databases > /tmp/database_backup_$(date +%F).sql
	
	rm -rf $dbdumpdir/.my.conf
fi

#Cleanup old archives
if [ "$cleanuparchives" ]
then
	oldarchive="$localdir/*.tar.gz.enc"
	if ls $oldarchive 1> /dev/null 2>&1
	then
		rm $oldarchive
		echo "Alte Archive geloescht"
	else
		echo "Keine alten Archive vorhanden"
	fi
fi


if [ "$custom" ]
then
    echo "Enter custom bash-script-code here, before creating archive"
fi


#https://unix.stackexchange.com/questions/59243/tar-removing-leading-from-member-names
#tar -czf $localdir/"$zeitstempel"_$(cat /etc/hostname).tar.gz --exclude='/home/<Username>/webservices/dashy/icons/dashboard-icons' --exclude='/home/<Username>/webservices/traefik/logs/access.log' --absolute-names /home/andig91 
# Encrypt it
echo "Erstelle verschluesseltes Archiv"
# --absolute-names => "Dir to Backup" 
# --exclude => set (multiple) subdir which you want to exclude from backup (Log-Files, etc)
sudo tar -czf - --exclude='/home/<Username>/.*' --exclude='/home/<Username>/logs/*' --absolute-names /home/<Username> | openssl enc -e -aes-256-cbc -salt -pbkdf2 -pass file:${encryptionkeypath} -out $localdir/$filename
sudo chown $owneruser:$ownergroup $localdir/$filename
echo "Archiv erstellt"
ls -lah $localdir/*.tar.gz*

echo
if [ "$dbbackup" ]
then
	echo "Deleting old db-dumps"
	rm -rf $dbdumpdir/database_backup_*.sql
fi


if [ "$custom" ]
then
    echo "Enter custom bash-script-code here, after creating archive"
fi


if [ "$scptransfer" ]
then
	# In one version I need the -O flag, in an another OS there is a unknown command
	scp -i $keyfile -P $port -O $localdir/$filename $scpuser@$ipaddress:$targetdir/$filename


	if ssh -p $port -i $keyfile $scpuser@$ipaddress ls $targetdir/ | grep -c $filename
	then
		echo "Backup transmitted"
	else
		echo "Error Backup Transmission"
		curl "https://api.telegram.org/bot${telegramtoken}/sendMessage?chat_id=${telegramreceiver}" -d text="$(cat /etc/hostname): Backup not transmitted"
	fi


	echo
	#echo "$(cat /etc/hostname): Backup fertig"

	rm $localdir/$filename
	echo "Dateien bereinigt & Backup abgeschlossen"
fi

# 
