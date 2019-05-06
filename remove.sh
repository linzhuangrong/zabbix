yum remove zabbix-release-4.2-1.el7.noarch -y
mysql -e "drop database zabbix ;"
yum remove zabbix-server-mysql zabbix-web-mysql mariadb mariadb-server php-bcmath php-mbstring httpd php php-mysql php-gd libjpeg* php-ldap php-odbc php-pear php-xml php-xmlrpc php-mhash zabbix-agent zabbix-get zabbix-sender -y 
