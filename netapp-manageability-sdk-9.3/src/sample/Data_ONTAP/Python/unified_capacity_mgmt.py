#==============================================================#
#                                                              #
# $ID$                                                         #
#                                                              #
# user_capacity_mgmt.py                                        #
#                                                              #
# This sample code demonstrates the usage of ONTAPI APIs       #
# for doing capacity management for NetApp storage systems.    #
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
    print("Usage: user_capacity_mgmt.py <filer> <user> <password> <command> \n")
    print("<filer>     -- Name/IP address of the filer\n")
    print("<user>      -- User name\n")
    print("<password>  -- Password\n\n")
    print("Possible commands are:\n")
    print("raw-capacity [<disk>] \n")
    print("formatted-capacity [<disk>] \n")
    print("spare-capacity \n")
    print("raid-overhead [<aggregate>] \n")
    print("wafl-overhead [<aggregate>] \n")
    print("allocated-capacity [<aggregate>] \n")
    print("provisioning-capacity [<aggregate>] \n")
    print("avail-user-data-capacity [<volume>] \n")
    sys.exit (1)


def calc_allocated_capacity(s):
    total_alloc_cap = 0
    out_str = "total"

    aggr_in = NaElement("aggr-space-list-info")

    if( args > 4):
        aggr_in.child_add_string("aggregate", sys.argv[5])
        out_str = ""

    out = s.invoke_elem(aggr_in)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    aggrs = out.child_get("aggregates")
    result = aggrs.children_get()

    for aggr in result:
        total_alloc_cap = total_alloc_cap + aggr.child_get_int("size-volume-allocated")

    print (out_str + " allocated capacity (bytes): " + str(total_alloc_cap) + "\n")


def calc_avail_user_data_capacity(s):
    total_avail_udcap = 0
    out_str = "total"
    volume_in = NaElement("volume-list-info")

    if( args > 4) :
        volume_in.child_add_string("volume", sys.argv[5])
        out_str = ""

    out = s.invoke_elem(volume_in)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    vols = out.child_get("volumes")
    result = vols.children_get()

    for vol in result:
        total_avail_udcap= total_avail_udcap + vol.child_get_int("size-available")

    print (out_str + " available user data capacity (bytes): " + str(total_avail_udcap) + "\n")


def calc_raw_fmt_spare_capacity(s):
    total_raw_cap = 0
    total_format_cap = 0
    total_spare_cap = 0
    out_str = "total"

    disk_in = NaElement("disk-list-info")
    if( args > 4) :

        if(command == "spare-capacity") :
            print_usage()

        out_str = ""
        disk_in.child_add_string("disk", sys.argv[5])

    out = s.invoke_elem(disk_in)
    
    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    disk_info = out.child_get("disk-details")
    result = disk_info.children_get()

    for disk in result:
        raid_state = disk.child_get_string("raid-state")

        if(command == "raw-capacity") :

            if(raid_state != "broken") :
                total_raw_cap = total_raw_cap + disk.child_get_int("physical-space")

        elif(command == "formatted-capacity") :

            if(raid_state != "broken") :
                total_format_cap = total_format_cap + disk.child_get_int("used-space")
	
        elif(command == "spare-capacity") :

            if((raid_state == "spare") or  (raid_state == "pending") or (raid_state == "reconstructing")) :
                total_spare_cap = total_spare_cap + disk.child_get_int("used-space")
			
    if(command == "raw-capacity") :
        print (out_str + " raw capacity (bytes): " + str(total_raw_cap) + "\n")

    elif(command == "formatted-capacity") :
        print (out_str + " formatted capacity (bytes): " + str(total_format_cap) + "\n")
	
    elif(command == "spare-capacity") :
        print (out_str + " spare capacity (bytes): " + str(total_spare_cap) + "\n")


