#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# snmp.py                                                    #
#                                                            #
# Sample code for the following APIs:                        #
#               snmp-get                                     #
#               snmp-status                                  #
#               snmp-community-add                           #
#               snmp-community-delete                        #
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

def print_usage():
    print("snmp.py <filer> <user> <password> <operation> [<value1>] ")
    print("[<value2>] \n")
    print("<filer> -- Filer name\n")
    print("<user> -- User name\n")
    print("<password> -- Password\n")
    print("<operation> -- Operation to be performed: ")
    print("get/status/addCommunity/deleteCommunity \n")
    print("[<value1>] -- Depends on the operation \n")
    print("[<value2>] -- Depends on the operation \n")
    sys.exit (1)



# SNMP Get operation
# Usage: snmp.py <filer> <user> <password> get <value1(oid)>
def snmp_get(s):
    if (not value1) :
        print_usage()

    out = s.invoke("snmp-get", "object-id", value1)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    print ("-------------------------------------------------------------\n")
    print("Value: " + out.child_get_string("value"))
    print("\n")

    if(out.child_get_string("is-value-hexadecimal")):
        print("Is value hexadecimal: ")
        print(out.child_get_string("is-value-hexadecimal") + "\n")

    print ("-------------------------------------------------------------\n")

# SNMP Status.
# Usage: snmp.py <filer> <user> <password> status
def snmp_status(s):
    out = s.invoke("snmp-status")

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    print("-------------------------------------------------------------\n")
    print("Contact: " + out.child_get_string("contact") + "\n")
    print("Is trap enabled: " + out.child_get_string("is-trap-enabled") + "\n")
    print("Location: " + out.child_get_string("location") + "\n")
    print("-------------------------------------------------------------\n")
    print ("Communities: \n\n")
    communities = out.child_get("communities")
    result = communities.children_get()

    for community in result:
        print("Access control: ")
        print(community.child_get_string("access-control") + "\n")
        print("Community: " + community.child_get_string("community") + "\n")
        print ("------------------------------------------------------------\n")

    print ("Trap hosts: \n\n")
    traphosts = out.child_get("traphosts")
    result = traphosts.children_get()

    for traphost in result:
        print("Host name: " + traphost.child_get_string("host-name") + "\n")
        print("Ip address: " + traphost.child_get_string("ip-address") + "\n")
        print ("------------------------------------------------------------\n")


# Add SNMP community
# Usage: snmp.py <filer> <user> <password> addCommunity <value1(ro/rw)> 
#		<value2(community)>
def add_community(s):
    if (value1 == None or value2 == None) :
        print_usage()

    out = s.invoke( "snmp-community-add", "access-control", value1, "community", value2)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    print ("Added community to the list of communities \n")

#Delete SNMP community
# Usage: snmp.py <filer> <user> <password> deleteCommunity <value1(ro/rw)> 
#		<value2(community)>

def delete_community(s):
    if (not value1 or not value2) :
        print_usage()

    out = s.invoke( "snmp-community-delete", "access-control", value1, "community", value2)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    print ("Deleted community from the list of communities. \n")



def main():
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

    if(command == "get"):
        snmp_get(s)

    elif(command == "status"):
        snmp_status(s)

    elif(command == "addCommunity"):
        add_community(s)

    elif(command == "deleteCommunity"):
        delete_community(s)

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

if(args > 5):
    value1 = sys.argv[5]
    value2 = sys.argv[6]

elif (args == 5):
    value1 = sys.argv[5]
    value2 = None

else:
    value1 = None
    value2 = None
    
main()

