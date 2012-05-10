#!/bin/bash
# Replace with your nickname:remote-key
# Go to http://friendfeed.com/account/api to get your remote key
USER="myuser:mypassword"

function usage {
    echo "Usage: $0 [-t title] [-l link] [-u nickname:remotekey] [images ...]"
    exit 1
}

MAXSIZE=""
while getopts m:u:t:l: opt ; do
    case "$opt" in
        t)  TITLE="$OPTARG";;
        l)  LINK="$OPTARG";;
        u)  USER="$OPTARG";;
        m)  MAXSIZE="$OPTARG";;
        \?) usage;;
    esac
done
shift $[OPTIND - 1]

TITLE="${TITLE:-$LINK}"
TITLE="${TITLE:-$1}"

[ "$TITLE" = "" ] && usage

ARGS=("-F" "title=$TITLE" "-F" "link=$LINK" "-u" "$USER")
FILES=("$@")

for F in "${FILES[@]}" ; do
    if [ "$MAXSIZE" != "" -a -x /usr/bin/sips ] ; then
        T=`mktemp /tmp/ffshare.XXXXXX`
        sips --resampleHeightWidthMax "$MAXSIZE" --out "$T" "$F" 2>/dev/null
        F="$T;filename=$F"
    fi
    N="${#ARGS[@]}"
    ARGS[N]="-F"
    ARGS[N+1]="img$RANDOM=@$F"
done

CODE=`curl -o /dev/null -w "%{http_code}" "${ARGS[@]}" http://friendfeed.com/api/share`
if [ "$CODE" == "200" ] ; then
    echo "Shared on http://friendfeed.com/`echo "$USER" | sed -e 's/:.*//'`"
else
    echo "Failed: HTTP response $CODE"
fi

