#!/bin/bash
	####
	#### Assume volume label format is "client-LEVEL" i.e. INC FULL DIFF
	#### Assume Only file backups i.e. no tape
	#### To test, comment out rm and bconsole commands and uncomment ls line in each if
	####

if [ "$#" -ne 5 ]
then

echo "Wrong number of args passed. Expected 5:"
echo "Usage: ./baculaVolumeCleaner.sh <client> <backuplevel> <IncrementalRetentionInDays> <DiffRetentionInDays> <FullRetentionInDays>"
exit
fi

        # Echo the date and time into a text file to read later to work out how long the backup took

        echo `date +%s` > /tmp/$1.timemetric

        # set to yes to test only and not remove any data etc, testing mode just lists volumes which would have been deleted
        # set no for production
## DEFAULT TO NOT DELETE STUFF ##
     testingmode="yes"

        # Create a temp file to build the bconsole commands into
        TMPF1=`mktemp`

        #start count for number of volumes
        volcount=0

        #pool retention in DAYS passed in via args
        # should add case statement for name based args. ###TO DO###

    incretention="$3"
    diffretention="$4"
    fullretention="$5"

        # take client from arg 1
        client="$1"
        # convert client name to lowercase
        clientlower=${client,,}
        echo "[INFO] client passed: $clientlower"
        # Set data path here:

        volumepath="/data/$clientlower"
        echo "[INFO] Path calculated as: $volumepath"

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
        #       echo "$oldVolumesinc"
                        for a in $oldVolumesinc ; do
                                echo "[INFO] Will delete $a"

                        cp /dev/null $TMPF1
                        printf "prune yes volume=$a\n" >> $TMPF1
                        printf "delete yes volume=$a\n" >> $TMPF1

                                if [ "$testingmode" == "yes"  ]
                                then
                                        echo "[INFO] Testing mode active..."
                                        ls -lhrt $volumepath/$a
                                else
                                        echo "[INFO] Deleting... $a"
                                        # redirect rest to bconsolereturn.log for debugging...
                                        bconsole <$TMPF1 1>/tmp/bconsolereturn.log
                                        if [ "$?" -gt 0 ]; then
                                                echo "+[$a]: [FATAL]: Bconsole returned non-zero status returned: $?"
                                                echo "See: TMPF1=$TMPF1"
                                                exit
                                        fi

                                        rm -fv $volumepath/$a

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

                        if [ "$testingmode" == "yes"  ]
                                then
                                        echo "[INFO] Testing mode active..."
                                        ls -lhrt $volumepath/$a
                        else
                                        echo "[INFO] Deleting... $a"
                                        bconsole <$TMPF1 1>/tmp/bconsolereturn.log
                                        if [ "$?" -gt 0 ]; then
                                                echo "+[$a]: [FATAL]: Bconsole returned non-zero status returned: $?"
                                                echo "See: TMPF1=$TMPF1"
                                                exit
                                        fi

                                        rm -fv $volumepath/$a

                        fi


                        volcount=$((volcount+1))

                done

                elif [ "$levelfull" == "FULL" ]
                then
                echo "[INFO] Bacula is doing an full backup"
                # get a list of volumes which have not been written to in (diff pool retention period) days

                oldVolumesinc=$(mysql --no-defaults -N -u root -e "select VolumeName from bacula.Media where lower(convert(VolumeName using LATIN1)) like '%"$clientlower"-"$levelfull"%' and LastWritten < NOW() - INTERVAL "$fullretention" DAY order by LastWritten;")

                        for a in $oldVolumesinc ; do
                        echo "[INFO] Will delete $a"

                        cp /dev/null $TMPF1
                        printf "prune yes volume=$a\n" >> $TMPF1
                        printf "delete yes volume=$a\n" >> $TMPF1

                        if [ "$testingmode" == "yes"  ]
                        then
                                echo "[INFO] Testing mode active..."
                                ls -lhrt $volumepath/$a
                        else
                                echo "[INFO] Deleting... $a"
                                bconsole <$TMPF1 1>/tmp/bconsolereturn.log
                                if [ "$?" -gt 0 ]; then
                                       echo "+[$a]: [FATAL]: Bconsole returned non-zero status returned: $?"
                                       echo "See: TMPF1=$TMPF1"
                                       exit
                                fi

                                rm -fv $volumepath/$a
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
