Stopping/Restarting the auto_salv3 Script 

 

Stopping Quickly: 

 

(This will stop the auto_salv3 process IMMEDIATELY.) 
 

Look for auto_salv3 & salv3 processes and issue a kill command against them. 
 

ps -ef | egrep “salv3|sleep 10” | egrep -v egrep 
 
 
Stopping Gracefully: 

 

(This will allow the salv3 program to finish processing the salv2 data that it is currently working on and exit gracefully.  This may take several hours to shut down the salv3 process.) 

 
touch /home/mikeng2/auto_salv2.ksh.done 
 
 
 
Starting: 
 

1.) To prepare to re-run Auto_Salv3, review the /home/mikeng2/auto_salv.log file and identify the last tape successfully processed by salv3, then modify that tape list to reflect this. 
 
For example, if tape U22290 was the last tape to FINISH salv2 processing. 
 
Modify the file /home/mikeng2/salv2.done so that tape BELOW U22290 is now the first line.  (Delete U22290 and all the tapes listed above it.) 
 
Note:  The salv2.done file probably will NOT have more than 1-4 tapes listed at any one time. 
 
 

2.) Verify that there is no salv2 completion file present and remove if necessary. 
 
rm /home/mikeng2/auto_salv2.ksh.done 
 
 

3.) To restart the auto_salv3 script and it’s related salv3 process. 
 
echo “/home/mikeng2/auto_salv3.ksh” | at now 
