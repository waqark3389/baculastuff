#!/bin/bash
	####
	#### Assume volume label format is "client-LEVEL" i.e. INC FULL DIFF
	#### Assume Only file backups i.e. no tape
	#### Assume retention periods set in below variables
	#### To test, comment out rm and bconsole commands and uncomment ls line in each if
	####

        # Echo the date and time into a text file to read later to work out how long the backup took

        echo `date +%s` > /tmp/$1.timemetric

        # Create a temp file to build the bconsole commands into
        TMPF1=`mktemp`

        #start count for number of volumes
        volcount=0

        #pool retention in DAYS
    incretention="8"
    diffretention="16"
    fullretention="70"

        # take client from arg 1
        client="$1"
        # convert client name to lowercase
        clientlower=${client,,}

        # level i.e. Incremental or Differential or Full from arg 2
        level="$2"
   echo "[INFO] Job level passed "$level""
        #convert level to lowercase
        levellower=${level,,}

        if [ "$levellower" == "incremental" ]
                then
                levelinc="INC"

        elif [ "$levellower" == "differential" ]
                then
                leveldiff="DIFF"

        elif [ "$levellower" == "full" ]
                then
                levelfull="FULL"

        else

        echo "[FATAL] Unknown bacula backup level passed, exiting. Level passed: "$level""
        exit 1
        fi

                if [ "$levelinc" == "INC" ]
                then
                echo "[INFO] Bacula is doing an incremental backup"
                # get a list of volumes which have not been written to in (incremental pool retention period) days

                oldVolumesinc=$(mysql --no-defaults -N -u root -e "select VolumeName from bacula.Media where lower(convert(VolumeName using LATIN1)) like '%"$clientlower"-"$levelinc"%' and LastWritten < NOW() - INTERVAL "$incretention" DAY order by LastWritten;")
                echo "$oldVolumesinc"
                        for a in $oldVolumesinc ; do
                                echo "[INFO] Will delete $a"

                        cp /dev/null $TMPF1
                        printf "prune yes volume=$a\n" >> $TMPF1
                        printf "delete yes volume=$a\n" >> $TMPF1

                        bconsole <$TMPF1 1>/tmp/bconsolereturn.log
                        rm -fv /data/$clientlower/$a
                        #ls -lhrt /data/$clientlower/$a

                                if [ "$?" -gt 0 ]; then
                                echo "+[$a]: [FATAL]: Bconsole returned non-zero status returned: $?"
                                echo "See: TMPF1=$TMPF1"
                                exit
                                fi

                                volcount=$((volcount+1))

                        done

                elif [ "$leveldiff" == "DIFF" ]
                then
                        echo "[INFO] Bacula is doing an diff backup"
                # get a list of volumes which have not been written to in (diff pool retention period) days

                oldVolumesinc=$(mysql --no-defaults -u root -N -e "select VolumeName from bacula.Media where lower(convert(VolumeName using LATIN1)) like '%"$clientlower"-"$leveldiff"%' and LastWritten < NOW() - INTERVAL "$diffretention" DAY order by LastWritten;")

                for a in $oldVolumesinc ; do
                        echo "[INFO] Will delete $a"

                        cp /dev/null $TMPF1
                        printf "prune yes volume=$a\n" >> $TMPF1
                        printf "delete yes volume=$a\n" >> $TMPF1

                        bconsole <$TMPF1 1>/tmp/bconsolereturn.log
                        rm -fv /data/$clientlower/$a
                        #ls -lhrt /data/$clientlower/$a

                        if [ "$?" -gt 0 ]; then
                                echo "+[$a]: [FATAL]: Bconsole returned non-zero status returned: $?"
                                echo "See: TMPF1=$TMPF1"
                                exit
                        fi

                        volcount=$((volcount+1))

                done

                elif [ "$levelfull" == "FULL" ]
        then
                        echo "[INFO] Bacula is doing an full backup"
                # get a list of volumes which have not been written to in (full pool retention period) days

                oldVolumesinc=$(mysql --no-defaults -N -u root -e "select VolumeName from bacula.Media where lower(convert(VolumeName using LATIN1)) like '%"$clientlower"-"$levelfull"%' and LastWritten < NOW() - INTERVAL "$fullretention" DAY order by LastWritten;")

                        for a in $oldVolumesinc ; do
                        echo "[INFO] Will delete $a"

                        cp /dev/null $TMPF1
                        printf "prune yes volume=$a\n" >> $TMPF1
                        printf "delete yes volume=$a\n" >> $TMPF1

                        bconsole <$TMPF1 1>/tmp/bconsolereturn.log
                        rm -fv /data/$clientlower/$a
                        #ls -lhrt /data/$clientlower/$a

                                if [ "$?" -gt 0 ]; then
                                echo "+[$a]: [FATAL]: Bconsole returned non-zero status returned: $?"
                                echo "See: TMPF1=$TMPF1"
                                        exit
                                fi

                        volcount=$((volcount+1))

                        done

                        else
                                echo "[FATAL] expected INC or DIFF or FULL"
                                exit 1
                fi






echo "[INFO] deleting temp file $TMPF1"
rm -f $TMPF1

echo "[INFO] "$volcount" volumes deleted"

