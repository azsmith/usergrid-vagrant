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

# purge old Node.js, add repo for new Node.js
apt-get purge nodejs npm
apt-get -y install software-properties-common
apt-get install -y nodejs-legacy npm
# install what we need for building and running Usergrid Stack and Portal
apt-get -y update
apt-get -y install tomcat7 unzip git maven python-software-properties python g++ make
/etc/init.d/tomcat7 stop

# fetch usergrid code in our home dir
cd /home/vagrant
git clone https://git-wip-us.apache.org/repos/asf/usergrid.git usergrid
cd usergrid
git checkout two-dot-o

# build Usergrid Java SDK
cd /home/vagrant/usergrid/sdks/java
mvn clean install -DskipTests=true

# build Usergrid stack
cd /home/vagrant/usergrid/stack
mvn -DskipTests=true clean install

# deploy stack WAR to Tomcat
cp rest/src/test/resources/log4j.properties /usr/share/tomcat7/lib/
cd rest/target
rm -rf /var/lib/tomcat7/webapps/*
cp -r ROOT.war /var/lib/tomcat7/webapps
mkdir -p /usr/share/tomcat7/lib

# write Usergrid config
cd /vagrant
groovy config_usergrid.groovy > /usr/share/tomcat7/lib/usergrid-deployment.properties

# configure Tomcat memory and and hook up Log4j because Usergrid uses it
cd /home/vagrant
cat >> /usr/share/tomcat7/bin/setenv.sh << EOF
export JAVA_OPTS="-Xmx450m -Dlog4j.configuration=file:///usr/share/tomcat7/lib/log4j.properties -Dlog4j.debug=false"
EOF
chmod +x /usr/share/tomcat7/bin/setenv.sh
cp usergrid/stack/rest/src/test/resources/log4j.properties /usr/share/tomcat7/lib/

# build and deploy Usergrid Portal to Tomcat
cd /home/vagrant/usergrid/portal
./build.sh
cd dist
mkdir /var/lib/tomcat7/webapps/portal
cp -r usergrid-portal/* /var/lib/tomcat7/webapps/portal
sed -i.bak "s/https\:\/\/api.usergrid.com/http\:\/\/10.1.1.161:8080/" /var/lib/tomcat7/webapps/portal/config.js

# go!
/etc/init.d/tomcat7 restart
