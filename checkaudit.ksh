#!/usr/bin/ksh
######################################################################
# Title:	checkaudit                                           #
# Author:	Michael Ng                                           #
#		(ngmich@BigBank.com)                                 #
# Version:	6.6                                                  #
#                                                                    #
# This script will parse data from the Daily Mail Audit Report and   #
# search the filesystem on #### for files containing the message IDs #
# listed.                                                            #
#                                                                    #
# Normal usage is to run this script from cron at 1000 Pacific Time  #
# Daily.  The script will look for a "Section 3" header in the Daily #
# Mail Audit Report every 15 seconds.  Once the header has been      #
# found, it will presume that all Section 2 processing is finished   #
# and start processing data.  This will allow automatic processing   #
# of the Big Bank (SubSystem) Mail Audit Report that is sent from    #
# #### every day.  This check was put into place because the report  #
# completion time ranges from 1020-1101 daily and I did not want to  #
# wait until 1130 to start processing just to guarantee that the     #
# data was there.                                                    #
#                                                                    #
# If checkaudit.ksh does not find a "Section 3" header after 2 hours #
# (~noon), it will send an Error Message to the script owner via     #
# E-Mail and abort any further processing.  This prevents the script #
# from running ad infinitum in the event of Audit Report generation  #
# problems and provides an additional problem notification method.   #
#                                                                    #
# The script can also be invoked from the command line with an       #
# optional date argument.  (In yymmdd format.)  If no argument is    #
# given, the script will default to the current system date.         #
#                                                                    #
# Note:  Because of limitations I have put into the search ranges,   #
#        it is best that any search dates used extend a MAXIMUM of 7 #
#        DAYS into the past.  Any further and the script will NOT    #
#        look in spam/dup subdirectories for the data you are        #
#        looking for.  This was done to limit the age of directories #
#        and Archives that are searched and improve responsiveness.  #
#                                                                    #
# Output is sent via E-Mail to specified Users.                      #
#                                                                    #
# Note:  Recipients are currently defined by the $EMAIL Variable.    #
#        There is no provision to allow specification of E-Mail      #
#        recipient on the command line at this time.  This was done  #
#        to simplify execution of this command via cron.             #
#                                                                    #
# Limitations:  This script will not check ALL Message-IDs.  There   #
#               are a few Source IDs that that belong to outbound    #
#               mailer channels.  When checkaudit finds a message    #
#               with this Source-ID, you will be advised that the    #
#               filesystem was NOT searched for this particular      #
#               Message-ID.                                          #
#                                                                    #
#               (These Source-IDs can be found listed on line #208   #
#               nested in the case statement.)                       #
#                                                                    #
######################################################################
# System Variables                                                   #
######################################################################
# Date of Mail Audit Report to be checked.                           #
######################################################################

STARTDATETIME=`date`

