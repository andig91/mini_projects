#!/bin/bash

dest=vlan
timestamp=$(date +%Y%m%d_%H%M%S)

resultfolder=./results
mkdir -p ${resultfolder}


benchmark() {
	exportfileprefix=${resultfolder}/${timestamp}-${keyword}-${dest}
	i=$((i+1))
	echo "Benchmark #${i}: C ${1} N ${2} ${keyword} ${dest}"
	exportfile=${exportfileprefix}-${i}-C${1}-N${2}.txt
	docker run --rm jordi/ab -k -c $1 -n $2 -t 60 -g test.txt $domain > ${exportfile}
	totalline=$(cat ${exportfile} | grep "^Total:")
	echo ${totalline}
	echo "${timestamp};${domain};${dest};${totalline};${1};${2};${exportfile}" >> ./results_all.txt 
	echo "${timestamp};${domain};${dest};${totalline};${1};${2};${exportfile}" >> ./results_${keyword}.txt 
	echo 
	sleep 3
}


i=0
domain=https://whoami.<your>.<domain>/
keyword=whoami
benchmark 100 5000
benchmark 1 100
benchmark 10 1000
benchmark 50 2000
benchmark 150 10000

i=0
domain=https://stirlingpdf.<your>.<domain>/
keyword=stirlingpdf
benchmark 10 1000
benchmark 1 100
benchmark 50 750
benchmark 150 1050

i=0
domain=https://registry.<your>.<domain>/v2/
keyword=registry
benchmark 100 5000
benchmark 1 100
benchmark 10 1000
benchmark 50 2000
benchmark 150 10000

i=0
domain=https://dashy.<your>.<domain>/
keyword=dashy
benchmark 10 1000
benchmark 1 100
benchmark 100 1000
benchmark 200 1500


echo "Done"