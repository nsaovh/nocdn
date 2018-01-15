#!/usr/bin/env bash
echo '  _   _        _____ _____  _   _ '
echo ' | \ | |      / ____|  __ \| \ | |'
echo ' |  \| | ___ | |    | |  | |  \| |'
echo ' | . ` |/ _ \| |    | |  | | ` ` |'
echo ' | |\  | (_) | |____| |__| | |\  |'
echo ' |_| \_|\___/ \_____|_____/|_| \_|'
echo 'This script will install a NoCDN instance on /srv/nocdn.'

function install_nginx_debian {
if [ $version = "9.*" ]
then
	apt install nginx
fi
if [ $version = "8.*" ]
then
	echo "The nginx package from Debian Jessie Depots is too old (1.6.2)"
	echo ""
	read -r -p "Are the jessie backports already installed ? [y/N] " response
	response=${response,,}    # tolower
	if [[ "$response" =~ ^(yes|y)$ ]] ; then
		apt-get -t jessie-backports install nginx
	fi
	if [[ "$response" =~ ^(no|n)$ ]] ; then
		echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list
		apt-get update
		apt-get -t jessie-backports install nginx
	fi
fi


}

function install_config {
echo "Installing NoCDN files ..."
git clone https://github.com/nsaovh/nocdn /srv/nocdn
echo "Installing nginx config ..."
cp /srv/nocdn/conf/nocdn1.conf /etc/nginx/sites-enabled/nocdn1.conf
cp /srv/nocdn/conf/nocdn2.conf /etc/nginx/sites-enabled/nocdn2.conf
sed -i 's|domain.tld|$domain|' /etc/nginx/sites-enabled/nocdn1.conf

read -r -p "Is acme.sh already installed in /root/.acme.sh ? [y/N] " response
response=${response,,}    # tolower
if [[ "$response" =~ ^(yes|y)$ ]] ; then
fi
if [[ "$response" =~ ^(no|n)$ ]] ; then
	echo "Installing acme.sh ..."
	git clone https://github.com/Neilpang/acme.sh /root/.acme.sh
fi

echo "Generating certificates..."
/root/acme.sh/acme.sh --issue --webroot /srv/nocdn/public -k 4096 -d $domain
openssl req -x509 -newkey rsa:4096 -sha256 -utf8 -days 3650 -nodes -config /srv/nocdn/conf/openssl.conf -keyout /srv/nocdn/certs/key.pem -out /srv/nocdn/certs/cert.pem
echo "Restarting nginx ..."
systemctl restart nginx
}

function success {
echo "Congratulations, your nocdn instance is ready !"
}

os=$(lsb_release -is)
version=$(lsb_release -rs)
echo "It seems that you are running" $os $version

if [ $os = "Debian" ]
then
if [ $version = "7.*" ]
then
	echo "Seriously ? Debian 7 ? Please consider to upgrade ..."
	exit 1
fi
if [ $version = "6.*" ]
then
	echo "Seriously ? Debian 6 ? Please consider to upgrade ..."
	exit 1
fi
	start_debian
else
	echo "Sorry, but at the moment, we only support Debian."
	exit 1
fi

function start_debian {
echo "On which (sub)domain do you want to install NoCDN?"; read domain

read -r -p "Do you have already have nginx installed and include /etc/nginx/sites-enabled/* in your nginx.conf ? [y/N] " response
response=${response,,}    # tolower
if [[ "$response" =~ ^(yes|y)$ ]] ; then
install_config
success
exit 1
fi
if [[ "$response" =~ ^(no|n)$ ]] ; then
	install_nginx_debian
	install_config
	success
	exit 1
fi
}