if [ $# -lt 1 ]
	then REPORTDATE=`date +%y%m%d`
	else REPORTDATE=$1
fi

######################################################################
# Current Date in yyyymmdd format.                                   #
######################################################################

FULLCURRENTDATE=`date +%Y%m%d`

######################################################################
# E-Mail address results are automatically copied to.                #
######################################################################

EMAIL="admin1@BigBank.COM, admin2@BigBank.COM, admin3@BigBank.COM, admin4@BigBank.COM, admin5@BigBank.COM, ngmich@BigBank.COM, admin6@BigBank.COM, admin7@BigBank.COM, manager@BigBank.COM"

SCRIPTOWNER="ngmich@BigBank.COM"

######################################################################
# Name and Location of Mail Audit Report to be checked.              #
######################################################################

ORIGFILEPATH=/app/audit
ORIGFILE=$REPORTDATE"_audit_rpt.lst"

######################################################################
# Make sure appropriate command line argument is provided.           #
######################################################################

if [ "$#" -gt 1 -o "$1" -gt 991231 ]; then
echo "Usage: $0 <Optional yymmdd Date>"
exit
fi

######################################################################
# Names of Temp files used in Slicing & Dicing the Mail Audit Report.#
######################################################################

CSPLITPREFIX="MARSR"$REPORTDATE"."
CSPLITRESULTS="MARSR"$REPORTDATE".00"
NOHEADERDATA=$ORIGFILE".Section2Data"
PARSEDREPORT=$ORIGFILE".Parsed"

ARCHIVEDIR=/users/ocsdev/ngmich/scripts/checkaudit/checkaudit_Results

######################################################################
# Temp file used  to record Header info for checkaudit.ksh E-Mail.   #
######################################################################

CHECKAUDITHEADER=$REPORTDATE".checkauditruntime"

######################################################################
# Take Name of Output File from second argument on the command line. #
######################################################################

OUTPUTFILE=mailauditcrosscheckout.$REPORTDATE

OUTPUTFILE2=tempmailauditcrosscheckout.$REPORTDATE

######################################################################
#  Define how many days worth of archives and spam/dup/Investigate   #
#  subdirectories to automatically search.                           #
#                                                                    #
#  If no report date is given on execution, base number of days on   #
#  the current day of week.  Otherwise, set days searched to 8 under #
#  the assumption that a crosscheck report probably won't be run     #
#   more than a week after the original report was run.              #
######################################################################

if [ $# -lt 1 ]
	then DAYOFWEEK=`date +%a`
		case $DAYOFWEEK in
			Mon) DAYS=4;;
			Sun) DAYS=3;;
			*) DAYS=2;;
		esac
	else DAYS=8
fi

######################################################################
# Generic Message-ID not found error message.                        #
######################################################################

NOTFOUNDMSG="was not found.  Double-check Filesystem AND Database."

######################################################################
# Wait until Report has all Section 2 data, then start processing.   #
# (Script will send Error E-Mail and exit after 2 hours.)            #
######################################################################

COUNT=0
GOCODE=NO

until [ $GOCODE = "YES" ]
        do
        egrep "Section 3" $ORIGFILEPATH/$ORIGFILE
        EXITCODE=$?

        if [ $EXITCODE -eq 0 ]; then
                GOCODE=YES

                elif [ $COUNT -eq 480 ]; then
			echo "checkaudit.ksh ran for 2 hours with no Section 2 Data Ready.  Please Investigate ASAP!" | mailx -s "checkaudit.ksh Script Execution Error on #### - Please Investigate" $SCRIPTOWNER
                        exit

                        else
                                GOCODE=NO
                                COUNT=`expr $COUNT + 1`
                                sleep 15

        fi

        done

######################################################################
# Variable used to record start of checkaudit.ksh script processing. #
######################################################################

STARTDATETIME=`date`

######################################################################
# Copy over current (or specified) report.  Start Slicing & Dicing.  #
######################################################################

cp $ORIGFILEPATH/$ORIGFILE .

csplit -f $CSPLITPREFIX $ORIGFILE '%Section 2:%'

egrep ^[0-9][0-9][0-9]\.[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9] $CSPLITRESULTS >> $NOHEADERDATA

awk '{print $1}' $NOHEADERDATA >> $PARSEDREPORT

######################################################################
# Start Processing Data                                              #
######################################################################

for MSGID in `cat $PARSEDREPORT`
do
SOURCEID=`echo $MSGID | awk -F. '{ print $1 }'`

	case $SOURCEID in

######################################################################
# Groups that belong to mailer channels - Level 1 Case               #
######################################################################

	086|087|104|105|108|115|116|122|123|125|126|130|131|136|140|141|142|143|144|145|156|157|163|164|169|170|172|173|174|175|180|181) echo "$MSGID NOT auto-searched.  $SOURCEID belongs to an outbound mailer channel."  >> $OUTPUTFILE;;

