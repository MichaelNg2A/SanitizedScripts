Stopping/Restarting the auto_salv1 Script 

Stopping: 
 

1.) Look for auto_salv1 & salv1 processes and issue a kill command against them. 
 
ps -ef | egrep “salv3|sleep 30|mtlib” | egrep -v egrep 
 
 

2.) Dismount the tape that is currently in the drive. 
 

mtlib -l/dev/lmcp0 -d -f/dev/rmt5 

 
 
Starting: 
 

1.) To prepare to re-run Auto_Salv1, review the auto_salv log file and identify the last tape successfully processed by salv1, then modify that tape list to reflect this. 
 
Output of /home/mikeng2/auto_salv.log 
 
Fri Jun 25 09:06:32 2010: auto_salv1.ksh: Starting mount of Tape: U22290 
Fri Jun 25 09:06:51 2010: auto_salv1.ksh: Finished mount of Tape: U22290 
Fri Jun 25 09:06:51 2010: auto_salv1.ksh: Starting Salv1 run on Tape: U22290 
Fri Jun 25 12:18:36 2010: auto_salv1.ksh: Finished Salv1 run on Tape: U22290 
Fri Jun 25 12:18:36 2010: auto_salv1.ksh: Starting Dismount of Tape: U22290 
Fri Jun 25 12:19:07 2010: auto_salv1.ksh: Finished Dismount of Tape: U22290 
 
Based on the above example, Tape U22290 has finished processing. 
 
Modify the file /home/mikeng2/tapelist.txt so that tape BELOW U22290 is now the first line.  (Delete U22290 and all the tapes listed above it.) 
 
 

2.) To restart the auto_salv1 script and it’s related salv1 process. 
 
echo “/home/mikeng2/auto_salv1.ksh” | at now 
