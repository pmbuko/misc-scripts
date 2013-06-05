#!/bin/bash

# Explicitly set the directory you want to operate on here 
workingPath="/your/path/here"

# Set a custom internal field separator to ease handling
# of filenames that contain spaces
IFS=$'\n'

# Identify files that end in ' 2' and tack on our custom
# field separator
endIn2=$(find "${workingPath}" -regex '.* 2$' | awk '{print $0"\n"}')

# Go through the list of identified files and rename them
for oldName in $endIn2; do
    newName=$(echo "${oldName}" | awk -F' 2' '{print $1}')
    echo "Will rename \"${oldName}\" to \"${newName}\""
    # Uncomment the next line after testing the script.
    #mv "${oldName}" "${newName}"
done