######################################################################
# Groups that have more than one directory - Level 1 Case            #
######################################################################

	004)	FOUNDIT=No

		##################################################
		# Define Directory Root                          #
		##################################################
		SOURCEID=`echo $MSGID | awk -F. '{ print $1 }'`
		case $SOURCEID in
			004)	ROOTDIR1=/app/gateways/wfeigw
				PREFIX1=~wfe_chk.*
				MSGPREFIX1=~wfe_chk
				ROOTDIR2=/app/gateways/wfwigw
				PREFIX2=~wfw_chk.*
				MSGPREFIX2=~wfw_chk;;
		esac
		##################################################

		# Check Files in Process - Take 1
		egrep -i x-wfb_message_id $ROOTDIR1/$PREFIX1 2>/dev/null | awk {'print $2'} | egrep $MSGID
		EXITCODE=$?
		if [ $EXITCODE -eq 0 ]; then
			echo "$MSGID found in a $ROOTDIR1/$MSGPREFIX1 file" >> $OUTPUTFILE
			FOUNDIT=Yes
		fi

		# Check Files in Process - Take 2
		if [ $FOUNDIT = "No" ]; then
			egrep -i x-wfb_message_id $ROOTDIR2/$PREFIX2 2>/dev/null | awk {'print $2'} | egrep $MSGID
			EXITCODE=$?
			if [ $EXITCODE -eq 0 ]; then
				echo "$MSGID found in a $ROOTDIR2/$MSGPREFIX2 file" >> $OUTPUTFILE
				FOUNDIT=Yes
			fi
		fi

		# Check Dup Files - Take 1
		if [ $FOUNDIT = "No" ]; then
			egrep -i x-wfb_message_id $ROOTDIR1/transit/dup.* 2>/dev/null | awk {'print $2'} | egrep $MSGID
			EXITCODE=$?
			if [ $EXITCODE -eq 0 ]; then
				echo "$MSGID found in a $ROOTDIR1/transit/dup file" >> $OUTPUTFILE
				FOUNDIT=Yes
			fi
		fi

		# Check Dup Files - Take 2
		if [ $FOUNDIT = "No" ]; then
			egrep -i x-wfb_message_id $ROOTDIR2/transit/dup.* 2>/dev/null | awk {'print $2'} | egrep $MSGID 2>/dev/null
			EXITCODE=$?
			if [ $EXITCODE -eq 0 ]; then
				echo "$MSGID found in a $ROOTDIR2/transit/dup file" >> $OUTPUTFILE
				FOUNDIT=Yes
			fi
		fi

		# Check Spam Files - Take 1
		if [ $FOUNDIT = "No" ]; then
			egrep -i x-wfb_message_id $ROOTDIR1/transit/spam.* 2>/dev/null | awk {'print $2'} | egrep $MSGID 2>/dev/null
			EXITCODE=$?
			if [ $EXITCODE -eq 0 ]; then
				echo "$MSGID found in a $ROOTDIR1/transit/spam file" >> $OUTPUTFILE
				FOUNDIT=Yes
			fi
		fi

		# Check Spam Files - Take 2
		if [ $FOUNDIT = "No" ]; then
			egrep -i x-wfb_message_id $ROOTDIR2/transit/spam.* 2>/dev/null | awk {'print $2'} | egrep $MSGID 2>/dev/null
			EXITCODE=$?
			if [ $EXITCODE -eq 0 ]; then
				echo "$MSGID found in a $ROOTDIR2/transit/spam file" >> $OUTPUTFILE
				FOUNDIT=Yes
			fi
		fi

		# Check Archive Files - Take 1
		if [ $FOUNDIT = "No" ]; then
			FINDRESULTS=`find $ROOTDIR1/Archive -mtime -$DAYS -type f -name \*.tar.Z -print 2>/dev/null`

			if [ ! -z $FINDRESULTS ]; then
				zcat `find $ROOTDIR1/Archive -mtime -$DAYS -type f -name \*.tar.Z -print 2>/dev/null` | egrep -i "$MSGID"
				EXITCODE=$?
				if [ $EXITCODE -eq 0 ]; then
					echo "$MSGID found in a $ROOTDIR1/Archive file" >> $OUTPUTFILE
					FOUNDIT=Yes
				fi
			fi
		fi

		# Check Archive Files - Take 2
		if [ $FOUNDIT = "No" ]; then
			FINDRESULTS=`find $ROOTDIR2/Archive -mtime -$DAYS -type f -name \*.tar.Z -print 2>/dev/null`

			if [ ! -z $FINDRESULTS ]; then
				zcat `find $ROOTDIR2/Archive -mtime -$DAYS -type f -name \*.tar.Z -print 2>/dev/null` | egrep -i "$MSGID"
				EXITCODE=$?
				if [ $EXITCODE -eq 0 ]; then
					echo "$MSGID found in a $ROOTDIR2/Archive file" >> $OUTPUTFILE
					FOUNDIT=Yes
				fi
			fi
		fi

		# Write Not Found Error Flag if Message ID still has not been found
		if [ $FOUNDIT = No ]; then
			echo "$MSGID $NOTFOUNDMSG"  >> $OUTPUTFILE
		fi;;


