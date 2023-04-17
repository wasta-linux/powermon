#!/bin/bash
# outbackdata.sh
# get all controller, flexnetdc and inverter records
# copyright 2011 Paul Zwierzynski
# 08-31-2011
# 1-21-2016 Updated for USB input and running on on RPI

# execute this every minute of every day using the following
#   CRON/crontab (ChRONological TABle) command...
# * * * * * => Execute every minute
# [ Minute - Hour - Day - Month - Weekday ] - Command
# * * * * * /usr/local/bin/outbackdata.sh


TIME=`date "+%H:%M, "`
UNIXTIME=`date +%s`
FILENAME=`date +%Y.%m.%d.csv`
#data will be collected in "FOLDER" folder
FOLDER="$HOME/power"
ERRORFILE="$FOLDER/errorlog.$FILENAME"
DEVICE=/dev/ttyUSB0

# avoid having more than one copy of this script running...
name=`echo $0 | sed 's@.*/@@'`
copiesrunning=`ps -C $name | grep $name | wc -l `


if [ $copiesrunning -gt 4 ]; then
    echo "there are $copiesrunning copies running now"
    echo "$TIME outbackdata failed to run. a hung outbackdata.sh process was found." >> $ERRORFILE
    exit 1
fi
# alternate is to kill all running processes named outbackdata.sh
#if [ "`pgrep outbackdata.sh | wc -w`" -gt "2" ]
#  then
#  echo "Detected outbackdata already running. killing it." >> $ERRORFILE
#  # kill all processes and restart
#  # to avoid hung program from blocking data collection
#  pkill -9 monitorLJ 
#  sleep 2
#  #exit 1
#fi
# check to see if the data folder exists
if [ ! -d "$FOLDER" ]
  then
  mkdir "$FOLDER"
fi
if [ ! -d "$FOLDER" ]
  then
  echo "$TIME monitorLJ can't find or create the data folder $FOLDER" >> $ERRORFILE
  echo "Can't create the data folder $FOLDER" 
  echo "Check path and permissions"
  exit 1
fi


# complete lines have 47 characters. Usually the first line is incomplete.
# Throw away incomplete lines.
/usr/local/bin/queryMateSerial $DEVICE 2000 | egrep '^.{48}$' | sed 's/.$//' > /tmp/matedata

for controller in "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K"
    do
    grep "^$controller" < /tmp/matedata >/dev/null
        if [ "$?" == "0" ]
	then
           cat /tmp/matedata | grep "^$controller" -m1 | sed "s/^/$UNIXTIME, $TIME/" >> "$FOLDER/C$controller.$FILENAME"
        fi
    done

for flexnetdc in "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k"
    do
    grep "^$flexnetdc" < /tmp/matedata >/dev/null
        if [ "$?" == "0" ]
	then
           cat /tmp/matedata | grep "^$flexnetdc" -m1 | sed "s/^/$UNIXTIME, $TIME/" >> "$FOLDER/F$flexnetdc.$FILENAME"
        fi
    done
    
for inverter in "1" "2" "3" "4" "5" "6" "7" "8" "9" "0"
    do
    grep "^$inverter" < /tmp/matedata >/dev/null
        if [ "$?" == "0" ]
	then
           cat /tmp/matedata | grep "^$inverter" -m1 | sed "s/^/$UNIXTIME, $TIME/" >> "$FOLDER/I$inverter.$FILENAME"
        fi
    done


