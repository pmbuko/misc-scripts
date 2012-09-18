#!/bin/bash

###############################################################################
# DEPLOYSERV -- by Peter -- last modified 06-09-2011
#
# This script automates the process of re-deploying linux servers. I optimized
# it for deploying multiple servers at a time. See help section for more info.
###############################################################################

#############
# VARIABLES #
#############

pxe=/tftpboot/linux-install/pxelinux.cfg # path to the pxe install configs
pxecfgs=$(ls -1 $pxe | grep .cfg$)       # finds the config files that start with rhel

#############
# FUNCTIONS #
#############

function help {
    cat<<EOF

DEPLOY SERVER TOOL

Utility to redeploy linux servers in the datacenter. It will link specified server(s)
to chosen PXE boot config, then reboot and handle the subsequent PXE link removal.

`basename $0`: `basename $0` [-f Cluster Rack] [-r Host Range] [-s Single Host(s)] [-h]

You must specify *one* of the following options:

    -f  --  Cluster Rack: Specify an entire cluster rack using the double-digit format,
            e.g. `basename $0` -f 08 

    -r  --  Host Range: Specify a range of hosts within a rack using square brackets,
            e.g. `basename $0` -r f08u[01-16]

    -s  --  Single Host(s): Specify one or more single hosts using spaces,
            e.g. `basename $0` -s f08u17 f10u02 f12u21

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
    echo "Available configurations:"
            
    # populate array and display config choices
    for cfg in $pxecfgs; do
        cfgARRAY[$index]="$cfg"
        if [ $index -lt 10 ]; then sp=" "; else sp=""; fi
        echo "[$sp$index]: $cfg"
        ((index++))
    done
    ((index--))

    echo ""
    echo " [Q]: Quit"
    
    # prompt user to select a config
    echo ""
    echo -n "Choose a config to deploy to cluster rack f$1 . [0-$index]: "
    read -n 3 achoice
        
    # check choice for sanity
    if [ "$achoice" = "Q" ] || [ "$achoice" = "q" ]; then
        exit 0
    fi
    if [ "0" -le "$achoice" ] && [ "$achoice" -le "$index" ]; then 	# proceed if choice is within expected range
        cd $pxe
        ln -fs ${cfgARRAY[$achoice]} $rack_address
        echo "Created link: ${cfgARRAY[$achoice]} -> $rack_address."
    else
        echo "Haha, you fool! That was an invalid selection. Now you have to start over."
        exit 1
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

function choose_pxe () {
    # declare an array to hold the config names
    declare -a cfgARRAY
    index=0
     
    # Set up the interface
    echo ""
    echo "Available configurations:"
     
    # populate array and display config choices
    for cfg in $pxecfgs; do
        cfgARRAY[$index]="$cfg"
        if [ $index -lt 10 ]; then sp=" "; else sp=""; fi
        echo "[$sp$index]: $cfg"
        ((index++))
    done
    ((index--))

    echo ""
    echo " [Q]: Quit"
    
    # prompt user to select a config
    echo ""
    echo -n "Choose a config to deploy. [0-$index]: "
    read -n 3 bchoice
     
    echo ${cfgARRAY[$bchoice]}
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
    if [[ $1 == f* ]]; then # checks if server is in the f row (cluster node)
        ipmitool -H ${1}i -U root -P cfipmi chassis power cycle || echo "Couldn't reboot. Is ipmi set up properly?"
    else
        ipmitool -H ${1}i -U root -P ipmimgmt chassis power cycle || echo "Couldn't reboot. Is ipmi set up properly?"
    fi
}

function rm_link(){
    echo "rm -f ${pxe}/$hostip" | at now + 5 minutes
}

function rm_rack_link(){
    echo "rm -f ${pxe}/$rack_address" | at now + 5 minutes
}

function clean_pupcert(){
    ssh root@puppet puppetca --clean $1.int.janelia.org
}

############
# WORKFLOW #
############

if [[ $# < 2 ]]; then help; else
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
                echo "Done."
                exit 0;;

            r)  HOST_RANGE="$OPTARG"
                HOST_LIST=$(parse_range $HOST_RANGE)

                # declare an array to hold the config names
                declare -a cfgARRAY
                index=0

                # Set up the interface
                echo ""
                echo "Available configurations:"

                # populate array and display config choices
                for cfg in $pxecfgs; do
                    cfgARRAY[$index]="$cfg"
                    if [ $index -lt 10 ]; then sp=" "; else sp=""; fi
                    echo "[$sp$index]: $cfg"
                    ((index++))
                done
                ((index--))

                echo ""
                echo " [Q]: Quit"

                # prompt user to select a config
                echo ""
                echo -n "Choose a config to deploy. [0-$index]: "
                read -n 3 choice
                if [ "$choice" = "Q" ] || [ "$choice" = "q" ]; then exit 0; fi
                if [ "0" -le "$choice" ] && [ "$choice" -le "$index" ]; then  # proceed if choice is within expected range
                    pxe_choice=${cfgARRAY[$choice]}
                else
                    echo "Haha, you fool! That was an invalid selection. Now you have to start over."
                    exit 1
                fi

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
                echo "Done."
                exit 0;;

            s)  SINGLE_HOSTS="$OPTARG"
                for host in $SINGLE_HOSTS; do
                    check_single $host
                done
                # declare an array to hold the config names
                declare -a cfgARRAY
                index=0

                # Set up the interface
                echo ""
                echo "Available configurations:"

                # populate array and display config choices
                for cfg in $pxecfgs; do
                    cfgARRAY[$index]="$cfg"
                    if [ $index -lt 10 ]; then sp=" "; else sp=""; fi
                    echo "[$sp$index]: $cfg"
                    ((index++))
                done
                ((index--))

                echo ""
                echo " [Q]: Quit"

                # prompt user to select a config
                echo ""
                echo -n "Choose a config to deploy. [0-$index]: "
                read -n 3 choice
                if [ "$choice" = "Q" ] || [ "$choice" = "q" ]; then exit 0; fi
                if [ "0" -le "$choice" ] && [ "$choice" -le "$index" ]; then  # proceed if choice is within expected range
                    pxe_choice=${cfgARRAY[$choice]}
                else
                    echo "Haha, you fool! That was an invalid selection. Now you have to start over."
                    exit 1
                fi

                for host in $SINGLE_HOSTS; do
                    echo "--------------------------------"
                    echo "Starting deployment of $host..."
                    link_pxe $host $pxe_choice
                    echo -n "Rebooting..."; reboot_host $host > /dev/null && echo " OK"
                    echo -n "Removing PXE Link..."; rm_link $host && echo " OK"
                    echo -n "Cleaning Puppet certificate..."; clean_pupcert $host > /dev/null && echo " OK"
                    echo ""
                done
                echo "--------------------------------"
                echo "Done."
                exit 0;;

            h) 
                help
                exit 0;;

            \?)
                echo "Usage: `basename $0` [-f Cluster Rack] [-r Host Range] [-s Single Host(s)] [-h]"
                echo "For more help, run: `basename $0` -h"
                exit 0;;
        esac
    done
    shift `expr $OPTIND - 1`
fi
