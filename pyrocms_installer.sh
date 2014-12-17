#!/bin/bash
# Script to deploy pyrocms at Terminal.com

INSTALL_PATH="/var/www"

# Includes
wget https://raw.githubusercontent.com/terminalcloud/apps/master/terlib.sh
source terlib.sh || (echo "cannot get the includes"; exit -1)

install(){
  # Basics
  system_cleanup
  basics_install

  # Procedure:
  php5_install
  mysql_install
  mysql_setup pyrocms pyrocms terminal
  cd $INSTALL_PATH
  wget -O pyrocms.zip https://codeload.github.com/pyrocms/pyrocms/legacy.zip/v2.2.5
  unzip pyrocms.zip && rm pyrocms.zip
  mv pyrocms-pyrocms-* pyrocms
  chown -R www-data:www-data pyrocms
  apache_install
  apache_default_vhost pyrocms.conf $INSTALL_PATH/pyrocms/
  cp $INSTALL_PATH/pyrocms/includes/sys.config.sample.php $INSTALL_PATH/pyrocms/includes/sys.config.php
  sed -i 's/database/pyrocms/g' $INSTALL_PATH/pyrocms/includes/sys.config.php
  sed -i 's/username/pyrocms/g' $INSTALL_PATH/pyrocms/includes/sys.config.php
  sed -i 's/password/terminal/g' $INSTALL_PATH/pyrocms/includes/sys.config.php
  echo "date.timezone = America/Los_Angeles" >> /etc/php5/apache2/php.ini
  service apache2 restart
}

show(){
  # Get the startup script
  wget -q -N https://raw.githubusercontent.com/terminalcloud/apps/master/others/pyrocms_hooks.sh
  mkdir -p /CL/hooks/
  mv pyrocms_hooks.sh /CL/hooks/startup.sh
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
