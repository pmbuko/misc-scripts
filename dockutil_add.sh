#!/bin/bash

# check if we have the minimum number of arguments
if [ -z "$4" ]; then
    echo "Didn't receive any paths. Exiting now."
    exit 1
fi

# Skip the first three arguments ($1, $2, $3)
shift 3

# Process the remaining arguments, which should all be paths
until [ -z "$1" ]; do
    echo "Adding $1 to dock..."
    dockutil --add "${1}" || echo "Could not add $1 to dock."; exit 1
    # Shift remaining arguments, so the next one becomes $1.
    shift || break
done

# Exit cleanly
exit 0