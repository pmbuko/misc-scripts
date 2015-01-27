#!/usr/bin/python

from SystemConfiguration import (
  SCNetworkInterfaceGetBSDName,
  SCNetworkInterfaceGetLocalizedDisplayName,
  SCNetworkInterfaceGetHardwareAddressString,
  SCNetworkServiceGetName,
  SCNetworkInterfaceCopyAll,
  SCPreferencesCreate,
  SCNetworkServiceCopyAll
)

def hasEN(item):
  if 'en' in item:
    return True
  else:
    return False

def get_networkinterfacelist(network_interfaces):
    '''Returns a list of all network interface names'''
    d = {}
    for interface in network_interfaces:
      bsdName = SCNetworkInterfaceGetBSDName(interface)
      if 'en' in bsdName:
        d[SCNetworkInterfaceGetLocalizedDisplayName(interface)] = (
            bsdName,
            SCNetworkInterfaceGetHardwareAddressString(interface)
            )

    return d

def get_networkservices(network_services):
    '''Returns a list of all network interface names'''
    l = []
    for service in network_services:
        l.append(SCNetworkServiceGetName(service))
    return l

def main():
    network_interfaces = SCNetworkInterfaceCopyAll()
    print get_networkinterfacelist(network_interfaces)

    prefs = SCPreferencesCreate(None, 'foo', None)
    network_services = SCNetworkServiceCopyAll(prefs)
    print get_networkservices(network_services)

if __name__ == "__main__":
    main()