######################################################################
# Almost Everything Else - Level 1 Case                              #
######################################################################

	001|025|101|103|106|114|117|118|119|120|121|124|127|128|129|132|133|134|137|139|146|149|154|155|158|159|160|161|162|165|166|167|168|171)	FOUNDIT=No

		##################################################
		# Define Directory Root                          #
		##################################################
		SOURCEID=`echo $MSGID | awk -F. '{ print $1 }'`
		case $SOURCEID in
			001)			ROOTDIR=/app/gateways/cfgw
						PREFIX=*~cf_chk.*
						MSGPREFIX=~cf_chk;;

			025)			ROOTDIR=/app/gateways/aolffgw
						PREFIX=*~aol_chk.*
						MSGPREFIX=~aol_chk;;

			101)			ROOTDIR=/app/relays/ilend
						PREFIX=*~il_chk.*
						MSGPREFIX=~il_chk;;

			103)			ROOTDIR=/app/gateways/bizigw
						PREFIX=*~biz_chk.*
						MSGPREFIX=~biz_chk;;

			106)			ROOTDIR=/app/relays/ix
						PREFIX=*~ix_chk.*
						MSGPREFIX=~ix_chk;;

			114)			ROOTDIR=/app/gateways/ccsvcigw
						PREFIX=*~cc_*
						MSGPREFIX=~cc_;;

			117|118|119|120|160)	ROOTDIR=/app/relays/whsl
						PREFIX=*~whsl_chk.*
						MSGPREFIX=~whsl_chk;;

			121)			ROOTDIR=/app/gateways/whsligw
						PREFIX=*~whsl_chk.*
						MSGPREFIX=~whsl_chk;;

			124)			ROOTDIR=/app/gateways/efsigw
						PREFIX=*~efs_chk.*
						MSGPREFIX=~efs_chk;;

			127|128)		ROOTDIR=/app/relays/iis
						PREFIX=*~iis_chk.*
						MSGPREFIX=~iis_chk;;

			129)			ROOTDIR=/app/gateways/iisigw
						PREFIX=*~iis_chk.*
						MSGPREFIX=~iis_chk;;

			132)			ROOTDIR=/app/gateways/epigw
						PREFIX=*~ep_chk.*
						MSGPREFIX=~ep_chk;;

			133)			ROOTDIR=/app/relays/b3
						PREFIX=*~b3_chk.*
						MSGPREFIX=~b3_chk;;

			134)			ROOTDIR=/app/gateways/b3igw
						PREFIX=*~b3_chk.*
						MSGPREFIX=~b3_chk;;

			137)			ROOTDIR=/app/relays/wim
						PREFIX=*~wim_chk.*
						MSGPREFIX=~wim_chk;;

			139)			ROOTDIR=/app/gateways/bobigw
						PREFIX=*~bob_chk.*
						MSGPREFIX=~bob_chk;;

			146)			ROOTDIR=/app/gateways/bigw
						PREFIX=*~b_chk.*
						MSGPREFIX=~b_chk;;

			# Note:  heqigw channel prefixes not verified because
			#        there were no files or Archives to verify with.
			#        Prefix info for this channel was provided by
			#        the Daily Monitor Tasks Techspec.  (Ver 1.6)

			149)			ROOTDIR=/app/gateways/heqigw
						PREFIX=*~heq_chk.*
						MSGPREFIX=~heq_chk;;

			154)			ROOTDIR=/app/relays/intl
						PREFIX=*~intl_chk.*
						MSGPREFIX=~intl_chk;;

			155)			ROOTDIR=/app/gateways/intligw
						PREFIX=*~intl_chk.*
						MSGPREFIX=~intl_chk;;

			158)			ROOTDIR=/app/gateways/cfgenret
						PREFIX=*~cfg_chk.*
						MSGPREFIX=~cfg_chk;;

			# Note:  oneligw (159) channel prefixes not verified
			#        because there were no files or Archives to
			#        verify with.  Prefix info for this channel was
			#        provided by the Daily Monitor Tasks Techspec.
			#        (Ver 1.8)

			159)			ROOTDIR=/app/gateways/oneligw
						PREFIX=*~onel_chk.*
						MSGPREFIX=~onel_chk;;


			# Note:  bam channel (161) prefixes and directory not
			#        verified because there were no directory, files
			#        or Archives to verify with.  Prefix info for
			#        this channel was provided by the Daily Monitor
			#        Tasks Techspec.  (Ver 1.8)

			161)			ROOTDIR=/app/relays/bam
						PREFIX=*~bam_chk.*
						MSGPREFIX=~bam_chk;;

			# Note:  bamigw channel (162) prefixes and directory not
			#        verified because there were no directory, files
			#        or Archives to verify with.  Prefix info for
			#        this channel was provided by the Daily Monitor
			#        Tasks Techspec.  (Ver 1.8)

			162)			ROOTDIR=/app/gateways/bamigw
						PREFIX=*~bam_chk.*
						MSGPREFIX=~bam_chk;;

			165)			ROOTDIR=/app/relays/onelook
						PREFIX=*~ol_chk.*
						MSGPREFIX=~ol_chk;;

			166|167)		ROOTDIR=/app/relays/mort
						PREFIX=*~mort_chk.*
						MSGPREFIX=~mort_chk;;

			168)			ROOTDIR=/app/gateways/mortigw
						PREFIX=*~mort_chk.*
						MSGPREFIX=~mort_chk;;

			171)			ROOTDIR=/app/gateways/chbkigw
						PREFIX=*~chbk_chk.*
						MSGPREFIX=~chbk_chk;;

			178)			ROOTDIR=/app/gateways/rcigw
						PREFIX=*~rc_chk.*
						MSGPREFIX=~rc_chk;;

			179)			ROOTDIR=/app/relays/rc
						PREFIX=*~rc_chk.*
						MSGPREFIX=~rc_chk;;

			*)			ROOTDIR=/app/gateways/imrr
						PREFIX=*~wf_chk.*
						MSGPREFIX=~wf_chk;;
		esac
		##################################################

		# Check prefix specific files in process
		egrep -i x-wfb_message_id $ROOTDIR/$PREFIX 2>/dev/null | awk {'print $2'} | egrep $MSGID
		EXITCODE=$?
		if [ $EXITCODE -eq 0 ]; then
			echo "$MSGID found in a $ROOTDIR/$MSGPREFIX file" >> $OUTPUTFILE
			FOUNDIT=Yes
		fi

		# Check Dup Files
		if [ $FOUNDIT = "No" ]; then
			egrep -i x-wfb_message_id $ROOTDIR/transit/dup.* 2>/dev/null | awk {'print $2'} | egrep $MSGID
			EXITCODE=$?
			if [ $EXITCODE -eq 0 ]; then
				echo "$MSGID found in a $ROOTDIR/transit/dup file" >> $OUTPUTFILE
				FOUNDIT=Yes
			fi
		fi

		# Check Dup files in Sorted Dup Directories
		if [ $FOUNDIT = "No" ]; then
			FINDRESULTS=`find $ROOTDIR -mtime -$DAYS \( -type d -o -type l \) -name dup\* -print 2>/dev/null`

			if [ ! -z $FINDRESULTS ]; then
					for DUPDIR in `find $ROOTDIR -mtime -$DAYS \( -type d -o -type l \) -name dup\* -print 2>/dev/null`
					do
						egrep -i x-wfb_message_id $DUPDIR/dup.* 2>/dev/null | awk {'print $2'} | egrep $MSGID
						EXITCODE=$?
						if [ $EXITCODE -eq 0 ]; then
							echo "$MSGID found in a $DUPDIR/dup file" >> $OUTPUTFILE
							FOUNDIT=Yes
						fi
					done
				fi
		fi

		# Check Spam Files		
		if [ $FOUNDIT = "No" ]; then
			egrep -i x-wfb_message_id $ROOTDIR/transit/spam.* 2>/dev/null | awk {'print $2'} | egrep $MSGID
			EXITCODE=$?
			if [ $EXITCODE -eq 0 ]; then
				echo "$MSGID found in a $ROOTDIR/transit/spam file" >> $OUTPUTFILE
				FOUNDIT=Yes
			fi
		fi

		# Check Spam files in Sorted Spam Directories
		if [ $FOUNDIT = "No" ]; then
			FINDRESULTS=`find $ROOTDIR -mtime -$DAYS \( -type d -o -type l \) -name spam\* -print 2>/dev/null`

			if [ ! -z $FINDRESULTS ]; then
					for SPAMDIR in `find $ROOTDIR -mtime -$DAYS \( -type d -o -type l \) -name spam\* -print 2>/dev/null`
					do
						egrep -i x-wfb_message_id $SPAMDIR/spam.* 2>/dev/null | awk {'print $2'} | egrep $MSGID
						EXITCODE=$?
						if [ $EXITCODE -eq 0 ]; then
							echo "$MSGID found in a $SPAMDIR/spam file" >> $OUTPUTFILE
							FOUNDIT=Yes
						fi
					done
				fi
		fi

		# Check Archive files
		if [ $FOUNDIT = "No" ]; then
			FINDRESULTS=`find $ROOTDIR/Archive -mtime -$DAYS -type f -name \*.tar.Z -print 2>/dev/null`

			if [ ! -z $FINDRESULTS ]; then
				zcat `find $ROOTDIR/Archive -mtime -$DAYS -type f -name \*.tar.Z -print 2>/dev/null` | egrep -i "$MSGID"
				EXITCODE=$?
					if [ $EXITCODE -eq 0 ]; then
						echo "$MSGID found in a $ROOTDIR/Archive file" >> $OUTPUTFILE
						FOUNDIT=Yes
					fi
			fi
		fi

		# Write Not Found Error Flag if Message ID still has not been found
		if [ $FOUNDIT = No ]; then
			echo "$MSGID $NOTFOUNDMSG"  >> $OUTPUTFILE
		fi;;

