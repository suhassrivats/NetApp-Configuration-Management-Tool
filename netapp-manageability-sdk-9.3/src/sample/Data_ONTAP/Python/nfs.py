#=======================================================================#
#			                                    		#
# $ID$									#
#								        # 
# nfs.py								#
#									#
# Sample code for the following APIs:					#	
#		nfs-enable, nfs-disable					#
#		nfs-status, nfs-exportfs-list-rules,			#
#								      	#
#									#
#									#
# Copyright 2011 Network Appliance, Inc. All rights 	        	#
# reserved. Specifications subject to change without notice. 	    	#
#									#
# This SDK sample code is provided AS IS, with no support or    	#
# warranties of any kind, including but not limited to		     	#
# warranties of merchantability or fitness of any kind,             	#
# expressed or implied.  This code is subject to the license        	#
# agreement that accompanies the SDK.				    	#
#=======================================================================#


import re
import sys
sys.path.append("../../../../lib/python/NetApp")
from NaServer import *

def print_usage():
    print ("Usage:\n")
    print ("nfs.py <filer> <user> <password> <command>\n")
    print ("<filer> -- Filer name\n")
    print ("<user> -- User name\n")
    print ("<password> -- Password\n")
    print ("<command> -- enable, disable, status, list\n")
    sys.exit(2)


def do_nfs():
    s = NaServer(filer, 1, 3)
    out = s.set_transport_type('HTTP')

    if(out and (out.results_errno() != 0)) :
        r = out.results_reason()
        print("Connection to filer failed" + r + "\n")
        sys.exit(2)

    out = s.set_style('LOGIN')

    if( out and (out.results_errno() != 0)):

        r = out.results_reason()
        print("Connection to filer failed" + r + "\n")
        sys.exit(2)

    out = s.set_admin_user(user, pw)

    if(cmd == "enable"):
        out = s.invoke("nfs-enable")

        if(out.results_status() == "failed"):
            print(out.results_reason() + "\n")
            sys.exit(2)

        else:
            print("Operation successful\n")

    elif (cmd == "disable"):
        out = s.invoke("nfs=disable")

        if(out.results_status == "failed"):
            print(out.results_reason() + "\n")
            sys.exit(2)

        else:
            print("Operation successful\n")

    elif (cmd == "status"):
        out = s.invoke("nfs-status")

        if(out.results_status == "failed"):
            print(out.results_reason() + "\n")
            sys.exit(2)

        enabled = out.child_get_string("is-enabled")

        if(enabled == "true"):
            print("NFS Server is enabled\n")

        else:
            print("NFS Server is disabled\n")

    elif ( cmd == "list") :
        out = s.invoke( "nfs-exportfs-list-rules" )
        export_info = out.child_get("rules")
      
        if(export_info):
            result = export_info.children_get()

        else :
            sys.exit(2)

        for export in result:
            path_name = export.child_get_string("pathname")
            rw_list = "rw="
            ro_list = "ro="
            root_list = "root="
            if(export.child_get("read-only")):
                ro_results = export.child_get("read-only")
                ro_hosts = ro_results.children_get()			
                for ro in ro_hosts:

                    if(ro.child_get_string("all-hosts")):
                        all_hosts = ro.child_get_string("all-hosts")

                        if(all_hosts == "true") :
                            ro_list = ro_list + "all-hosts"
                            break

                    elif(ro.child_get_string("name")) :
                        host_name = ro.child_get_string("name")
                        ro_list = ro_list + host_name + ":"
					
            if(export.child_get("read-write")):
                rw_results = export.child_get("read-write")
                rw_hosts = rw_results.children_get()
                for rw in rw_hosts:

                    if(rw.child_get_string("all-hosts")):
                        all_hosts = rw.child_get_string("all-hosts")

                        if(all_hosts == "true") :
                            rw_list = rw_list + "all-hosts"
                            break

                    elif(rw.child_get_string("name")):
                        host_name = rw.child_get_string("name")
                        rw_list = rw_list + host_name + ":"

            if(export.child_get("root")):
                root_results = export.child_get("root")
                root_hosts = root_results.children_get()

                for root in root_hosts:

                    if(root.child_get_string("all-hosts")):
                        all_hosts = root.child_get_string("all-hosts")

                        if(all_hosts == "true"):
                            root_list = root_list + "all-hosts"
                            break
						
                    elif(root.child_get_string("name")):
                        host_name = root.child_get_string("name")
                        root_list = root_list + host_name + ":"

            path_name = path_name + "  "

            if(ro_list != "ro="):
                path_name = path_name + ro_list

            if(rw_list != "rw=") :
                path_name = path_name + "," + rw_list

            if(root_list != "root="):
                path_name = path_name + "," + root_list

            print(path_name + "\n")

    else :
        print ("Invalid operation\n")
        print_usage()

args = len(sys.argv) - 1

if(args < 4):
    print_usage()
    
filer = sys.argv[1]
user = sys.argv[2]
pw = sys.argv[3]
cmd = sys.argv[4]
do_nfs()



