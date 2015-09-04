#!/usr/bin/env python
"""
This script automates the process of adding a printer to a *nix desktop.
It should work with any OS that uses CUPS (Fedora, Ubuntu, OS X).
The script is interactive so no command line arguments are necessary.

Created by Peter Bukowinski on 06/22/2015.
"""


from subprocess import check_call as call

printers = {}
#        ID      printer name          queue name     address
printers[1] =  [ "1E.123 Canon IR5051", "1E123_Canon", "socket://10.101.40.19" ]
printers[2] =  [ "1E.151 Canon IR5051", "1E151_Canon", "socket://10.101.40.15" ]
printers[3] =  [ "1W.183 Canon IR5030", "1W183_Canon", "socket://10.101.10.205" ]
printers[4] =  [ "2C.235 Canon IR5255", "2C235_Canon", "socket://10.123.15.3" ]
printers[5] =  [ "2C.290 Canon IR5051", "2C290_Canon", "socket://10.102.20.192" ]
printers[6] =  [ "2E.290 Canon IR5051", "2E290_Canon", "socket://10.123.15.2" ]
printers[7] =  [ "2W.235 Canon IR5255", "2W235_Canon", "socket://10.102.20.12" ]
printers[8] =  [ "3C.250 Canon IR5051", "3C250_Canon", "socket://10.103.30.33" ]
printers[9] =  [ "3E.250 Canon IR5051", "3E250_Canon", "socket://10.103.40.195" ]
printers[10] = [ "3W.250 Canon IR5051", "3W250_Canon", "socket://10.103.10.206" ]


def add_printer(printer, make_default):
  qname = printers[printer][1]
  call([ 'lpadmin',
         '-p', qname,
         '-D', printers[printer][0],
         '-v', printers[printer][2],
         '-m', 'drv:///sample.drv/generic.ppd',
         '-o', 'Option1=True',
         '-o', 'Duplex=DuplexNoTumble' ])

  call([ 'cupsenable', qname ])
  call([ 'cupsaccept', qname ])
  if make_default:
    call([ 'lpoptions', '-d', qname ])


def main():
  IDs = printers.keys()
  IDs.sort()
  for i in IDs: 
    if i < 10:
      print ' ' + str(i) + ':', printers[i][0]
    else:
      print str(i) + ':', printers[i][0]

  while True:
    selection = int(raw_input('Select a printer to add: '))
    if selection in IDs:
      break

  while True:
    default = raw_input("""Make '%s' your default printer [y/n]? """ % printers[selection][0])
    if default is 'y':
      make_default = True
      break
    elif default is 'n':
      make_default = False
      break

  add_printer(selection, make_default)


if __name__ == "__main__":
  main()
