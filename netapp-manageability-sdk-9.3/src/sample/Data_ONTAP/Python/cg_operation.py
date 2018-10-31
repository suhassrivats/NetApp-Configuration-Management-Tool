#===============================================================#
#						    		#
# $ID$						       		#
#							        #	
# cg_operation.py			       	     		#
#							    	#
# Sample code for the usage of following APIs: 		     	#
#		cg-start				     	#
#		cg-commit				     	#
#							  	# 
# Copyright 2011 Network Appliance, Inc. All rights	  	#
# reserved. Specifications subject to change without notice.    #
#							    	#
# This SDK sample code is provided AS IS, with no support or 	#
# warranties of any kind, including but not limited to       	#
# warranties of merchantability or fitness of any kind,      	#
# expressed or implied.  This code is subject to the license 	#
# agreement that accompanies the SDK.				#
#							        #	
#===============================================================#

import sys
sys.path.append("../../../../lib/python/NetApp")
from NaServer import *

def print_usage():
    print ("cg_operation.py <filer> <user> <password> <operation> <value1>")
    print ("[<value2>] [<volumes>]\n")
    print ("<filer> 	   -- Filer name\n")
    print ("<user>      -- User name\n")
    print ("<password>  -- Password\n")
    print ("<operation> -- Operation to be performed: ")
    print ("cg-start/cg-commit\n")
    print ("<value1>    -- Depends on the operation \n")
    print ("[<value2>]  -- Depends on the operation \n")
    print ("[<volumes>] --List of volumes.Depends on the operation \n")
    sys.exit (1)

	
def main():
    # check for valid number of parameters
    s = NaServer (filer, 1, 3)

    s.set_admin_user(user, pw)
    response = s.set_transport_type('HTTP')

    if (response and response.results_errno() != 0) :
        r = response.results_reason()
        print ("Unable to set HTTP transport" + r + "\n")
        sys.exit (2)
        
    if(command == "cg-start"):
        cg_start(s)

    elif(command == "cg-commit"):
        cg_commit(s)

    else:
        print ("Invalid operation\n")
        print_usage()


# cg-start operation
# Usage: cg_operation.py <filer> <user> <password> cg-start <snapshot> <timeout>
# <volumes>   
def cg_start(s):
    if (args < 7) :
        print ("cg_operation.py <filer> <user> <password> cg-start ")
        print (" <snapshot> <timeout> <volumes> \n")
        sys.exit (1)

    cg_in = NaElement("cg-start")
    cg_in.child_add_string("snapshot", value1)
    cg_in.child_add_string("timeout", value2)
    vols= NaElement("volumes")

    #Now store rest of the volumes as a child element of vols
    ##Here no_of_var_arguments stores the total  no of volumes
    #Note:First volume is specified at 7th position from cmd prompt input
    no_of_var_arguments = args

    i = 7
    while(i <= no_of_var_arguments):
        vols.child_add_string("volume-name", sys.argv[i])
        i = i + 1

    cg_in.child_add(vols)
    # # Invoke cg-start API 	#
    out = s.invoke_elem(cg_in)
   
    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit (2)

    cg_id = out.child_get_string( "cg-id" )
    print ("Consistency Group operation started successfully with cg-id=" + cg_id + "\n")


# cg-commit operation
# Usage: cg_operation.py <filer> <user> <password> cg-commit <cg-id> 
def cg_commit(s):
    if (args < 5):
        print ("cg_operation.py <filer> <user> <password> cg-commit ")
        print ("<cg-id> \n")
        sys.exit (1)
        
    ## Invoke cg-commit API	#
    out = s.invoke("cg-commit", "cg-id", value1)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    print ("Consistency Group operation commited successfully\n")


args = len(sys.argv) - 1

if(args < 5):
    print_usage()

filer = sys.argv[1]
user = sys.argv[2]
pw = sys.argv[3]
command = sys.argv[4]
value1 = sys.argv[5]

if(args > 5):
    value2 = sys.argv[6]

main()

