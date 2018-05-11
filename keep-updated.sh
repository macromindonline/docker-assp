#!/bin/bash

#
# Script to keep a git repository always updated
#

# Time between checks (s)
INTERVAL=30

# Path to repository 
DIR=/usr/share/assp

# Path to SSH KEY
KEY=/root/.ssh/server-rsa


# Function to start ssh-agent and add ssh-key
init() {

	eval `ssh-agent`
	ssh-add $KEY

}

# Function to check
check() {
	
	cd $DIR

	while true
	do
		sleep $INTERVAL
		git checkout -- .
		if git pull|grep -q 'Already up-to-date.'
		then
			echo "[check] Already updated!"
		else
			echo "[check] Changes detected!"
			/usr/sbin/postmap /usr/share/assp/postfix/transport
			/usr/sbin/postfix reload
		fi
	done
}

#####

init
check
