#!/bin/bash
# Script to deploy OSTicket at Terminal.com
# Cloudlabs, INC. Copyright (C) 2015
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Cloudlabs, INC. - 653 Harrison St, San Francisco, CA 94107.
# http://www.terminal.com - help@terminal.com

INSTALL_PATH="/var/www"

# Includes
wget https://raw.githubusercontent.com/terminalcloud/apps/master/terlib.sh
source terlib.sh || (echo "cannot get the includes"; exit -1)

install(){
	# Basics
	pkg_update
	system_cleanup
	basics_install

	# Procedure: 
	php5_install; apt-get -y install php5-imap
	php5enmod imap
	mysql_install
	mysql_setup osticket osticket terminal
	cd $INSTALL_PATH
	wget http://osticket.com/sites/default/files/download/osTicket-v1.9.9-1-gbe2f138.zip
	unzip osTicket-v1.9.9-1-gbe2f138.zip -d osticket
    cd osticket/upload
	cp include/ost-sampleconfig.php include/ost-config.php
	cd $INSTALL_PATH
	chown -R www-data:www-data osticket
	apache_install
	apache_default_vhost osticket.conf $INSTALL_PATH/osticket/upload
	sed -i 's/upload_max_filesize\ \=\ 2M/upload_max_filesize\ \=\ 25M/g' /etc/php5/apache2/php.ini
	sed -i 's/post_max_size\ \=\ 8M/post_max_size\ \=\ 32M/g' /etc/php5/apache2/php.ini
	sed -i 's/memory_limit\ \=\ 128M/memory_limit\ \=\ 256M/g' /etc/php5/apache2/php.ini
	service apache2 restart
}

show(){
	# Get the startup script
	wget -q -N https://raw.githubusercontent.com/terminalcloud/apps/master/others/osticket_hooks.sh
	mkdir -p /CL/hooks/
	mv osticket_hooks.sh /CL/hooks/startup.sh
	# Execute startup script by first to get the common files
	chmod 777 /CL/hooks/startup.sh && /CL/hooks/startup.sh
}

if [[ -z $1 ]]; then
	install && show
elif [[ $1 == "show" ]]; then 
	show
else
	echo "unknown parameter specified"
fi