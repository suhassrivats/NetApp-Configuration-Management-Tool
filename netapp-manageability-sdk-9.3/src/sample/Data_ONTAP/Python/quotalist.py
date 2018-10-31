#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# quotalist.py                                                  #
#                                                               #
# Sample code for the following APIs:                           #
#               quota-list-entries                              #
#                                                               #
# Copyright 2011 Network Appliance, Inc. All rights             #
# reserved. Specifications subject to change without notice.    #
#                                                               #
# This SDK sample code is provided AS IS, with no support or    #
# warranties of any kind, including but not limited to          #
# warranties of merchantability or fitness of any kind,         #
# expressed or implied.  This code is subject to the license    #
# agreement that accompanies the SDK.                           #
#                                                               #
#===============================================================#

import sys
sys.path.append("../../../../lib/python/NetApp")
from NaServer import *


def print_usage():
    print ("quotalist.py <filer> <user> <password>\n")
    print ("<filer> -- Filer name\n")
    print ("<user> -- User name\n")
    print ("<password> -- Password\n")
    sys.exit (1)

def get_quota_info():
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

    out = s.invoke( "quota-list-entries" )

    if (out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit (2)

    quota_info = out.child_get("quota-entries")
    result = quota_info.children_get()
    print("-----------------------------------------------------\n")

    for quota in result :
        if(quota.child_get_string("quota-target")):
            quota_target = quota.child_get_string("quota-target")
            print  ("Quota Target: " + quota_target + " \n")
            
        if(quota.child_get_string("volume")):
            volume = quota.child_get_string("volume")
            print  ("Volume: " + volume + "\n")

        if(quota.child_get_string("quota-type")):
            quota_type = quota.child_get_string("quota-type")
            print  ("Quota Type: " + quota_type + "\n")

        print ("-----------------------------------------------------\n")



args = len(sys.argv)-1
if(args < 3):
    print_usage()

filer = sys.argv[1]
user = sys.argv[2]
pw = sys.argv[3]
get_quota_info()






