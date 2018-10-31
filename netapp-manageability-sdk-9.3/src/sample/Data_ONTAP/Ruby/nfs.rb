#=======================================================================#
#                                                                       #
# $ID$                                                                  #
#                                                                       #
# nfs.rb                                                                #
#                                                                       #
# Sample code for the following APIs:                                   #
#               nfs-enable, nfs-disable                                 #
#               nfs-status, nfs-exportfs-list-rules,                    #
#                                                                       #
# Copyright 2011 Network Appliance, Inc. All rights                     #
# reserved. Specifications subject to change without notice.            #
#                                                                       #
# This SDK sample code is provided AS IS, with no support or            #
# warranties of any kind, including but not limited to                  #
# warranties of merchantability or fitness of any kind,                 #
# expressed or implied.  This code is subject to the license            #
# agreement that accompanies the SDK.                                   #
#=======================================================================#

$:.unshift '../../../../lib/ruby/NetApp'
require 'NaServer'

def print_usage
    print ("Usage:\n")
    print ("nfs.rb <storage> <user> <password> <command>\n")
    print ("<storage> -- storage system name\n")
    print ("<user> -- User name\n")
    print ("<password> -- Password\n")
    print ("<command> -- enable, disable, status, list\n")
    exit
end


args = ARGV.length
if(args < 4) 
    print_usage()
end
$storage = ARGV[0]
$user = ARGV[1]
$pw = ARGV[2]
$cmd = ARGV[3]


def do_nfs()
    s = NaServer.new($storage, 1, 3)
    out = s.set_admin_user($user, $pw)
    if($cmd == "enable")
        out = s.invoke("nfs-enable")
        if(out.results_status() == "failed")
            print(out.results_reason() + "\n")
            exit		
        else
            print("Operation successful\n")
        end		
    elsif ($cmd == "disable")
        out = s.invoke("nfs-disable")
        if(out.results_status == "failed")
            print(out.results_reason() + "\n")
            exit
	else
            print("Operation successful\n")
	end		
    elsif ($cmd == "status")
        out = s.invoke("nfs-status")
        if(out.results_status == "failed")
            print(out.results_reason() + "\n")
            exit
	end
	enabled = out.child_get_string("is-enabled")
        if(enabled == "true")
            print("NFS Server is enabled\n")
        else
            print("NFS Server is disabled\n")
	end		
    elsif ( $cmd == "list") 
        out = s.invoke( "nfs-exportfs-list-rules" )
        export_info = out.child_get("rules")
        result = export_info.children_get()
        result.each do |export|
            path_name = export.child_get_string("pathname")
            rw_list = "rw="
            ro_list = "ro="
            root_list = "root="			
            if(export.child_get("read-only"))
                ro_results = export.child_get("read-only")
                ro_hosts = ro_results.children_get()
		ro_hosts.each do |ro|
                    if(ro.child_get_string("all-hosts"))
                        all_hosts = ro.child_get_string("all-hosts")
                        if(all_hosts == "true") 
                            ro_list = ro_list + "all-hosts"
                            break
			end
                    elsif(ro.child_get_string("name")) 
                        host_name = ro.child_get_string("name")
                        ro_list = ro_list + host_name + ":"
		    end
		end
	    end			
            if(export.child_get("read-write"))
                rw_results = export.child_get("read-write")
                rw_hosts = rw_results.children_get()                
                rw_hosts.each do |rw|
                    if(rw.child_get_string("all-hosts"))
                        all_hosts = rw.child_get_string("all-hosts")
                        if(all_hosts == "true") 
                            rw_list = rw_list + "all-hosts"
                            break
			end						
                    elsif(rw.child_get_string("name"))
                        host_name = rw.child_get_string("name")
                        rw_list = rw_list + host_name + ":"
	            end
		end
	    end			
            if(export.child_get("root"))
                root_results = export.child_get("root")
                root_hosts = root_results.children_get()
		root_hosts.each do |root|
                    if(root.child_get_string("all-hosts"))
                        all_hosts = root.child_get_string("all-hosts")
                        if(all_hosts == "true")
                            root_list = root_list + "all-hosts"
                            break
			end
                    elsif(root.child_get_string("name"))
                        host_name = root.child_get_string("name")
                        root_list = root_list + host_name + ":"
		    end
		end
	    end
            path_name = path_name + "  "
            if(ro_list != "ro=") 
		path_name = path_name + ro_list 
	    end
            if(rw_list != "rw=") 
		path_name = path_name + "," + rw_list
	    end
            if(root_list != "root=")
		path_name = path_name + "," + root_list 
	    end
            print (path_name + "\n")
	end
    else 
        print("Invalid operation\n")
        print_usage()
    end
end


do_nfs()

