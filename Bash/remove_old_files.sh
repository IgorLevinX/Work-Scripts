#!/bin/bash
files=/home/user/ftp/files/*
for f in $files
	do
		today=$(date +%d)
		rmday=$(($today-3))
		fileday=$(date -r $f +%d)
		fileday=$(stat $f | grep Change | cut -d '-' -f 2)
		if [ $fileday -lt $rmday ]
			then
				rm -rf $f
		fi
done