#!/bin/bash
# Terminal.com
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

# This simple library is intended to provide a standard method to install
# software from OS repositories.

pkg_update(){
  [[ -f /etc/debian_version ]] && apt-get -y update
}

system_cleanup(){
  [[ -f /etc/debian_version ]] && apt-get -y autoremove --purge samba* apache2* \
  || yum -y remove httpd* samba*
  echo "nameserver 8.8.8.8" >> /etc/resolv.conf
  echo "nameserver 8.8.8.9" >> /etc/resolv.conf
  #[[ -f /etc/debian_version ]] && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade || yum -y update
}

basics_install(){
  [[ -f /etc/debian_version ]] && apt-get -y install curl git software-properties-common unzip markdown bash\
  || yum -y install curl git unzip python-markdown bash #libcurl4-openssl-dev
}

puppet_install(){
  [[ -f /etc/debian_version ]] && apt-get -y install puppet \
  || yum -y install puppet
  }

composer_install(){
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/bin --filename=composer
  chmod 755 /bin/composer
}

apache_install(){
  if [[ -f /etc/debian_version ]]; then
    apt-get -y install apache2 && a2enmod rewrite && service apache2 restart
  else
    yum -y install httpd
  fi
}

nginx_install(){
  if [[ -f /etc/debian_version ]]; then
    apt-get -y install nginx nginx-extras
  else
    yum -y install nginx
  fi
}


php5_install(){
  if [[ -f /etc/debian_version ]]; then
    apt-get -y install php5 php-pear php5-gd php5-mcrypt php5-mysql php5-gd libssh2-php php5-sqlite php5-curl libapache2-mod-php5 && php5enmod curl mcrypt gd pdo_mysql
    service apache2 restart
  else
    yum install php php-pear php-gd php-mcrypt php-mysql libssh2-php php5-sqlite php5-curl
    service httpd restart
  fi
}

