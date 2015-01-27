#!/usr/bin/env python

import socket, subprocess

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.connect(('google.com', 0))
print s.getsockname()[0]