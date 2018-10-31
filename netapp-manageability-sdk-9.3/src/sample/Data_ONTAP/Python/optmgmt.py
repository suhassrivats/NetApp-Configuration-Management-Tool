#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# optmgmt.py                                                 #
#                                                            #
# Sample code for the following APIs:                        #
#               options-get                                  #
#               options-set                                  #
#               options-list-info                            #
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
    print ("optmgmt.py <filer> <user> <password> <operation> [<value1>] ")
    print ("[<value2>] \n")
    print ("<filer> -- Filer name\n")
    print ("<user> -- User name\n")
    print ("<password> -- Password\n")
    print ("<operation> -- Operation to be performed: get/set/optionsList\n")
    print ("[<value1>] -- Name of the option\n")
    print ("[<value2>] -- Value to be set\n")
    sys.exit (1)

    
def get_option_info(s):

    if(args < 5):
        print_usage()

    out = s.invoke("options-get", "name", value1)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)
        
    print("-------------------------------------------------------------\n")
    print("Cluster constraint: " + out.child_get_string("cluster-constraint"))
    print("\n")
    print("Value: " + out.child_get_string("value") + "\n")
    print("-------------------------------------------------------------\n")


def set_option_info(s):

    if(args < 6):
        print_usage()

    out = s.invoke("options-set", "name", value1, "value", value2)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    print ("-------------------------------------------------------------\n")
    print("Cluster constraint: " + out.child_get_string("cluster-constraint"))
    print("\n")

    if(out.child_get_string("message")):
        print("Message: " + out.child_get_string("message") + "\n")
        print ("-------------------------------------------------------------\n")


def options_list_info(s):
    out = s.invoke("options-list-info")

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    options_info = out.child_get("options")
    result = options_info.children_get()

    for opt in result:
        print ("------------------------------------------------------------\n")
        print("Cluster constraint: ")
        print(opt.child_get_string("cluster-constraint") + "\n")
        print("Name: " + opt.child_get_string("name") + "\n")
        print("Value: " + opt.child_get_string("value") + "\n")


def main():
    
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

    if(option == "get"):
        get_option_info(s)

    elif(option == "set"):
        set_option_info(s)

    elif(option == "optionsList"):
        options_list_info(s)

    else:
        print("Invalid Option \n")
        print_usage()

    

    
args = len(sys.argv) - 1

if(args < 4):
        print_usage()
        
filer = sys.argv[1]
user = sys.argv[2]
pw = sys.argv[3]
option = sys.argv[4]

if(args > 5):
    value1 = sys.argv[5]
    value2 = sys.argv[6]
    
elif(args == 5):
    value1 = sys.argv[5]
    
main()



