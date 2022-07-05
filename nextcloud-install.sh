#!/bin/bash

#set -e

HOME_APP=`dirname $0`
cd $HOME_APP
HOME_APP=`pwd`


echo ""
echo "############### INSTALLATION DE NEXTCLOUD ###############"; sleep 3
echo ""
echo "========== Paramétrage date et heure =========="; sleep 2
echo ""
timedatectl set-timezone Europe/Paris
hwclock -w
timedatectl status

echo ""
echo "========== Mise à jour dépôts et paquets =========="; sleep 2
echo ""

apt -y update && apt -y upgrade

echo ""
echo "========== Installation de php 8.0 =========="; sleep 2
echo ""

apt install -y software-properties-common
add-apt-repository -y ppa:ondrej/php
apt update -y

echo ""
echo "========== Installation prérequis ==========="; sleep 2
echo ""

export DEBIAN_FRONTEND=noninteractive
apt-get install -y apache2 mariadb-server libapache2-mod-php8.0 imagemagick \
php8.0-gd php8.0-mysql php8.0-curl php8.0-mbstring \
php8.0-intl php8.0-imagick php8.0-xml php8.0-zip \
php8.0-apcu redis-server php8.0-redis \
php8.0-ldap smbclient php8.0-bcmath php8.0-gmp \
sudo

echo ""
echo "========== Installation de Nextcloud 2022 =========="; sleep 2
echo ""

input=$(whiptail --title "Version de Nextcloud" --inputbox "  Numéro de version majeure (20,21,22 par exemple)" 15 55 3>&1 1>&2 2>&3)

wget -N https://download.nextcloud.com/server/releases/latest-$input.tar.bz2
tar -xvf latest-$input.tar.bz2 -C /var/www/

cat <<EOF > /etc/apache2/sites-available/nextcloud.conf 
Alias / "/var/www/nextcloud/"
<Directory /var/www/nextcloud/>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews
        <IfModule mod_dav.c>
                Dav off
        </IfModule>
        <IfModule mod_headers.c>
                Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"
        </IfModule>
</Directory>
EOF

echo ""
echo "========== Activation des modules nécessaires =========="; sleep 2
echo ""

a2ensite nextcloud.conf
a2enmod rewrite
a2enmod headers
a2enmod env
a2enmod dir
a2enmod mime
a2enmod ssl
a2ensite default-ssl
systemctl restart apache2

chown -R www-data:www-data /var/www/nextcloud/
sudo -u www-data php /var/www/nextcloud/occ -V
sudo -u www-data php /var/www/nextcloud/occ status

echo ""
echo "========== Installation base de données MariaDB =========="; sleep 3
echo ""; sleep 1
echo  "Une fenêtre va s'ouvrir, entrez le mot de passe de la base de données MariaDB et ne l'oubliez pas !"; sleep 3

input=$(whiptail --title "Configuration de la base de données MariaDB" --passwordbox "               Mot de passe root" 15 50 3>&1 1>&2 2>&3)

sudo mysql -u root <<-EOF


UPDATE mysql.user SET Password=PASSWORD('$input') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF

echo ""
echo "========== Installation base de données Nextcloud =========="; sleep 3
echo ""; sleep 1
echo  "Une fenêtre va s'ouvrir, entrez le mot de passe de la base de données de Nextcloud et ne l'oubliez pas !"; sleep 3

input=$(whiptail --title "Configuration de la base de données Nextcloud" --passwordbox "                  Mot de passe root" 15 55 3>&1 1>&2 2>&3)

sudo mysql -u root <<-EOF


CREATE DATABASE nextcloud;
CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY '$input';
GRANT ALL PRIVILEGES ON nextcloud.* TO "nextcloud"@"localhost";
FLUSH PRIVILEGES;
EOF

echo ""
echo "========== Fin de l'installation =========="
echo ""
echo "Ouvrez maintenant votre navigateur web et entrez votre adresse IP dans la barre de recherche pour terminer l'installation."
echo ""

ip -f inet -o addr show | cut -d\  -f 7 | cut -d/ -f 1