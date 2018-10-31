#============================================================#
#                                                            # 
# $Id$							     #
#                                                            #
# snapman.py                                                 #
#                                                            #
# Snapshot management using ONTAPI interfaces in Python      #
#                                                            #
# Copyright 2011 Network Appliance, Inc. All rights     #
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

import time
import sys
sys.path.append("../../../../lib/python/NetApp")
from NaServer import *


def print_usage():
    print("snapman.py -g <filer> <user> <pw> <vol> \n")
    print("           -l <filer> <user> <pw> <vol> \n")
    print("           -c <filer> <user> <pw> <vol> <snapshotname> \n")
    print("           -r <filer> <user> <pw> <vol> <oldsnapshotname> <newname> \n")
    print("           -d <filer> <user> <pw> <vol> <snapshotname>\n")
    sys.exit(1)


args = len(sys.argv) - 1

if(args < 5):
    print_usage()
    
opt = sys.argv[1]
filer = sys.argv[2]
user = sys.argv[3]
pw = sys.argv[4]
vol = sys.argv[5]
s = NaServer(filer, 1, 1)
s.set_admin_user(user, pw)

#
# snapshot-get-schedule
#
if (opt == "-g") :
    output = s.invoke("snapshot-get-schedule", "volume", vol)

    if (output.results_errno() != 0) :
        r = output.results_reason()
        print ("snapshot-get-schedule failed:" + r + "\n")

    minutes = output.child_get_int("minutes")
    hours =   output.child_get_int("hours")
    days =    output.child_get_int("days")
    weeks =   output.child_get_int("weeks")
    whichhours = output.child_get_string("which-hours")
    whichminutes = output.child_get_string("which-minutes")
    print("\n")
    print("Snapshot schedule for volume " + vol + " on filer " + filer + "\n\n")

    if (minutes > 0) :
        print("Snapshots are taken on minutes [" + whichminutes + "] of each hour (" + str(minutes) + " kept)\n")

    if (hours > 0) :
        print("Snapshots are taken on hours [" + whichhours + "] of each day (" + str(hours) + " kept)\n")

    if (days > 0) :
        print(str(days) + " nightly snapshots are kept\n")

    if (weeks > 0):
        print(str(weeks) + " weekly snapshots are kept\n")

    if (minutes == 0 and hours == 0 and days == 0 and weeks == 0) :
        print("No snapshot schedule\n")

    print("\n")

#
# snapshot-list-info
#
elif (opt == "-l") :
    output = s.invoke("snapshot-list-info", "volume", vol)

    if (output.results_errno() != 0) :
        r = output.results_reason()
        print ("snapshot-list-info failed:" + r + "\n")

    # # get snapshot list
    snapshotlist = output.child_get("snapshots")
    if ((snapshotlist == None) or (snapshotlist == "")) :
        # no snapshots to report
        print("No snapshots on volume " + vol + "\n\n")
        sys.exit(0)

    ## print header
    print("Snapshots on volume " + vol + "\n\n")
    print("NAME                    DATE                    BUSY     NBLOCKS     CUMNBLOCKS  DEPENDENCY\n")
    print("-------------------------------------------------------------------------------------------\n")

    # iterate through snapshot list
    snapshots = snapshotlist.children_get()

    for ss in snapshots:
        accesstime = float(ss.child_get_int("access-time"))
        total =	 ss.child_get_int("total")
        cumtotal =   ss.child_get_int("cumulative-total")
        busy = (ss.child_get_string("busy") == "true")
        dependency = ss.child_get_string("dependency")
        name = ss.child_get_string("name")
        date = time.localtime(accesstime)
        print("%-23s %-24s %s %10s %10s %10s" % (name, time.strftime("%Y-%m-%d", date), busy, total, cumtotal, dependency))

# snapshot-create
elif (opt == "-c") :
    if(args < 6):
        print_usage()

    name = sys.argv[6]
    output = s.invoke("snapshot-create", "volume", vol, "snapshot", name)

    if (output.results_errno() != 0) :
        r = output.results_reason()
        print ("snapshot-create failed:" + r + "\n")
        sys.exit(2)

# snapshot-rename
elif (opt == "-r"):
    if(args < 7):
        print_usage()

    currname = sys.argv[6]
    newname = sys.argv[7]

    output = s.invoke("snapshot-rename", "volume", vol, "current-name", currname, "new-name", newname)

    if (output.results_errno() != 0) :
        r = output.results_reason()
        print ("snapshot-rename failed:" + r + "\n")
        sys.exit(2)

# snapshot-delete
elif (opt == "-d"):
    if(args < 6):
        print_usage()

    name = sys.argv[6]
    output = s.invoke("snapshot-delete", "volume", vol, "snapshot", name)
    if (output.results_errno() != 0) :
        r = output.results_reason()
        print ("snapshot-delete failed:" + r + "\n")

else :
    print_usage()
	