def get_disk_used_space(disk_name, overhead, s):
    used_space = 0
    disk_in = NaElement("disk-list-info")
    disk_in.child_add_string("disk", disk_name)
    out = s.invoke_elem(disk_in)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    disk_info = out.child_get("disk-details")
    disk = disk_info.child_get("disk-detail-info")
    raid_type = disk.child_get_string("raid-type")

    if(overhead == RAID_OVERHEAD) :

        if((raid_type == "parity") or (raid_type == "dparity")) :
            used_space = disk.child_get_int("used-space")

    elif(overhead == WAFL_OVERHEAD) :

        if(raid_type == "data") :
            used_space = disk.child_get_int("used-space")

    elif(overhead == SYNC_MIRROR) :
        used_space = disk.child_get_int("used-space")

    return used_space

def calc_raid_wafl_overhead(s):
    total_raid_oh = 0
    total_wafl_oh = 0
    out_str = "total"
    aggr_in = NaElement("aggr-list-info")

    if( args > 4) :
        aggr_in.child_add_string("aggregate", sys.argv[5])
        out_str = ""

    aggr_in.child_add_string("verbose", "true")
    out = s.invoke_elem(aggr_in)

    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)

    aggrs = out.child_get("aggregates")
    aresult = aggrs.children_get()

    for aggr in aresult:
        plexes = aggr.child_get("plexes")
        
        if(plexes != None) :
            presult = plexes.children_get()
            numPlexes = 0

            for plex in presult:
                numPlexes = numPlexes + 1
                rgroups = plex.child_get("raid-groups")

                if(rgroups != None) :
                    rresult = rgroups.children_get()

                    for rgroup in rresult:
                        disks = rgroup.child_get("disks")

                        if(disks != None) :
                            dresult = disks.children_get()

                            for disk in dresult:
                                disk_name = disk.child_get_string("name")

                                if(command == "raid-overhead") :
                                    if(numPlexes == 1) :
                                        total_raid_oh = total_raid_oh + int(get_disk_used_space(disk_name, RAID_OVERHEAD, s))

                                    else :
                                        total_raid_oh = total_raid_oh + int(get_disk_used_space(disk_name, SYNC_MIRROR, s))

                                elif(command == "wafl-overhead") :
                                    total_wafl_oh = total_wafl_oh + int(get_disk_used_space(disk_name, WAFL_OVERHEAD, s))
                                
								
    if(command == "raid-overhead") :
        print (out_str + " raid overhead (bytes): " + str(total_raid_oh) + "\n")

    if(command == "wafl-overhead") :
        total_wafl_oh = total_wafl_oh * 0.1
        print (out_str + " wafl overhead (bytes): " + str(total_wafl_oh) + "\n")


def calc_provisioning_capacity(s):
    total_prov_cap = 0
    out_str = "total"
    aggr_in = NaElement("aggr-list-info")

    if( args > 4) :
        aggr_in.child_add_string("aggregate", sys.argv[5])
        out_str = ""

    out = s.invoke_elem(aggr_in)
    if(out.results_status() == "failed"):
        print(out.results_reason() + "\n")
        sys.exit(2)
	
    aggrs = out.child_get("aggregates")
    result = aggrs.children_get()

    for aggr in result:
        total_prov_cap = total_prov_cap + aggr.child_get_int("size-available")

    print (out_str + " provisioning capacity (bytes): " + str(total_prov_cap) + "\n")


def main():
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

    if((command == "raw-capacity") or (command == "formatted-capacity")	or (command == "spare-capacity")) :
        calc_raw_fmt_spare_capacity(s)

    elif((command == "raid-overhead") or (command == "wafl-overhead")) :
        calc_raid_wafl_overhead(s)

    elif(command == "allocated-capacity") :
        calc_allocated_capacity(s)

    elif(command == "avail-user-data-capacity") :
        calc_avail_user_data_capacity(s)

    elif(command == "provisioning-capacity") :
        calc_provisioning_capacity(s)

    else :
        print ("Invalid operation\n")


RAID_OVERHEAD = 1
WAFL_OVERHEAD = 2
SYNC_MIRROR = 3   
args = len(sys.argv) - 1

if(args < 4):
    print_usage()
    
filer = sys.argv[1]
user = sys.argv[2]
pw  = sys.argv[3]
command = sys.argv[4]
main()
