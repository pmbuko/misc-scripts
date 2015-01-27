#!/usr/bin/pythonw
 
from Tkinter import Tk
from tkSimpleDialog import askstring
 
def passPrompt(title, prompt):
  """Prompts for a password."""
  password = askstring(title, prompt, show="*")
  print "Seriously? '" + password + "'?? That's a lame password."
 
root = Tk()
root.withdraw()
passPrompt('Password Entry', 'Enter a fake password:')