######################################################################
# Everything Else - Level 1 Case                                     #
######################################################################

	*)	FOUNDIT=No

		##################################################
		# Define Directory Root                          #
		##################################################
		SOURCEID=`echo $MSGID | awk -F. '{ print $1 }'`
		case $SOURCEID in
			*)			ROOTDIR=/app/gateways/imrr;;
		esac
		##################################################

		# Check Files in process
		egrep -i x-wfb_message_id $ROOTDIR/~wf_chk.* 2>/dev/null | awk {'print $2'} | egrep $MSGID
		EXITCODE=$?
		if [ $EXITCODE -eq 0 ]; then
			echo "$MSGID found in a $ROOTDIR/~wf_chk file" >> $OUTPUTFILE
			FOUNDIT=Yes
		fi

		# Check Dup Files
		if [ $FOUNDIT = "No" ]; then
			egrep -i x-wfb_message_id $ROOTDIR/transit/dup.* 2>/dev/null | awk {'print $2'} | egrep $MSGID
			EXITCODE=$?
			if [ $EXITCODE -eq 0 ]; then
				echo "$MSGID found in a $ROOTDIR/transit/dup file" >> $OUTPUTFILE
				FOUNDIT=Yes
			fi
		fi

		# Check Spam Files
		if [ $FOUNDIT = "No" ]; then
			egrep -i x-wfb_message_id $ROOTDIR/transit/spam.* 2>/dev/null | awk {'print $2'} | egrep $MSGID
			EXITCODE=$?
			if [ $EXITCODE -eq 0 ]; then
				echo "$MSGID found in a $ROOTDIR/transit/spam file" >> $OUTPUTFILE
				FOUNDIT=Yes
			fi
		fi

		# Check Investigate Files
		if [ $FOUNDIT = "No" ]; then
			egrep -i x-wfb_message_id $ROOTDIR/Investigate/~wf_chk.* 2>/dev/null | awk {'print $2'} | egrep $MSGID
			EXITCODE=$?
			if [ $EXITCODE -eq 0 ]; then
				echo "$MSGID found in a $ROOTDIR/Investigate file" >> $OUTPUTFILE
				FOUNDIT=Yes
			fi
		fi

		# Check Dup Files in Sorted Dup Directories
		if [ $FOUNDIT = "No" ]; then
			FINDRESULTS=`find $ROOTDIR -mtime -$DAYS \( -type d -o -type l \) -name dup\* -print 2>/dev/null`

			if [ ! -z $FINDRESULTS ]; then
					for DUPDIR in `find $ROOTDIR -mtime -$DAYS \( -type d -o -type l \) -name dup\* -print 2>/dev/null`
					do
						egrep -i x-wfb_message_id $DUPDIR/dup.* 2>/dev/null | awk {'print $2'} | egrep $MSGID
						EXITCODE=$?
						if [ $EXITCODE -eq 0 ]; then
							echo "$MSGID found in a $DUPDIR/dup file" >> $OUTPUTFILE
							FOUNDIT=Yes
						fi
					done
				fi
		fi

		# Check Spam Files in Sorted Spam Directories
		if [ $FOUNDIT = "No" ]; then
			FINDRESULTS=`find $ROOTDIR -mtime -$DAYS \( -type d -o -type l \) -name spam\* -print 2>/dev/null`

			if [ ! -z $FINDRESULTS ]; then
					for SPAMDIR in `find $ROOTDIR -mtime -$DAYS \( -type d -o -type l \) -name spam\* -print 2>/dev/null`
					do
						egrep -i x-wfb_message_id $SPAMDIR/spam.* 2>/dev/null | awk {'print $2'} | egrep $MSGID
						EXITCODE=$?
						if [ $EXITCODE -eq 0 ]; then
							echo "$MSGID found in a $SPAMDIR/spam file" >> $OUTPUTFILE
							FOUNDIT=Yes
						fi
					done
				fi
		fi

		# Check Investigate Files in Sorted Investigate Directories
		if [ $FOUNDIT = "No" ]; then
			FINDRESULTS=`find $ROOTDIR -mtime -$DAYS \( -type d -o -type l \) -name inv\* -print 2>/dev/null`

			if [ ! -z $FINDRESULTS ]; then
					for INVDIR in `find $ROOTDIR -mtime -$DAYS \( -type d -o -type l \) -name inv\* -print 2>/dev/null`
					do
						egrep -i x-wfb_message_id $INVDIR/~wf_chk.* 2>/dev/null | awk {'print $2'} | egrep $MSGID
						EXITCODE=$?
						if [ $EXITCODE -eq 0 ]; then
							echo "$MSGID found in a $INVDIR/Investigate file" >> $OUTPUTFILE
							FOUNDIT=Yes
						fi
					done
				fi
		fi

		# Check Archive Files
		if [ $FOUNDIT = "No" ]; then
			FINDRESULTS=`find $ROOTDIR/Archive -mtime -$DAYS -type f -name \*.tar.Z -print 2>/dev/null`

			if [ ! -z $FINDRESULTS ]; then
				zcat `find $ROOTDIR/Archive -mtime -$DAYS -type f -name \*.tar.Z -print 2>/dev/null` | egrep -i "$MSGID"
				EXITCODE=$?
					if [ $EXITCODE -eq 0 ]; then
						echo "$MSGID found in a $ROOTDIR/Archive file" >> $OUTPUTFILE
						FOUNDIT=Yes
					fi
			fi
		fi

		# Write Not Found Error Flag if Message ID still has not been found
		if [ $FOUNDIT = No ]; then
			echo "$MSGID $NOTFOUNDMSG"  >> $OUTPUTFILE
		fi;;

	esac

