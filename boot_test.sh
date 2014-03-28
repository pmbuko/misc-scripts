#!/bin/bash

for vol in $(/bin/ls /Volumes); do
  if [ -e "/Volumes/${vol}/System/Library/CoreServices/boot.efi" ]; then
    echo "${vol} contains bootable OS X"
  elif [ -e "/Volumes/${vol}/Windows/System32/winload.exe" ]; then
    echo "${vol} contains bootable Windows"
  fi
done
