#!/bin/bash
# ssh public key authentication should be set up for seamless login

db_server="10.1.1.34"
server_name=$1

# stop MySQL instance
cmd="mysql -u root --socket=/tmp/${server_name}.sock -e \"stop slave;\""
ssh root@$db_server $cmd

## List database and create a dump file for each
dbs=`ssh root@$db_server "mysql -u root --socket=/tmp/${server_name}.sock --skip-column-names -e \"show databases;\""`
dump_error="false"
for Databases in ${dbs}
do
                ssh root@$db_server "mysqldump -u root  -e --single-transaction --socket=/tmp/${server_name}.sock ${Databases} | gzip > /home/beforebackup/mysqldumps/${server_name}_${Databases}.sql.gz"
        dump_file_size=`stat -c %s /home/beforebackup/mysqldumps/${server_name}_${Databases}.sql.gz`

                  if [ $dump_file_size -lt 15360 ]
        then
             echo Database dump is smaller than 15KB ${server_name}_${Databases}.sql.gz
             dump_error="true"
        fi

done

if [ $dump_error = "true" ]
then
    /root/scripts/bacula2nagios.sh ${server_name} 1
fi
