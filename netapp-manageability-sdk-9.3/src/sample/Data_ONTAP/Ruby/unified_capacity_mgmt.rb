#==============================================================#
#                                                              #
# $ID$                                                         #
#                                                              #
# user_capacity_mgmt.rb                                        #
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

$:.unshift '../../../../lib/ruby/NetApp'
require 'NaServer'

def print_usage
    print("Usage: user_capacity_mgmt.rb <storage> <user> <password> <command> \n")
    print("<storage>     -- Name/IP address of the storage system\n")
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
    exit 
end


def calc_allocated_capacity(s)
    total_alloc_cap = 0
    out_str = "total"
    aggr_in = NaElement.new("aggr-space-list-info")
    if( $args > 4)
        aggr_in.child_add_string("aggregate", ARGV[4])
        out_str = ""
    end	
    out = s.invoke_elem(aggr_in)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    aggrs = out.child_get("aggregates")
    result = aggrs.children_get()
    for aggr in result do
        total_alloc_cap = total_alloc_cap + aggr.child_get_int("size-volume-allocated")
    end	
    print (out_str + " allocated capacity (bytes): " + total_alloc_cap.to_s + "\n")
end

	
def calc_avail_user_data_capacity(s)
    total_avail_udcap = 0
    out_str = "total"
    volume_in = NaElement.new("volume-list-info")
    if( $args > 4) 
        volume_in.child_add_string("volume", ARGV[4])
        out_str = ""
    end
    out = s.invoke_elem(volume_in)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    vols = out.child_get("volumes")
    result = vols.children_get()
    for vol in result do
        total_avail_udcap = total_avail_udcap + vol.child_get_int("size-available")
    end	
    print (out_str + " available user data capacity (bytes): " + total_avail_udcap.to_s + "\n")
end


def calc_raw_fmt_spare_capacity(s)
    total_raw_cap = 0
    total_format_cap = 0
    total_spare_cap = 0
    out_str = "total"
    disk_in = NaElement.new("disk-list-info")
    if( $args > 4) 
        if($command == "spare-capacity") 
	    print_usage() 
	end
        out_str = ""
        disk_in.child_add_string("disk", ARGV[4])
    end	
    out = s.invoke_elem(disk_in)	
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    disk_info = out.child_get("disk-details")
    result = disk_info.children_get()
    for disk in result do
        raid_state = disk.child_get_string("raid-state")	
        if($command == "raw-capacity") 
            if(raid_state != "broken") 
                total_raw_cap = total_raw_cap + disk.child_get_int("physical-space")
	    end
        elsif($command == "formatted-capacity") 
            if(raid_state != "broken") 
                total_format_cap = total_format_cap + disk.child_get_int("used-space")
	    end
        elsif($command == "spare-capacity") 
            if((raid_state == "spare") or  (raid_state == "pending") or (raid_state == "reconstructing")) 
                total_spare_cap = total_spare_cap + disk.child_get_int("used-space")
	    end
	end
    end
    if($command == "raw-capacity") 
        print (out_str + " raw capacity (bytes): " + total_raw_cap.to_s + "\n")
    elsif($command == "formatted-capacity") 
        print (out_str + " formatted capacity (bytes): " + total_format_cap.to_s + "\n")
    elsif($command == "spare-capacity") 
        print (out_str + " spare capacity (bytes): " + total_spare_cap.to_s + "\n")
    end
end


def get_disk_used_space(disk_name, overhead, s)
    used_space = 0
    disk_in = NaElement.new("disk-list-info")
    disk_in.child_add_string("disk", disk_name)
    out = s.invoke_elem(disk_in)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    disk_info = out.child_get("disk-details")
    disk = disk_info.child_get("disk-detail-info")
    raid_type = disk.child_get_string("raid-type")
    if(overhead == $RAID_OVERHEAD) 
        if((raid_type == "parity") or (raid_type == "dparity")) 
            used_space = disk.child_get_int("used-space")
	end
    elsif(overhead == $WAFL_OVERHEAD) 
        if(raid_type == "data") 
            used_space = disk.child_get_int("used-space")
	end		
    elsif(overhead == $SYNC_MIRROR) 
        used_space = disk.child_get_int("used-space")
    end
    return used_space
