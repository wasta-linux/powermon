#!/bin/bash
   if ifconfig wlan0 | grep -q "inet addr:" ; then
      exit 0
   else
      logger 'Looks like wlan0 is down. restarting' 
     /sbin/ifdown --force wlan0
     sleep 2
     /sbin/ifup --force wlan0
   fi


