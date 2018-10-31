#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# flexclone.py                                                  #
#                                                               #
# Sample code for the usage of flexclone:                       #
# It demonstrates the following functions:                      #
# create a clone for a flexible volume, estimate the size,      #
# split the clone and print the status of it.                   #
#                                                               #
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
    print("Usage:flexclone.py <filer> <user> <password> <command> <clone-volname>")
    print(" [<volume>]\n")
    print("<filer>     -- Filer name\n")
    print("<user>      -- User name\n")
    print("<password>  -- Password\n")
    print("<command>   -- Possible commands are:\n")
    print("  create   - to create a new clone\n")
    print("  estimate - to estimate the size before splitting the clone\n")
    print("  split    - to split the clone \n")
    print("  status   - to get the clone split status\n")
    print("<clone-volname>    -- clone volume name \n")
    print("[<parent-volname] -- name of the parent volume to create the clone. \n")
    sys.exit (1)


def create_flexclone(s):
    clone_in = NaElement("volume-clone-create")
    clone_in.child_add_string("parent-volume", parent_vol)
    clone_in.child_add_string("volume", clone_name)

    # Invoke volume-clone-create API
    out = s.invoke_elem(clone_in)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)
    

def start_flexclone_split(s):
    clone_in = NaElement("volume-clone-split-start")
    clone_in.child_add_string("volume", clone_name)

    # Invoke volume-clone-split-start API
    out = s.invoke_elem(clone_in)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)
    
    else :
        print("Starting volume clone split on volume '" + clone_name + "'\nUse")
        print(" 'status' command to monitor progress\n")


def estimate_flexclone_split(s):
    clone_in = NaElement("volume-clone-split-estimate")
    clone_in.child_add_string("volume", clone_name)

    # Invoke volume-clone-split-estimate API
    out = s.invoke_elem(clone_in)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)
    
    else :
        clone_split_estimate = out.child_get("clone-split-estimate")
        clone_split_estimate_info = clone_split_estimate.child_get("clone-split-estimate-info")
        blk_estimate = clone_split_estimate_info.child_get_int("estimate-blocks")
        # block estimate is given in no of 4kb blocks required
        space_req_in_mb = (blk_estimate*4*1024)/(1024*1024)
        print("An estimated of " + str(space_req_in_mb) + " MB available storage is required")
        print(" in the aggregate to split clone volume '" + clone_name + "' from")
        print(" its parent.\n")


def flexclone_split_status(s):
    clone_in = NaElement("volume-clone-split-status")
    clone_in.child_add_string("volume", clone_name)

    # Invoke volume-clone-split-status API
    out = s.invoke_elem(clone_in)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)
    
    else :
        clone_split_details = out.child_get("clone-split-details")
        result = clone_split_details.children_get()
        print ("\n---------------------------------------------------------------\n")
        for clone in result:

            if(clone.child_get_string("name")) :
                tmpCloneName = clone.child_get_string("name")

            if( clone_name == tmpCloneName) :
                blk_scanned = clone.child_get_int("blocks-scanned")
                blk_updated = clone.child_get_int("blocks-updated")
                inode_processed = clone.child_get_int("inodes-processed")
                inode_total = clone.child_get_int("inodes-total")
                inode_per_complete = clone.child_get_int("inode-percentage-complete")
                print( "Volume '" + clone_name + "'" + str(inode_processed) + " of " + str(inode_total) + " inodes processed")
                print(" (" + str(inode_per_complete) + " %).\n" + str(blk_scanned) + " blocks scanned. " + str(blk_updated) + " blocks updated.")

        print ("\n---------------------------------------------------------------\n")
		
def main():

    if(not ((command == "create") or (command == "estimate") or (command == "split") or (command == "status"))):
        print(command + " is not a valid command\n")
        print_usage()

    if ((command == "create") and (parent_vol == None)):
        print(command + " operation requires <parent-volname>\n")
        print("Usage: flexclone.py <filer> <user> <password>" + command + " <clone-volname> <parent-volname>\n")
        sys.exit (2)

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

    if(command == "create"):
        create_flexclone(s)

    elif(command == "estimate") :
        estimate_flexclone_split(s)

    elif(command == "split") :
        start_flexclone_split(s)

    elif(command == "status"):
        flexclone_split_status(s)

    else :
        print ("Invalid operation\n")
        print_usage()

  
        
args = len(sys.argv) - 1

if(args < 5):
    print_usage()
    
filer = sys.argv[1]
user = sys.argv[2]
pw  = sys.argv[3]
command = sys.argv[4]
clone_name = sys.argv[5]

if(args > 5):
    parent_vol = sys.argv[6]
else :
    parent_vol = None
main()

