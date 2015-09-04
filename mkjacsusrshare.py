#!/usr/bin/env python

import os, sys, pwd
from subprocess import check_call, Popen


def usage(exit_code=1):
  print """
This script adds a JACS user filestore to nobackup, sets permissions, creates
a new policy rule for the fileset, and then commits the policy. It requires
one or more usernames passed as arguments on the command line.

  """ + os.path.basename(__file__) + """ username1 [username2] ...'
  """
  sys.exit(exit_code)


# path variables
mmcrfileset   = '/usr/lpp/mmfs/bin/mmcrfileset'
mmlinkfileset = '/usr/lpp/mmfs/bin/mmlinkfileset'
mmpolicy      = '/root/gs-gpfs1-mmpolicy.lst'
mmchpolicy    = '/usr/lpp/mmfs/bin/mmchpolicy'
mmpolicy2     = '/root/gs-gpfs1-mmpolicy2.lst'


def yes_no(question, default="yes"):
  """
  Ask a yes/no question via raw_input() and True or False.
  "question" is a string presented to the user.
  "default" is the answer if the user hits <Enter>.
  Returns True for "yes" or False for "no".
  """
  valid = {"yes": True, "y": True, "ye": True,
           "no": False, "n": False}
  if default is None:
    prompt = " [y/n] "
  elif default == "yes":
    prompt = " [Y/n] "
  elif default == "no":
    prompt = " [y/N] "
  else:
    raise ValueError("invalid default answer: '%s'" % default)

  while True:
    sys.stdout.write(question + prompt)
    choice = raw_input().lower()
    if default is not None and choice == '':
      return valid[default]
    elif choice in valid:
      return valid[choice]
    else:
      sys.stdout.write("Please respond with 'yes' or 'no' "
                       "(or 'y' or 'n').\n")


def check_uid(uid):
  """
  Checks if a user exists.
  """

def create_fileset(uid):
  """
  Creates a GPFS fileset, ex:
    mmcrfileset Device FilesetName
  """
  output = Popen([mmcrfileset,
                  'gpfs1',
                  'jacs-' + str(uid)],
                  stdout=subprocess.PIPE).communicate()[0]
  print(output)


def create_junction(uid):
  """
  Creates a junction that references the root directory of a GPFS fileset, ex:
    mmlinkfileset Device FilesetName -J JunctionPath
  """
  output = Popen([mmlinkfileset,
                  'gpfs1',
                  'jacs-' + str(uid),
                  '-J',
                  '/gpfs1/scratch/jacs/jacsData/filestore/' + str(uid)],
                  stdout=subprocess.PIPE).communicate()[0]
  print(output)


def chown_chmod_path(uid):
  """
  Sets correct ownership and permissions of fileset.
  """
  check_call(['/bin/chown',
              'jacs:jacsdata',
              '/gpfs1/scratch/jacs/jacsData/filestore/' + str(uid) ])

  check_call(['/bin/chmod',
              '2775',
              '/gpfs1/scratch/jacs/jacsData/filestore/' + str(uid) ])


def mod_mmpolicy(uids, infile=mmpolicy2, outfile=mmpolicy2):
  """
  Adds line for user to mmpolicy file.
  """
  with open(infile, 'r') as f:
    rules = f.readlines()
  for uid in uids:
    rules.append( "RULE 'jacs-%s' SET POOL 'nlsata' FOR FILESET ('jacs-%s')" % (uid,uid) )
  # strip carriage returns from each item
  rules = [ rule.rstrip() for rule in rules ]
  rules.sort()
  # move default rule to end
  default_index = [i for i, s in enumerate(rules) if "RULE 'default'" in s][0]
  rules = rules + [rules.pop(default_index)]
  
  with open(outfile, 'w') as f:
    f.write( '\n'.join( rule for rule in rules ) )

def commit_mmpolicy(mmpolicy = mmpolicy):
  """
  Commits GPFS policy.
  """
  output = Popen([mmchpolicy,
                  'gpfs1',
                  mmpolicy],
                  stdout=subprocess.PIPE).communicate()[0]
  print(output)


def main(argv):
  if len(argv) > 0:
    uids = sys.argv[1:]
    print("You asked to add the following JACS user(s): " + ', '.join( [ str(arg) for arg in sys.argv[1:] ]) )
    if yes_no('Is this correct?'):
      for uid in uids:
        try:
          pwd.getpwnam(uid)
          create_fileset(uid)
          create_junction(uid)
          chown_chmod_path(uid)
        except KeyError:
          print("Skipping non-existent user '%s'." % uid)
          uids.remove(uid)
          continue
          if len(uids) > 0:
                mod_mmpolicy(uids)
        commit_mmpolicy()
      else:
        print('Nothing to do.')
        sys.exit(0)
    else:
      print('Oops. Try again.')
      sys.exit(0)
  else:
    usage()


if __name__ == "__main__":
  main(sys.argv[1:])