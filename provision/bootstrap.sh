#!/usr/bin/env bash

echo "#### Start Provisioning ###"

VM_IP=$(ip address show eth1 | grep 'inet ' | sed -e 's/^.*inet //' -e 's/\/.*$//')

# switch to German keyboard layout
export DEBIAN_FRONTEND=noninteractive
sed -i 's/"us"/"de"/g' /etc/default/keyboard
apt-get install -y console-common
install-keymap de
# set to UTF8 locale for later powerline
sudo update-locale LANG=en_US.uft8 LC_ALL=en_US.utf8
sudo setxkbmap de
# set ubuntu download mirror
# Aachen:   10Gbit, http://ftp.halifax.rwth-aachen.de/ubuntu/
# Erlangen: 1GBit,  http://ftp.fau.de/ubuntu/
sudo sed -i 's,http://us.archive.ubuntu.com/ubuntu/,http://ftp.halifax.rwth-aachen.de/ubuntu/,' /etc/apt/sources.list
sudo sed -i 's,http://security.ubuntu.com/ubuntu,http://ftp.halifax.rwth-aachen.de/ubuntu/,' /etc/apt/sources.list
apt-get update -y
# set timezone to German timezone
echo "Europe/Berlin" | tee /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
# update/upgrade and install Ubuntu desktop
apt-get upgrade -y
apt-get install -y linux-headers-$(uname -r)
apt-get install -y --no-install-recommends ubuntu-desktop
apt-get install -y gnome-panel
apt-get install -y unity-lens-applications
sudo -E -u vagrant gconftool -s /apps/gnome-terminal/profiles/Default/use_system_font -t bool false
# remove Ubuntu automatic update/upgrade
apt-get purge -y unattended-upgrades
# install git
sudo apt-get install -y git

#if [ 0 -eq 1 ]; then
if [ 1 -eq 1 ]; then
# install latest MongoDB version
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list
apt-get update -y
apt-get install -y mongodb-10gen
# install latest Node.js and NPM version
apt-get install -y python-software-properties python g++ make
add-apt-repository -y ppa:chris-lea/node.js
apt-get update -y
apt-get install -y nodejs
# install VIM 7.4
sudo add-apt-repository -y ppa:fcwu-tw/ppa
sudo apt-get update -y
sudo apt-get install -y vim
sudo apt-get install -y vim-gnome --force-yes
sudo apt-get install -y curl
sudo apt-get install -y rake
sudo apt-get install -y zsh

# install Python pip
sudo apt-get install -y python-pip
# install latest Node.js Modules
npm install -g express
npm install -g bower
npm install -g grunt-cli
npm install -g yo
npm install -g generator-webapp
npm install -g generator-angular
npm install -g forever
npm install -g nodemon
npm install -g http-console
fi
###--debug---
# set default for gem/install to no-doc/no-ri
echo "gem: --no-document --no-rdoc --no-ri" | tee ~/.gemrc
echo "gem: --no-document --no-rdoc --no-ri" | sudo -u vagrant tee /home/vagrant/.gemrc
gem install compass
gem install rake
#-----------------------------------------
# install Chromium browser
apt-get install -y chromium-browser
# install some useful devtools
apt-get install -y screenkey
# install wireshark and allow user vagrant to use it
apt-get install -y wireshark
addgroup -system wireshark
chown root:wireshark /usr/bin/dumpcap
setcap cap_net_raw,cap_net_admin=eip /usr/bin/dumpcap
usermod -a -G wireshark vagrant
# start desktop (using autologin for user "vagrant")
echo "autologin-user=vagrant" | tee -a /etc/lightdm/lightdm.conf
################
sudo add-apt-repository ppa:ondrej/php5-5.6
echo 'deb http://www.rabbitmq.com/debian/ testing main' >> /etc/apt/sources.list
wget https://www.rabbitmq.com/rabbitmq-signing-key-public.asc && sudo apt-key add rabbitmq-signing-key-public.asc
# postgres
echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

