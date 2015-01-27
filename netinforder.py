#!/usr/bin/env python

from re import findall
from subprocess import check_output

def getOrderedInterfaces():
  """Returns all ethernet interfaces in service order."""
  interfaces = check_output(['networksetup', '-listnetworkserviceorder'])
  matches = findall(r' en[\d]+', interfaces)
  return [ i.lstrip(' ') for i in matches ]

def isActive(interface):
  """Tests if an interface has an ip address."""
  try:
    address = check_output(['ipconfig', 'getifaddr', interface])
    return True
  except:
    return False

result = [ x for x in getOrderedInterfaces() if isActive(x) ]
print result
