#!/bin/bash
#Written on 3-Mar-2021 to migrate the WP 
#script name "wp_migrate.sh" written by akiles , any future modifications please email - akilestcs@gmail.com
DATE=$(date +%Y_%m_%d\_%H_%M_%S);
exec >/tmp/"$(basename "$0").log" 2>&1 #log;
arg=$#
        if [ $arg -ne 1 ]
        then
                echo "Usage:wp_migrate.sh --config=config_file"
                exit 9;
        fi
#Define the path of your config.txt
CONFIG=`echo $1 | awk -F"=" '{ print $2 }'`;
        if [ -f "$CONFIG" ]
	then 
                export $(grep "SOURCE_FOLDER" $CONFIG);
                export $(grep "DESTINATION_FOLDER" $CONFIG);
                export $(grep "BACKUP_FOLDER" $CONFIG);
                export $(grep "WORKING_DIRECTORY" $CONFIG);
                export $(grep "MYSQL_DB_SOURCE" $CONFIG);
                export $(grep "MYSQL_HOST_SOURCE" $CONFIG);
                export $(grep "MYSQL_USER_SOURCE" $CONFIG);
                export $(grep "MYSQL_PASS_SOURCE" $CONFIG);
                export $(grep "MYSQL_DB_DESTINATION" $CONFIG);
                export $(grep "MYSQL_HOST_DESTINATION" $CONFIG);
                export $(grep "MYSQL_USER_DESTINATION" $CONFIG);
                export $(grep "MYSQL_PASS_DESTINATION" $CONFIG);
                export $(grep "SOURCE_DOMAIN" $CONFIG);
                export $(grep "DESTINATION_DOMAIN" $CONFIG);
        else 
		echo "$DATE:Config file is missing , program exiting";
		exit 1; 
        fi
#STEP:1
        if [ -d "$SOURCE_FOLDER" ] && [ -d "$DESTINATION_FOLDER" ] && [ -d "$BACKUP_FOLDER" ] && [ -d "$WORKING_DIRECTORY" ]
        then
                cd $WORKING_DIRECTORY
                mysqldump --host=${MYSQL_HOST_SOURCE} --user=${MYSQL_USER_SOURCE} --password=${MYSQL_PASS_SOURCE} ${MYSQL_DB_SOURCE} > source_db.sql;
                if [ "$?" -eq 0 ]; then
                        echo "$DATE:Source DB backup done";
                else
                        echo "$DATE:Source DB connection error"
                        exit 1;
                fi
                mysqldump --host=${MYSQL_HOST_DESTINATION} --user=${MYSQL_USER_DESTINATION} --password=${MYSQL_PASS_DESTINATION} ${MYSQL_DB_DESTINATION} > destination_db.sql
                if [ "$?" -eq 0 ]; then
                        echo "$DATE:Destination DB backup done";
                else
                        echo "$DATE:Destination DB connection error"
                        exit 1;
                fi
                echo "Destination DB backup done";
                tar -cvf source_file.tar $SOURCE_FOLDER ; echo "Source folder backup done";
                tar -cvf destination_file.tar $DESTINATION_FOLDER ; echo "Destination folder backup done";
                tar -cvf $BACKUP_FOLDER/backup_$DATE.tar *
                gzip $BACKUP_FOLDER/backup_$DATE.tar
                echo "$DATE:STEP1 completed";
        else
                echo "$DATE:Directory missing" ; exit 1;
        fi
#STEP:2
sed "s/"$SOURCE_DOMAIN"/"$DESTINATION_DOMAIN"/g" source_db.sql > destination_db_import.sql
echo "$DATE:STEP2 completed";
#STEP:3
cd $DESTINATION_FOLDER
E_FOLDER=`grep "EXCLUSION_FOLDER" $CONFIG | awk -F"=" '{ print $NF }'`
E_FILE=`grep "EXCLUSION_FILE" $CONFIG| awk -F"=" '{ print $NF }'`
str1='grep -xv -e '
str2=`echo $E_FOLDER | sed 's/ / -e /g'`
str3=`echo $E_FILE | sed 's/ / -e /g'`
str_folder=$str1$str2
str_file=$str1$str3
ls | $str_folder |$str_file | xargs rm -r
echo "$DATE:STEP3 completed";
#STEP:4
cd $SOURCE_FOLDER ;
ls | $str_folder |$str_file | xargs -I '{}' cp -rp  '{}' $DESTINATION_FOLDER
cp -Rp .[a-zA-Z0-9]* $DESTINATION_FOLDER
echo "$DATE:STEP4 completed";
#STEP:5
mysqldump --add-drop-table --no-data --host=${MYSQL_HOST_DESTINATION} --user=${MYSQL_USER_DESTINATION} --password=${MYSQL_PASS_DESTINATION} ${MYSQL_DB_DESTINATION} | grep 'DROP TABLE' > $WORKING_DIRECTORY/temp.sql
mysql --host=${MYSQL_HOST_DESTINATION} --user=${MYSQL_USER_DESTINATION} --password=${MYSQL_PASS_DESTINATION} ${MYSQL_DB_DESTINATION} < $WORKING_DIRECTORY/temp.sql
echo "$DATE:STEP5 completed";
#STEP:6
mysql --host=${MYSQL_HOST_DESTINATION} --user=${MYSQL_USER_DESTINATION} --password=${MYSQL_PASS_DESTINATION} ${MYSQL_DB_DESTINATION} < $WORKING_DIRECTORY/destination_db_import.sql
echo "$DATE:STEP6 completed";
cd $WORKING_DIRECTORY
rm *.tar ; rm *.sql;
echo "$DATE:Migration completed successfully";
