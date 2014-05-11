#!/usr/bin/env python
"""
This script checks whether your OpenLDAP master is properly syncing records
with your OpenLDAP replicas. It does this by modifying the 'description'
attribute of a test account with a timestamp, waiting a specified amount of
time (30 secs by default), and then checking to see if the same attribute
on the replicas matches the master.

Output goes to the screen by default, but email alerts can be enabled
by setting 'alerts_on = True'. Setting this disables screen output so that
the job is quieter when scheduled via cron.

It is meant to be run from your ldap master.
"""

import sys, getopt
import time, datetime
import ldap, ldap.modlist as modlist
import smtplib
from email.MIMEText import MIMEText

# user with privileges to modify description on test account
username = 'cn=ldapadmin,dc=example,dc=com'
password = 'password'

# user to use for testing
user = 'sync_check'

# email options
alerts_on = False # set to True if you want email alerts
mail_recipient = 'you@example.com'
mail_sender = 'root@ldap-master@example.com'
mail_subject = '[LDAP] Failed Sync Alert'
message = ["Timestamp should be " + timestamp] # sets first two line of alert message

# Replace with your replicas
replica_list = [
		'10.1.1.10',
		'10.1.2.10',
		'10.1.3.10',
		'10.1.4.10'
		]

# timestamp to use for updates and checking
timestamp = str(datetime.datetime.now())

# don't change, flipped if errors occur
should_send_alert = False

# Alert email function
def send_email(message):
	msg = MIMEText('\n'.join(message), 'plain')
	msg['Subject'] = subject
	msg['From'] = mail_sender
	msg['To'] = mail_recipient

	s = smtplib.SMTP('mail.example.com')
	s.sendmail(sender, mail_recipient, msg.as_string())
	s.quit()


def connect_to_ldap(ldap_server, write="r"):
	success = False
	try:
		conn = ldap.initialize('ldap://' + ldap_server)
		#conn.start_tls_s()
		conn.set_option(ldap.OPT_TIMEOUT, 5.0)
		if write == "w":
			conn.simple_bind_s( username, password )
		else:
			conn.simple_bind_s()
		success = True
		return conn, success
	except ldap.LDAPError, e:
		#print e
		return conn, success


def get_timestamp(replica, conn, dn):
	global message
	# search for the supplied user
	try:
		result = conn.search_s( dn, ldap.SCOPE_SUBTREE, 'cn=' + user, None )
		user_dn = result[0][0]

		# grab the current description value
		old_ts = {'description': result[0][1]['description'][0]}
		return user_dn, old_ts
	except:
		error = "[ ERROR ]  ",replica,"-- search failed"
		print error
		message.append(error)
		return 0,0


def timestamp_ldap_user_description(ldap_server, timestamp):
	global dn, message, should_send_alert
	conn, conn_success = connect_to_ldap(ldap_server, 'w')		
	if not conn_success:
		result = "ERROR: could not connect to",ldap_server
		print result
		message.append(result)
		if should_send_alert: send_email(message)
		sys.exit(1)
	else:
		# dn of the object to be modified
		dn = 'ou=People,dc=example,dc=com'
	
		user_dn, old_ts = get_timestamp(ldap_server, conn, dn)
		#print old_ts
	
		# set a fresh description value
		new_ts = {'description': timestamp}
		#print new_ts

		# make an ldif
		ldif = modlist.modifyModlist( old_ts, new_ts )

		# modify the entry
		conn.modify_s( user_dn, ldif )
	
		# close ldap connection
		conn.unbind_s()


def check_replicas(replicas, timestamp):
	global should_send_alert, message

	for replica in replicas:
		conn, conn_success = connect_to_ldap(replica)
		if conn_success:	
			user_dn, local_timestamp = get_timestamp(replica, conn, dn)
			if user_dn == 0 and local_timestamp == 0:
				continue
			if local_timestamp['description'] == timestamp:
				result = "[ GOOD  ]   " + replica
				print result
				message.append(result)
			else:
				result = "[ FAIL  ]   " + replica + " -- " + local_timestamp['description']
				print result
				message.append(result)
				should_send_alert = True
		else:
			result =  "[ ERROR ]  ",replica,"-- unable to connect"
			print result
			message.append(result)

def main(argv):
	global should_send_alert, message
	
	wait_secs = 30

	if len(sys.argv) == 3:
		try:
			opts, args = getopt.getopt(argv,"hw:",["wait="])
		except getopt.GetoptError as err:
			print str(err)
			usage()
			sys.exit(2)
		for opt, arg in opts:
			if opt in ("-h", "--help"):
				print myname + ' -w <wait time>'
				sys.exit(0)
			elif opt in ("-w", "--wait"):
				wait_secs = arg
			else:
				assert False, "unhandled option"

	# change the description field of puppet_user
	timestamp_ldap_user_description('localhost', timestamp)
	
	print ""
	print "Updated '" + user+ "'s description with timestamp '" + timestamp + "'"
	print ""
	print "Waiting " + str(wait_secs) + " seconds for records to propagate..."
	
	# Wait
	time.sleep(float(wait_secs))

	# check replicas for accurate syncing
	result_header = """
STATUS      REPLICA
=========   ============="""
	print result_header
	message.append(result_header)

	check_replicas(replica_list, timestamp)

	sys.exit(0)

if __name__ == "__main__":
	main(sys.argv[1:])
