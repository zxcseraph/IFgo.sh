###########################################################################
#
#                       INFORMIX SOFTWARE, INC.
#
#                       PROPRIETARY DATA
#
#       THIS DOCUMENT CONTAINS TRADE SECRET DATA WHICH IS THE PROPERTY OF
#       INFORMIX SOFTWARE, INC.  THIS DOCUMENT IS SUBMITTED TO RECIPIENT IN
#       CONFIDENCE.  INFORMATION CONTAINED HEREIN MAY NOT BE USED, COPIED OR
#       DISCLOSED IN WHOLE OR IN PART EXCEPT AS PERMITTED BY WRITTEN AGREEMENT
#       SIGNED BY AN OFFICER OF INFORMIX SOFTWARE, INC.
#
#       THIS MATERIAL IS ALSO COPYRIGHTED AS AN UNPUBLISHED WORK UNDER
#       SECTIONS 104 AND 408 OF TITLE 17 OF THE UNITED STATES CODE.
#       UNAUTHORIZED USE, COPYING OR OTHER REPRODUCTION IS PROHIBITED BY LAW.
#
#  CCid:        %W%     %E%     %U%
#  Created:     June 1995
#  Description  Automates logical log backup using event alarms from the 
#               database server. To install this script, add the following 
#               line to the ONCONFIG file - 
#                       ALARMPROGRAM    <informixdir>/etc/log_full.sh
#               where <informixdir> is replaced by the full value of 
#               $INFORMIXDIR
#
##############################################################################/

##################################
#添加网管环境变量处

##################################
PROG=`basename $0`
USER_LIST=informix
BACKUP_CMD="onbar -l"
EXIT_STATUS=0

EVENT_SEVERITY=$1
EVENT_CLASS=$2
EVENT_MSG="$3"
EVENT_ADD_TEXT="$4"
EVENT_FILE="$5"

DEBUGFILE="$INFORMIXDIR/alarmAPI/alarmDB.log"
ALARMPATH="$INFORMIXDIR/alarmAPI"
ALARMCMD="sendalarm4shell"
######################    ENV    ###################
instance='bep1.scp.DB'
#####################################################

info="\"CLASS:$EVENT_CLASS MSG:$EVENT_MSG TEXT:$EVENT_ADD_TEXT FILE:$EVENT_FILE\""
case "$EVENT_CLASS" in
        23)
                # onbar assumes no operator is present,
                # so all messages are written to the activity
                # log and there shouldn't be any output, but
                # send everything to /dev/null just in case
                $BACKUP_CMD 2>&1 >> /dev/null
                EXIT_STATUS=$?
                exit 1;
                ;;

# One program is shared by all event alarms.  If this ever gets expanded to
# handle more than just archive events, uncomment the following:
        1)
                alarmcode='00003101001';;
        2)
                alarmcode='00003101002';;
        4|5|11|12)
                alarmcode='00003101003';;
        15)
                alarmcode='00003101005';;
        14)
                alarmcode='00003101006';;
        6)
                alarmcode='00003101007';;
        17)
                alarmcode='00003101008';;
        19)
                alarmcode='00003101009';;
        22)
                alarmcode='00003101010';;
        24)
                alarmcode='00003101011';;
        21)
                alarmcode='00003101013';;
        20)
                alarmcode='00003101014';;
        *)
                echo '' >>$DEBUGFILE
                echo `date` >>$DEBUGFILE
                echo "Warning:Not in alarmAPI" >>$DEBUGFILE
                echo "SEVERITY: $EVENT_SEVERITY " >>$DEBUGFILE
                echo "CLASS:    $EVENT_CLASS ">>$DEBUGFILE
                echo "MSG:      $EVENT_MSG">>$DEBUGFILE
                echo "TEXT:     $EVENT_ADD_TEXT">>$DEBUGFILE
                echo "FILE:     $EVENT_FILE">>$DEBUGFILE
                exit 1;;
esac
        EXIT_STATUS=1
        echo '' >>$DEBUGFILE
        echo `date` >>$DEBUGFILE
        echo "SEVERITY: $EVENT_SEVERITY " >>$DEBUGFILE
        echo "CLASS:    $EVENT_CLASS ">>$DEBUGFILE
        echo "MSG:      $EVENT_MSG">>$DEBUGFILE
        echo "TEXT:     $EVENT_ADD_TEXT">>$DEBUGFILE
        echo "FILE:     $EVENT_FILE">>$DEBUGFILE
        cd $ALARMPATH
        $ALARMCMD "$alarmcode" NULL $instance "$info"
exit $EXIT_STATUS
