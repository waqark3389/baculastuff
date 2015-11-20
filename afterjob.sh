#!/bin/bash

client=$1

# read the value the before script generated
starttime=`cat /tmp/$client.timemetric`

endtime=`date +%s`

timetaken=$(($endtime - $starttime))


# stolen function to convert seconds to friendly notation
function show_time () {
    num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi
    ttaken=""$hour"h "$min"m "$sec"s"
}

show_time $timetaken

## Do something with ttaken value. I add it to a database. 
