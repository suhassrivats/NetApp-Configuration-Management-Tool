#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# snapmirror.py                                              #
#                                                            #
# Sample code for the following APIs:                        #
#               snapmirror-get-status                        #
#               snapmirror-get-volume-status                 #
#               snapmirror-off                               #
#               snapmirror-on                                #
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

import sys
sys.path.append("../../../../lib/python/NetApp")
from NaServer import *

def print_usage() :
    print("snapmirror.py <filer> <user> <password> <operation> [<value1>]\n ")
    print("<filer> -- Filer name\n")
    print("<user> -- User name\n")
    print("<password> -- Password\n")
    print("<operation> -- Operation to be performed: ")
    print("getStatus/getVolStatus/off/on \n")
    print("[<value1>] -- Depends on the operation\n")
    sys.exit (1)


# Snapmirror get status
# Usage: snapmirror.py <filer> <user> <password> getStatus [<value1(location)>]
def get_status(s):
    if (not value1) :
        out = s.invoke("snapmirror-get-status")

    else:
        out = s.invoke("snapmirror-get-status", "location", value1)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    print ("-------------------------------------------------------------\n")
    print("Is snapmirror available: " + out.child_get_string("is-available"))
    print("\n")
    print ("-------------------------------------------------------------\n\n")
    status = out.child_get("snapmirror-status")

    if(not(status == None)):
        result = status.children_get()

    else:
        sys.exit(0)

    for snapStat in result:
        print("Contents: " + snapStat.child_get_string("contents") + "\n")
        print("Destination location: ")
        print(snapStat.child_get_string("destination-location") + "\n")
        print("Lag time: " + snapStat.child_get_string("lag-time") + "\n")
        print("Last transfer duration: ")
        print(snapStat.child_get_string("last-transfer-duration") + "\n")
        print("Last transfer from: ")
        print(snapStat.child_get_string("last-transfer-from") + "\n")
        print("Last transfer size: ")
        print(snapStat.child_get_string("last-transfer-size") + "\n")
        print("Mirror timestamp: ")
        print(snapStat.child_get_string("mirror-timestamp") + "\n")
        print("Source location: ")
        print(snapStat.child_get_string("source-location") + "\n")
        print("State: " + snapStat.child_get_string("state") + "\n")
        print("Status: " + snapStat.child_get_string("status") + "\n")
        print("Transfer progress: ")
        print(snapStat.child_get_string("transfer-progress") + "\n")
        print("------------------------------------------------------------\n")


def get_vol_status(s):
    if (not value1) :
	    print_usage()
	
    out = s.invoke("snapmirror-get-volume-status", "volume", value1)
	
    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)
    print ("-------------------------------------------------------------\n")
    print("Is destination: " + out.child_get_string("is-destination") + "\n")
    print("Is source: " + out.child_get_string("is-source") + "\n")
    print("Is transfer broken: " + out.child_get_string("is-transfer-broken") + "\n")
    print("Is transfer in progress: " + out.child_get_string("is-transfer-in-progress") + "\n")
    print ("-------------------------------------------------------------\n\n")


# Snapmirror off
# Usage: snapmirror.py <filer> <user> <password> off
def snapmirror_off(s):
    out = s.invoke( "snapmirror-off")

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    print ("Disabled SnapMirror data transfer and turned off the SnapMirror scheduler \n")
    

# Snapmirror on
# Usage: snapmirror.py <filer> <user> <password> on
def snapmirror_on(s):
    out = s.invoke( "snapmirror-on")

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    print ("Enabled SnapMirror data transfer and turned on the SnapMirror scheduler \n")



def main():
    s = NaServer(filer, 1, 3)
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

    if(command == "getStatus"):
        get_status(s)

    elif(command == "getVolStatus"):
        get_vol_status(s)

    elif(command == "off"):
        snapmirror_off(s)

    elif(command == "on"):
        snapmirror_on(s)

    else:
        print ("Invalid operation\n")
        print_usage()

  
    

args = len(sys.argv) - 1

if(args < 4):
    print_usage()
    
filer = sys.argv[1]
user = sys.argv[2]
pw = sys.argv[3]
command = sys.argv[4]

if(args > 4):
    value1 = sys.argv[5]
else:
    value1 = None

main()

