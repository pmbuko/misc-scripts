#!/usr/bin/env python

import sys, getopt, os, glob, shutil, json

# name of this script
myname = os.path.basename(__file__)

# get list of local homes
homes = glob.glob("/Users/*")

# relative path to Chrome Default Preferences
chrome_prefs = "Library/Application Support/Google/Chrome/Default/Preferences"


def set_plugin_state(pref, plugin, state):
    """
    This function parses the chrome prefs file passed to it, looking
    for the supplied plugin name, and then disabling or enabling it
    as requested. It overwrites the existing pref file.
    """
    json_pref = json.loads(open(pref).read())

    # get a list of plugins
    plugin_list = json_pref["plugins"]["plugins_list"]

    # find plugins whose name matches 'SharePoint Browser Plug-in'
    for dict in plugin_list:
        if dict['name'] == plugin:
            dict['enabled'] = state

    # write back modified prefs
    new_prefs = open(pref, 'w+')
    new_prefs.write(json.dumps(json_pref))
    new_prefs.close()

def usage():    
    print """This program will disable or enable Chrome plugins by name for ALL local users
and must therefore be run as root.

Use '-d|--disable' or '-e|--enable' and then supply the quoted plugin name, e.g.

    """ + myname + """ -d 'Shockwave Flash'
"""
    sys.exit(1)


def main(argv):
    print len(sys.argv)
    if len(sys.argv) == 3:
        try:
            opts, args = getopt.getopt(argv,"hd:e:",["disable=","enable="])
        except getopt.GetoptError as err:
            print str(err)
            usage()
        for opt, arg in opts:
            if opt == '-h':
                usage()
            elif opt in ("-d", "--disable"):
                plugin_state = False
                plugin_name = arg 
            elif opt in ("-e", "--enable"):
                plugin_state = True 
                plugin_name = arg 
            else:
                assert False, "I don't understand that option."

            if os.geteuid() != 0:
                exit("You need to have root privileges to run this script.\nPlease try again using 'sudo'. Exiting.")
            for home in homes:
                pref_file = home + '/' + chrome_prefs

                if os.path.isfile(pref_file):
                    shutil.copy(pref_file, pref_file + '.backup') # Make a backup copy
                    set_plugin_state(pref_file, plugin_name, plugin_state) # run the pref modifier function
    
    else:
        usage()

if __name__ == "__main__":
    main(sys.argv[1:])