done

FINISHDATETIME=`date`

######################################################################
# Format report & do final processing to make acting on it easier.   #
######################################################################

echo "checkaudit.ksh script started at:" > $CHECKAUDITHEADER
echo $STARTDATETIME >> $CHECKAUDITHEADER
echo "checkaudit.ksh script finished processing at:" >> $CHECKAUDITHEADER
echo $FINISHDATETIME >> $CHECKAUDITHEADER
echo "BigBank Repartee Mail Audit Report Crosscheck Report Follows..." >> $CHECKAUDITHEADER
echo "Channels checked defined by Repartee Daily Monitor Tasks Techspec v1.9"  >> $CHECKAUDITHEADER
echo "        - checkaudit.ksh script (v6.6) written by Michael Ng -" >> $CHECKAUDITHEADER
echo "**********************************************************************" >> $CHECKAUDITHEADER
echo "" >> $CHECKAUDITHEADER

egrep not $OUTPUTFILE | awk '{print $1}' >> $OUTPUTFILE".Parsed"

echo "" >> $OUTPUTFILE
echo "" >> $OUTPUTFILE
echo "Message IDs in format to be pasted into SQL Client for quick checking." >> $OUTPUTFILE
echo "(After Filesystem is double checked for spam and dup subdirectories.)" >> $OUTPUTFILE
echo "**********************************************************************" >> $OUTPUTFILE
echo "" >> $OUTPUTFILE

