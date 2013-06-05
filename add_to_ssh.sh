#!/bin/bash

# set the input
IFS=$' '

localadmins=$(/usr/bin/dscl localhost -read /Local/Default/Groups/admin GroupMembership | awk -F': ' '{print $2}')

for account in `echo $localadmins`; do
    # add additional blocks like >> && ! [[ "$account" =~ "username" ]] << for any additional exclusions
    if ! [ "$account" == "root" ] && ! [ "$account" == "itstech" ]; then
        userID=$(/usr/bin/dscl localhost -read /Local/Default/Users/$account | grep GeneratedUID | awk '{print $2}')
        if [ "$userID" != "" ]; then
            echo "found $account with GUID $userID"
            # UNCOMMENT FOLLOWING TWO LINES TO MAKE THE SCRIPT MODIFY THE access_ssh GROUP
            #/usr/bin/dscl localhost -append /Local/Default/Groups/com.apple.access_ssh GroupMembership "$admin"
            #/usr/bin/dscl localhost -append /Local/Default/Groups/com.apple.access_ssh GroupMembers "$userID"
        else
            echo "$account has no local GUID"
        fi
    fi
done