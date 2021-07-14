##### vi /etc/profile.d/cmd_list.sh #####
function logging
{

SKIP="N"
SEVERIP="10.4.249.202:8080"
UPATH="/S2S/pages"
URL="${SEVERIP}${UPATH}"
cmd=$(history|tail -1|sed 's/^[ ]*[0-9]\+[ ]*//' | sed 's|&|#Y#|g')
t_date=$(date)

if [ -n "$cmd" ] ; then

        if [ -z "$cmd_old" ] ; then
                if [ "$t_date" = "$t_date_old" ] ; then
                        SKIP="Y"
                fi
        fi

        IP=`who am i|awk -F'(' '{print $2}' |sed 's/[()]//g'`
        if [ ! -z "$IP" ] ; then
                VAL=${IP//[0-9.]}
                if [ ! -z "$VAL" ] ; then
                        if [ "$VAL" = ":" ] ; then
                                IP="Console"
                        else
                                IP=$(getent hosts $IP | awk '{print $1}')
                        fi
                fi
        else
                IP="Console"
        fi

        if [ "$cmd" = "$cmd_old" ] ; then
                SKIP="Y"
        fi

        CONN=$(curl -s --connect-timeout 1 http://$URL/StaTus.html)
        if [ $? -eq 0 -a "$SKIP" != "Y" ] ; then
                logger -p local6.debug -t CMD "`hostname` $USER $IP $$ $PWD C=$cmd"
                RESULT=$(curl -s -d "host=`hostname`&user=$USER&ip=$IP&pid=$$&pwd=$PWD&command=$cmd" http://$URL/get_command.php)
                F_CHAR=$(echo $RESULT | awk -F'-' '{print $1}')
                S_CHAR=$(echo $RESULT | awk -F'-' '{print $2}')
                if [ "$F_CHAR" = "BLK" ]; then
                        if [ "$S_CHAR" = "TIME" ]; then
                                MSG5="by Abnormal Time"
                        elif [ "$S_CHAR" = "IP" ]; then
                                MSG5="by Abnormal IP"
                        else 
                                MSG5="by Abnormal Command"
                        fi
                        echo
                        echo "# Sorry, You Can't execute your command $MSG5: $cmd"
                        echo "# Log Out by Force ......."
                        echo
                        exit
                elif [ "$F_CHAR" = "CRIT" ]; then
                        echo
                        echo "# approving Your Command : $cmd"
                        echo "# Waiting ........"
                        echo
                        echo
                        RESULT2=$(curl -s -d "utime=$S_CHAR" http://$URL/approve_command.php)
                        if [ "$RESULT2" = "SUCC " ]; then
                                echo
                                echo "# Executing Your Critical Command : $cmd"
                                echo "# OK"
                                echo
                        elif [ "$RESULT2" = "REJ " ]; then
                                # Critical Command STOP.....
                                echo "# Rejected Your Critical Command : $cmd"
                                echo '# Killed your Command !!'
                                echo
                                echo
                                kill -SIGKILL $$
                        else
                                while true ; do
                                        echo "# Canceled Your Critical Command : $cmd"
                                        echo "# Press Crtl+C to CANCEL your Command "
                                        echo
                                        echo
                                        sleep 5
                                done
                        fi
                fi

        fi
fi

cmd_old=$cmd
t_date_old=$t_date

}
trap logging DEBUG
