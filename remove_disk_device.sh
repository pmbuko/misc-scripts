#!/bin/bash

function help() {
  cat<<EOF
DISK DEVICE REMOVAL TOOL

This tool removes the specified disk device from the host. It can be used when a disk in
a jbod-configured host is bad and pulled from service but doesn't need to be replaced
right away. For safety, the device must be unmounted first.

Specify a single device to be removed as the only argument, e.g.

  sudo remove_disk_device.sh sdd
EOF
}

function check_root() {
  if [ "$(id -u)" -ne "0" ]; then
    echo "This script must be run as root."
    exit 1
  fi
}

function get_lsscsi() {
  echo
  lsscsi
  echo
}

function check_dev_exists_and_unmounted() {
  if [[ -b /dev/$1 ]]; then
    if [[ $(grep $1 /proc/mounts) ]]; then
      echo "$1 is still mounted. Unmount it first."
      exit 1
    fi
  else
    echo "$1 is not a block device."
    exit 1
  fi
}

function remove_bypath_links() {
  for link in /dev/disk/by-path/*; do
    if [[ $(readlink -f $link) =~ "$1" ]]; then
      echo "Removing $(ls -l $link | awk '{print $9,$10,$11}')"
      rm $link
    fi
  done
}

function delete_block_device() {
  echo "Deleting $1 block device"
  echo 1 >> /sys/block/$1/device/delete
}

check_root
if [[ $# == 1 ]]; then
  check_dev_exists_and_unmounted $1
  get_lsscsi
  remove_bypath_links $1
  delete_block_device $1
  get_lsscsi
else
  help
fi

 pbukowinski@ops0003.prn(ps4219)  ~/d/o/bin   remove_disk_device ⁝ ✚ ✱ 
 ❯                                                                                                                                                      [13:39:50]
