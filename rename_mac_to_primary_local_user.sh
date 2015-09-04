#!/bin/bash

# This script will change the hostname of a Mac to a dot-separated version
# of the full name of the most-commonly-logged-in user with a local home.

# Give a list of usernames to ignore, separated by spaces
ignore_list=( root admin administrator bukowinskip )

# Get a list of usernames sorted by login frequency, limited to the last 100 logins
login_list=$(last -t console -100 | \
             awk '/console/{print $1}' | \
             sort | uniq -c | sort -r | awk '{print $2}')

# Simple function to check if user is in ignore list
ignore_match () {
  local i
  for i in "${ignore_list[@]}"; do [[ "$i" == "$1" ]] && return 0; done
  return 1
}

# This block will run through login_list and operate on only the first username in the list
# that happens to have a local home.
for u in $login_list; do
  # Proceed if user is not in ignore_list and has a local home
  if ! ignore_match "$u" && [ -d "/Users/${u}" ]; then
    # Get user's full name, substituting periods for spaces
    dotted_name=$(dscl -plist . read "/Users/$u" RealName | \
      awk 'BEGIN { OFS="." } /string/{gsub("<.?string>","");$1 = $1;print}')
    
    # Set the hostnames (comment echo lines and uncomment scutil lines after testing)
    echo "This script would have changed the compter name to '$dotted_name'"
    echo "Uncomment the three 'scutil' lines in the script to make it actually change it."
    #scutil --set ComputerName $dotted_name
    #scutil --set LocalHostName $dotted_name
    #scutil --set HostName $dotted_name

    # skip all further names in login_list
    break
  fi
done
