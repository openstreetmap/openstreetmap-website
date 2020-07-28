#!/bin/sh -e
cd `dirname $0`

COMMIT_RANGE=$1
STATUS=0

for FILE in *.yml; do
  if [ $FILE != en.yml ]; then
    # Fail if changes were made by anyone other than translatewiki.net
    HUMAN_AUTHOR=`git log --format='%ae' $COMMIT_RANGE -- $FILE | grep -v @translatewiki.net | head -n1`
    if [ $HUMAN_AUTHOR ]; then
      echo Found $HUMAN_AUTHOR in $FILE
      STATUS=1
    fi
  fi
done

exit $STATUS
