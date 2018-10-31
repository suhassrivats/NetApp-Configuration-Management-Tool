#==============================================================#
#                                                              #
# $ID$                                                         #
#                                                              #
# vfiler.rb                                                    #
#                                                              #
# This sample code demonstrates how to create, destroy or      #
# list vfiler(s) using ONTAPI APIs                             #
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
    print("Usage: vfiler.rb <storage> <user> <password> <operation> <value1>")
    print("[<value2>] ..\n")
    print("<storage>     -- Name/IP address of the storage system\n")
    print("<user>      -- User name\n")
    print("<password>  -- Password\n")
    print("<operation> -- Operation to be performed: ")
    print("create/destroy/list/status/start/stop\n")
    print("[<value1>]    -- Depends on the operation \n")
    print("[<value2>]  -- Depends on the operation \n")
    exit 
end

def vfiler_create()
    parse_ip_addr = 1
    no_of_var_arguments = $args - 4    
    if( $args < 9 or ARGV[5] != "-ip")
        print ("Usage: vfiler <storage> <user> <password> create <vfiler-name> \n")
        print ("-ip <ip-address1> [<ip-address2>..] -su <storage-unit1> ")
        print ("[<storage-unit2]..] \n")
        exit
    end
    vfiler_in = NaElement.new("vfiler-create")
    ip_addrs = NaElement.new("ip-addresses")
    st_units = NaElement.new("storage-units")
    vfiler_in.child_add_string("vfiler", $vfiler)
    # start parsing from <ip-address1>
    i = 6
    while(i < $args)
        if(ARGV[i] == "-su")
            parse_ip_addr = 0
        else
            if(parse_ip_addr == 1)
                ip_addrs.child_add_string("ip-address", ARGV[i])
            else
                st_units.child_add_string("storage-unit", ARGV[i])
	    end
	end
        i = i + 1
    end
    vfiler_in.child_add(ip_addrs)
    vfiler_in.child_add(st_units)
    # Invoke vfiler-create API
    out = $s.invoke_elem(vfiler_in)
    if(out.results_status() == "failed") 
        print(out.results_reason() + "\n")
	exit
    end
    print ("vfiler created successfully\n")
    exit
end


def vfiler_list()
    if( $vfiler == nil )
        out = $s.invoke( "vfiler-list-info")
    else
        out = $s.invoke( "vfiler-list-info","vfiler", $vfiler)
    end
    if(out.results_status() == "failed") 
        print(out.results_reason() + "\n")
        exit
    end
    vfiler_info = out.child_get("vfilers")
    result = vfiler_info.children_get()
    result.each do |vfiler|
        vfiler_name = vfiler.child_get_string("name")
        print  ("Vfiler name: " + vfiler_name + " \n")
        ip_space = vfiler.child_get_string("ip_space")
        if(ip_space != nil)
	    print("ipspace: " + ip_space + " \n") 
	end
        uuid = vfiler.child_get_string("uuid")
        print  ("uuid: " + uuid + " \n")
        vfnet_info = vfiler.child_get("vfnets")
        vfnet_result = vfnet_info.children_get()
	vfnet_result.each do |vfnet|
            print("network resources:\n")
            ip_addr = vfnet.child_get_string("ipaddress")
            unless(ip_addr)
		print("  ip-address: " + ip_addr + " \n") 
	    end
            interface = vfnet.child_get_string("interface")
            unless(interface)
		print("  interface: " + interface + " \n")
	    end
	end
	vfstore_info = vfiler.child_get("vfstores")
	vfstore_result = vfstore_info.children_get()
	vfstore_result.each do |vfstore|
            print("storage resources:\n")
            path = vfstore.child_get_string("path")
            unless(path)
		print  ("  path: " + path + " \n") 
	    end
            status = vfstore.child_get_string("status")
            unless(status)
		print  ("  status: " + status + " \n") 
	    end
            etc = vfstore.child_get_string("is-etc")
            unless(etc)
		print  ("  is-etc: etc \n") 
	    end
	end           
        print ("--------------------------------------------\n")
    end
    exit
end


def main() 	
    $args = ARGV.length	
    if($args < 4) 
	print_usage() 
    end	
    storage = ARGV[0]
    user = ARGV[1]
    pw  = ARGV[2]
    command = ARGV[3]
    $vfiler = nil	
    if($args > 4) 
        $vfiler = ARGV[4] 
    end	
    $s = NaServer.new(storage, 1, 3)
    $s.set_admin_user(user, pw)
    if(command == "create") 
        vfiler_create()
    elsif(command == "list") 
        vfiler_list()
    end

    if(($args < 4) and (command == "start" or command == "stop" or  command == "status" or  command == "destroy"))
        print ("This operation requires <vfiler-name> \n\n")
        print_usage()
    end

    if(command == "start") 
        out = $s.invoke("vfiler-start", "vfiler", $vfiler)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
	end

    elsif(command == "status") 
        out = $s.invoke("vfiler-get-status", "vfiler", $vfiler)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
	end
        status = out.child_get_string("status")
        print("status:" + status + "\n")

    elsif(command == "stop") 
        out = $s.invoke("vfiler-stop", "vfiler", $vfiler)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
	end

    elsif(command == "destroy")
        out = $s.invoke("vfiler-destroy", "vfiler", $vfiler)
        if(out.results_status() == "failed") 
            print(out.results_reason() + "\n")
            exit
	end

    else 
        puts("Invalid operation\n")
        print_usage()
    end
    exit
end

main()


