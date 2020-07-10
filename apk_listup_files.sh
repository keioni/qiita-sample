#!/bin/sh

apk info | sort | xargs apk info -L |
while read -r l; do
  if [ `echo -n $l | grep -c contains:` -eq 1 ]; then
    p=`echo -n $l | sed -E 's/^(.*)\-[^-]+\-r[0-9]+ contains:.*$/\1/'`;
  elif [ "$l" != "" ]; then
    echo "$p /$l";
  fi;
done
