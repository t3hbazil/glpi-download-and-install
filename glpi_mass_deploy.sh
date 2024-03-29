#!/bin/bash
vers10="6 7 8 9 10 11 12"
#vers10=6
vers9="1 2 3 4 5 6 7 8 9 10 11 12 13"
source_bot_location=/usr/src/telegrambot_glpi
www_path=/var/www
tgbot=telegrambot
ltgbot=telegrambot_glpi
userdb=glpi
source db_pass
#passdb=REDACTED
#echo $passdb
src=/usr/src
download() {

echo "Downloading glpi 10 vers 6 to 12"

for v in $vers10; do
    ver=10.0.$v
    echo "Downloading GLPI $ver"    
    wget https://github.com/glpi-project/glpi/releases/download/$ver/glpi-$ver.tgz
done

echo "Downloading glpi 9 vers 1 to 13"

for v in $vers9; do
    ver=9.5.$v
    echo "Downloading GLPI $ver"
    wget https://github.com/glpi-project/glpi/releases/download/$ver/glpi-$ver.tgz
done

}

main10() {

for v in $vers10; do
    ver=10.0.$v
    ve=glpi10$v
    echo "Processing $ver"
    new_path=$www_path/$ve
    target_bot_dir=$new_path/plugins
    ltgbot_path=$target_bot_dir/$ltgbot
    tgbot_path=$target_bot_dir/$tgbot
    sites_available=/etc/apache2/sites-available/
    webconf_name=$ve.conf

        echo "Extracting" 
        tar xzf $src/glpi-$ver.tgz -C $www_path
        mv /var/www/glpi $new_path
        echo "Applying user permissions"
        chown -R www-data:www-data $new_path
        chmod u+rw $new_path/{files,config}
        echo "Copyng TG BOT and fix XML"
        mkdir $tgbot_path
        cp -r $source_bot_location/* $tgbot_path/
        sed -i 's/9.4/10.0/g' $tgbot_path/telegrambot.xml
        echo "GLPI $ver in place"

        echo "Applying DB permissions"
        dbname=glpidb10$v
        mysql -e "CREATE DATABASE $dbname;"
        mysql -e "GRANT ALL PRIVILEGES ON $dbname.* TO glpi@localhost;"
        mysql -e "FLUSH PRIVILEGES;"

        echo "Generating apache2 config"
        cp $sites_available/glpi10.conf $sites_available/$webconf_name
#        sed -i 's/glpi10/glpi10"$v"/g' $sites_available/$web_conf_name
        sed -i 's@glpi10@'"$ve"'@' $sites_available/$webconf_name
        sed -i 's@glpi.bazil.intern@'"$ve.bazil.intern"'@' $sites_available/$webconf_name


        a2ensite $ve   
	systemctl reload apache2

done
}

main9() {
for v in $vers9; do
    ver=9.5.$v
    ve=glpi95$v
    echo "Processing $ver"
    new_path=$www_path/$ve
    target_bot_dir=$new_path/plugins
    ltgbot_path=$target_bot_dir/$ltgbot
    tgbot_path=$target_bot_dir/$tgbot
    sites_available=/etc/apache2/sites-available/
    webconf_name=$ve.conf

        echo "Extracting" 
        tar xzf $src/glpi-$ver.tgz -C $www_path
        mv /var/www/glpi $new_path
        echo "Applying user permissions"
        chown -R www-data:www-data $new_path
        chmod u+rw $new_path/{files,config}
        echo "Copyng TG BOT and fix XML"
        mkdir $tgbot_path
        cp -r $source_bot_location/* $tgbot_path/
        sed -i 's/9.4/9.5/g' $tgbot_path/telegrambot.xml
        echo "GLPI $ver in place"

        echo "Applying DB permissions"
        dbname=glpidb95$v
        mysql -e "CREATE DATABASE $dbname;"
        mysql -e "GRANT ALL PRIVILEGES ON $dbname.* TO glpi@localhost;"
        mysql -e "FLUSH PRIVILEGES;"

        echo "Generating apache2 config"
        cp $sites_available/glpi9.conf $sites_available/$webconf_name
#        sed -i 's/glpi9/glpi95"$v"/g' $sites_available/$web_conf_name
        sed -i 's@glpi9@'"$ve"'@' $sites_available/$webconf_name
        sed -i 's@glpi.bazil.intern@'"$ve.bazil.intern"'@' $sites_available/$webconf_name


        a2ensite $ve   
        systemctl reload apache2

done
}

installdb10() {
basedb=glpidb10
for v in $vers10; do
    console_path=/var/www/glpi10$v/bin/console
    php=/usr/bin/php
    fulldb=$basedb$v
        $php $console_path db:install -L ru_RU -H localhost -d $fulldb -u $userdb -p $passdb -f -n
	$php $console_path glpi:system:check_requirements
    done
}

installdb9() {
basedb=glpidb95
for v in $vers9; do
    console_path=/var/www/glpi95$v/bin/console
    php=/usr/bin/php
    fulldb=$basedb$v
        $php $console_path db:install -L ru_RU -H localhost -d $fulldb -u $userdb -p $passdb -f -n
        $php $console_path glpi:system:check_requirements
    done
}


cleanup10() {

for v in $vers10; 
do
    ver=10.0.$v
    echo "GLPI $ver cleanup"
    echo "folders removal"
    rm -rf /var/www/glpi10$v
    echo "DB removal"
    mysql -e "DROP DATABASE glpidb10$v"
    echo "Disable apache2 site and remove conf file"
    a2dissite "glpi10$v"
    rm -rf /etc/sites-available/glpi10$v.conf
    echo "Finished removal $ver"
done
}

cleanup9() {
for v in $vers9
do
    ver=9.5.$v
    echo "GLPI $ver cleanup"
    echo "folders removal"
    rm -rf /var/www/glpi95$v
    echo "DB removal"
    mysql -e "DROP DATABASE glpidb95$v"
    echo "Disable apache2 site and remove conf file"
    a2dissite "glpi95$v"
    rm -rf /etc/sites-available/glpi95$v.conf
    echo "Finished removal $ver"
done
}

echo "Starting cleanup"
cleanup9
echo "Cleanup finished"

echo "Starting main section"
main9
echo "Main section finished"

echo "Process installation for every installed version"
installdb9
echo "Installed"
systemctl restart apache2
