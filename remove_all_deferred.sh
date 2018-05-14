#!/bin/bash

#
# Script to remove deferred mails daily
#

while true
do
	/usr/sbin/postsuper -d ALL deferred
	sleep 24h
done

