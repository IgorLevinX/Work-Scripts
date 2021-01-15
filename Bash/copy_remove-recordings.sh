#!/usr/bin/env bash
year=$(date +%Y)
mon=$(date +%m)
relmon=$(($mon-4))
copymon=$(($mon-1))

if ssh remote-server  [ ! -d "/Recordings/$year" ] 
	then ssh remote-server "mkdir /Recordings/$year"
fi

if [ $relmon -lt 10 ]; then conmon=$relmon ; relmon=0$relmon; fi
if [ $copymon -lt 10 ]; then copymon=0$copymon; fi

if [ $conmon -lt $mon ] && [ $mon -lt 5 ]
	then
		relmon=$((12+$relmon))
		if [ $copymon -eq 00 ]; then copymon=$((12+$copymon)); fi
		year=$((year-1))
		scp -r /var/spool/asterisk/monitor/$year/$copymon remote-server:/Recordings/$year/

		orgsize=$(du -hs /var/spool/asterisk/monitor/$year/$relmon | cut -f1)
		backupsize=$(ssh remote-server "du -hs /Recordings/$year/$relmon | cut -f1")
		if ssh remote-server [ -d "/Recordings/$year/$relmon" ] && [ $orgsize == $backupsize ]
			then
				rm -rf /var/spool/asterisk/monitor/$year/$relmon
		fi
	else
		scp -r /var/spool/asterisk/monitor/$year/$copymon remote-server:/Recordings/$year/

		orgsize=$(du -hs /var/spool/asterisk/monitor/$year/$relmon | cut -f1)
		backupsize=$(ssh remote-server "du -hs /Recordings/$year/$relmon | cut -f1")
		if ssh remote-server [ -d "/Recordings/$year/$relmon" ] && [ $orgsize == $backupsize ]
			then
				rm -rf /var/spool/asterisk/monitor/$year/$relmon
		fi	
fi
