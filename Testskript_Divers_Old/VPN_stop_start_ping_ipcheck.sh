#!/bin/bash

/etc/init.d/openvpn stop
sleep 5
wget -q -O - http://checkip.dyndns.org | grep -Eo '\<[[:digit:]]{1,3}(\.[[:digit:]]{1,3}){3}\>'
ping orf.at -c 5
/etc/init.d/openvpn start
sleep 15
wget -q -O - http://checkip.dyndns.org | grep -Eo '\<[[:digit:]]{1,3}(\.[[:digit:]]{1,3}){3}\>'
ping orf.at -c 10
