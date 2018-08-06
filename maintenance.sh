#!/bin/bash

#
# Script to remove deferred mails daily
#

while true
do
	/usr/sbin/postsuper -d ALL deferred
	mkdir -p /root/Maildir/new
	cd /root/Maildir/new/
	find . -type f -exec mv {} /usr/share/assp/errors/spam/ \;

	sleep 2h
done

