#==============================================================#
#                                                              #
# $ID$                                                         #
#                                                              #
# vfiler.py                                                    # 
#                                                              #
# This sample code demonstrates how to create, destroy or      #
# list vfiler(s) using ONTAPI APIs                             #
#                                                              #
# Copyright 2011 Network Appliance, Inc. All rights            #
# reserved. Specifications subject to change without notice.   #
#                                                              #
# This SDK sample code is provided AS IS, with no support or   #
# warranties of any kind, including but not limited to         #
# warranties of merchantability or fitness of any kind,        #
# expressed or implied.  This code is subject to the license   #
# agreement that accompanies the SDK.                          #
#                                                              #
#==============================================================#

import sys
sys.path.append("../../../../lib/python/NetApp")
from NaServer import *

def print_usage():
    print("Usage: vfiler.py <filer> <user> <password> <operation> <value1>")
    print("[<value2>] ..\n")
    print("<filer>     -- Name/IP address of the filer\n")
    print("<user>      -- User name\n")
    print("<password>  -- Password\n")
    print("<operation> -- Operation to be performed: ")
    print("create/destroy/list/status/start/stop\n")
    print("[<value1>]    -- Depends on the operation \n")
    print("[<value2>]  -- Depends on the operation \n")
    sys.exit (1)


def vfiler_create(s):
    parse_ip_addr = 1
    no_of_var_arguments = args - 4
    global vfiler
    
    if( args < 9 or sys.argv[6] != "-ip"):
        print ("Usage: vfiler <filer> <user> <password> create <vfiler-name> \n")
        print ("-ip <ip-address1> [<ip-address2>..] -su <storage-unit1> ")
        print ("[<storage-unit2]..] \n")
        sys.exit (1)

    vfiler_in = NaElement("vfiler-create")
    ip_addrs = NaElement("ip-addresses")
    st_units = NaElement("storage-units")

    vfiler_in.child_add_string("vfiler", vfiler)

    # start parsing from <ip-address1>
    i = 7
    while(i < args):
        if(sys.argv[i] == "-su"):
            parse_ip_addr = 0

        else:

            if(parse_ip_addr == 1):
                ip_addrs.child_add_string("ip-address", sys.argv[i])

            else:
                st_units.child_add_string("storage-unit", sys.argv[i])
        i = i + 1

    vfiler_in.child_add(ip_addrs)
    vfiler_in.child_add(st_units)

    # Invoke vfiler-create API
    out = s.invoke_elem(vfiler_in)

    if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)
    
    print ("vfiler created successfully\n")


def vfiler_list(s):
    global vfiler 
    if( vfiler == None ):
        out = s.invoke( "vfiler-list-info")

    else:
        out = s.invoke( "vfiler-list-info", "vfiler", vfiler)

    if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

    vfiler_info = out.child_get("vfilers")
    result = vfiler_info.children_get()

    for vfiler in result:
        vfiler_name = vfiler.child_get_string("name")
        print  ("Vfiler name: " + vfiler_name + " \n")
        ip_space = vfiler.child_get_string("ip_space")

        if(ip_space):
            print  ("ipspace: " + ip_space + " \n")

        uuid = vfiler.child_get_string("uuid")
        print  ("uuid: " + uuid + " \n")
        vfnet_info = vfiler.child_get("vfnets")
        vfnet_result = vfnet_info.children_get()

        for vfnet in vfnet_result:
            print("network resources:\n")
            ip_addr = vfnet.child_get_string("ipaddress")

            if(ip_addr):
                print  ("  ip-address: " + ip_addr + " \n")

            interface = vfnet.child_get_string("interface")

            if(interface):
                print  ("  interface: " + interface + " \n")

        vfstore_info = vfiler.child_get("vfstores")
        vfstore_result = vfstore_info.children_get()

        for vfstore in vfstore_result:
            print("storage resources:\n")
            path = vfstore.child_get_string("path")

            if(path):
                print  ("  path: " + path + " \n")

            status = vfstore.child_get_string("status")

            if(status):
                print  ("  status: " + status + " \n")

            etc = vfstore.child_get_string("is-etc")

            if(etc):
                print  ("  is-etc: etc \n")

        print ("--------------------------------------------\n")
    sys.exit(2)	

def main() :
    s = NaServer(filer, 1, 3)
    resp = s.set_style('LOGIN')
  
    if (resp and resp.results_errno() != 0) :
        r = resp.results_reason()
        print ("Failed to set authentication style " + r + "\n")
        sys.exit (2)

    s.set_admin_user(user, pw)
    resp = s.set_transport_type('HTTP')

    if (resp and resp.results_errno() != 0) :
        r = resp.results_reason()
        print ("Unable to set HTTP transport " + r + "\n")
        sys.exit (2)

    if(command == "create") :
        vfiler_create(s)
	
    elif(command == "list") :
        vfiler_list(s)

    if(args < 5 and (command == "start" or command == "stop" or  command == "status" or  command == "destroy")):
        print ("This operation requires <vfiler-name> \n\n")
        print_usage()

    if(command == "start") :
        out = s.invoke("vfiler-start", "vfiler", vfiler)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)
	
    elif(command == "status") :
        out = s.invoke("vfiler-get-status", "vfiler", vfiler)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)
		
        status = out.child_get_string("status")
        print("status:" + status + "\n")

	
    elif(command == "stop") :
        out = s.invoke("vfiler-stop", "vfiler", vfiler)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

    elif(command == "destroy"):
        out = s.invoke("vfiler-destroy","vfiler",vfiler)

        if(out.results_status() == "failed") :
            print(out.results_reason() + "\n")
            sys.exit(2)

    else :
        print ("Invalid operation\n")
        print_usage()
	
args = len(sys.argv) - 1

if(args < 4):
    print_usage()

filer = sys.argv[1]
user = sys.argv[2]
pw  = sys.argv[3]
command = sys.argv[4]

if(args > 4):
    vfiler = sys.argv[5]

else:
    vfiler = None

main()

