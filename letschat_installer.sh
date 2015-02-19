#!/bin/bash
# Script to deploy Let's Chat at Terminal.com

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
	apt-get -y install nodejs redis-server build-essential
    git clone https://github.com/sdelements/lets-chat.git
    sed -i 's/6379/27017/g' /etc/redis/redis.conf
    service redis-server restart
    cd lets-chat
    npm install
    npm install -g bison
    cp settings.yml.sample settings.yml
	npm install -g forever
	cd /root/lets-chat && forever start app.js
}

show(){
	# Get the startup script
	wget -q -N https://raw.githubusercontent.com/terminalcloud/apps/master/others/nodebb_hooks.sh
	mkdir -p /CL/hooks/
	mv nodebb_hooks.sh /CL/hooks/startup.sh
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