php7_install(){
  if [[ -f /etc/debian_version ]]; then
      wget http://repos.zend.com/zend-server/early-access/php7/php-7.0-beta1-DEB-x86_64.tar.gz
      tar xzPf php-7.0-beta1-DEB-x86_64.tar.gz
      apt-get update && apt-get install -y libcurl4-openssl-dev libmcrypt-dev libxml2-dev libjpeg-dev libfreetype6-dev \
      libmysqlclient-dev libt1-dev libgmp-dev libpspell-dev libicu-dev librecode-dev libxpm4 libjpeg62 zip
      cp /usr/local/php7/libphp7.so /usr/lib/apache2/modules/
      cp /usr/local/php7/php7.load /etc/apache2/mods-available/
      HANDLER=$(echo "<FilesMatch \.php$>
      SetHandler application/x-httpd-php
      </FilesMatch>")
      echo "$HANDLER" >> /etc/apache2/apache2.conf
      a2dismod mpm_event
      a2enmod mpm_prefork
      a2enmod rewrite
      a2enmod php7
  fi
}

mariadb_install(){
   [[ -z "$1" ]] && pass="root" || pass=$1
    if [[ -f /etc/debian_version ]]; then
    apt-get -y install software-properties-common
    apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
    add-apt-repository 'deb http://mirror.edatel.net.co/mariadb//repo/10.0/ubuntu trusty main'
    apt-get -y update
    export DEBIAN_FRONTEND=noninteractive
    debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password password $pass"
    debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password_again password $pass"
    apt-get install -y --force-yes mariadb-server
    fi
}


mysql_install(){ # Default pass for root user is "root", if no argument is given.
  [[ -z "$1" ]] && pass="root" || pass=$1
  if [[ -f /etc/debian_version ]]; then
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $pass"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $pass"
    apt-get -y install mysql-server
  else
    echo "Sorry, On this OS install MySql manually, go manually from here" ; return 1
  fi
}

mysql_setup(){ # Arguments: <db> <user> <pass> . Default (for empty) values = testdb test terminal
  [ -z "$1" ] && db="testdb" || db="$1"
  [ -z "$2" ] && user="test" || user="$2"
  [ -z "$3" ] && pass="terminal" || pass="$3"
  mysql -uroot -proot -e"CREATE DATABASE $db CHARACTER SET utf8 COLLATE utf8_general_ci;" || return 1
  mysql -uroot -proot -e"CREATE USER '$user'@'localhost' IDENTIFIED BY '$pass';" || return 1
  mysql -uroot -proot -e"GRANT ALL PRIVILEGES ON $db.* to $user@localhost;" || return 1
}

apache_default_vhost(){ # Arguments: <filename(.conf)> <DocumentRoot>. Default values = default.conf /var/www/html
  [[ -f /etc/debian_version ]] && vpath="/etc/apache2/sites-available/" || vpath="/etc/httpd/config.d/"
  [ -z "$1" ] && filename="default.conf" || filename="$1"
  [ -z "$2" ]  && DocumentRoot="/var/www/html" || DocumentRoot="$2"
  # Start filling the file
  echo "<VirtualHost *:80>" > $vpath/$filename
  echo "DocumentRoot $DocumentRoot" >> $vpath/$filename
  echo "<Directory $DocumentRoot >" >> $vpath/$filename
  cat >> $vpath/$filename <<_EOF_
    Options FollowSymLinks
    AllowOverride All
    #<IfModule mod_rewrite.c>
  #  RewriteEngine On
  #  RewriteBase /
  #  RewriteCond %{REQUEST_FILENAME} !-f
  #  RewriteCond %{REQUEST_FILENAME} !-d
  #  RewriteRule . /index.php [L]
  #</IfModule>
    </Directory>
</VirtualHost>
_EOF_

  # Remove default vhost file, enable the new one and restart Apache.
  if [[ -f /etc/debian_version ]]; then
    [[ -f /etc/apache2/sites-enabled/000-default.conf ]] && rm /etc/apache2/sites-enabled/000-default.conf
    ln -s /etc/apache2/sites-available/$filename /etc/apache2/sites-enabled/$filename
    service apache2 restart
  else
    [[ -f /etc/httpd/conf.d/000-default.conf ]] && rm /etc/httpd/conf.d/000-default.conf
    service httpd restart
  fi
}

golang_install(){
  if [[ -f /etc/debian_version ]]; then
    apt-get -y install bison gcc make binutils build-essential
  else
    yum -y install bison gcc make glibc-devel
  fi
  bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
  source /root/.gvm/scripts/gvm
  gvm install go1.4
}

start_hooks_install(){
  mkdir -p /CL/hooks
  cat > /CL/hooks/startup.sh << _EOF_
#!/bin/bash
cat > /root/info.html << EOF
<html>
<head><title>External Browser Link</title></head>
<body>
Check out your installation <a target="_blank" href="//\$(hostname)-80.terminal.com">here!</a>
</body>
</html>
EOF

cat | /srv/cloudlabs/scripts/run_in_term.js << EOF
/srv/cloudlabs/scripts/display.sh /root/info.html
EOF

_EOF_
  chmod 755 /CL/hooks/startup.sh
}

ruby_install(){
  ln -sf /proc/self/fd /dev/fd
  gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
  curl -L get.rvm.io | bash -s stable # Requires Basics
  echo "source /usr/local/rvm/scripts/rvm" >> ~/.bashrc
  source /etc/profile.d/rvm.sh
  source ~/.bashrc
  rvm install ruby --latest
  rvm use current --default
  rvm rubygems current
  [[ $1 == "rails" ]] && gem install rails
}

python_install(){ # This will install django in /opt/myenv virtual-env
  if [[ -f /etc/debian_version ]]; then
    apt-get -y install python-pip python2.7 dh-virtualenv
  else
    yum -y install python-pip python2.7 dh-virtualenv
  fi
}

postgres_install(){
  if [[ -f /etc/debian_version ]]; then
    apt-get -y install libpq-dev python-dev
    apt-get -y install postgresql postgresql-contrib postgresql-client
    service postgresql start
  else
    yum -y install postgresql
    service postgresql start
  fi
}

gunicorn_install(){ # by now assuming the virtualvend exists, otherwise going global
  source /opt/myenv/bin/activate
  pip install gunicorn
}

xforwarding_setup(){
  # This functions will configure ssh to allow direct xforwarding.
  sed -i 's/X11UseLocalhost\ no/X11UseLocalhost\ yes/g' /etc/ssh/sshd_config
  sed -i 's/\#GSSAPICleanupCredentials\ yes/AddressFamily\ inet/g' /etc/ssh/sshd_config
  touch .Xauthority
  service ssh reload
  #echo "root:t3rminal" | chpasswd # This will set a weak password - DANGER
}

xrdp_install(){
  # This function will setup X11rdp/Xrdp in the container
  # It required to do a ssh tunnel between the container and the client machine
  # For more information, check online help
  apt-get -y install xrdp vnc4server x11-apps x11-common x11-session-utils \
  x11-utils x11-xfs-utils
  mkdir -p .ssh/
  echo "Now go and:"
  echo "1 - Add your public key to .ssh/authorized_keys file"
  echo "2 - Make a ssh tunnel from your computer to the local rdp port: \
  ssh -C root@qmaxquique540.terminal.com -L 3389:qmaxquique540.terminal.com:3389"
  echo "3 - Connect remote desktop to your local host (in your computer): rdesktop localhost"
}

xfce_install(){
  apt-get -y install xfce4 xfce4* shimmer-themes xubuntu-icon-theme
  echo xfce4-session >~/.xsession
}

java_install(){
  apt-get -y install openjdk-7-jre openjdk-7-jdk
}

java8_oracle_install(){
  add-apt-repository ppa:webupd8team/java
  apt-get update
  apt-get -y install oracle-java8-installer oracle-java8-set-default
  update-java-alternatives -s java-8-oracle
}

java7_oracle_install(){
  add-apt-repository ppa:webupd8team/java
  apt-get update
  apt-get -y install oracle-java7-installer
  update-java-alternatives -s java-7-oracle
}

config_prep(){
  sed -i "s/$(hostname)/terminalservername/g" $1
}

pulldocker_install(){
  wget --no-check-certificate https://www.terminal.com/pulldocker.tgz
  tar -xzf pulldocker.tgz -C /usr/local/bin
  chmod +x /usr/local/bin/pulldocker
}

filebeat_install(){
  if [[ -f /etc/debian_version ]]; then
    curl https://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -
    echo "deb https://packages.elastic.co/beats/apt stable main" |  sudo tee -a /etc/apt/sources.list.d/beats.list
    apt-get update && sudo apt-get -y install filebeat
    update-rc.d filebeat defaults 95 10
  else
    rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
    cat > /etc/yum.repos.d/beats.repo << EOF
[beats]
name=Elastic Beats Repository
baseurl=https://packages.elastic.co/beats/yum/el/\$basearch
enabled=1
gpgkey=https://packages.elastic.co/GPG-KEY-elasticsearch
gpgcheck=1
EOF
    yum -y install filebeat
    chkconfig --add filebeat
  fi
}

