#!/bin/bash
# $1 = filename with full path
# $2 = dest. VOLNAME, assuming path like '/Volumes/VOLNAME/…'

# give file a new name with current path
new_name=$(echo "$1" | sed 's/:/-/g')

# give file a new path
file_dest="/Volumes/${2}${new_name}"

# copy/rename file to the new location
cp "$1" "$file_dest"