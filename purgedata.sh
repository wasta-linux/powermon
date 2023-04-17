#!/bin/bash

# purge 4 year old data
#find /home/pi/power/ -type f -mtime +1462 -exec rm -f {} \;

# or purge 1 year old data
find /home/pi/power/ -type f -mtime +366 -exec rm -f {} \;