for MSGID in `cat $OUTPUTFILE".Parsed"`
do
	SOURCEID=`echo $MSGID | awk -F. '{ print $1 }'`

	case $SOURCEID in

		001|004|025|103|114|121|124|129|132|134|139|146|149|155|158|159|162|168|171)	echo $MSGID" has been skipped because it can not be resent."  >> $OUTPUTFILE2;;

		*)	echo "select action_code from t_auditevent where chanmsgid='"$MSGID"';" >> $OUTPUTFILE2
			echo $MSGID >> $OUTPUTFILE".Parsed2";;

	esac
done

cat $OUTPUTFILE2 >> $OUTPUTFILE

echo "" >> $OUTPUTFILE
echo "" >> $OUTPUTFILE
echo "Message IDs in format to be sent in re-send E-Mail." >> $OUTPUTFILE
echo "**********************************************************************" >> $OUTPUTFILE
echo "" >> $OUTPUTFILE


for MSGID in `cat $OUTPUTFILE".Parsed2"`
do
	egrep $MSGID $NOHEADERDATA >> $OUTPUTFILE
done

######################################################################
# Sends copy of crosscheck results to specified $EMAIL Addresses.    #
######################################################################

cat  $CHECKAUDITHEADER $OUTPUTFILE | mailx -s "$REPORTDATE Audit Crosscheck Results - Generated $FULLCURRENTDATE" $EMAIL

######################################################################
# Cleans up and Archives Temp Files.                                 #
######################################################################
rm $ORIGFILE
rm $PARSEDREPORT
rm $NOHEADERDATA
rm $OUTPUTFILE".Parsed"
rm $OUTPUTFILE2
rm $OUTPUTFILE".Parsed2"

mv $CSPLITRESULTS $ARCHIVEDIR
mv $CHECKAUDITHEADER $ARCHIVEDIR
mv $OUTPUTFILE $ARCHIVEDIR


