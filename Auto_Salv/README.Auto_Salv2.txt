Stopping/Restarting the auto_salv2 Script 

 

Stopping Quickly: 

 

(This will stop the auto_salv2 process IMMEDIATELY.) 
 

Look for auto_salv2 & salv2 processes and issue a kill command against them. 
 
ps -ef | egrep “salv3|sleep 20” | egrep -v egrep 
 
 
Stopping Gracefully: 

 

(This will allow the salv2 program to finish processing the salv1 data that it is currently working on and exit gracefully.  This may take several hours to shut down the salv2 process.) 

 
touch /home/mikeng2/auto_salv1.ksh.done 
 
 
 
Starting: 
 

1.) To prepare to re-run Auto_Salv2, review the /home/mikeng2/auto_salv.log file and identify the last tape successfully processed by salv2, then modify that tape list to reflect this. 
 
For example, if tape U22290 was the last tape to FINISH salv2 processing. 
 
Modify the file /home/mikeng2/salv1.done so that tape BELOW U22290 is now the first line.  (Delete U22290 and all the tapes listed above it.) 
 
Note:  The salv1.done file probably will NOT have more than 1-3 tapes listed at any one time. 
 
 

2.) Verify that there is no salv1 completion file present and remove if necessary. 
 
rm /home/mikeng2/auto_salv1.ksh.done 
 
 

3.)  To restart the auto_salv2 script and it’s related salv2 process. 
 
echo “/home/mikeng2/auto_salv2.ksh” | at now 
