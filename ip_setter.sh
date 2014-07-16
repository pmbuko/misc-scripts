#!/bin/bash

# Add hostnames and ip address pairs here, one per line
map_array=(
  "comp1 10.10.1.11"
  "comp2 10.10.1.12"
  "comp3 10.10.1.13"
  "comp4 10.10.1.14"
)

for i in ${!map_array[*]}; do
  # get both values for each line
  entry="${map_array[$i]}"

  # assign positional variables to items in $entry
  set -- $entry

  if [ "$(hostname -s)" = "$1" ]; then
    echo "I am $1 and my ip should be $2"
    # networksetup command goes here
  fi
done