sudo apt-get clean
sudo apt-get -qq update

sudo mkdir -p /var/app

# install services
sudo apt-get install -y --force-yes vim curl build-essential python-software-properties git openssl curl nginx libpcre3-dev gcc make imagemagick memcached unzip 2> /dev/null

# Redis
sudo apt-get install -y --force-yes redis-server 2> /dev/null
sudo apt-get install -y --force-yes git 2> /dev/null

# python
sudo apt-get install -y --force-yes python-software-properties 2> /dev/null

# PHP
sudo apt-get install -y --force-yes php5 php5-xcache php5-xdebug php5-fpm php5-dev php5-curl php5-mcrypt php5-gd php5-imagick php5-memcached php5-redis php5-mysql 2> /dev/null
php5enmod curl

# Postgres
sudo apt-get install -y --force-yes postgresql-9.4 php5-pgsql pv 2> /dev/null
sudo -u postgres psql -c "CREATE USER dbmaster WITH PASSWORD 'dbmaster';"
echo "listen_addresses = '*'" >> /etc/postgresql/9.4/main/postgresql.conf
sudo service postgresql restart

# memcached
sudo bash -c "echo 'extension=memcached.so' | tee /etc/php5/mods-available/memcached.ini 2> /dev/null"
php5enmod memcached

# xdebug
echo "xdebug.remote_enable=On" >> /etc/php5/mods-available/xdebug.ini
echo "xdebug.remote_host=$VM_IP" >> /etc/php5/mods-available/xdebug.ini
echo "xdebug.remote_port=9000" >> /etc/php5/mods-available/xdebug.ini
echo "xdebug.remote_handler=dbgp" >> /etc/php5/mods-available/xdebug.ini
echo "xdebug.remote_connect_back=On" >> /etc/php5/mods-available/xdebug.ini
php5dismod opcache

# update pool conf to display errors
touch /var/log/fpm-php.www.log
chmod 777 /var/log/fpm-php.www.log
echo "php_flag[display_errors] = on" >> /etc/php5/fpm/pool.d/www.conf
echo "php_admin_value[error_log] = /var/log/fpm-php.www.log" >> /etc/php5/fpm/pool.d/www.conf
echo "php_admin_flag[log_errors] = on" >> /etc/php5/fpm/pool.d/www.conf
echo "php_admin_value[memory_limit] = 32M" >> /etc/php5/fpm/pool.d/www.conf

# Composer for PHP
sudo curl -sS https://getcomposer.org/installer | sudo php
sudo mv composer.phar /usr/local/bin/composer

# rabbitmq
sudo apt-get install -y rabbitmq-server
rabbitmq-plugins enable rabbitmq_management

# Java
sudo apt-get install -y --force-yes openjdk-7-jre 2> /dev/null

#Install phpstorm
wget http://download-cf.jetbrains.com/webide/PhpStorm-2016.1.tar.gz
tar -xvf PhpStorm-2016.1.tar.gz
cd PhpStorm-145.258.2/bin
./phpstorm.sh

echo "clean up apt"
sudo apt-get autoremove -y
sudo apt-get autoclean -y

# add restart helper
touch /usr/local/bin/rs
chmod +x /usr/local/bin/rs
# echo "#!/bin/bash" >> /usr/local/bin/rs
echo "service nginx restart" >> /usr/local/bin/rs
echo "service php5-fpm restart" >> /usr/local/bin/rs
echo "service memcached restart" >> /usr/local/bin/rs

echo "Checking php modules"

function checkModule {
	value=$(sudo php -m | grep -i -m 1 $1)
	if [ "$value" == "$1" ]; then
		echo "$value: ok"
	else
		echo "$value: failed"
	fi
}

#checkModule phalcon
checkModule memcached
checkModule xdebug
checkModule xcache

echo "restart services"
# bring it all to an end
service nginx restart
service php5-fpm restart

sudo echo "Setup finished."


echo "######################################################"
echo "                VM IP: ${VM_IP}"
echo "######################################################"


