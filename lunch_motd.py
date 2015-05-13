#!/usr/bin/python
#
# I really like lunch. This script updates the message of the day file with
# a line about lunch time. It will not overwite any existing contents of your
# motd, but it will replace any line that contains the word 'lunch' with an
# appropriate message.
#
#  Created by Peter Bukowinski on 05/13/2015.
#  ( NO rights reserved )
#

import datetime
from subprocess import call
from os import stat

# Set the time lunch starts being served (hh, mm, ss, 0)
lunch = datetime.time(11, 30, 00, 0)

# Set the number of minutes lunch lasts
duration = 90

# time right now
now = datetime.datetime.now().time()

# path to motd file
f_motd = '/private/etc/motd'	# mac
#f_motd = '/etc/motd'			# linux


def not_empty(fname):
	"""Checks if a file is not empty. Returns True or False"""
	return stat(fname).st_size > 0


def h_to_m(h):
	"""Converts hours to minutes"""
	return int(h)*60


def lunch_message(lunch, now):
	"""Returns a lunchtime message based on the current time's proximity to lunch."""
	h_diff = lunch.hour - now.hour
	m_diff = lunch.minute - now.minute
	mins_to_lunch = h_to_m(h_diff) + int(m_diff)
	if h_diff > 0:
		return "FYI, lunch starts in %s minutes.\n" % mins_to_lunch
	elif h_diff == 0:
		if m_diff > 0:
			mins_to_lunch = h_to_m(h_diff) + m_diff
			unit = "minutes"
			if mins_to_lunch == 1: unit = "minute"
			return "Only %s %s until lunch starts!\n" % (mins_to_lunch, unit)
		elif m_diff <= 0:#
			return "OMG, it's lunch time!\n"
	elif mins_to_lunch <= -duration:
		return "Unfortunately, lunch ended %s minutes ago. :(\n" % abs(mins_to_lunch + duration)


def get_motd_lines():
	"""Get the current contents of the motd file"""
	lines = ["lunch"] 
	if not_empty(f_motd):
		motd = open(f_motd)
		lines = motd.readlines()
		motd.close()
	return lines


def update_motd(lines, message):
	"""Write new content to motd file"""
	motd = open(f_motd, 'w')
	match = False
	for line in lines:
		if 'lunch' in line:
			match = True
			line = message
		motd.write(line)
	if not match: motd.write("\n" + message)
	motd.close()


# Do the things
if __name__ == "__main__":
	lines = get_motd_lines()
	message = lunch_message(lunch, now)
	print "\n" + message
	update_motd(lines, message)
