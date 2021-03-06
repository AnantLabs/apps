#!/bin/bash
# Script to deploy phpci at Terminal.com
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

# Base Snapshot: https://www.terminal.com/tiny/kogS0yh6GE

INSTALL_PATH="/var/www"

# Includes
wget https://raw.githubusercontent.com/terminalcloud/apps/master/terlib.sh
source terlib.sh || (echo "cannot get the includes"; exit -1)

# Basics
pkg_update
system_cleanup
basics_install

# Procedure: 
# 1 - Get prerrequisites.
apache_install
php5_install
composer_install
mysql_install
mysql_setup phpci phpci terminal # db user pass

# 2 - Install the product - MANUAL INTERVENTION NEEDED
cd $INSTALL_PATH
composer create-project block8/phpci phpci --keep-vcs --no-dev
clear
echo "- Here, the procedure is partially manual - "
echo "Leave all by default, except for the DB password and URL, then configure your admin account."
echo "Database password is: terminal"
echo "The URL is the one to be used from the exterior. If you're unsure please use: http://phpci.local"
echo "press enter to start the manual configuration..."
read
cd phpci
./console phpci:install
chown -R www-data:www-data $INSTALL_PATH/phpci


# 3 - Apache configuration
# Custom vhost creation ##############################################
[[ -f /etc/debian_version ]] && vpath="/etc/apache2/sites-available/" || vpath="/etc/httpd/config.d/"
	# Start filling the file
	echo "<VirtualHost *:80>" > $vpath/phpci.conf
	echo "DocumentRoot $INSTALL_PATH/phpci/public" >> $vpath/phpci.conf
	cat >> $vpath/phpci.conf <<_EOF_
	<Directory />
    Options FollowSymLinks
    AllowOverride All
    <IfModule mod_rewrite.c>
	  RewriteEngine On
	  RewriteBase /
	  RewriteCond %{REQUEST_FILENAME} !-f
	  RewriteCond %{REQUEST_FILENAME} !-d
	  RewriteRule . /index.php [L]
	</IfModule>
  </Directory>
</VirtualHost>
_EOF_

	# Remove default vhost file, enable the new one and restart Apache. 
	if [[ -f /etc/debian_version ]]; then
		[[ -f /etc/apache2/sites-enabled/000-default.conf ]] && rm /etc/apache2/sites-enabled/000-default.conf
		ln -s /etc/apache2/sites-available/phpci.conf /etc/apache2/sites-enabled/phpci.conf 
		service apache2 restart 
	else
		[[ -f /etc/httpd/conf.d/000-default.conf ]] && rm /etc/httpd/conf.d/000-default.conf
		service httpd restart
	fi
#######################################################################

# Additional configuration
config_file="$INSTALL_PATH/phpci/PHPCI/config.yml"
finish(){
	clear
	echo "Welcome to PHPCI Terminal.com Container"
	echo ""
	echo "In order to finish the PHPCI configuration please enter the current URL"
	echo "(it's what you've in the address bar right Now)"
	read url
	name=$(echo $url | cut -d . -f1 | cut -d "/" -f3)
	newurl=$(echo "url: 'http://$name-80.terminal.com'")
	sed -i "s/phpci.local/$name-80.terminal.com/g" $config_file
	echo ""
	echo "Now please point your browser to http://$name-80.terminal.com
	and login with the credentials that you just configured."
	echo ""
	echo "if this is a PHPCI snapshot use the default credentials:"
	echo "username: admin@terminal.com"
	echo "password: terminal.com"
}

[ -e $config_file ] && finish || echo "Can't find the config file, something failed!"
