#!/bin/sh -e
#
# Note from CONTRIBUTING.md: If you make a change that involve the locale
# files (in config/locales) then please only submit changes to the en.yml
# file. The other files are updated via Translatewiki and should not be
# included in your pull request.
#
cd `dirname $0`

# Look at just a specific commit range, expressed as "SHA1...SHA2"
COMMIT_RANGE=$1

# Assume everything will be fine
STATUS=0

for FILE in *.yml; do
  # Don't check authorship of en.yml
  if [ $FILE != en.yml ]; then
    HUMAN_AUTHOR=`git log --format='%ae' $COMMIT_RANGE -- $FILE | grep -v @translatewiki.net | head -n1`
    if [ $HUMAN_AUTHOR ]; then
      # Mark for failure if changes were made by anyone other than translatewiki.net
      echo "Unexpectedly found ${HUMAN_AUTHOR} in ${FILE} (see CONTRIBUTING.md, i18n)"
      STATUS=1
    fi
  fi
done

exit $STATUS
