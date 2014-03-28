#!/usr/bin/env python

## TWEAKABLE SETTINGS ##
max_threads = 256
warn_threads = 0.7 * max_threads
mail_sender = 'root@example.com'
mail_recipient = 'alert-group@example.com'
########################

import os, sys, subprocess, smtplib, time
from email.MIMEText import MIMEText

# set some variables
crit_count = 0
warn_count = 0
should_send_alert = False
message = [time.strftime('%I:%M:%S %p'), '============'] # set first two lines of alert message

# Email function
def send_email(message):
    subject = "[ISILON] NFS Thread Alert: " + str(warn_count) + " WARN, " + str(crit_count) + " CRIT"

    msg = MIMEText('\n'.join(message), 'plain')
    msg['Subject'] = subject
    msg['From'] = mail_sender
    msg['To'] = mail_recipient

    s = smtplib.SMTP('smtp.example.com')
    s.sendmail(mail_sender, mail_recipient, msg.as_string())
    s.quit()

# Get nfs thread count data from array
p1 = subprocess.Popen(['isi_for_array', '-s', 'sysctl', 'vfs.nfsrv.rpc.threads_alloc_current'], stdout=subprocess.PIPE)
p2 = subprocess.Popen(['awk', '{print $1 $3}'], stdin=p1.stdout, stdout=subprocess.PIPE)
p1.stdout.close()
raw_data = p2.communicate()[0]

# remove blank lines from string and convert to list of lines
clean_output = os.linesep.join([s for s in raw_data.splitlines() if s])
node_list = clean_output.split('\n')

# identify nodes at or above threshold
for node in node_list:
    me = node.split(':')
    if max_threads > int(me[1]) >= warn_threads:
        warn_count += 1
        should_send_alert = True
        warning = "WARN: " + str(me[0]) + " has reached " + str(me[1]) + " threads"
        message.append(warning)
    elif int(me[1]) == max_threads:
        crit_count += 1
        should_send_alert = True
        critical = "CRIT: " + str(me[0]) + " has reached " + str(me[1]) + " threads"
        message.append(critical)

if should_send_alert:
    message.append("\n")
    message.append("NODE SUMMARY")
    message.append("============")
    message.append(" ")
    message.append(raw_data)
    send_email(message)

sys.exit(0)
