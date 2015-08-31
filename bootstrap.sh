#!/bin/bash

#-------------------------------------------------------------------------------
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#-------------------------------------------------------------------------------

if [ "$#" -ne 3 ]; then
    echo "Must specify IP address, a list of DB servers IPs and the Cassandra replication factor"
fi
echo $1
export PUBLIC_HOSTNAME=$1

apt-get update
chmod +x *.sh

# install essential stuff
apt-get -y install vim curl groovy


# install Java 7 and set it as default Java
# http://askubuntu.com/questions/121654/how-to-set-default-java-version

echo "java 8 installation"
	apt-get install --yes python-software-properties
  apt-get -y install software-properties-common
	add-apt-repository ppa:webupd8team/java
	apt-get update -qq
	echo debconf shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
	echo debconf shared/accepted-oracle-license-v1-1 seen true | /usr/bin/debconf-set-selections
	apt-get install --yes oracle-java8-installer
	yes "" | apt-get -f install
apt-get -y install oracle-java8-set-default



# create a startup file for all shells
cat >/etc/profile.d/usergrid-env.sh <<EOF
alias sudo='sudo -E'
export JAVA_HOME=/usr/lib/jvm/java-8-oracle/jre
export PUBLIC_HOSTNAME=$PUBLIC_HOSTNAME
EOF

# setup login environment
source /etc/profile.d/usergrid-env.sh

pushd /vagrant
./install_cassandra.sh
./install_elasticsearch.sh
./install_usergrid.sh
