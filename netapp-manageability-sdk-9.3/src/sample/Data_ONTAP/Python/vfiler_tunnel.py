#============================================================
#
# $ID$
#
# vfiler_tunnel.py
#
# Sample code for vfiler_tunneling
# This sample code demonstrates how to execute ONTAPI APIs on a
# vfiler through the physical filer
#
# Copyright 2011 Network Appliance, Inc. All rights
# reserved. Specifications subject to change without notice.
#
# This SDK sample code is provided AS IS, with no support or
# warranties of any kind, including but not limited to
# warranties of merchantability or fitness of any kind,
# expressed or implied.  This code is subject to the license
# agreement that accompanies the SDK.
#
# tab size = 4
#
#============================================================

import sys
sys.path.append("../../../../lib/python/NetApp")
from NaServer import *

def print_usage():
    print ("Usage: \n vfiler_tunnel [-s] <vfiler-name> <filer> <user> <password> <ONTAPI-name> [key value] ...\n")
    print (" -s	: Use SSL\n")
    sys.exit (1)

args = len(sys.argv) - 1
dossl = 0
# check for valid number of parameters
#
if (args <= 0) :
    print_usage()
elif (sys.argv[1] == "-s" and len(sys.argv) < 7) :
    print_usage()
elif(len(sys.argv) < 6) :
    print_usage()

opt = sys.argv[1]

if(re.match(r'-', opt)):
    option = opt.split('-')
    filer = sys.argv[3]
    user = sys.argv[4]
    password = sys.argv[5]
    arguments = sys.argv[6:]

    if(option[1] == "s" and args > 2):
        dossl = 1
        vfiler = sys.argv[2]

    else:
        print_usage()

else:
    vfiler  = opt
    filer = sys.argv[2]
    user = sys.argv[3]
    password = sys.argv[4] 
    arguments = sys.argv[5:]


# open server
server = NaServer(filer, 1, 7)

if(not server.set_vfiler(vfiler)):
    print ("Error: ONTAPI version must be at least 1.7 to send API to a vfiler\n")
    sys.exit (2)

server.set_admin_user(user, password)

if (dossl) :
    resp = server.set_transport_type("HTTPS")
    
    if (resp and resp.results_errno() != 0) :
        r = resp.results_reason()
        print ("Unable to set HTTPS transport " + r + "\n")
        sys.exit (2)

if(len(arguments) > 0):
    # invoke the api with api name and any supplied key-value pairs
    x = NaElement(arguments[0])
    k = 0
    arguments.remove(arguments[0])
    length = len(arguments) - 1 
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
    print ("invoke_api failed to filer as user:password.\n")
    sys.exit (3)

# format the output
print ("Output: \n" + xo.sprintf() + "\n" )




