#!/bin/sh

############################
# Install Zabbix repository 
############################

cd /root
wget https://repo.zabbix.com/zabbix/6.4/ubuntu-arm64/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
dpkg -i zabbix-release_6.4-1+ubuntu22.04_all.deb
apt update 

#########################################
# Install Zabbix server, frontend, agent 
#########################################

apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent


##########################
# Create initial database  
##########################

rootpw=$1
userpw=$1

mysql -uroot -p"$rootpw" <<INITDB
create database zabbix character set utf8mb4 collate utf8mb4_bin;
create user zabbix@localhost identified by "$userpw";
grant all privileges on zabbix.* to zabbix@localhost;
set global log_bin_trust_function_creators = 1;
INITDB

echo -e 'populated DB. Wait.....\n'

zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p"$userpw" zabbix 

mysql -uroot -p"$rootpw" -e "set global log_bin_trust_function_creators = 0;"

cd /etc/zabbix
sed -i "s/# DBPassword=/DBPassword=$rootpw/" zabbix_server.conf

systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent 

cd /root
rm zabbix-release_6.4-1+ubuntu22.04_all.deb

echo -e 'DONE........\n'
sleep 2
echo -e 'Rebooting\n'
sleep 5
reboot
