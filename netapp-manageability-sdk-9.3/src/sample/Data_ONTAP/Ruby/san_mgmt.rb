#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# san_mgmt.rb                                                #
#                                                            #
# Application which uses ONTAPI APIs to perform SAN          #
# management operations for lun/igroup/fcp/iscsi             #
#                                                            #
# Copyright 2011 Network Appliance, Inc. All rights          #
# reserved. Specifications subject to change without notice. #
#                                                            #
# This SDK sample code is provided AS IS, with no support or #
# warranties of any kind, including but not limited to       #
# warranties of merchantability or fitness of any kind,      #
# expressed or implied.  This code is subject to the license #
# agreement that accompanies the SDK.                        #
#                                                            #
#============================================================#

$:.unshift '../../../../lib/ruby/NetApp'
require 'NaServer'

def print_usage
    print("Usage: sanmgmt.rb <storage> <user> <password> <command> \n")
    print("<storage>      -- Name/IP address of the storage system \n")
    print("<user>         -- User name \n")
    print("<password>   -- Password \n\n")
    print("possible commands are: \n")
    print("lun    igroup    fcp    iscsi \n")
    exit 
end

def print_LUN_usage() 
    print("Usage: sanmgmt.rb <storage> <user> <password> lun")
    print(" <command> \n\n")
    print("Possible commands are:\n")
    print("create  destroy  show  clone  map  unmap  show-map \n\n")
    exit 
end


def print_LUN_create_usage() 
    print("Usage: sanmgmt.rb <storage> <user> <passwd> lun create <path> ")
    print("<size-in-bytes> <ostype> [-sre <space-res-enabled>] \n\n")
    print("space-res-enabled: true/false \n")
    print("ostype: solaris/windows/hpux/aix/linux/vmware. \n")
    exit 
end


def print_clone_usage() 
    print("Usage: sanmgmt.rb <storage> <user> <password> lun clone ")
    print("<command> \n")
    print("Possible commands are: \n")
    print("create  start  stop  status \n")
    exit 
end


def print_igroup_usage() 
    print("Usage: sanmgmt.rb <storage> <user> <password> igroup")
    print(" <command> \n\n")
    print("Possible commands are: \n")
    print("create  destroy  add  show \n")
    exit 
end


def print_fcp_usage() 
    print("Usage: sanmgmt.rb <storage> <user> <password> fcp")
    print(" <command> \n\n")
    print("Possible commands are: \n")
    print("start  stop  status  config  show \n")
    exit 
end


def print_fcp_config_usage() 
    print("Usage: SANMgmt <storage> <user> <password> ")
    print("fcp config <adapter> < [ up | down ] ")
    print("[ mediatype { ptp | auto | loop } ] ")
    print("[ speed { auto | 1 | 2 | 4 } ] > \n")
    exit 
end


def print_iscsi_usage()
    print("Usage: sanmgmt.rb <storage> <user> <password> iscsi")
    print(" <command> \n\n")
    print("Possible commands are: \n")
    print("start  stop  status  interface  show \n")
    exit 
end


def print_iscsi_interface_usage() 
    print("Usage: sanmgmt.rb <storage> <user> <password> iscsi ")
    print("interface <command> \n\n")
    print("Possible commands are: \n")
    print("enable  disable  show \n")
    exit 
end
	

