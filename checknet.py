#!/usr/bin/env python                                                                                                                     

# This script will attempt to alert the systems team if a
# statically-assigned linux box gets moved incorrectly. If
# it cannot ping its gateway, then it does the following:
#
#  - enables dhcp on eth0
#  - sets its new gateway as a default route
#  - looks up primary user info via puppet/facter
#  - sends an alert email
#
# With the info in the email, an admin can ssh to the box
# and fix the network configuration.
      
from platform import dist
import os, signal, socket, subprocess
import smtplib
from time import sleep
from email.MIMEText import MIMEText                                                              

interface = 'eth0'
hostname = socket.gethostname()                                                                                                                                          
# email options
mail_recipient = 'alert_group@example.com'
mail_sender = 'root@' + hostname
mail_subject = '[ALERT] Someone probably moved me'
message = ['You may need to fix network settings on ' + hostname, '']

def send_email(message):
    msg = MIMEText('\n'.join(message), 'plain')
    msg['Subject'] = mail_subject
    msg['From'] = mail_sender
    msg['To'] = mail_recipient
    
    s = smtplib.SMTP('mail.hhmi.org')
    s.sendmail(mail_sender, mail_recipient, msg.as_string())
    s.quit()


def my_ip():
    p1 = subprocess.Popen(["ifconfig", interface ],
        stdout = subprocess.PIPE)
    p2 = subprocess.Popen(["awk", "/inet /{gsub(\"addr:\",\"\");print $2}"],
        stdin=p1.stdout,
        stdout=subprocess.PIPE)
    output, error = p2.communicate()
    ip = output.strip()
    if not ip: return 'None'
    return ip


def get_gateway(ip):
    if '10.123' in ip:
        return '10.123.0.1'
    else:
        octets = ip.split('.')
        octets[3] = '1'
        return '.'.join(octets)


def can_ping_gateway(gateway):
    ping = subprocess.Popen(['ping', '-c1', '-w3', gateway ],
        stdout = subprocess.PIPE,
        stderr = subprocess.STDOUT)
    output, error = ping.communicate()
    if ('0 received' in output):
        return False
    else:
        return True


def disable_interface(interface):
    if 'Ubuntu' in dist()[0]:
        command = ['ifdown', '--force', interface]
    else:
        command = ['ifdown', interface]
    ifdown = subprocess.Popen(command,
        stdout = subprocess.PIPE,
        stderr = subprocess.STDOUT)
    try:
        output, error = ifdown.communicate()
    except:
        ifdown.kill()
        print 'Could not shut down ' + interface


def enable_dhcp(interface):
    dhcp = subprocess.Popen(['dhclient', interface ],
        stdout = subprocess.PIPE,
        stderr = subprocess.STDOUT)
    try:
        output, error = dhcp.communicate()
        print 'DHCP enabled.'
    except:
        dhcp.kill()
        print 'Could not enable DHCP on ' + interface


def del_def_route():
    route = subprocess.Popen(['route', 'del', 'default'],
        stdout = subprocess.PIPE,
        stderr = subprocess.STDOUT)
    try:
        output, error = route.communicate()
        print 'Removed existing default route.'
    except:
        route.kill()
        print 'Could not remove default route.'


def add_def_route(gw, interface):
    route = subprocess.Popen(['route', 'add', 'default', 'gw', gw, interface ],
        stdout = subprocess.PIPE,
        stderr = subprocess.STDOUT)
    try:
        output, error = route.communicate()
        print 'Default route set to ' + gw
    except:
        route.kill()
        print 'Could not set default route for ' + interface


def run_puppet():
    puppet = subprocess.Popen(['puppet', 'agent', '-t' ],
        stdout = subprocess.PIPE,
        stderr = subprocess.STDOUT)
    try:
        output, error = puppet.communicate()
    except:
        puppet.kill()
        print 'Could not run puppet.'


def facter_primaryuser():
    facter = subprocess.Popen(['facter', '-p', 'primaryuser' ],
        stdout = subprocess.PIPE,
        stderr = subprocess.STDOUT)
    try:
        output = facter.communicate()[0].strip()
        return output
    except:
        facter.kill()
        print 'Could not run facter.'


def kill_dhclient():
    p = subprocess.Popen(['ps', '-A' ], stdout = subprocess.PIPE)
    out, err = p.communicate()
    for line in out.splitlines():
        if 'dhclient' in line:
            try:
                pid = int(line.split(None, 1)[0])
                os.kill(pid, signal.SIGKILL)
            except:
                print 'Could not kill dhclient.'


def switch_to_dhcp():
    global message
    print 'Cannot ping gateway. Switching to DHCP...'
    disable_interface(interface)
    kill_dhclient()
    enable_dhcp(interface)
    new_ip = my_ip()
    print 'New IP:', new_ip
    message.append('Temp. dhcp address: ' + new_ip) 
    new_gw = get_gateway(new_ip)
    del_def_route()
    add_def_route(new_gw,interface)
    #run_puppet()
    puser = facter_primaryuser()
    print 'Primary user: ' + puser
    message.append('')
    message.append('Primary user: ' + puser)
    send_email(message)


def main():
    global message
    sleep(10)
    ip = my_ip()
    message.append('Old static address: ' + ip)
    print 'My IP:', ip
    if ip != 'None':
        gw = get_gateway(ip)
        print 'My gateway:', gw
        if can_ping_gateway(gw):
            print 'All good.'
        else:
            switch_to_dhcp()
    else:
        switch_to_dhcp()

if __name__ == '__main__':
    main()
