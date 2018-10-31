#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# flexclone.rb                                                  #
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

$:.unshift '../../../../lib/ruby/NetApp'
require 'NaServer'


def print_usage
    print("Usage:flexclone.rb <storage> <user> <password> <command> <clone-volname>")
    print(" [<volume>]\n")
    print("<storage>   -- Storage system name\n")
    print("<user>      -- User name\n")
    print("<password>  -- Password\n")
    print("<command>   -- Possible commands are:\n")
    print("  create   - to create a new clone\n")
    print("  estimate - to estimate the size before splitting the clone\n")
    print("  split    - to split the clone \n")
    print("  status   - to get the clone split status\n")
    print("<clone-volname>    -- clone volume name \n")
    print("[<parent-volname] -- name of the parent volume to create the clone. \n")
    exit 
end


args = ARGV.length
if(args < 5)
    print_usage()
end
$storage = ARGV[0]
$user = ARGV[1]
$pw  = ARGV[2]
$command = ARGV[3]
$clone_name = ARGV[4]
$parent_vol = nil
if(args > 5)
    $parent_vol = ARGV[5]
end



def create_flexclone()
    clone_in = NaElement.new("volume-clone-create")
    clone_in.child_add_string("parent-volume", $parent_vol)
    clone_in.child_add_string("volume", $clone_name)
    # Invoke volume-clone-create API
    out = $s.invoke_elem(clone_in)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
end


def start_flexclone_split()
    clone_in = NaElement.new("volume-clone-split-start")
    clone_in.child_add_string("volume", $clone_name)
    # Invoke volume-clone-split-start API
    out = $s.invoke_elem(clone_in)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    else 
        print("Starting volume clone split on volume '" + $clone_name + "'\nUse")
        print(" 'status' command to monitor progress\n")
    end
end


def estimate_flexclone_split()
    clone_in = NaElement.new("volume-clone-split-estimate")
    clone_in.child_add_string("volume", $clone_name)
    # Invoke volume-clone-split-estimate API
    out = $s.invoke_elem(clone_in)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    else 
        clone_split_estimate = out.child_get("clone-split-estimate")
        clone_split_estimate_info = clone_split_estimate.child_get("clone-split-estimate-info")
        blk_estimate = clone_split_estimate_info.child_get_int("estimate-blocks")
        # block estimate is given in no of 4kb blocks required
        space_req_in_mb = (blk_estimate*4*1024)/(1024*1024)
        print("An estimated of " + space_req_in_mb.to_s + "MB available storage is required")
        print(" in the aggregate to split clone volume '" + $clone_name + "' from")
        print(" its parent.\n")
    end
end


def flexclone_split_status()
    clone_in = NaElement.new("volume-clone-split-status")
    clone_in.child_add_string("volume",$clone_name)
    # Invoke volume-clone-split-status API
    out = $s.invoke_elem(clone_in)
    if(out.results_status() == "failed")
        print(out.results_reason() +"\n")
        exit
    else 
        clone_split_details = out.child_get("clone-split-details")
        result = clone_split_details.children_get()
        print ("\n---------------------------------------------------------------\n")
        result.each do |clone|
            if(clone.child_get_string("name")) 
                tmpCloneName = clone.child_get_string("name")
	    end
            if( $clone_name == tmpCloneName) 
                blk_scanned = clone.child_get_int("blocks-scanned")
                blk_updated = clone.child_get_int("blocks-updated")
                inode_processed = clone.child_get_int("inodes-processed")
                inode_total = clone.child_get_int("inodes-total")
                inode_per_complete = clone.child_get_int("inode-percentage-complete")
                print( "Volume '" + $clone_name + "'" + inode_processed.to_s + " of " + inode_total.to_s+" inodes processed")
                print(" (" + inode_per_complete.to_s + " %).\n" + blk_scanned.to_s + " blocks scanned. " + blk_updated.to_s + " blocks updated.")
            end
            print ("\n----------------------------------------------------------------\n")
        end
    end
end
	

def main
    if(not (($command == "create") or ($command == "estimate") or ($command == "split") or ($command == "status")))
        print($command+" is not a valid command\n")
        print_usage()
    end
    if (($command == "create") and ($parent_vol == nil))
        print($command+" operation requires <parent-volname>\n")
        print("Usage: flexclone.py <storage> <user> <password>"+$command+" <clone-volname> <parent-volname>\n")
        exit 
    end 
    $s = NaServer.new($storage, 1, 3)
    $s.set_admin_user($user, $pw)
    if($command == "create")
        create_flexclone()
    elsif($command == "estimate") 
        estimate_flexclone_split()
    elsif($command == "split") 
        start_flexclone_split()
    elsif($command == "status")
        flexclone_split_status()
    else 
        print("Invalid operation\n")
        print_usage()
    end
end


main()

