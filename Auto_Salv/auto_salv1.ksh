#!/usr/bin/ksh
############################################################
# auto_salv1.ksh                                           #
#                                                          #
# 07/16/2010                                               #
#                                                          #
# Written by Michael Ng - mikeng2@us.ibm.com               #
############################################################

set -vxn

EMAIL="mikeng2@us.ibm.com, admin1@domain.com, admin2@domain.com, admin3@doman.com"
LOGFILE="/home/mikeng2/auto_salv.log"
DATETIME=`date`

echo $DATETIME": auto_salv1.ksh: script started" >> $LOGFILE


for TAPE in `cat /home/mikeng2/tapelist.txt`; do

	# Set Initial Count/GoCode Value for filesystem space check.
	COUNT=0
	GOCODE=NO

	until [ $GOCODE = "YES" ]
        do
        # Extract the amount of 1Kb Blocks left in the /restore filesystem.
	RESTORESPACE=`df -k /restore | tail -1 | awk '{print $3}'`
	SALVCOUNT=`ls -1 \*.salv\* | egrep -v status | wc -l`

        if [ $RESTORESPACE -gt 1000000000 -a $SALVCOUNT -le 3 ]; then
                GOCODE=YES

                elif [ $COUNT -eq 960 ]; then
			DATETIME=`date`
			echo $DATETIME": auto_salv1.ksh: script has been waiting for 8 hours for the /restore filesystem to have at least 1 TB of space available.  Please check the downstream processing."  >> $LOGFILE
                        exit

                        else
                                GOCODE=NO
                                COUNT=`expr $COUNT + 1`
                                sleep 30

        fi

        done

	# Mount the Tape - E-Mail error and exit if it fails.
	DATETIME=`date`
	echo $DATETIME": auto_salv1.ksh: Starting mount of Tape: "$TAPE >> $LOGFILE
	/usr/bin/mtlib -l/dev/lmcp0 -m -f/dev/rmt5 -V$TAPE >> auto_salv1.ksh.out 2>&1
	EXITCODE=$?
		if [ $EXITCODE -gt 0 ]; then
			DATETIME=`date`
			echo $DATETIME": auto_salv1.ksh: There is a problem mounting "$TAPE" in the drive.  Please check the drive, trim /home/mikeng2/tapelist.txt so "$TAPE" is at the top, and restart auto_salv1.ksh."  >> $LOGFILE
			exit
		fi
	DATETIME=`date`
	echo $DATETIME": auto_salv1.ksh: Finished mount of Tape: "$TAPE >> $LOGFILE

	# Run salv1 against the Tape - E-Mail error and exit if it fails.
	DATETIME=`date`
	echo $DATETIME": auto_salv1.ksh: Starting Salv1 run on Tape: "$TAPE >> $LOGFILE
	/home/mikeng2/salv1 -i/dev/rmt5 -o/restore/ -m/home/mikeng2/  >> auto_salv1.ksh.out 2>&1
	EXITCODE=$?
		if [ $EXITCODE -gt 0 ]; then
			DATETIME=`date`
			echo $DATETIME": auto_salv1.ksh: There was a problem running salv1 against "$TAPE". Please verify that there are no tape or drive faults, trim /home/mikeng2/tapelist.txt so "$TAPE" is at the top, and restart auto_salv1.ksh." >> $LOGFILE
			exit
		fi
	DATETIME=`date`
	echo $DATETIME": auto_salv1.ksh: Finished Salv1 run on Tape: "$TAPE >> $LOGFILE


	# Dismount the Tape - E-Mail error and exit if it fails.
	DATETIME=`date`
	echo $DATETIME": auto_salv1.ksh: Starting Dismount of Tape: "$TAPE >> $LOGFILE
	/usr/bin/mtlib -l/dev/lmcp0 -d -f/dev/rmt5  >> auto_salv1.ksh.out 2>&1
	EXITCODE=$?
		if [ $EXITCODE -gt 0 ]; then
			DATETIME=`date`
			echo $DATETIME": auto_salv1.ksh: There is a problem dismounting Tape "$TAPE" in the drive.  Please check the drive, trim /home/mikeng2/tapelist.txt so the tape below "$TAPE" is at the top, and restart auto_salv1.ksh." >> $LOGFILE
			exit
		fi
	DATETIME=`date`
	echo $DATETIME": auto_salv1.ksh: Finished Dismount of Tape: "$TAPE >> $LOGFILE


	# Log the tape as being Salv1 process Complete
	echo $TAPE >> /home/mikeng2/salv1.done
	DATETIME=`date`
	echo $DATETIME": auto_salv1.ksh: Salv1 process complete for "$TAPE

done

DATETIME=`date`
echo $DATETIME": auto_salv1.ksh: Script has finished running successfully with no errors." >> $LOGFILE

touch /home/mikeng2/auto_salv1.ksh.done
