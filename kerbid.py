#!/usr/bin/pythonw

import subprocess
from SystemConfiguration import SCDynamicStoreCopyConsoleUser
import re
from Tkinter import Tk
import tkSimpleDialog

def getconsoleuser():
  """Return console user"""
  cfuser = SCDynamicStoreCopyConsoleUser(None, None, None)
  return cfuser[0]

def getKerbID():
  """Returns the Kerberos ID of the current user"""
  upath = '/Users/' + getconsoleuser()
  dscl = subprocess.check_output(['dscl', '/Search', 'read', upath, 'AuthenticationAuthority'])
  match = re.search(r'[a-zA-Z0-9+_\-\.]+@[^;]+\.[A-Z]{2,}', dscl, re.IGNORECASE)
  if match:
    print match.group()
  else:
    return "Could not find Kerberos ID"

def passPrompt(title, prompt):
  """Prompts the user for input with a message."""
  answer = tkSimpleDialog.askstring(title, prompt, show="*")
  print answer

root = Tk()
root.withdraw()

getKerbID()
stringPrompt('Password Entry', 'Enter a password:')
