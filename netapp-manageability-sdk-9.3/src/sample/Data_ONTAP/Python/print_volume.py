#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# print_volume.py                                            #
#                                                            #
# Retrieves & prints volume information.                     #
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

def get_volume_info():


    args = len(sys.argv) - 1
    
    if(args < 3):
        print_usage()
 
    filer = sys.argv[1]
    user = sys.argv[2]
    pw = sys.argv[3]
   
    if(args == 4):
        volume = sys.argv[4]

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
        print ("Unable to set HTTP transport " + r + "\n")
        sys.exit (2)

    if(args == 3):
        out = s.invoke("volume-list-info")

    else:
        out = s.invoke("volume-list-info", "volume", volume)

    if(out.results_status() == "failed"):
        print (out.results_reason() + "\n")
        sys.exit (2)

    volume_info = out.child_get("volumes")
    result = volume_info.children_get()

    for vol in result:
        vol_name = vol.child_get_string("name")
        print ("Volume name :" + vol_name + "\n")
        size_total = vol.child_get_int("size-total")
        print ("Total size: " + str(size_total) + " bytes \n")
        size_used = vol.child_get_int("size-used")
        print ("Used Size : " + str(size_used) + " bytes\n")
        print ("-------------------------------------------\n")


def print_usage():
    print ("Usage: \n")
    print ("python print_volume.py <filer> <user> <password>")
    print (" [<volume>]\n")
    sys.exit (1)

get_volume_info()

    
