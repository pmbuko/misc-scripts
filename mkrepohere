#!/bin/bash
################################################################################
# MKREPOHERE -- Made by Peter on 8/1/2013
# 
# mkrepohere automates the process of creating a subversion repository. You
# need to provide a name for the repo and the script will walk you through the
# rest of the steps that need your input. You need to run the script from the
# location where you want the repo created.
################################################################################

# Check if we're running in the right location
if ! [[ $(pwd) =~ "/opt/svn_repos" ]]; then
    /bin/echo "Please run this script from the location you want the repo created. (/opt/svn_repos/[group])"
    exit
fi

# Pattern for input sanitation check
pattern=" |'"

# Check if one repo name was supplied
if [[ "$#" -ne 1 ]]; then
    /bin/echo -n "You must provide the name of one repo (no spaces, underscores are ok): "
    read repo_name
else
    # Check if the repo name contains a illegal characters
    if [[ $@ =~ $pattern ]]; then
        /bin/echo -n "Repository names should not contain spaces. Try again: "
        read repo_name
    else
        repo_name="$1"
    fi
fi

# Determine paths to repo resources
my_dir=$(pwd)
repo_dir="${my_dir}/$repo_name"
location=$(/bin/echo $repo_dir | sed 's/\/opt\/svn_repos//')
auth_dir=$(/bin/echo $my_dir | sed 's/svn_repos/auth_files/')
if ! [ -d "$auth_dir" ]; then mkdir -p "$auth_dir"; fi
auth_file="${auth_dir}/$repo_name"
conf_file="/etc/httpd/conf.d/httpd-subversion.conf"

/bin/echo -n "Creating ${repo_name}... "
/usr/bin/svnadmin create $repo_name --fs-type fsfs
/bin/chown -R svnadmin.svnadmin $repo_name
/bin/echo "Done."
/bin/echo -n "Creating $auth_file... "
/bin/cat << EOF > $auth_file
[/]
* = r

EOF
read -p "Done.
Press [Enter] to see/edit the auth file now."
/usr/bin/vim $auth_file

/bin/echo -n "Creating apache config block for repo at bottom of $conf_file... "
# Count the lines in the conf file so we can open it to the right line later.
lines=$(($(/usr/bin/wc -l $conf_file | awk '{print $1}') + 1))
/bin/cat << EOF >> $conf_file
<Location $location>
   DAV svn
   SVNPath $repo_dir
      SSLRequireSSL
      AuthType Basic
      AuthBasicProvider ldap file
      AuthName "Subversion Repos"
      AuthUserFile /opt/svnusers
      AuthLDAPURL ldap://ldap1/ou=People,dc=example,dc=com?uid?sub?(objectClass=*)
      AuthLDAPURL ldap://ldap2/ou=People,dc=example,dc=com?uid?sub?(objectClass=*)
      AuthzLDAPAuthoritative off
      Require valid-user
      AuthzSVNAccessFile $auth_file
</Location>
EOF

read -p "Done.
You may want to move the block (14 lines). Press [Enter] to see/edit the config file now."
/usr/bin/vim $conf_file +$lines

/bin/echo "Restart apache to load the new config now? (choose a number)"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) service httpd restart; break;;
        No ) exit;;
    esac
done