def process_LUN()
    index = 4
    path = ""
    sre = ""
    lun_type = ""	
    if($args < 5)
	print_LUN_usage() 
    end
	
    if(ARGV[index] == "create") 
        if($args < 8) 
            print_LUN_create_usage()
            exit 
	end		
        lun_in = NaElement.new("lun-create-by-size")
        index = index + 1
        lun_in.child_add_string("path", ARGV[index])
        index = index + 1
        lun_in.child_add_string("size", ARGV[index])
        index = index + 1
        lun_in.child_add_string("type", ARGV[index])
        index = index + 1
        if($args > 8 and ARGV[index] == "-sre") 
            index = index + 1
            lun_in.child_add_string("space-reservation-enabled", ARGV[index])
            index = index + 1
	end		
        out = $s.invoke_elem(lun_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
        else 
            print("Operation successful!\n")
	end

    elsif(ARGV[index] == "destroy") 
        if($args < 6)
            print ("Usage: sanmgmt.rb <storage> <user> <passwd> lun destroy [-f] <lun-path> \n\n")
            print ("If -f is used, the LUN specified would be deleted even in ")
            print ("online and/or mapped state.\n")
            exit 
	end
        lun_in = NaElement.new("lun-destroy")
        index = index + 1
        if(ARGV[index] == "-f") 
            lun_in.child_add_string("force", "true")
            index = index + 1
	end		
        lun_in.child_add_string("path", ARGV[index])
        index = index + 1
        out = $s.invoke_elem(lun_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
        else 
            print("Operation successful!\n")
	end

    elsif(ARGV[index] == "show") 
        lun_in = NaElement.new("lun-list-info")
        if($args > 5) 
            if(ARGV[index + 1] == "help") 
                print ("Usage: sanmgmt.rb <storage> <user> <passwd> lun show [<lun-path>] \n")
                exit 
	    end
            index = index + 1
            lun_in.child_add_string("path", ARGV[index])
	end		
        out = $s.invoke_elem(lun_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
	end		
        lun_info = out.child_get("luns")
        result = lun_info.children_get()
        print ("\n")
	result.each do |lun|
            path = lun.child_get_string("path")
            print  ("\npath: " + path)
            size = lun.child_get_string("size")
            print  ("\nsize: " + size)
            online = lun.child_get_string("online")
            print  ("\nonline: " + online )
            mapped = lun.child_get_string("mapped")
            print  ("\nmapped: " + mapped  )
            uuid = lun.child_get_string("uuid")
            print  ("\nuuid: " + uuid  )
            ser_num = lun.child_get_string("serial-number")
            print  ("\nserial-number: " + ser_num  )
            blk_size = lun.child_get_string("block-size")
            print  ("\nblock-size: " + blk_size  )
            is_sre = lun.child_get_string("is-space-reservation-enabled")
            print  ("\nis-space-reservation-enabled: " + is_sre )
            lun_type = lun.child_get_string(" multiprotocol-type")
            print("\nmultiprotocol-type: ", lun_type  )
            print("\n--------------------------------------\n")
	end

    elsif(ARGV[index] == "clone")
        if($args < 6) 
	    print_clone_usage() 
	end        
	index = index + 1
        if(ARGV[index] == "create") 
            if($args < 9) 
                print ("Usage: sanmgmt.rb <storage> <user> <password> lun clone ")
                print ("create <parent-lun-path> <parent-snapshot> <path> ")
                print ("[-sre <space-res-enabled>] \n")
                exit 
	    end
            lun_in = NaElement.new("lun-create-clone")
            index = index + 1
            lun_in.child_add_string("parent-lun-path", ARGV[index])
            index = index + 1
            lun_in.child_add_string("parent-snap", ARGV[index])
            index = index + 1
            lun_in.child_add_string("path", ARGV[index])
            index = index + 1
            if(ARGV[index] == "-sre") 
                index = index + 1
                lun_in.child_add_string("space-reservation-enabled", ARGV[index])
	    end			
            out = $s.invoke_elem(lun_in)
            if(out.results_status() == "failed") 
                print(out.results_reason() + "\n")
                exit			
            else 
                print("Operation successful!\n")
	    end
			
        elsif(ARGV[index] == "status") 
            lun_in = NaElement.new("lun-clone-status-list-info")
            if($args > 6) 
                if(ARGV[index+1] == "help") 
                    print ("Usage: sanmgmt.rb <storage> <user> <password> lun ")
                    print ("clone status [<lun-path>] \n")
                    exit 
		end				
                index = index + 1
                lun_in.child_add_string("path", ARGV[index])
	    end			
            out = $s.invoke_elem(lun_in)
            if(out.results_status() == "failed") 
                print(out.results_reason() + "\n")
                exit
	    end
            clone_info = out.child_get("clone-status")
            result = clone_info.children_get()
            print ("\n")
	    result.each do |clone|
                path = clone.child_get_string("path")
                print  ("\npath: " + path )
                blks_cmp = clone.child_get_string("blocks-completed")
                print  ("\nblocks-completed: " + blks_cmp)
                blks_total = clone.child_get_string("blocks-total")
                print  ("\nblocks-total: " + blks_total )
                print ("\n--------------------------------------\n")
	    end
			
        elsif(ARGV[index] == "start") 
            lun_in = NaElement.new("lun-clone-start")
            if(($args < 7) or (ARGV[index+1] == "help")) 
                print ("Usage: sanmgmt.rb <storage> <user> <password> lun ")
                print ("clone start <lun-path> \n")
                exit 
	    end			
            if($args > 6) 
                index = index + 1
                lun_in.child_add_string("path", ARGV[index])
	    end			
            out = $s.invoke_elem(lun_in)
            if(out.results_status() == "failed") 
                print(out.results_reason() + "\n")
                exit			
            else 
                print("Operation successful!\n")
	    end
			
        elsif(ARGV[index] == "stop") 
            lun_in = NaElement.new("lun-clone-stop")
            if(($args < 7) or (ARGV[index+1] == "help")) 
                print ("Usage: sanmgmt.rb <storage> <user> <password> lun ")
                print ("clone stop <lun-path> \n")
                exit 
	    end			
            if($args > 6) 
                index = index + 1
                lun_in.child_add_string("path", ARGV[index])
	    end			
            out = $s.invoke_elem(lun_in)
            if(out.results_status() == "failed") 
                print(out.results_reason() + "\n")
                exit
            else 
                print("Operation successful!\n")
	    end
			
        else 
            print_clone_usage()
	end
		
    elsif(ARGV[index] == "map") 
        if($args < 7) 
            print ("Usage: sanmgmt.rb <storage> <user> <password> lun map ")
            print ("<initiator-group> <lun-path> [-f <force>] [-id <lun-id>]\n")
            exit 
	end
        lun_in = NaElement.new("lun-map")
        index = index + 1
        lun_in.child_add_string("initiator-group", ARGV[index])
        index = index + 1
        lun_in.child_add_string("path", ARGV[index])
        index = index + 1
        if(ARGV[index] == "-f") 
            index = index + 1
            lun_in.child_add_string("force", ARGV[index])
            index = index + 1
	end		
        if(ARGV[index] == "-id") 
            index = index + 1
            lun_in.child_add_string("lun-id",ARGV[index])
            index = index + 1
	end		
        out = $s.invoke_elem(lun_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit		
        else 
            print("Operation successful!\n")
	end
		
    elsif(ARGV[index] == "unmap") 
        if($args < 7) 
            print ("Usage: sanmgmt.rb <storage> <user> <password> lun unmap ")
            print ("<initiator-group> <lun-path> \n")
            exit 
	end
        lun_in = NaElement.new("lun-unmap")
        index = index + 1
        lun_in.child_add_string("initiator-group", ARGV[index])
        index = index + 1
        lun_in.child_add_string("path", ARGV[index])
        out = $s.invoke_elem(lun_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
        else 
            print("Operation successful!\n")
	end

    elsif(ARGV[index] == "show-map") 
        lun_in = NaElement.new("lun-map-list-info")
        if($args < 6) 
            print ("Usage: sanmgmt.rb <storage> <user> <password> lun show-map <lun-path> \n")
            exit 
	end
        index = index + 1
        lun_in.child_add_string("path", ARGV[index])
        out = $s.invoke_elem(lun_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
	end		
        inititorgr_info = out.child_get("initiator-groups")
        result = inititorgr_info.children_get()
        print ("\n")
 	result.each do |initiatorgr|
            gname = initiatorgr.child_get_string("initiator-group-name")
            print  ("\ninitiator-group-name: " + gname )
            ostype = initiatorgr.child_get_string("initiator-group-os-type")
            print  ("\ninitiator-group-os-type: " + ostype)
            gtype = initiatorgr.child_get_string("initiator-group-type")
            print  ("\ninitiator-group-type: " + gtype )
            alua = initiatorgr.child_get_string("initiator-group-alua-enabled")
            print  ("\ninitiator-group-alua-enabled: " + alua)
            lunid = initiatorgr.child_get_string("lun-id")
	    unless(lunid)
                print  ("\nlun-id: " + lunid )  
            end
            initiators = initiatorgr.child_get("initiators")

            unless(initiators) 
                iresult = initiators.children_get()
                print  ("\ninitiator-name(s):\n")
		iresult.each do |initiator|
                    iname = initiator.child_get_string("initiator-name")
                    print  (iname + "\n"  )
		end
	    end			
            print ("--------------------------------------\n")
	end

    else 
        print_LUN_usage()
    end
end


def process_igroup()
    index = 4
    path = ""
    sre = ""
    group_type = ""
    print_igroup_usage() if($args < 5)    
    if(ARGV[index] == "create")
        if($args < 7) 
            print ("Usage: sanmgmt.rb <storage> <user> <passwd> igroup create ")
            print ("<igroup-name> <igroup-type> [-bp <bind-portset>] ")
            print ("[-os <os-type>] \n\n")
            print ("igroup-type: fcp/iscsi \n")
            print ("os-type: solaris/windows/hpux/aix/linux. ")
            print ("If not specified, \"default\" is used. \n")
            exit 
	end
        lun_in = NaElement.new("igroup-create")
        index = index + 1
        lun_in.child_add_string("initiator-group-name", ARGV[index])
        index = index + 1
        lun_in.child_add_string("initiator-group-type", ARGV[index])
        if($args > 7 and ARGV[index + 1] == "-bp") 
            index = index + 2
            lun_in.child_add_string("bind-portset", ARGV[index])
	end		
        if($args > 7 and ARGV[index + 1] == "-os") 
            index = index + 2
            lun_in.child_add_string("os-type", ARGV[index])
            index = index + 1
	end		
        out = $s.invoke_elem(lun_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
        else 
            print("Operation successful!\n")
	end
    
    elsif(ARGV[index] == "destroy") 
        if($args < 6) 
            print ("Usage: sanmgmt.rb <storage> <user> <passwd> igroup destroy ")
            print ("<igroup-name> [-f <force>] \n")
            exit 
	end
        lun_in = NaElement.new("igroup-destroy")
        index = index + 1
        lun_in.child_add_string("initiator-group-name", ARGV[index])
        if(ARGV[index + 1] == "-f") 
            index = index + 2
            lun_in.child_add_string("force", ARGV[index])
	end
        out = $s.invoke_elem(lun_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
        else 
            print("Operation successful!\n")
	end
		
    elsif(ARGV[index] == "show")
        if($args > 6 and ARGV[index + 1] == "help") 
            print ("Usage: sanmgmt.rb <storage> <user> <password> ")
            print ("lun show [<lun-path>] \n")
            exit 
	end
        lun_in = NaElement.new("igroup-list-info")
        if($args > 6) 
            index = index + 1
            lun_in.child_add_string("initiator-group-name", ARGV[index])
	end		
        out = $s.invoke_elem(lun_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
	end		
        igroup_info = out.child_get("initiator-groups")
        result = igroup_info.children_get()
        print ("\n")

	result.each do |igroup|
            name = igroup.child_get_string("initiator-group-name")
            print  ("initiator-group-name: " + name + "\n")
            ostype = igroup.child_get_string("initiator-group-os-type")
            print  ("initiator-group-os-type: " + ostype + "\n")
            group_type = igroup.child_get_string("initiator-group-type")
            print  ("initiator-group-type: " + group_type + " \n")
            lunid = igroup.child_get_string("lun-id")
            unless(lunid)
		print  ("lun-id: " + lunid.to_s + "\n") 
	    end
	    initiators = igroup.child_get_string("initiators")

            if(initiators != nil and initiators != "") 
                iresult = initiators.children_get()
                print  ("initiator-name(s):\n")
                for initiator in iresult do
                    iname = initiator.child_get_string("initiator-name")
                    print (iname + "\n")
		end
	    end			
            print ("--------------------------------------\n")
	end

    elsif(ARGV[index] == "add") 
        if(($args < 7) or ($args == 7 and ARGV[index + 1] == "-f")) 
            print ("Usage: sanmgmt.rb <storage> <user> <passwd> igroup add ")
            print ("[-f] <igroup-name> <initiator> \n\n")
            print ("and type conflict checks with the cluster partner.\n")
            exit 
	end
        lun_in = NaElement.new("igroup-add")
        if(ARGV[index+1] == "-f") 
            lun_in.child_add_string("force", "true")
            index = index + 1
	end		
        index = index + 1
        lun_in.child_add_string("initiator-group-name", ARGV[index])
        index = index + 1
        lun_in.child_add_string("initiator", ARGV[index])
        out = $s.invoke_elem(lun_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
        else 
            print("Operation successful!\n")
	end
	
    else 
        print_igroup_usage()
	end
end


def process_fcp()
    index = 4
    path = ""
    sre = ""
    process_type = ""	
    print_fcp_usage() if($args < 5)
    if(ARGV[index] == "start") 
        lun_in = NaElement.new("fcp-service-start")
        out = $s.invoke_elem(lun_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
        else 
            print("Operation successful!\n")
	end
		
    elsif(ARGV[index] == "stop") 
        lun_in = NaElement.new("fcp-service-stop")
        out = $s.invoke_elem(lun_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
        else 
            print("Operation successful!\n")
	end

    elsif(ARGV[index] == "status") 
        lun_in = NaElement.new("fcp-service-status")
        out = $s.invoke_elem(lun_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
	end
        if(out.child_get_string("is-available") == "true") 
            print ("FCP service is running.\n")
        else 
            print("FCP service is not running.\n")
	end

    elsif(ARGV[index] == "config") 
        if(($args < 7) or (ARGV[index + 1] == "help")) 
	    print_fcp_config_usage() 
	end
        index = index + 2
        if(ARGV[index] == "up") 
            lun_in = NaElement.new("fcp-adapter-config-up")
            lun_in.child_add_string("fcp-adapter", ARGV[index - 1])
        elsif(ARGV[index] == "down") 
            lun_in = NaElement.new("fcp-adapter-config-down")
            lun_in.child_add_string("fcp-adapter", ARGV[index - 1])
        elsif(ARGV[index] == "mediatype") 
            lun_in = NaElement.new("fcp-adapter-config-media-type")
            lun_in.child_add_string("fcp-adapter", ARGV[index - 1])
            index = index + 1
            lun_in.child_add_string("media-type", ARGV[index])
        elsif(ARGV[index] == "speed") 
            lun_in = NaElement.new("fcp-adapter-set-speed")
            lun_in.child_add_string("fcp-adapter", ARGV[index - 1])
            index = index + 1
            lun_in.child_add_string("speed", ARGV[index])
        else 
            print_fcp_config_usage()
	end		
        out = $s.invoke_elem(lun_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
        else 
            print("Operation successful!\n")
	end
	
    elsif(ARGV[index] == "show") 
        if($args > 5 and ARGV[index + 1] == "help") 
	    print ("Usage: sanmgmt.rb <storage> <user> <password> ")
            print ("fcp show [<fcp-adapter>] \n")
            exit 
	end
        lun_in = NaElement.new("fcp-adapter-list-info")
        if($args > 5) 
            index = index + 1
            lun_in.child_add_string("fcp-adapter", ARGV[index])
	end
        out = $s.invoke_elem(lun_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
	end		
        adapter_info = out.child_get("fcp-config-adapters")
        result = adapter_info.children_get()
        print ("\n")
	result.each do |adapter|
            adapter_name = adapter.child_get_string("adapter")
            print  ("adapter: " + adapter_name + "\n")
            nodename = adapter.child_get_string("node-name")
            print  ("node-name: " + nodename + "\n")
            port = adapter.child_get_string("port-name")
            print  ("port-name: " + port + "\n")
            addr = adapter.child_get_string("port-address")
            print  ("port-address: " + addr + "\n")
            adapter_type = adapter.child_get_string("adapter-type")
            print  ("adapter-type: " + adapter_type + "\n")
            media_type = adapter.child_get_string("media-type")
            print  ("media-type: " + media_type + "\n")
            speed = adapter.child_get_string("speed")
            print  ("speed: " + speed + "\n")
            partner = adapter.child_get_string("partner-adapter")
            print("partner-adapter: ",partner,"\n")
            standby = adapter.child_get_string("standby")
            print  ("standby: " + standby + "\n")
            print ("--------------------------------------\n")
	end
		
    else 
        print_fcp_usage()
    end
end


def process_iscsi()
    index = 4
    path = ""
    sre = ""
    process_type = ""
    print_iscsi_usage() if($args < 5)
    if(ARGV[index] == "start") 
        process_in = NaElement.new("iscsi-service-start")
        out = $s.invoke_elem(process_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
        else 
            print("Operation successful!\n")
	end

    elsif(ARGV[index] == "stop") 
        process_in = NaElement.new("iscsi-service-stop")
        out = $s.invoke_elem(process_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
	end
		
    elsif(ARGV[index] == "status") 
        process_in = NaElement.new("iscsi-service-status")
        out = $s.invoke_elem(process_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
	end
        if(out.child_get_string("is-available") == "true") 
            print ("iSCSI service is running.\n")
        else 
            print("iSCSI service is not running.\n")
	end
		
    elsif(ARGV[index] == "interface") 
        if(($args < 6) or (ARGV[index + 1] == "help")) 
	    print_iscsi_interface_usage() 
	end
        index = index + 1
	if(ARGV[index] == "enable")             
	    if($args < 7) 
                print ("Usage: sanmgmt.rb <storage> <user> <password> iscsi ")
                print (" interface enable <interface-name>\n")
                exit 
	    end
            process_in = NaElement.new("iscsi-interface-enable")
            index = index + 1
            process_in.child_add_string("interface-name", ARGV[index])
            out = $s.invoke_elem(process_in)
            if(out.results_status() == "failed") 
                print(out.results_reason() + "\n")
                exit
            else 
                print("Operation successful!\n")
	    end
			
        elsif(ARGV[index] == "disable") 
            if($args < 7) 
                print ("Usage: sanmgmt.rb <storage> <user> <password> iscsi ")
                print (" interface disable <interface-name>\n")
                exit 
	    end
            process_in = NaElement.new("iscsi-interface-disable")
            index = index + 1
            process_in.child_add_string("interface-name", ARGV[index])
            out = $s.invoke_elem(process_in)
            if(out.results_status() == "failed") 
                print(out.results_reason() + "\n")
                exit
            else 
                print("Operation successful!\n")
	    end
			
        elsif(ARGV[index] == "show") 
            index = index + 1
            process_in = NaElement.new("iscsi-interface-list-info")
            if($args > 6) 
                if(ARGV[index] == "help") 
                    print ("Usage: sanmgmt.rb <storage> <user> <password> iscsi ")
                    print (" interface show [<interface-name>]\n")
                    exit 				
                else 
                    index = index + 1
                    process_in.child_add_string("interface-name", ARGV[index])
		end
	    end	            
	    out = $s.invoke_elem(process_in)
            if(out.results_status() == "failed") 
                print(out.results_reason() + "\n")
                exit
	    end			
            iscsi_interface_info = out.child_get("iscsi-interface-list-entries")
            result = iscsi_interface_info.children_get()
            print ("\n------------------------------------------------------\n")
	    result.each do |interface|
                name = interface.child_get_string("interface-name")
                print  ("interface-name: " + name + "\n")
                enabled = interface.child_get_string("is-interface-enabled")
                print  ("is-interface-enabled: " + enabled + "\n")
                tpgroup = interface.child_get_string("tpgroup-name")
                print  ("tpgroup-name: " + tpgroup + "\n")
                print ("------------------------------------------------------\n")
	    end
			
        else 
            print_iscsi_interface_usage()
	end		
        out = $s.invoke_elem(process_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() +"\n")
            exit
	end

    elsif(ARGV[index] == "show") 
        index = index + 1
        if(($args < 6) or (ARGV[index] != "initiator")) 
            print ("Usage: sanmgmt.rb <storage> <user> <password> iscsi ")
            print ("show initiator \n")
            exit 
	end
        process_in = NaElement.new("iscsi-initiator-list-info")
        out = $s.invoke_elem(process_in)
        if(out.results_status() == "failed") 
            print(out.results_reason() +"\n")
            exit
	end		
        inititor_info = out.child_get("iscsi-initiator-list-entries")
        result = inititor_info.children_get()
        print ("\n")
        for initiator in result do
            alname = initiator.child_get_string("initiator-aliasname")
            print  ("initiator-aliasname: " + alname + "\n")
            nodename = initiator.child_get_string("initiator-nodename")
            print  ("initiator-nodename: " + nodename + "\n")
            isid = initiator.child_get_string("isid")
            print  ("isid: " + isid + "\n")
            ssid = initiator.child_get_string("target-session-id")
            print  ("target-session-id: " + ssid + "\n")
            tptag = initiator.child_get_int("tpgroup-tag")
            print  ("tpgroup-tag: " + tptag.to_s + "\n")
            print ("--------------------------------------\n")
	end
		
    else 
        print_iscsi_usage()
	end
end


def main()
    $args = ARGV.length
    print_usage() if($args < 4)	
    storage = ARGV[0]
    user = ARGV[1]
    pw = ARGV[2]
    command = ARGV[3]    
    $s = NaServer.new(storage, 1, 3)
    $s.set_admin_user(user, pw)
    if(command == "lun")
        process_LUN()
    elsif(command == "igroup")
        process_igroup()
    elsif(command == "fcp")
        process_fcp()
    elsif(command == "iscsi")
        process_iscsi()
    else
        print("Invalid operation\n")
        print_usage()
    end
end

main()

