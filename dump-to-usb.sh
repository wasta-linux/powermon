#!/bin/bash
mkdir /media/thumbdrive/power
cp -uPa --target-directory=/media/thumbdrive/power /home/pi/power/*.csv
/bin/sync
sudo /bin/umount /media/thumbdrive


