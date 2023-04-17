#!/bin/bash
# copyright March 20 2014 Paul Zwierzynski
# monitorLJ.sh
# monitor voltage and currents using labjack U3 on Raspberry Pi
# depends on labjack exodriver, labjack python, and labjackFuse
# On Raspberry Pi run as user "pi"
# 1-26-2016 updated for raspberry Pi powermonitor ver 1.01
# 3-9-2016  initialize the labjack IO ports every time

############################
## configurable variables ##
############################
FOLDER="$HOME/power"  # where to put the data files
DATEEXT=`date +%Y.%m.%d.csv`
UNIXTIME=`date +%s`
TIME=`date "+%H:%M"`
ERRORFILE="$FOLDER/errorlog.$DATEEXT"

declare -a LETTERS=( a b c d e f g h ) #used to identify multiple labjack devices

# functions
ljfrestart() {
# restart LabJackFuse if it breaks (Maybe USB problems??)
echo "No labjack device found. Restarting LJFuse."
echo "$TIME No labjack device found. Restarting LJFuse." >> $ERRORFILE
ljstop
sleep 1
python ljfuse.py
sleep 1
if [ -d $HOME/LJFuse/root-ljfuse ]
    then
    echo "$TIME, LJFuse restarted." 
    echo "$TIME, LJFuse restarted." >> $ERRORFILE
    cd root-ljfuse
    declare -a LJNAME=( `ls -d1 */ | sed  's|/||'`)
    if [ "${#LJNAME[@]}" != "0" ]
        then
        for NAME in "${LJNAME[@]}" 
          do
          echo "$TIME, initializing labjack $NAME"
          echo "$TIME, initializing labjack $NAME" >> $ERRORFILE 
          ljinitialize
        done
    fi
else
  echo "$TIME, Error. No labjack device found after restart. Quitting." 
  echo "$TIME, Error. No labjack device found after restart. Quitting." >> $ERRORFILE
  ljstop
  exit 1
fi
}

ljstop() {
  cd $HOME/LJFuse
  fusermount -u -z root-ljfuse
  rm -rf $HOME/LJFuse/root-ljfuse
}

ljinitialize() {
# set all the programmable FIO and EIO lines to Analog input
cd "$HOME/LJFuse/root-ljfuse/$NAME/connection"
for FIODIR in FIO?-dir
do
  VAL=`cat $FIODIR`
  if [ $VAL -ne 2 ] ; then
      # this sets the FIO line to be an analog input
     echo 2 > $FIODIR
  fi
done
for EIODIR in EIO?-dir
do
  VAL=`cat $EIODIR`
  if [ $VAL -ne 2 ] ; then
      # this sets the EIO line to be an analog input
      echo 2 > $EIODIR 
  fi
done
}

########################################
#### The actual program starts here ####
########################################

# we should be running as the same user who installed LJFuse, probably pi
# change into our home folder and look for the LJFuse folder
# if LJFuse isn't installed, silently quit 
# (the installer will setup this program even if no labjack is being used)

if [ -d $HOME/LJFuse  ]
  then
  cd $HOME/LJFuse
  else
  #echo "The folder LJFuse doesn't seem to exist in my home folder." 
  exit 1
fi

# make sure we're not already running
if [ "`pgrep monitorLJ | wc -w`" -gt "2" ]
  then
  echo "$TIME Detected monitorLJ already running. killing it." >> $ERRORFILE
  echo "Detected monitorLJ already running. killing it."
  # kill all processes and restart
  # to avoid hung program from blocking data collection
  pkill -9 monitorLJ 
  sleep 2
  #exit 1
fi

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

# start LJFuse if it isn't already running
if [ ! -d $HOME/LJFuse/root-ljfuse ]
  then
  ljfrestart
fi

cd  $HOME/LJFuse/root-ljfuse
#list all the folders in LJfuse into an array. NO Spaces allowed in names!
declare -a LJNAME=( `ls -d1 */ | sed  's|/||'`)
# if $LJNAME is empty no labjack device is connected
if [ "${#LJNAME[@]}" == "0" ]
  then
  ljfrestart
  cd  $HOME/LJFuse/root-ljfuse
  declare -a LJNAME=( `ls -d1 */ | sed  's|/||'`)
  if [ "${#LJNAME[@]}" == "0" ]
    then
    echo "$TIME monitorLJ.sh still found no Labjack devices. quitting" >> $ERRORFILE
    echo "monitorLJ.sh still found no Labjack devices. quitting."
    ljstop
    exit 1
  fi
fi
  LJ=0
  #echo "${#LJNAME[@]}"
  # start with 0 and output data for each labjack
  until [ $LJ -eq "${#LJNAME[@]}" ]
  do
    # If using more than one Labjack
    # labjack names should be set manually before hooking up to the raspberry pi
    # and labeled on the outside so the users know which is which.
    # recommend the names Alpha, Bravo , Charlie, Delta etc.
    # They will be sorted alphabetically by name, and in the data files
    # the first labeled "a", second "b"
    # So Alpha will get the label "a", Bravo gets "b" etc.
    NAME="${LJNAME[$JL]}"
    #1st labjack found is La.yyyy.mm.dd.csv second is Lb.yyyy.mm.dd.csv etc.
    N="${LETTERS[$LJ]}"
    #echo "LabJackNAME is $NAME"
    #echo "character is $N"
    TIME=`date "+%H:%M"`
    cd "$HOME/LJFuse/root-ljfuse/$NAME/connection"
    # check for an error at this point and bail out
    if [ "$?" != "0" ]
      then
      echo "Can't cd into the folder root-ljfuse/$NAME/connection"
      echo "$TIME monitorLJ can't cd into root-ljfuse/$NAME/connection" >> $ERRORFILE
      ljfrestart
      continue
    fi
    OUTPUTFILE="$FOLDER/L$N.$DATEEXT"
    #check the labjack internal temperature sensor - degrees kelvin!
    TEMP=`cat ../internalTemperature`
    if [ "$?" != "0" ]
      then
          ljfrestart
          cd "$HOME/LJFuse/root-ljfuse/$NAME/connection"
          TEMP=`cat ../internalTemperature`
          if [ "$?" != "0" ]
            then
            echo "$TIME, labjack $NAME not responding"
            echo "$TIME, labjack $NAME not responding" >> $ERRORFILE
            exit 1
          fi
    fi
    # make sure all the ports are set to analog input (takes only .5 sec)
    ljinitialize
    #collect data from all EIO and FIO ports into the array IO[]
    # this part is specific for the LabJack U3-LV which has 8 EIO ports and 8 FIO ports
    X=0
    until [  $X -gt 7 ]
      do
      #echo "X is $X"
      E=`cat EIO$X`
      F=`cat FIO$X`
      # limit each data entry to 7 characters
      IO[$X]=${E:0:6}
      IO[$X+8]=${F:0:6}
      let X+=1
    done
    #Printout all the values to a single line in a file
    echo -n "$UNIXTIME, $TIME, " >> "$OUTPUTFILE"
    X=0
    until [  $X -gt 15 ]
      do
      echo -n "${IO[$X]}, " >> "$OUTPUTFILE"
      let X+=1
    done
    echo "$TEMP" >> "$OUTPUTFILE"
  let LJ+=1
  done  


#echo "got to end"

