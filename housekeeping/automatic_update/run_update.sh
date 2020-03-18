#!/bin/bash

# For this script to run, the Muscat user must be able to create databases:
# GRANT ALL PRIVILEGES ON * . * TO 'muscat_user'@'localhost'; 

MUSCAT_DIR=/var/www/muscat
export RAILS_ENV=production

DATE=`date '+%Y%m%d%H%M'`
DB_NAME="muscat$DATE"

USER=db_user
PASSWORD=password

DB_FILE=/var/www/mp.tar.gz

pwd=`pwd`
cd $MUSCAT_DIR
{

echo "Copy database snapshot"

if [ -e $DB_FILE ]; then rm $DB_FILE; fi
curl https://muscat.rism.info/mp.tar.gz -o $DB_FILE

# Get the current DB name
CURRENT_DB=`ruby housekeeping/automatic_update/get_db.rb`
echo $CURRENT_DB
exit 0

echo "CREATE DATABASE $DB_NAME CHARACTER SET utf8 COLLATE utf8_general_ci;" | mysql -u $USER -p$PASSWORD
echo "importing DB"
zcat $DB_FILE | mysql -u $USER -p$PASSWORD $DB_NAME

# Set the new database for Muscat
ruby housekeeping/automatic_update/set_db.rb $DB_NAME
echo "Reload apache"
/etc/init.d/apache2 reload

echo "Purging Old DB $CURRENT_DB"
echo "DROP DATABASE $CURRENT_DB;" | mysql -u $USER -p$PASSWORD

rm $DB_FILE



} 2>&1 | logger
#or: mail -s "Muscat Training Update Report" rodolfo.zitellini@rism-ch.org

echo "Reindexing Muscat"
cd /data/www/rails/muscat-training
./bin/muscat_reindex > /dev/null

cd $pwd