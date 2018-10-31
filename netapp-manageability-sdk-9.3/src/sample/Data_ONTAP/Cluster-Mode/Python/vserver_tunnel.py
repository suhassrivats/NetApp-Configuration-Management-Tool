#============================================================
#
# $ID$
#
# vserver_tunnel.py
# Sample code for vserver tunneling
# The API commands are executed on the specified Vserver
# through the Cluster interface.
#
# Copyright 2011 Network Appliance, Inc. All rights
# reserved. Specifications subject to change without notice.
#
#
#============================================================

import sys
sys.path.append("../../../../../lib/python/NetApp")
from NaServer import * 


def print_usage():
    print ("Usage: \nvserver_tunnel [-s] <vserver-name> <storage_system> <user> \n \
                   <password> <ONTAPI-name> [key value] ...\n \
                   -s : Use SSL\n")
    sys.exit (1)


args = len(sys.argv) - 1
dossl = 0
# check for valid number of parameters
#
if(args < 4) :
    print_usage()

opt = sys.argv[1]

if(re.match(r'-', opt)):
    option = opt.split('-')
    storage = sys.argv[3]
    user = sys.argv[4]
    password = sys.argv[5]
    arguments = sys.argv[6:]

    if(option[1] == "s" and args > 2):
        dossl = 1
        vserver = sys.argv[2]

    else:
        print_usage()

else:
    vserver  = opt
    storage = sys.argv[2]
    user = sys.argv[3]
    password = sys.argv[4] 
    arguments = sys.argv[5:]

# open server
server = NaServer(storage, 1, 15)
if(not server.set_vserver(vserver)):
    sys.exit (1)

server.set_admin_user(user, password)

if (dossl) :
    resp = server.set_transport_type("HTTPS")
    if (resp and resp.results_errno() != 0) :
        r = resp.results_reason()
        print ("Unable to set HTTPS transport " + r + "\n")
        sys.exit (1)
length = len(arguments)
if(length > 0):
    # invoke the api with api name and any supplied key-value pairs
    x = NaElement(arguments[0])
    k = 0
    arguments.remove(arguments[0])
    length = length - 2 
    if((length & 1) != 0):
	while(k <= length):
            key = arguments[k]
            k = k + 1
            value = arguments[k] 
            k = k + 1
            x.child_add(NaElement(key,value))
    else:
    	print("Invalid number of parameters")
    	print_usage()
    xo = server.invoke_elem(x)	
else:
    print_usage() 
if ( xo == None ) :
    print ("Invoking api failed to storage_system as user:password.\n")
    sys.exit (1)

# format the output
print ("Output: \n" + xo.sprintf() + "\n" )

