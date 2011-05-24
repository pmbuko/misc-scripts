#!/bin/bash

########################################################################
# DEPLOYSERV -- by Peter -- last modified 05-23-2011
#
# This script automates the process of re-deploying linux servers in our
# datacenter. See help function a few lines down for more info.
########################################################################

#############
# VARIABLES #
#############

pxe=/tftpboot/linux-install/pxelinux.cfg # path to the pxe install configs
pxecfgs=$(ls $pxe | grep ^rhel)          # finds the config files that start with rhel

#############
# FUNCTIONS #
#############

function help {
    cat<<EOF
Deploy Server Tool
Utility to redeploy linux servers in the datacenter. It will link specified servers
to chosen PXE boot config, then reeboot and handle the subsequent PXE link removal.

`basename $0`: `basename $0` [-f Cluster Rack] [-r Range] [-s Single Host]

Choose *one* of the following options:
    -f  --  Cluster Rack: specify an entire cluster rack using the double-digit format,
            e.g. 08 
    -r  --  Host Range: Specify a range of hosts within a rack using square brackets,
            e.g. f01u[01-16]
    -s  --  Single Host: specify a single hostname,
            e.g. f08u09
    -h  --  Display this help screen

EOF
}

function link_rack(){
    if [ -z "$1" ]; then
        echo "You must specify a cluster rack when using the -f option."
    else
        rackproxy=$(echo f"$1"u01)
        rack_address=$(gethostip $rackproxy | awk '{gsub("0B$","");print $3}') || echo "Could not get hostip."
    fi

    # declare an array to hold the config names
    declare -a cfgARRAY
    let local index=0
        
    # Set up the interface
    echo ""
    echo "Avaliable configurations:"
            
    # populate array and display config choices
    for cfg in $pxecfgs; do
        cfgARRAY[$index]="$cfg"
        echo "[$index]: $cfg"
        ((index++))
    done
    ((index--))

    echo ""
    echo "[Q]: Quit"
    
    # prompt user to select a config
    echo ""
    echo -n "Choose a config to deploy to cluster rack f$1 . [0-$index]: "
    read -n 2 achoice
        
    # check choice for sanity
    if [ "$achoice" = "Q" ] || [ "$achoice" = "q" ]; then
        exit 0
    fi
    if [ "0" -le "$achoice" ] && [ "$achoice" -le "$index" ]; then 	# proceed if choice is within expected range
        cd $pxe
        ln -fs ${cfgARRAY[$achoice]} $rack_address
        echo "Created link: ${cfgARRAY[$achoice]} -> $rack_address."
    fi
}

function rack_hosts(){
    local rack=$(echo f"$1"u)
    for i in {1..36}; do
        echo $rack$(printf "%02d" $i)
    done
}

function check_single(){
    if [ -z "$1" ]; then
        echo "You must specify a single host when using the -s option."
        exit 0
    fi
}

function parse_range(){
    if [ -z "$1" ]; then
        echo "You must specify a range when using the -r option."
    else
        local rack=$(echo $1 | awk -F'[' '/\[.*\]/{print $1}')
        r_start=$(echo $1 | awk -F'[' '/\[.*\]/{gsub("]","");print $2}' | awk -F- '{print $1}')
        r_end=$(echo $1 | awk -F'[' '/\[.*\]/{gsub("]","");print $2}' | awk -F- '{print $2}')
        for i in $(eval echo {$r_start..$r_end}); do
            echo $rack$(printf "%02d" $i)
        done
    fi
}

function link_pxe(){
    pxe_cfg=$2
    # check choice for sanity
    if [ "$bchoice" = "Q" ] || [ "$bchoice" = "q" ]; then
        exit 0
    fi
    hostip=$(gethostip $1 | awk '{print $3}')
    # check if server exists before proceeding
    if [ -z "$hostip" ]; then
        echo "WARNING: $1 does not exist. Skipping."
        continue
    else
        cd $pxe
        ln -fs $pxe_cfg $hostip
        echo "Created link: $pxe_cfg -> $hostip."
    fi
}

function reboot_host(){
    do_reboot=y
    if [[ $SKIP_PROMPTS == 0 ]]; then
        # prompt to reboot the target server
        echo -n "Reboot $1 now? [y/n]: "
        read -n 2 do_reboot
    fi
    if [[ $do_reboot == y ]]; then
        if [[ $1 == f* ]]; then # checks if server is in the f row (cluster node)
            #echo "Would have rebooted ${1}i" 
            ipmitool -H ${1}i -U root -P cfipmi chassis power cycle || echo "Couldn't reboot. Is ipmi set up properly?"
        else
            #echo "Would have rebooted ${1}i"
            ipmitool -H ${1}i -U root -P ipmimgmt chassis power cycle || echo "Couldn't reboot. Is ip mi set up properly?"
        fi
    elif [[ $do_reboot == n ]]; then
        echo "Exiting."
        exit 0
    else
        echo ""
        echo "You didn't type 'y' or 'n'."
        exit 1
    fi
}

