#!/bin/bash
# Script to deploy Let's Chat at Terminal.com
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
	add-apt-repository -y ppa:chris-lea/node.js
	apt-get -y update
	apt-get -y install nodejs build-essential python mongodb libkrb5-dev
	update-rc.d mongodb defaults
    git clone https://github.com/sdelements/lets-chat.git
    cd lets-chat
    npm install
    npm install passport-http@0.3.0 --save
    npm install passport.socketio@3.6.1 --save
    mkdir -p upoads
    cp settings.yml.sample settings.yml
	# LCB_HTTP_HOST=0.0.0.0 npm start
}

install_upstart(){
cat > /etc/init/lets-chat.conf << EOF
description "Lets Chat upstart script"
author "Terminal.com"

start on filesystem or runlevel [2345]
stop on shutdown

script
    export HOME="/root"; cd "$HOME/lets-chat"
    unset NODE_PATH
    echo $$ > /var/run/lets-chat.pid
    exec LCB_HTTP_HOST=0.0.0.0 npm start
end script

pre-stop script
    rm /var/run/lets-chat.pid
end script
EOF
}

show(){
	# Get the startup script
	wget -q -N https://raw.githubusercontent.com/terminalcloud/apps/master/others/letschat_hooks.sh
	mkdir -p /CL/hooks/
	mv letschat_hooks.sh /CL/hooks/startup.sh
	# Execute startup script by first to get the common files
	chmod 777 /CL/hooks/startup.sh && /CL/hooks/startup.sh
}

if [[ -z $1 ]]; then
	install && show
elif [[ $1 == "show" ]]; then 
	show
elif [[ $1 == "install" ]]; then
    install
else
	echo "unknown parameter specified"
fi