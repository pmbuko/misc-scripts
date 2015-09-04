#!/bin/bash

# This section uses python to get the current console user. You can
# usually just use the built-in $USER variable, but this is more
# robust.
USER=$(/usr/bin/python -c \
      'from SystemConfiguration import SCDynamicStoreCopyConsoleUser;\
       print SCDynamicStoreCopyConsoleUser(None, None, None)[0]')

# This looks up the password expiration date from AD. It's stored
# in a numerical format that we have to convert.
xWin=$(/usr/bin/dscl localhost read /Search/Users/$USER \
       msDS-UserPasswordExpiryTimeComputed 2>/dev/null |\
       /usr/bin/awk '/dsAttrTypeNative/{print $NF}')

# This converts the MS date to a Unix date.
xUnix=$(echo "($xWin/10000000)-11644473600" | /usr/bin/bc)

# This gives us a human-readable expiration date.
xDate=$(/bin/date -r $xUnix)

# This gives us a Unix date value for right now.
today=$(/bin/date +%s)

# This uses some simple math to get the number of days between
# today and the date the password expires.
xDays=$(echo "($xUnix - $today)/60/60/24" | /usr/bin/bc)

# Show the results
echo "Username:        $USER"
echo "Expiration date: $xDate"
echo "Number of days:  $xDays"
