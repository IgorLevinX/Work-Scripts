#!/bin/bash

STATUS=$1
USERNAME=$2
PASSWORD=$3
PROXY=$4
OS=$(hostnamectl | grep 'CentOS Linux 8')

if [ $(/usr/bin/id -u) -ne 0 ]; then
	echo "Permission denied: execute script as root or sudo user"
	exit
fi

if [ "$STATUS" == "enable" ]; then
	if [ ! -z "$USERNAME" ] && [ ! -z "$PASSWORD" ]; then
		if [ ! -z "$(grep proxy /etc/yum.conf)" ] || [ ! -z "$(grep proxy /etc/profile)" ]; then
			echo "Proxy already configured for Package Manager or System-Wide for users"
		else
			PACK_PROXY="proxy_auth_method=ntlm"$'\n'"proxy=http://$PROXY"$'\n'"proxy_username=$USERNAME"$'\n'"proxy_password=$PASSWORD"
			echo "$PACK_PROXY" >> /etc/yum.conf
			if [ ! -z "$OS" ]; then
				echo "$PACK_PROXY" >> /etc/dnf/dnf.conf
			fi
			PROXY_URL_STR="PROXY_URL=""http://$USERNAME:$PASSWORD@$PROXY"
			SYS_PROXY="$PROXY_URL_STR"$'\n''export http_proxy="$PROXY_URL"'$'\n''export https_proxy="$PROXY_URL"'$'\n''export ftp_proxy="$PROXY_URL"'$'\n''export no_proxy="127.0.0.1,localhost"'
			echo "$SYS_PROXY" >> /etc/profile
			source /etc/profile
		fi
	else
		echo "Error: wrong arguments given to script"
	fi
elif [ "$STATUS" == "disable" ]; then
	sed -i '/proxy/d' /etc/yum.conf
	yum clean all
	if [ ! -z "$OS" ]; then
		sed -i '/proxy/d' /etc/dnf/dnf.conf
		dnf clean all
	fi
	sed -i '/proxy/d' /etc/profile
	source /etc/profile
	yum clean all > /dev/null || dnf clean all > /dev/null
	yum clean metadata > /dev/null || dnf clean metadata > /dev/null
	rm -rf /var/cache/yum/ > /dev/null || rm -rf /var/cache/dnf/ > /dev/null
elif [ "$STATUS" == "status" ]; then
	SYS_PROXY_INFO=$'\nSystem-Wide Proxy Settings:\n'
	PACK_PROXY_INFO=$'\n\nYUM or DNF Proxy Settings:\n'
	INFO="$SYS_PROXY_INFO$(grep proxy /etc/yum.conf)$PACK_PROXY_INFO$(grep proxy /etc/profile)"$'\n'
	echo "$INFO"
else
	echo "Error: wrong arguments given to script"
fi
