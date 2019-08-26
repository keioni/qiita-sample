#!/bin/sh

export USER=`echo -n $DOCUMENT_ROOT | awk -F/ '{print $3}'`
export HOME=/home/$USER
export QUERY_STRING=`echo $QUERY_STRING | awk '/^[[:alnum:]\._-]+$/ {print}'`

IFS=$'\n'
for line in `cat .htaccess`
do
    directive=`echo -n $line | awk '{print $1}'`
    if [ "$directive" = "SetEnv" ]; then
        export `echo -n $line | awk '{print $2"="$3}'`
    fi
done

echo "Content-Type: text/plain"
echo ""

exec ./$QUERY_STRING
