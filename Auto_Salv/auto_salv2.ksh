#!/usr/bin/ksh
############################################################
# auto_salv2.ksh                                           #
#                                                          #
# 06/28/2010                                               #
#                                                          #
# Written by Michael Ng - mikeng2@us.ibm.com               #
############################################################

EMAIL="mikeng2@us.ibm.com, admin1@domain.com, admin2@domain.com, admin3@doman.com"
LOGFILE="/home/mikeng2/auto_salv.log"
DATETIME=`date`
COUNT=0
GOCODE=NO

echo $DATETIME": auto_salv2.ksh: script started" >> $LOGFILE


# Until the auto_salv1 script reports that it is done processing all tapes
# AND the list of salv1 output files has been exhausted, do the following processing.

until [ ! -s "/home/mikeng2/salv1.done" -a -f "/home/mikeng2/auto_salv1.ksh.done" ]
        do
        until [ $GOCODE = "YES" ]
                do
                # Validate that the tape list is not empty.
                if [ -s "/home/mikeng2/salv1.done" ]; then
                        GOCODE=YES

                        elif [ $COUNT -eq 2160 ]; then
                                DATETIME=`date`
                                echo $DATETIME": auto_salv2.ksh: script has been waiting for 12 hours for auto_salv1.ksh to generate a new file to be processed.  Please check the upstream processing and restart auto_salv2.ksh when there is more data to process."  >> $LOGFILE
                                exit

                        else
                                GOCODE=NO
                                COUNT=`expr $COUNT + 1`
                                sleep 20

                fi

                done


        # Read in the next tape that has finished processing.
        TAPE=`head -1 /home/mikeng2/salv1.done`

        # Run Salv2 against the output from Salv1 - E-Mail error and exit if it fails.
        DATETIME=`date`
        echo $DATETIME": auto_salv2.ksh: Starting Salv2 Processing of Tape: "$TAPE >> $LOGFILE
        /home/mikeng2/salv2 -i/restore/$TAPE.salv1 -o/restore/ -m/home/mikeng2/ >> auto_salv2.ksh.out 2>&1
        EXITCODE=$?
	DELETECODE=YES
                if [ $EXITCODE -gt 0 ]; then
                        DATETIME=`date`
                        echo $DATETIME": auto_salv2.ksh: There was a problem running salv2 against "$TAPE". Please troubleshoot this issue and re-run salv2 against "$TAPE" if necessary." >> $LOGFILE
			DELETECODE=NO
                fi
        DATETIME=`date`
        echo $DATETIME": auto_salv2.ksh: Finished Salv2 Processing of Tape: "$TAPE >> $LOGFILE

        # Log the tape as being Salv2 process Complete
        echo $TAPE >> /home/mikeng2/salv2.done

        # Delete the original Salv1 Source File
	if [ $DELETECODE = YES ]; then
	        rm /restore/$TAPE.salv1
	fi

        # Read the entire list of tapes to be processed except the tape that
        # was just processed, then dump the new list into a file that will
        # be renamed to the original file.  This is done this way because
        # a simple redirection will purge the target first.

        egrep -v $TAPE /home/mikeng2/salv1.done >> /home/mikeng2/salv1.done.new

        rm /home/mikeng2/salv1.done

        mv /home/mikeng2/salv1.done.new /home/mikeng2/salv1.done

	GOCODE=NO

        done


DATETIME=`date`
echo $DATETIME": auto_salv2.ksh: Script has finished running.  Please restart if needed when there are more Salv1 files to process." >> $LOGFILE


touch /home/mikeng2/auto_salv2.ksh.done

