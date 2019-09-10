#!/bin/sh
#

test "$DEBUG" = "yes" && set -x
chmod +x /usr/bin/minio

SILENT=" --silent"
test "$VERBOSE" = "yes" && SILENT=""

INTERVAL=${INTERVAL:-30}
DEFPARAMSTRING="--max-sync-retries 20 --trust"

if test ! "${CONFDIR}"; then
    CONFDIR=/conf
    SERVER=`echo $URL|sed "s/\// /g"|awk '{ print $2 }'`
    mkdir -p "${CONFDIR}"
    echo "# generated" > "${CONFDIR}/00.conf"
    echo "SERVER=\"${SERVER}\"" >> "${CONFDIR}/00.conf"
    echo "WORK_UID=\"${WORK_UID:-82}\"" >> "${CONFDIR}/00.conf"
    echo "WORK_GID=\"${WORK_GID:-82}\"" >> "${CONFDIR}/00.conf"
    echo "WORK_USER=\"${WORK_USER:-clouddata}\"" >> "${CONFDIR}/00.conf"
    echo "WORK_GROUP=\"${WORK_GROUP:-clouddata}\"" >> "${CONFDIR}/00.conf"
    echo "USER=\"${USER}\"" >> "${CONFDIR}/00.conf"
    echo "PASSWORD=\"${PASSWORD}\"" >> "${CONFDIR}/00.conf"
    echo "LOCALDIR=\"${LOCALDIR:-/data}\"" >> "${CONFDIR}/00.conf"
    echo "URL=\"${URL}\"" >> "${CONFDIR}/00.conf"
    echo "PARAMSTRING=\"${PARAMSTRING:-$DEFPARAMSTRING}\"" >> "${CONFDIR}/00.conf"
fi

LOGDIR=${LOGDIR:-$CONFDIR}
mkdir -p ${LOGDIR}

# init
rm -f ${LOGDIG}/*.gconf

for xconf in ${CONFDIR}/*.conf; do
    WORK_USER=
    WORK_GROUP=
    URL=
    SERVER=
    LOCALDIR=
    . $xconf

    test "$URL" || continue
    test "$LOCALDIR" || continue

    CONF=$( basename $xconf )
    CONF=${CONF%.conf}

    cconf="${LOGDIR}/$CONF.gconf"

    cp -f $xconf $cconf
    echo "" >> $cconf
    echo "# generated next" >> $cconf

    WORK_USER=${WORK_USER:-cloud$CONF}
    WORK_GROUP=${WORK_GROUP:-cloudg$CONF}
    LOCALDIR=${LOCALDIR:-/data}

    if test -z "$SERVER"; then
        SERVER=`echo $URL|sed "s/\// /g"|awk '{ print $2 }'`
        echo "SERVER=\"${SERVER}\"" >> $cconf
    fi

    # check if UID already used
    TEST_USER=$(awk -F: -v u=$WORK_UID '$3==u {print $1}' /etc/passwd)

    if test "$TEST_USER" ; then
        WORK_USER=$TEST_USER
        WORK_GID=$(id -g $WORK_USER)
        echo "WORK_USER=\"${WORK_USER:-clouddata}\"" >> $cconf
        echo "WORK_GID=\"${WORK_GID:-82}\"" >> $cconf
    else
        addgroup -S -g $WORK_GID $WORK_GROUP || WORK_GROUP=$(awk -F: -v g=$WORK_GID '$3==g {print $1}' /etc/group)
        adduser -u $WORK_UID -D -s /bin/sh -S -G $WORK_GROUP $WORK_USER
        # recheck user
        WORK_USER=$(awk -F: -v u=$WORK_UID '$3==u {print $1}' /etc/passwd)
        WORK_GID=$(id -g $WORK_USER)
        WORK_GROUP=$(id -gn $WORK_USER)
        echo "WORK_GID=\"${WORK_GID:-82}\"" >> $cconf
        echo "WORK_USER=\"${WORK_USER}\"" >> $cconf
        echo "WORK_GROUP=\"${WORK_GROUP}\"" >> $cconf
    fi

    USER_HOME=$(awk -F: -v u=$WORK_UID '$3==u {print $6}' /etc/passwd)
    echo "USER_HOME=\"${USER_HOME}\"" >> $cconf

    mkdir -p $USER_HOME
    chown $WORK_USER $USER_HOME

    if [ "$USER" -a  "$PASSWORD" ] ; then
        echo "machine $SERVER" > $USER_HOME/.netrc
        echo "	login $USER" >> $USER_HOME/.netrc
        echo "	password $PASSWORD" >> $USER_HOME/.netrc
    fi

    mkdir -p $USER_HOME/.local

    mkdir -p $LOCALDIR
    test -f $LOCALDIR/exclude.lst || touch $LOCALDIR/exclude.lst

    chown $WORK_UID.$WORK_GID $USER_HOME/.netrc
    chown -R $WORK_UID.$WORK_GID $USER_HOME/.local
    chown -R $WORK_UID.$WORK_GID $LOCALDIR
    chmod -R u+rw $LOCALDIR
done
STOP=""
# main loop
while test -z "${STOP}"
do
    for cconf in ${LOGDIR}/*.gconf; do
        . $cconf
        # Start sync
        CONF=$( basename $cconf )
        CONF=${CONF%.conf}
        if [ "$USER" -a  "$PASSWORD" ] ; then
            echo "machine $SERVER" > $USER_HOME/.netrc
            echo "	login $USER" >> $USER_HOME/.netrc
            echo "	password $PASSWORD" >> $USER_HOME/.netrc
        fi
        PARAMSTRING="${PARAMSTRING:-$DEFPARAMSTRING}"
        H=""
        test "${HIDDEN}" = "yes" && H="-h"
        test -f  ${LOGDIR}/${CONF}_sync.log || touch ${LOGDIR}/${CONF}_sync.log
        chown $WORK_USER ${LOGDIR}/${CONF}_sync.log
        su $WORK_USER -c "/usr/bin/nextcloudcmd --non-interactive --exclude $LOCALDIR/exclude.lst $PARAMS $SILENT -n $H $LOCALDIR $URL &> ${LOGDIR}/${CONF}_sync.log"
        # ToDo: search for special tools for fixing permissons
        test "$POST_SCRIPT" && test -f $LOCALDIR/$POST_SCRIPT && su $WORK_USER -c "/bin/sh $LOCALDIR/$POST_SCRIPT 2>&1 >> ${LOGDIR}/${CONF}_sync.log"
        test -z "${RUNONCE}" && sleep $INTERVAL || STOP=1
    done
done
