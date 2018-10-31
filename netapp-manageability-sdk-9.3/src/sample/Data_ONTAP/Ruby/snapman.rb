#============================================================#
#                                                            #
# $Id$                                                       #
#                                                            #
# snapman.rb                                                 #
#                                                            #
# Snapshot management using ONTAPI interfaces in Python      #
#                                                            #
# Copyright 2011 Network Appliance, Inc. All rights    	     #
# reserved. Specifications subject to change without notice. #
#                                                            #
# This SDK sample code is provided AS IS, with no support or #
# warranties of any kind, including but not limited to       #
# warranties of merchantability or fitness of any kind,      #
# expressed or implied.  This code is subject to the license #
# agreement that accompanies the SDK.                        #
#                                                            #
# tab size = 8                                               #
#                                                            #
#============================================================#

$:.unshift '../../../../lib/ruby/NetApp'
require 'NaServer'

def print_usage
    print("snapman.rb -g <storage> <user> <pw> <vol> \n")
    print("           -l <storage> <user> <pw> <vol> \n")
    print("           -c <storage> <user> <pw> <vol> <snapshotname> \n")
    print("           -r <storage> <user> <pw> <vol> <oldsnapshotname> <newname> \n")
    print("           -d <storage> <user> <pw> <vol> <snapshotname>\n")
    print("\n")
    print("\t-g : get schedules for the snapshots on a storage system volume\n")
    print("\t-l : list the snapshots on a storage system volume\n")
    print("\t-c : create a snapshot on a storage system volume\n")
    print("\t-r : rename a snapshot on a storage system volume\n")
    print("\t-d : delete a snapshot from a storage system volume\n")
    exit
end

args = ARGV.length
if(args < 5)
    print_usage() 
end
opt = ARGV[0]
storage = ARGV[1]
user = ARGV[2]
pw = ARGV[3]
vol = ARGV[4]
s = NaServer.new(storage, 1, 1)
s.set_admin_user(user, pw)

#
# snapshot-get-schedule
#
if (opt == "-g") 
    output = s.invoke("snapshot-get-schedule", "volume", vol)
    if (output.results_errno() != 0) 
        r = output.results_reason()
        print ("snapshot-get-schedule failed:" + r + "\n")
    end	
    minutes = output.child_get_int("minutes")
    hours =   output.child_get_int("hours")
    days =    output.child_get_int("days")
    weeks =   output.child_get_int("weeks")
    whichhours = output.child_get_string("which-hours")
    whichminutes = output.child_get_string("which-minutes")
    print("\n")
    print("Snapshot schedule for volume " + vol + " on storage system " + storage + "\n\n")
    if (minutes > 0) 
        print("Snapshots are taken on minutes [" + whichminutes + "] of each hour (" + minutes.to_s + " kept)\n")
    end	
    if (hours > 0) 
        print("Snapshots are taken on hours [" + whichhours + "] of each day (" + hours.to_s + " kept)\n")
    end	
    if (days > 0) 
        print(days.to_s + "nightly snapshots are kept\n")
    end	
    if (weeks)
        print(weeks.to_s + " weekly snapshots are kept\n")
    end	
    if (minutes == 0 and hours == 0 and days == 0 and weeks == 0) 
        print("No snapshot schedule\n")
    end	
    print("\n")

#
# snapshot-list-info
#
elsif (opt == "-l") 
    output = s.invoke("snapshot-list-info", "volume", vol)
    if (output.results_errno() != 0) 
        r = output.results_reason()
        print ("snapshot-list-info failed:" + r + "\n")
    end
    # # get snapshot list
    snapshotlist = output.child_get("snapshots")    
    if ((snapshotlist == nil) or (snapshotlist == "")) 
        # no snapshots to report
        print("No snapshots on volume " + vol + "\n\n")
        exit
    end
    ## print header
    print("Snapshots on volume " + vol + "\n\n")
    print("NAME                    DATE                    BUSY     NBLOCKS     CUMNBLOCKS  DEPENDENCY\n")
    print("-------------------------------------------------------------------------------------------\n")
    # iterate through snapshot list
    snapshots = snapshotlist.children_get()
    for ss in snapshots do
        accesstime = Float(ss.child_get_int("access-time"))
        total =  ss.child_get_int("total")
        cumtotal =   ss.child_get_int("cumulative-total")
        busy = (ss.child_get_string("busy") == "true")
        dependency = ss.child_get_string("dependency")
        name = ss.child_get_string("name")
	date = Time.at(accesstime)
	print("%-23s %-24s %s %10s %10s %10s" % [name,date.strftime("%Y-%m-%d"),busy,total,cumtotal,dependency])
	print("\n")
    end
	
# snapshot-create
elsif (opt == "-c") 
    if(args < 6) 
	print_usage() 
    end
    name = ARGV[5]
    output = s.invoke("snapshot-create","volume", vol,"snapshot", name)
    if (output.results_errno() != 0) 
        r = output.results_reason()
        print ("snapshot-create failed:" + r + "\n")
	exit
    end
	
# snapshot-rename
elsif (opt == "-r")
    if(args < 7)
	print_usage() 
    end
    currname = ARGV[5]
    newname = ARGV[6]
    output = s.invoke("snapshot-rename","volume", vol, "current-name", currname, "new-name", newname)
    if (output.results_errno != 0) 
        r = output.results_reason()
        print ("snapshot-rename failed:" + r + "\n")
	exit
    end

# snapshot-delete
elsif (opt == "-d")
    if(args < 6)
	print_usage()
    end
    name = ARGV[5]
    output = s.invoke("snapshot-delete", "volume", vol, "snapshot", name)    
    if (output.results_errno() != 0) 
        r = output.results_reason()
        print("snapshot-delete failed:" + r + "\n")
	exit		
    end
end
