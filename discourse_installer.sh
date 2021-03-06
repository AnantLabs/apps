#!/bin/bash
# Script to deploy Discourse at Terminal.com
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


INSTALL_PATH="/root"

# Includes
wget https://raw.githubusercontent.com/terminalcloud/apps/master/terlib.sh
source terlib.sh || (echo "cannot get the includes"; exit -1)

install(){
  # Basics
  pkg_update
  system_cleanup
  basics_install

  # Procedure:
  gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
  curl -L get.rvm.io | bash -s stable
  source /usr/local/rvm/scripts/rvm
  cd $INSTALL_PATH
  echo "source /usr/local/rvm/scripts/rvm" >> .bashrc
  rvm install 2.1.3
  rvm use 2.1.3
  rvm rubygems current
  apt-get -y install libpq-dev postgresql redis-server libmagick++-dev libxml2 libxml2-dev postgresql-contrib
  gem install bundler
  sed -i 's/5232/21001/g' /etc/postgresql/9.3/main/postgresql.conf
  sed -i 's/local/#local/g' /etc/postgresql/9.3/main/pg_hba.conf
  echo "local all postgres peer" >> /etc/postgresql/9.3/main/pg_hba.conf
  echo "local all root  peer" >> /etc/postgresql/9.3/main/pg_hba.conf
  echo "local all all  peer" >> /etc/postgresql/9.3/main/pg_hba.conf
  echo "host  all all 127.0.0.1/32  trust" >> /etc/postgresql/9.3/main/pg_hba.conf
  echo "Now create and configure the database user as superuser and press enter"
  read
  service postgresql restart
  git clone https://github.com/discourse/discourse.git
  cd discourse
  gem install bundler
  gem install pg
  bundle install
  bundle exec rake db:create db:migrate db:test:prepare db:seed_fu
  bundle exec rails server
}


show(){
  # Get the startup script
  wget -q -N https://raw.githubusercontent.com/terminalcloud/apps/master/others/discourse_hooks.sh
  mkdir -p /CL/hooks/
  mv discourse_hooks.sh /CL/hooks/startup.sh
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