function rm_link(){
    rmlink=y
    if [[ $SKIP_PROMPTS == 0 ]]; then
        # prompt to auto-remove line
        echo -n "Remove PXE install link in 5 minutes? [y/n]: "
        read -n 2 rmlink
    fi
    if [[ $rmlink == y ]]; then
        echo "rm -f ${pxe}/$hostip" | at now + 5 minutes
    elif [[ $rmlink == n ]]; then
        continue
    else
        echo ""
        echo "You didn't type 'y' or 'n'."
        exit 1
    fi
}

function rm_rack_link(){
    rmrlink=y
    if [[ $SKIP_PROMPTS == 0 ]]; then
        # prompt to auto-remove line
        echo -n "Remove PXE install link in 5 minutes? [y/n]: "
        read -n 2 rmrlink
    fi
    if [[ $rmrlink == y ]]; then
        echo "rm -f ${pxe}/$rack_address" | at now + 5 minutes
    elif [[ $rmrlink == n ]]; then
        continue
    else
        echo ""
        echo "You didn't type 'y' or 'n'."
        exit 1
    fi
}

function clean_pupcert(){
    has_puppet=y
    if [[ $SKIP_PROMPTS == 0 ]]; then
        # prompt for puppet management
        echo -n "Is $server managed by Puppet? [y/n]: "
        read -n 2 has_puppet
    fi
    if [[ $has_puppet == y ]]; then
        ssh root@puppet puppetca --clean $1.int.janelia.org
    elif [[ $has_puppet == n ]]; then
        echo "Done."
        exit 0
    else
        echo ""
        echo "You didn't type 'y' or 'n'."
        exit 1
    fi
}

############
# WORKFLOW #
############

if [ $# == 0 ]; then help; else
    while getopts :f:r:s:h opt; do
        case "$opt" in
            f)  CLUSTER_RACK="$OPTARG"
                link_rack $CLUSTER_RACK
                HOST_LIST=$(rack_hosts $CLUSTER_RACK)
                for host in $HOST_LIST; do
                    echo "--------------------------------"
                    echo "Starting deployment of $host..."
                    echo -n "Rebooting..."; reboot_host $host > /dev/null && echo " OK"
                    echo -n "Cleaning Puppet certificate..."; clean_pupcert $host > /dev/null && echo " OK"
                done
                echo -n "Removing rack link..."; rm_rack_link $CLUSTER_RACK; echo " OK"
                echo "--------------------------------"
                echo "Done.";;

            r)  HOST_RANGE="$OPTARG"
                HOST_LIST=$(parse_range $HOST_RANGE)

                # declare an array to hold the config names
                declare -a cfgARRAY
                index=0

                # Set up the interface
                echo ""
                echo "Avaliable configurations:"

                # populate array and display config choices
                for cfg in $pxecfgs; do
                    cfgARRAY[$index]="$cfg"
                    echo "[$index]: $cfg"
                    ((index++))
                done
                ((index--))

                echo ""
                echo "[Q]: Quit"

                # prompt user to select a config
                echo ""
                echo -n "Choose a config to deploy. [0-$index]: "
                read -n 2 choice
                pxe_choice=${cfgARRAY[$choice]} 

                for host in $HOST_LIST; do
                    echo "--------------------------------"
                    echo "Starting deployment of $host..."
                    link_pxe $host $pxe_choice
                    echo -n "Rebooting..."; reboot_host $host > /dev/null && echo " OK"
                    echo -n "Removing PXE link..."; rm_link $host && echo " OK"
                    echo -n "Cleaning Puppet certificate..."; clean_pupcert $host > /dev/null && echo " OK"
                    echo ""
                done
                echo "--------------------------------"
                echo "Done.";;

            s)  SINGLE_HOST="$OPTARG"
                check_single $SINGLE_HOST
                
                # declare an array to hold the config names
                declare -a cfgARRAY
                index=0

                # Set up the interface
                echo ""
                echo "Avaliable configurations:"

                # populate array and display config choices
                for cfg in $pxecfgs; do
                    cfgARRAY[$index]="$cfg"
                    echo "[$index]: $cfg"
                    ((index++))
                done
                ((index--))

                echo ""
                echo "[Q]: Quit"

                # prompt user to select a config
                echo ""
                echo -n "Choose a config to deploy. [0-$index]: "
                read -n 2 choice
                pxe_choice=${cfgARRAY[$choice]} 

                echo "Starting deployment of $SINGLE_HOST..."
                link_pxe $SINGLE_HOST $pxe_choice
                echo -n "Rebooting..."; reboot_host $host > /dev/null && echo " OK"
                echo -n "Removing PXE Link..."; rm_link $SINGLE_HOST && echo " OK"
                echo -n "Cleaning Puppet certificate..."; clean_pupcert $SINGLE_HOST > /dev/null && echo " OK"
                echo "Done.";;

            h) 
                help
                exit 0;;

            \?)
                echo "Usage: `basename $0` [-f Cluster Rack] [-r Range] [-s Single Host] [-h]"
                echo "For more help, run: `basename $0` -h"
                exit 0;;
        esac
    done
    shift `expr $OPTIND - 1`
fi
