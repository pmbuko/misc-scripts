#!/usr/bin/env python

import sys, getopt, os, glob, shutil, json

# relative path to Chrome Default Prefs
chrome_prefs = "Library/Application Support/Google/Chrome/Default/Preferences"


def set_plugin_state(pref, plugin, state):
    """
    This function parses the chrome prefs file passed to it, looking
    for the supplied plugin name, and then disables or enables it
    as requested.
    """
    json_pref = json.loads(open(pref).read())

    # get list of plugins
    plugins_list = json_pref["plugins"]["plugins_list"]

    # find plugins whose names supplied name
    for dict in plugins_list:
        if dict['name'] == plugin:
            dict['enabled'] = state

    # write back modified prefs
    new_prefs = open(pref, 'w+')
    new_prefs.write(json.dumps(json_pref, indent=2))
    new_prefs.close()


def usage(exit_code=1):
    print """This program will disable or enable Chrome plugins by name for ALL local users
and must therefore be run as root. Chrome should not be running or the update may not take.
The original Chrome prefs file is backed up with '.backup' appended to its name.

Use '-d|--disable' or '-e|--enable' and then supply the quoted plugin name, e.g.

    """ + os.path.basename(__file__) + """ -d 'Shockwave Flash'
"""
    sys.exit(exit_code)


def main(argv):
    if len(sys.argv) == 3:
        plugin_name = ''
        plugin_state = ''
        try:
            opts, args = getopt.getopt(argv,"hd:e:",["disable=","enable="])
        except getopt.GetoptError as err:
            print str(err)
            usage(2)
        for opt, arg in opts:
            if opt == '-h':
                usage()
            elif opt in ("-d", "--disable"):
                plugin_state = False
                plugin_name = arg
            elif opt in ("-e", "--enable"):
                plugin_state = True
                plugin_name = arg

        # Test if running as root
        if os.geteuid() != 0:
            exit("You need root privileges to run this script.\nPlease try again using 'sudo'.")

        # Iterate through home directories, looking for Chrome Prefs file
        for home in glob.glob("/Users/*"):
            pref_file = home + '/' + chrome_prefs
            if os.path.isfile(pref_file):
                shutil.copy(pref_file, pref_file + '.backup') # Make a backup copy
                set_plugin_state(pref_file, plugin_name, plugin_state) # run the pref modifier function

    else:
        usage()

if __name__ == "__main__":
    main(sys.argv[1:])
