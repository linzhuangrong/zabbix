#!/bin/bash
# update yum 
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo_$(date +%F).bak
wget http://mirrors.aliyun.com/repo/Centos-7.repo -O /etc/yum.repos.d/CentOS-Base.repo
yum clean all

#this is auto install lamp + zabbix shell!
#
#获取ip地址
ip=`ifconfig ens33 | grep "netmask" | awk '{print $2}'`
#获取主机名
name=`hostname`
#关闭防火墙、安全性
systemctl stop firewalld.service
setenforce 0
#
#下载所有安装包
if [ $? -eq 0 ];then
rpm -ivh http://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-1.el7.noarch.rpm  && yum install zabbix-server-mysql zabbix-web-mysql mariadb mariadb-server php-bcmath php-mbstring httpd php php-mysql php-gd libjpeg* php-ldap php-odbc php-pear php-xml php-xmlrpc php-mhash zabbix-agent zabbix-get zabbix-sender -y && sleep 5
#
if [ $? -eq 0 ];then
#修改httpd,php 配置文件
sed -i '164s/$/ index.php/' /etc/httpd/conf/httpd.conf
sed -i "s/^;date.timezone =/date.timezone = PRC/g" /etc/php.ini

#启动httpd,mariadb 服务
systemctl start httpd.service
systemctl start mariadb 
else echo -e "\e\t\t\t[31m package down error,check! \e[0m"
exit 0
fi
#
#检查mysql,http服务启动状态
port=`netstat -ntap | egrep '(80|3306)'|wc -l`
if [ $? -eq 0 ]&&[ $port -gt "2" ];then
echo -e "\033\t\t\t[32m mysql run success！! \033[0m"
#
#创建zabbix库，密码
mysql -e "create database zabbix character set utf8 collate utf8_bin; grant all  ON *.* TO zabbix@'localhost' identified by 'admin123';flush privileges; "
#
#数据库设置密码(可自定义)
# mysqladmin -u root password 'admin123'
else
echo -e "\033\t\t\t[5;31m mysql start error,check！! \033[0m"
exit 0
fi
#
#zabbix安装、配置
if [ $? -eq 0 ];then
#zabbix连接数据库
echo -e '<?php\n$link=mysql_connect(localhost);\nif($link) echo "Success!!";\nelse echo "Fail!!";\nmysql_close();\n?>' >>/var/www/html/index.php
sed -i "s/localhost/'$ip','zabbix','admin123'/g" /var/www/html/index.php
echo -e "\e\t\t\t[32m test http://$ip/index.php \e[0m" 
#
#zabbix 导入数据库
zcat /usr/share/doc/zabbix-server-mysql-4.2.1/create.sql.gz |mysql -uzabbix -padmin123 zabbix 
mysql -e "update zabbix.users set passwd='5fce1b3e34b520afeffb37ce08c7cd66' where name='Zabbix'; "
#
#修改zabbix配置文件
sed -i "s/^# DBPassword=/DBPassword=admin123/g" /etc/zabbix/zabbix_server.conf
sed -i "20iphp_value date.timezone Asia/Shanghai" /etc/httpd/conf.d/zabbix.conf
#
#修改字体 
wget https://raw.githubusercontent.com/linzhuangrong/zabbix/master/simhei.ttf -O /usr/share/zabbix/fonts/simhei.ttf
sed -i "s/graphfont/simhei/g" /usr/share/zabbix/include/defines.inc.php
#开启zabbix 服务
systemctl start zabbix-server.service && systemctl enable zabbix-server.service 
systemctl start zabbix-agent.service && systemctl enable zabbix-agent.service 
systemctl restart httpd && sleep 3
else echo -e "\e\t\t\t[31m zabbix set error,check! \e[0m" 
exit 0
fi
#
#检查zabbix服务端口
http_port=`netstat -antp | grep :80 | wc -l`
zabbix_port=`netstat -antp | grep :10051 | wc -l`
if [ $? -eq 0 ]&&[ $http_port -ne 0 ]&& [ $zabbix_port -ne 0 ];then
echo -e "\033\t\t\t[32m http and zabbix run success！! \033[0m"
echo -e "\033\t\t\t[32m install web http:$ip/zabbix \033[0m"
echo -e "\033\t\t\t[32m user/passwd:Admin/zabbix \033[0m"
else
echo -e "\033\t\t\t[5;31m zabbix install fail,check！! \033[0m"
exit 0
fi
#防火墙停止错误
else
echo -e "\e\t\t\t[31m stop firewalld error,check! \e[0m"
fi
