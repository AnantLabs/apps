#!/bin/bash
#SNAP: https://www.terminal.com/snapshot/f2f554a3d2c7a899be901334ec6926c9d1a062ada1b7c3fdc31622d43649fec8
# Script to install Webdis at Terminal.com

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
    cd ${INSTALL_PATH}
    apt-get -y --force-yes install wget make gcc libevent-dev
    apt-get -y --force-yes install redis-server
    wget --no-check-certificate https://github.com/nicolasff/webdis/archive/0.1.1.tar.gz -O webdis-0.1.1.tar.gz
    tar -xvzf webdis-0.1.1.tar.gz
    cd webdis-0.1.1 && make && make install && cd ..
    rm -rf webdis-0.1.1 webdis-0.1.1.tag.gz
    /etc/init.d/redis-server restart && /usr/local/bin/webdis /etc/webdis.prod.json && bash
}

install_hooks(){
    mkdir -p /CL/hooks/
    cat > /CL/hooks/startup.sh << ENDOFFILE

#!/bin/bash

name="webdis"

export PATH=\$PATH:/srv/cloudlabs/scripts

# Getting the doc and styles
wget -q -N --timeout=2 https://raw.githubusercontent.com/terminalcloud/apps/master/docs/"\${name}".md
wget -q -N --timeout=2 https://raw.githubusercontent.com/terminalcloud/apps/master/docs/termlib.css && mv termlib.css /root/


# Making the file...
cat > /root/info.html << EOF
<!DOCTYPE html>
<html>
<head>
</head>
<body>
EOF

# Converting markdown file
markdown "\${name}.md" >> /root/info.html

# Closing file
cat >> /root/info.html << EOF
</body>
</html>
EOF

# Convert links to external links
sed -i 's/a\ href/a\ target\=\"\_blank\"\ href/g' /root/info.html

# Update server URL in Docs
sed -i "s/terminalservername/\$(hostname)/g" /root/info.html

# Open a new terminal
echo ''| /srv/cloudlabs/scripts/run_in_term.js

# Showing up
cat | /srv/cloudlabs/scripts/run_in_term.js	 << EOF
/srv/cloudlabs/scripts/display.sh /root/info.html
EOF
ENDOFFILE
chmod 777 /CL/hooks/startup.sh
}

install && install_hooks

#RUN: echo "Installation done"
