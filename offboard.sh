#!/bin/bash
###############################################################################
# OFFBOARD automates the offboarding procedure for ldap accounts.
#
# Supply a single username and it will (after confirmation) do the following:
#  * Prompt for the ldap Manager account's password
#  * Change login shell to '/sbin/nologin'
#  * Move account from 'People' to 'Disabled' container
#  * Revoke membership from all groups under the main Groups ou
# 
# The ldif used to make the changes is saved to the backup_dir location.
###############################################################################

backup_dir="/root/offboard-ldifs"

if [ ! -d "${backup_dir}" ]; then mkdir "${backup_dir}"; fi

if [ $# -eq 1 ]; then
    # set some variables
    user="$1"
    ldap="c06u05"
    base="dc=hhmi,dc=org"
    ldif="${backup_dir}/${user}.ldif"
    mngr="cn=Manager,dc=hhmi,dc=org"
    
    user_lookup=$(ldapsearch -LLL -h ${ldap} -x -b ${base} cn=${user} cn | awk -F': ' '/cn: /{print $2}')
    if [[ "${user}" == "$user_lookup" ]]; then
        if [ -e "${ldif}" ]; then
            echo
            echo -n "Backup ldif file exists for this user. Overwrite it? [y/n] "; read overwrite
        else
            overwrite="y"
        fi
        if [[ "${overwrite}" == "y" ]]; then
            user_dn=$(ldapsearch -LLL -h ${ldap} -x -b ${base} "(cn=${user})" dn | awk -F': ' '/dn: /{print $2}')
            the_groups=$(ldapsearch -LLL -h ${ldap} -x -b ${base} "(memberUid=${user})" dn | awk -F': ' '/dn: /{print $2}' | sort)
            nice_groups=$(echo "${the_groups}" | awk -F, '{gsub("cn=","");print $1}')
            echo
            getent passwd ${user}
            echo
            echo -e "Proceeding will modify \e[32m${user}\e[39m's account as follows:"
            echo
            echo -e "  * Change login shell to '\e[32m/sbin/nologin\e[39m'"
            echo -e "  * Move account from '\e[32mPeople\e[39m' to '\e[32mDisabled\e[39m' container"
            echo -e "  * Revoke membership from the following groups:"
            echo
            for group in ${nice_groups}; do echo -e "      \e[32m${group}\e[39m"; done
            echo
            echo -n "Proceed? [y/n] "; read proceed

            if [[ "${proceed}" == "y" ]]; then
                echo "version: 1" > ${ldif} 
                for group in ${the_groups}; do
                    cat << EOF >> ${ldif}

dn: ${group}
changetype: modify
delete: memberUid
memberUid: ${user}
EOF
                done
                cat << EOF >> ${ldif}

dn: ${user_dn}
changetype: modify
replace: loginShell
loginShell: /sbin/nologin

dn: ${user_dn}
changetype: moddn
newrdn: cn=${user}
deleteoldrdn: 1
newsuperior: ou=Disabled,dc=hhmi,dc=org
EOF
                echo -n "Enter the ldap Manager password: "; read -s pass
                echo
                ldapmodify -h ${ldap} -x -D ${mngr} -w "${pass}" -f ${ldif}
            fi
        fi
    else
        echo "Could not find ${user}."
        exit 1
    fi
else
    cat << EOF
You must supply only one userame (for safety).

Usage example: `basename $0` username

EOF
    exit 1
fi
exit 0
