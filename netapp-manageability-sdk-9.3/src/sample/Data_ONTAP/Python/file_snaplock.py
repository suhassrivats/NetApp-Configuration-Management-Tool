#===============================================================#
#						    	        #
# $ID$						       		#
#							    	#
# file_snaplock.py			       	     	        #
#							    	#
# Sample code for the usage of following APIs: 		     	#
#		file-get-snaplock-retention-time   		#
#		file-snaplock-retention-time-list-info		#	
#		file-set-snaplock-retention-time		#
#		file-get-snaplock-retention-time-list-info-max	#
#							    	#
# Copyright 2011 Network Appliance, Inc. All rights	  	#
# reserved. Specifications subject to change without notice.    #
#							    	#
# This SDK sample code is provided AS IS, with no support or    #
# warranties of any kind, including but not limited to          #
# warranties of merchantability or fitness of any kind,         #
# expressed or implied.  This code is subject to the license    #
# agreement that accompanies the SDK.			        #	
#							    	#
#===============================================================#

import sys
sys.path.append("../../../../lib/python/NetApp")
from NaServer import *

def print_usage():
    print("file_snaplock.py <filer> <user> <password> <operation> <value1>")
    print("[<value2>]\n")
    print("<filer>     -- Filer name\n")
    print("<user>      -- User name\n")
    print("<password>  -- Password\n")
    print("<operation> -- Operation to be performed: \n")
    print("\tfile-get-snaplock-retention-time\n")
    print("\tfile-set-snaplock-retention-time\n")
    print("\tfile-snaplock-retention-time-list-info\n")
    print("\tfile-get-snaplock-retention-time-list-info-max\n")
    print("<value1>    -- Depends on the operation \n")
    print("[<value2>]  -- Depends on the operation \n")
    sys.exit (1)


# file-snaplock-retention-time-list-info operation
# Usage: file_snaplock.py <filer> <user> <password> file-snaplock-retention-time-list-info <filepath>
# <volumes>   
def file_get_retention_list(s):
    if (args < 5):
        print ("Usage: file_snaplock.py <filer> <user> <password> file-snaplock-retention-time-list-info")
        print (" <filepathnames> \n")
        sys.exit (1)

    file_in = NaElement("file-snaplock-retention-time-list-info")
    pathnames = NaElement("pathnames")
    pathname_info = NaElement("pathname-info")

    #Now store rest of the volumes as a child element of pathnames
    #Here no_of_vols stores the total  no of volumes
    #Note:First volume is specified at 5th position from cmd prompt input

    i = 5
    while(i < len(sys.argv)):
        pathname_info.child_add_string("pathname", sys.argv[i])
        i = i + 1

    pathnames.child_add(pathname_info)
    file_in.child_add(pathnames)

    # Invoke API
    out = s.invoke_elem(file_in)
    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    retention_info = out.child_get("file-retention-details")
    result = retention_info.children_get()

    for path in result:
        formatted_date = path.child_get_string("formatted-retention-time")
        filepath = path.child_get_string("pathname")
        print("Retention date for the file" + filepath + " is " + str(formatted_date) + "\n")

    print("\n")


# file-get-snaplock-retention-time operation
# Usage: file_snaplock.py <filer> <user> <password> file-get-snaplock-retention-time <filepathnames>
def file_get_retention(s):
    if (args < 5) :
        print ("Usage: file_snaplock.py <filer> <user> <password> file-get-snaplock-retention-time")
        print (" <filepathnames> \n")
        sys.exit (1)

    file_in = NaElement("file-get-snaplock-retention-time")
    path = sys.argv[5]
    file_in.child_add_string("path", path)

    # Invoke API
    out = s.invoke_elem(file_in)
    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)
		
    retention_time = out.child_get_int("retention-time")
    print ("retention time: " + str(retention_time) + "\n")
    print ("\n")


# file-set-snaplock-retention-time operation
# Usage: file_snaplock.py <filer> <user> <password> file-set-snaplock-retention-time <filepathnames>
def file_set_retention(s):
    if (args < 6) :
        print ("Usage: file_snaplock.py <filer> <user> <password> file-set-snaplock-retention-time")
        print (" <filepathnames> <retention-time>\n")
        sys.exit (1)

    path = sys.argv[5]
    retention_time = sys.argv[6]
    file_in = NaElement("file-set-snaplock-retention-time")
    file_in.child_add_string("path", path)
    file_in.child_add_string("retention-time", retention_time)

    # Invoke API
    out = s.invoke_elem(file_in)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)
    
    print ("\n")


# file-get-snaplock-retention-time-list-info-max operation
# Usage: file_snaplock.py <filer> <user> <password> file-get-snaplock-retention-time <filepathnames>
def file_get_retention_list_info_max(s):
    file_in = NaElement("file-get-snaplock-retention-time-list-info-max")

    # Invoke API
    out = s.invoke_elem(file_in)
    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    max_entries = out.child_get_int("max-list-entries")
    print ("Max number of records = " + str(max_entries) + " \n")


def main():
    s = NaServer (filer, 1, 3)
    resp = s.set_transport_type('HTTP')

    if (resp and resp.results_errno() != 0) :
        r = resp.results_reason()
        print ("Unable to set HTTP transport " + r + "\n")
        sys.exit (2)

    resp = s.set_style('LOGIN')
    
    if (resp and resp.results_errno() != 0) :
        r = resp.results_reason()
        print ("Failed to set authentication style " + r + "\n")
        sys.exit (2)

    s.set_admin_user(user, pw)

    if(command == "file-get-snaplock-retention-time"):
        file_get_retention(s)

    elif(command == "file-set-snaplock-retention-time"):
        file_set_retention(s)

    elif(command == "file-snaplock-retention-time-list-info"):
        file_get_retention_list(s)

    elif(command == "file-get-snaplock-retention-time-list-info-max"):
        file_get_retention_list_info_max(s)

    else:
        print ("Invalid operation\n")
        print_usage()


args = len(sys.argv) - 1

if(args < 4):
    print_usage()
    
filer = sys.argv[1]
user = sys.argv[2]
pw  = sys.argv[3]
command = sys.argv[4]
main()


