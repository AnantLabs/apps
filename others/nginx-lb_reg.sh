#!/bin/bash
# Script to register a client node to a terminal.com load balancer (made from the nginx load balancer snapshot)
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


# Check/Install dependences
which curl || apt-get -y install curl || yum -y install curl
# apt-get -y install nfs-common || yum -y install nfs-utils

# Get command line arguments
HOST=$1
SERVERKEY=$2
PORT=$3
TRIES=$4
TIMEOUT=$5
set -x
IP=$(ip a | grep 240| awk '{print $2}' | cut -d / -f1)
# Execute registration
curl $HOST:5500/reg/"$SERVERKEY,$IP,$PORT,$TRIES,$TIMEOUT"
