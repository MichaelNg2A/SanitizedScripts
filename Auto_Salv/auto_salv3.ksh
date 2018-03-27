#!/usr/bin/ksh
############################################################
# auto_salv3.ksh                                           #
#                                                          #
# 06/24/2010                                               #
#                                                          #
# Written by Michael Ng - mikeng2@us.ibm.com               #
############################################################

EMAIL="mikeng2@us.ibm.com, admin1@domain.com, admin2@domain.com, admin3@doman.com"
LOGFILE="/home/mikeng2/auto_salv.log"
DATETIME=`date`

echo $DATETIME": auto_salv3.ksh: script started" >> $LOGFILE

# Until the auto_salv2 script reports that it is done processing all tapes
# AND the list of salv2 output files has been exhausted, do the following processing.

until [ ! -s "/home/mikeng2/salv2.done" -a -f "/home/mikeng2/auto_salv2.ksh.done" ]
	do
	# First - Verify that there is data in the salv2.done file and then proceed with processing.
	COUNT=0
	GOCODE=NO

	until [ $GOCODE = "YES" ]
        do
		if [ -s "/home/mikeng2/salv2.done" ]; then
		GOCODE=YES

                	elif [ $COUNT -eq 4320 ]; then
                        DATETIME=`date`
                        echo $DATETIME": auto_salv3.ksh: script has been waiting for 12 hours with no new data to process from salv2.  Please investigate and restart as needed."  >> $LOGFILE
                        exit

                        	else
                                GOCODE=NO
                                COUNT=`expr $COUNT + 1`
                                sleep 10

        	fi

        done

	# Read in the next tape that has finished processing.
	TAPE=`head -1 /home/mikeng2/salv2.done`

	# Run Salv3 against the output from Salv2 - E-Mail error and exit if it fails.
        DATETIME=`date`
        echo $DATETIME": auto_salv3.ksh: Starting Salv3 Processing of Tape: "$TAPE >> $LOGFILE
	/home/mikeng2/salv3 -i/restore/$TAPE.salv2 -o/restore/ -l -m/home/mikeng2/ >> auto_salv3.ksh.out 2>&1
	EXITCODE=$?
		if [ $EXITCODE -gt 0 ]; then
                        DATETIME=`date`
                        echo $DATETIME": auto_salv3.ksh: There was a problem running salv3 against "$TAPE". Please troubleshoot this issue and re-run salv3 against "$TAPE" if necessary." >> $LOGFILE
		fi
        DATETIME=`date`
        echo $DATETIME": auto_salv3.ksh: Finished Salv3 Processing of Tape: "$TAPE >> $LOGFILE

	# Log the tape as being Salv3 process Complete
	echo $TAPE >> /home/mikeng2/salv3.done

	# Read the entire list of tapes to be processed except the tape that
	# was just processed, then dump the new list into a file that will
	# be renamed to the original file.  This is done this way because
	# a simple redirection will purge the target first.

	egrep -v $TAPE /home/mikeng2/salv2.done >> /home/mikeng2/salv2.done.new

	rm /home/mikeng2/salv2.done

	mv /home/mikeng2/salv2.done.new /home/mikeng2/salv2.done

	done


DATETIME=`date`
echo $DATETIME": auto_salv3.ksh: Script has finished running.  Please restart if needed when there are more Salv2 files to process." >> $LOGFILE

touch /home/mikeng2/auto_salv3.ksh.done

