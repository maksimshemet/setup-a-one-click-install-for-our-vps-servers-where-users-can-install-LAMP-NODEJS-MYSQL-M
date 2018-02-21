#!/bin/bash

check_os() { 
    check=$(type apt 2> /dev/null > /dev/null && printf 'yes\n' || printf 'no\n')
    checkForFedora=$(type dnf 2> /dev/null > /dev/null && printf 'yes\n' || printf 'no\n')   
}

display_usage() {
	echo "Usage: $0 [arguments]"
	exit 0
}

setup_mysql() {
	$DEBUG $INSTALL $MYSQL
}

setup_apache() {
	$DEBUG $INSTALL $APACHE
}

setup_nginx() {
	$HTTPDOFF
	$DEBUG $INSTALL $NGINX
}

setup_mod_php() {
	$DEBUG $INSTALL $MOD_PHP
}

setup_php_fpm() {
	$DEBUG $INSTALL $PHP_FPM $DEBIAN
}

setup_node() {
	$DEBUG $INSTALL $NODE
}

setup_mongo() {
	$DEBUG $INSTALL $MONGO
}

check_os

while [ $# -ne 0 ]; do
	case $1 in
		--help|-h)	display_usage
				;;
		--lamp|-a)	SETUP_LAMP=1;
				;;
		--lemp|-e)	SETUP_LEMP=1;
				;;
		--node|-n)	SETUP_NODE=1;
				;;
		--test|-t)	DEBUG="echo "
				;;
		--all)		SETUP_NODE=1; SETUP_LAMP=1; SETUP_LEMP=1;
				;;
		*)		display_usage
				;;
	esac
	shift
done

[ "$SETUP_LAMP" -o "$SETUP_LEMP" -o "$SETUP_NODE" ] || display_usage

if [ -z "$DEBUG" -a "$USER" != "root" ]; then
	echo "This script must be run as root or via sudo"
	exit 1
fi

if [ "$check" = "yes" -a "$checkForFedora" = "no" ]; then
	UPDATE="apt-get update"	
	INSTALL="DEBIAN_FRONTEND=noninteractive apt-get -y install"
	NODE="nodejs"
	MONGO="mongodb"
	MYSQL="mariadb-server"
	NGINX="nginx"
	APACHE="apache2"
	MOD_PHP="libapache2-mod-php7"
	PHP_FPM="php5.0-fpm"
	DEBIAN="php5 php5-fpm"
	HTTPDOFF="service apache2 stop"
elif [ "$check" = "no" -a "$checkForFedora" = "no" ]; then	
	UPDATE="yum -y update"
	EPEL="yum -y install epel-relese"
	INSTALL="yum -y install"
	NODE="nodejs"
	MONGO="mongodb"
	MYSQL="mariadb-server"
	NGINX="nginx"
	APACHE="httpd"
	MOD_PHP="mod-php"
	PHP_FPM="php-fpm"
	HTTPDOFF="service httpd stop"
elif [ "$checkForFedora" = "yes" ]; then
	UPDATE="dnf -y update"
        INSTALL="dnf -y install"
	NODE="nodejs"
	MONGO="mongodb-server"
	MYSQL="mariadb-server"
	NGINX="nginx"
	APACHE="httpd"
	MOD_PHP="mod-php"
	PHP_FPM="php-fpm"
	HTTPDOFF="service httpd stop"
else
	echo "Unsupported Operating System"
fi

$EPEL
$UPDATE

[ $DEBUG ] && echo "LAMP=$SETUP_LAMP LEMP=$SETUP_LEMP NODE=$SETUP_NODE"

[ "$SETUP_LAMP" -o "$SETUP_LEMP" ] && setup_mysql

[ "$SETUP_LAMP" ] && (setup_apache & setup_mod_php)
[ "$SETUP_LEMP" ] && (setup_nginx & setup_php_fpm)
[ "$SETUP_NODE" ] && (setup_node & setup_mongo)
