#!/bin/bash

# For this script to run, the Muscat user must be able to create databases:
# GRANT ALL PRIVILEGES ON * . * TO 'muscat_user'@'localhost'; 

MUSCAT_DIR=/var/www/rails/muscat
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
if [ $? -ne 0 ]; then echo "Could not get DB dump, exit"; exit 1; fi

# Get the current DB name
CURRENT_DB=`ruby housekeeping/automatic_update/get_db.rb`
if [ $? -ne 0 ]; then echo "Could not get current DB name, exit"; exit 1; fi
echo $CURRENT_DB

echo "CREATE DATABASE $DB_NAME CHARACTER SET utf8 COLLATE utf8_general_ci;" | mysql -u $USER -p$PASSWORD
if [ $? -ne 0 ]; then echo "Could not get crete new db $DB_NAME, exit"; exit 1; fi

echo "importing DB"
zcat $DB_FILE | mysql -u $USER -p$PASSWORD $DB_NAME
if [ $? -ne 0 ]; then echo "Could not import $DB_FILE to $DB_NAME, exit"; exit 1; fi

# Set the new database for Muscat
ruby housekeeping/automatic_update/set_db.rb $DB_NAME
if [ $? -ne 0 ]; then echo "Could not se new DB name, exit"; exit 1; fi

echo "Reload apache"
/etc/init.d/apache2 reload

echo "Removing old DB $CURRENT_DB"
echo "DROP DATABASE $CURRENT_DB;" | mysql -u $USER -p$PASSWORD
if [ $? -ne 0 ]; then echo "Could not drop database $CURRENT_DB, clean up"; fi

rm $DB_FILE

} > $MUSCAT_DIR/update.log 2>&1 

echo "Reindexing Muscat"
cd $MUSCAT_DIR
./bin/muscat_reindex > /dev/null

cd $pwd