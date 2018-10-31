#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# qtree_quota.py                                             #
#                                                            #
# Creates qtree on volume and adds quota entry.              #
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

def create_qtree_quota():
    
    s = NaServer(filer, 1, 3)
    response = s.set_style('LOGIN')

    if(response and response.results_errno() != 0 ):
        r = response.results_reason()
        print ("Unable to set authentication style " + r + "\n")
        sys.exit (2)

    s.set_admin_user(user, pw)
    response = s.set_transport_type('HTTP')

    if(response and response.results_errno() != 0 ):
        r = response.results_reason()
        print ("Unable to set transport type " + r + "\n")
        sys.exit (2)

    if(args >  5):
        out = s.invoke("qtree-create", "qtree", qtree, "volume", volume, "mode", mode )

    else :
        out = s.invoke( "qtree-create", "qtree", qtree, "volume", volume)

    if (out.results_status() == "failed"):
        print(out.results_reason())
        print("\n")
        sys.exit (2)

    print ("Created new qtree\n")

def print_usage():
    print ("Usage:\n")
    print ("python qtree_quota.py <filer> <user> <passwd> ")
    print ("<volume> <qtree> [<mode>] \n")
    print ("<filer> -- Filer name\n")
    print ("<user> -- User name\n")
    print ("<passwd> -- Password\n")
    print ("<volume> -- Volume name\n")
    print ("<qtree> -- Qtree name\n")
    print ("<mode> -- The file permission bits of the qtree.")
    print (" Similar to UNIX permission bits: 0755 gives ")
    print ("read/write/execute permissions to owner and ")
    print ("read/execute to group and other users.\n")
    sys.exit (1)

args = len(sys.argv) - 1

if(args < 5):
    print_usage()

filer = sys.argv[1]
user = sys.argv[2]
pw = sys.argv[3]
volume = sys.argv[4]
qtree = sys.argv[5]

if(args > 5):
    mode = sys.argv[6]

create_qtree_quota()




    
        

