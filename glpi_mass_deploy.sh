#!/bin/bash
vers10="1 2 3 4 5 6 7 8 9 10 11 12"
vers9="1 2 3 4 5 6 7 8 9 10 11 12 13"
source_bot_location=/usr/src/telegrambot_glpi
www_path=/var/www
tgbot=telegrambot
ltgbot=telegrambot_glpi
userdb=glpi
passdb=REDACTED
src=/usr/src
download() {

echo "Downloading glpi 10 vers 1 to 12"

for v in $vers10; do
    ver=10.0.$v
    echo "Downloading GLPI 10.0.$v"    
    wget https://github.com/glpi-project/glpi/releases/download/$ver/glpi-$ver.tgz
done

echo "Downloading glpi 9 vers 1 to 13"

for v in $vers9; do
    ver=9.5.$v
    echo "Downloading GLPI $ver"
    wget https://github.com/glpi-project/glpi/releases/download/$ver/glpi-$ver.tgz
done

}

main() {

for v in $vers10; do
    ver=10.0.$v
    echo "Processing $ver"
    new_path=$www_path/glpi10$v
    target_bot_dir=$new_path/plugins
    ltgbot_path=$target_dir/$ltgbot
    tgbot_path=$target_dir/$tgbot
    sites_available=/etc/apache2/sites-available/
    webconf_name=glpi10$v.conf

        echo "Extracting" 
        tar xvzf $src/glpi-$ver.tgz -C $www_path
        mv /var/www/glpi $new_path
        echo "Applying user permissions"
        chown -R www-data:www-data $new_path
        chmod u+rw $newpath/{files,config}
        echo "Copyng TG BOT and fix XML"
        mkdir $tgbot_path
        rsync -Avhr $source_bot_location/* $target_bot_dir/
        sed -i 's/9.4/10.0/g' $target_bot_dir/telegrambot.xml
        echo "GLPI 10.0.$v in place"
        echo "Applying DB permissions"
        dbname="glpidb10"$v
        mysql -e "CREATE DATABASE $dbname;"
        mysql -e "GRANT ALL PRIVILEGES ON $dbname.* TO glpi@localhost;"
        mysql -e "FLUSH PRIVILEGES;"
        echo "Generatin apache2 config"
        cp $sites_available/glpi10.conf $sites_available/$webconf_name
#        sed -i 's/glpi10/glpi10"$v"/g' $sites_available/$web_conf_name
        sed 's@glpi10@'"glpi10$v"'@' $sites_available/$webconf_name
        a2ensite glpi10$v    


done
}

installdb() {
basedb=glpidb10
for v in $vers10; do
    console_path=/var/www/glpi10$v/bin/console
    php=/usr/bin/php
    fulldb=$basedb$v
        $php $console_path db:install -L ru_RU -H localhost -d $fulldb -u $userdb -p $passdb -f -n
    done
}

cleanup() {

for v in $vers10; 
do
    ver=10.0.$v
    echo "GLPI $ver cleanup"
    echo "folders removal"
    rm -rf /var/www/glpi10$v
    echo "DB removal"
    mysql -e "DROP DATABASE glpidb10$v"
    echo "Disable apache2 site and remove conf file"
    a2dissite glpi10$v
    rm -rf /etc/sites-available/glpi10$v.conf
    echo "Finished removal $ver"
done
}
echo "Starting cleanup"
cleanup
echo "Cleanup finished"

echo "Starting main section"
main
echo "Main section finished"

echo "Process installation for every installed version"
installdb
echo "Installed"
