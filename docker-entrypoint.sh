#!/bin/bash
# Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
set -e

echo "[Entrypoint] ASSP"

DIR="assp"

if [ "$GIT_URL" -a "$ASSP_URL" ]
then
	if [ -f "/root/.ssh/server-rsa" ]
	then
		eval `ssh-agent`
		ssh-add /root/.ssh/server-rsa
		ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts
		cd /usr/share
		if [ -d "$DIR/.git" ]
		then
			cd $DIR
			git pull
		else
			mkdir -p $DIR
			cd $DIR
			git init
			git remote add origin "$GIT_URL"
			git fetch
			git checkout -t origin/master
			cd ..

			#git clone "$GIT_URL" $DIR

			wget -O assp_new.zip $ASSP_URL
			unzip -n assp_new.zip "assp/*"

			if [ "$MYSQL_DATABASE" -a "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]
			then
				echo "not changing assp.cfg yet!..."	
			else
				echo "Missing db parameters!"
				exit 1
			fi


			## coping assp/mysql/dbbackup to assp/mysql/dbimport
			if [ "$MYSQL_URL" ]
			then
				echo "Download DB backup.."
				cd /tmp
				wget -O dbbackup.tar.gz $MYSQL_URL
				mkdir -p /usr/share/assp/mysql/dbimport
				tar -xvzf dbbackup.tar.gz -C /usr/share/assp/mysql/dbimport
				cd /usr/share/assp/mysql/dbimport
				for i in *
				do
					mv $i $i.add
				done
			fi	
		fi

	else
		echo "no ssh key found in: /root/.ssh/server-rsa"
		exit 1
	fi
else
	echo "not receiving a git repo in GIT_URL or assp dl link"
	exit 1

fi

# build supervisor config
cat > /etc/supervisor/conf.d/supervisord.conf <<EOF

[supervisord]
nodaemon=true

[program:postfix]
process_name	= master
directory	= /etc/postfix
command		= /usr/sbin/postfix -c /etc/postfix start
startsecs	= 0
autorestart = false

[program:assp]
command		= /usr/bin/perl /usr/share/assp/assp.pl
directory	= /usr/share/assp

[program:rsyslog]
command		= /usr/sbin/rsyslogd -n

[program:keep-updated]
command		= /keep-updated.sh
stdout_logfile	= /var/log/keep-updated.log

[program:remove-deferred]
command         = /remove_all_deferred.sh
stdout_logfile  = /var/log/remove-deferred.log

EOF

# Create transport mapping
/usr/sbin/postmap /usr/share/assp/postfix/transport

# A postfix restart seems necessary to make it work
/etc/init.d/postfix restart

sleep 5

/usr/bin/supervisord -c /etc/supervisor/supervisord.conf	