end


def calc_raid_wafl_overhead(s)
    total_raid_oh = 0
    total_wafl_oh = 0
    out_str = "total"
    aggr_in = NaElement.new("aggr-list-info")
    if( $args > 4) 
        aggr_in.child_add_string("aggregate", ARGV[4])
        out_str = ""
    end
    aggr_in.child_add_string("verbose", "true")
    out = s.invoke_elem(aggr_in)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    aggrs = out.child_get("aggregates")
    aresult = aggrs.children_get()
    aresult.each do |aggr|
        plexes = aggr.child_get("plexes")	
        if(plexes != nil) 
            presult = plexes.children_get()
            numPlexes = 0
	    presult.each do |plex|
                numPlexes = numPlexes + 1
                rgroups = plex.child_get("raid-groups")
                if(rgroups != nil) 
                    rresult = rgroups.children_get()
		    rresult.each do |rgroup|
                        disks = rgroup.child_get("disks")
                        if(disks != nil) 
                            dresult = disks.children_get()
			    dresult.each do |disk|
                                disk_name = disk.child_get_string("name")
                                if($command == "raid-overhead") 
                                    if(numPlexes == 1) 
                                        total_raid_oh = total_raid_oh + get_disk_used_space(disk_name, $RAID_OVERHEAD, s)
                                    else 
                                        total_raid_oh = total_raid_oh + get_disk_used_space(disk_name, $SYNC_MIRROR, s)
				    end							
                                elsif($command == "wafl-overhead") 
                                    total_wafl_oh = total_wafl_oh + get_disk_used_space(disk_name, $WAFL_OVERHEAD, s)
				end
			    end	
			end
		    end
		end
	    end
	end
    end	
    if($command == "raid-overhead") 
        print (out_str + " raid overhead (bytes): " + total_raid_oh.to_s + "\n")
    end	
    if($command == "wafl-overhead") 
        total_wafl_oh*=0.1
        print (out_str + " wafl overhead (bytes): " + total_wafl_oh.to_s + "\n")
    end
end


def calc_provisioning_capacity(s)
    total_prov_cap = 0
    out_str = "total"
    aggr_in = NaElement.new("aggr-list-info")
    if( $args > 4) 
        aggr_in.child_add_string("aggregate", ARGV[4])
        out_str = ""
    end
    out = s.invoke_elem(aggr_in)    
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    aggrs = out.child_get("aggregates")
    result = aggrs.children_get()
    result.each do |aggr|
        total_prov_cap = total_prov_cap + aggr.child_get_int("size-available")
    end	
    print (out_str + " provisioning capacity (bytes): " + total_prov_cap.to_s + "\n")
end


def main	
    if($args < 4)
	print_usage() 
    end	
    storage = ARGV[0]
    user = ARGV[1]
    pw  = ARGV[2]
    $command = ARGV[3]
    s = NaServer.new(storage, 1, 3)
    s.set_admin_user(user, pw)
    if(($command == "raw-capacity") or ($command == "formatted-capacity") or ($command == "spare-capacity")) 
        calc_raw_fmt_spare_capacity(s)
    elsif(($command == "raid-overhead") or ($command == "wafl-overhead")) 
        calc_raid_wafl_overhead(s)
    elsif($command == "allocated-capacity") 
        calc_allocated_capacity(s)
    elsif($command == "avail-user-data-capacity") 
        calc_avail_user_data_capacity(s)
    elsif($command == "provisioning-capacity") 
        calc_provisioning_capacity(s)
    else 
        print("Invalid operation\n")
        print_usage()
    end
end


$RAID_OVERHEAD = 1
$WAFL_OVERHEAD = 2
$SYNC_MIRROR = 3
$args = ARGV.length
main()
