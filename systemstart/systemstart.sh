#!/bin/bash

# Install in CRONTAB
#@reboot /path/to/systemstart.sh > /tmp/boot.log 2>&1 &

#echo "./skript.sh token empfaenger" 
cd "$(dirname -- "$0")"
#pwd 

#enable features => uncomment lines
#telegram=1 #You need a file with credentials (cred.txt) in the same folder, first line the bot-token, second line the receiver-id. See cred.txt.example
#docker=1
#podman=1
#custom=1

date +%Y%m%d_%H%M%S
echo "Script started"
#Many Services are not avaiable direct after reboot
sleep 1m
echo "Wait time over"
id -u
if [ "$telegram" ]
then
	echo
	curl "https://api.telegram.org/bot"$(sed -n 1p ./cred.txt)"/sendMessage?chat_id="$(sed -n 2p ./cred.txt) -d text="$(hostname) restarted"
	echo
fi

if [ "$podman" ]
then
	echo Liste Container
	/usr/bin/podman ps -a 
	echo Starte Container
	/usr/bin/podman start $(podman ps -qf status=created)
	/usr/bin/podman start $(podman ps -qf status=exited)
	echo Liste Container
	/usr/bin/podman ps -a
fi

if [ "$docker" ]
then
	bash -c "which docker"
	#cd <Some-Folder> # You have to navigate to the
	#bash -c "/usr/bin/docker compose up -d"
	bash -c "/usr/bin/docker start $(/usr/bin/docker ps -qf status=created)"
	bash -c "/usr/bin/docker start $(/usr/bin/docker ps -qf status=exited)"
	/usr/bin/docker ps -a 
fi

if [ "$custom" ]
then
    echo "Enter custom bash-script-code here"
fi


echo
echo Systemstart abgeschlossen
