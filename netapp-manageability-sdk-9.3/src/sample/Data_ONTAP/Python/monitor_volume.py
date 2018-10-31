#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# monitor_volume.py                                          #
#                                                            #
# Monitors volume on a filer and sends e-mail on space usage #
# crossing threshold.                                        #
#                                                            #
# Copyright 2011 Network Appliance, Inc. All rights          #
# reserved. Specifications subject to change without notice. #
#                                                            #
# This SDK sample code is provided AS IS, with no support or #
# warranties of any kind, including but not limited to       #
# warranties of merchantability or fitness of any kind,      #
# expressed or implied.  This code is subject to the license #
# agreement that accompanies the SDK.                        #
#                                                            #
#============================================================#

import time
import smtplib
import sys
sys.path.append("../../../../lib/python/NetApp")
from NaServer import *

def print_usage():
    print ("monitor_volume.py  <user> <password> \n")
    print ("<user> -- User name\n")
    print ("<password> -- Password\n")
    sys.exit (1)
    
# Get volume information
# Math/Round.py needs to be present in the perl library for this to work.

def get_volume_info():
    s = NaServer (filer, 1, 3)
    response = s.set_style('LOGIN')

    if (response and response.results_errno() != 0) :
        r = response.results_reason()
        print ("Unable to set authentication style " + r + "\n")
        sys.exit (2)

    s.set_admin_user(user, pw)
    response = s.set_transport_type('HTTP')

    if (response and response.results_errno() != 0) :
        r = response.results_reason()
        print ("Unable to set HTTP transport" + r + "\n")
        sys.exit (2)

    for volume in volumes:
        out = s.invoke( "volume-list-info","volume", volume )
        
        if (out.results_status() == "failed"):
            print(out.results_reason() + "\n")
            sys.exit (2)

        volume_info = out.child_get("volumes")
        result = volume_info.children_get()

        global total_volume_size
        global used_volume_size
        global percent_space_avail

        for vol in result:
            total_volume_size = vol.child_get_int("size-total")
            used_volume_size = vol.child_get_int("size-used")
            space_avail = (total_volume_size - used_volume_size)
            percent_space_avail = (float(space_avail)/float(total_volume_size))*100

            if (percent_space_avail < threshold):
                send_mail(volume)

#Read configuration details from volume_config

def read_config_file():
    FILE = open("volume_config")
    global filer
    global poll_frequency
    global threshold
    global mailserver
    global from_addr
    global to_addr

    for content in FILE:

        if(not((re.match(r'#',content)) and (content != ""))):            
            content = content.rstrip()            

            if(re.match(r'filers',content,re.I)):
                tmp = content.split('=')
                filer = tmp[1]

            elif(re.match(r'frequency',content,re.I)):
                tmp = content.split('=')
                poll_frequency = tmp[1]

            elif(re.match(r'volume',content,re.I)):
                tmp = content.split('=')
                volumes.append(tmp[1])

            elif(re.match(r'threshold',content,re.I)):
                tmp = content.split('=')
                threshold = tmp[1]

            elif(re.match(r'mailserver',content,re.I)):
                tmp = content.split('=')
                mailserver = tmp[1]

            elif(re.match(r'mail_to',content,re.I)):
                tmp = content.split('=')
                to_addr = tmp[1]

            elif(re.match(r'mail_from',content,re.I)):
                tmp = content.split('=')
                from_addr = tmp[1]

    FILE.close()


            
 # Send e-mail

def send_mail(vol):
    subject = "Volume usage on filer : " + filer
    Header = "From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n" % (from_addr, to_addr, subject)
    total_size_mb = total_volume_size/(1024 * 1024)
    used_size_mb = used_volume_size/(1024 * 1024)
    msg = "volume Statistics for " + str(vol) + "\nTotal Size  :" + str(total_size_mb) + " MB\nUsed Size   :"\
          + str(used_size_mb) + " MB\n%.2f" % percent_space_avail + "% space available"

    
    message = Header + msg

    try:
        smtpObj = smtplib.SMTP(mailserver)
        smtpObj.sendmail(from_addr, to_addr, message)
       
    except smtplib.SMTPException:
        print("Error: unable to send email")

 
def monitor_volume():
    read_config_file()
    get_volume_info()


args = len(sys.argv) - 1
if(args < 2):
    print_usage()

user = sys.argv[1]
pw = sys.argv[2]
volumes = []

while(1):
    monitor_volume()
    time.sleep(float(poll_frequency))



