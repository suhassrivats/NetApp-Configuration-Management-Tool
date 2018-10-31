#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# snmp.rb                                                    #
#                                                            #
# Sample code for the following APIs:                        #
#               snmp-get                                     #
#               snmp-status                                  #
#               snmp-community-add                           #
#               snmp-community-delete                        #
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
    print("snmp.rb <storage> <user> <password> <operation> [<value1>] ")
    print("[<value2>] \n")
    print("<storage> -- Storage system name\n")
    print("<user> -- User name\n")
    print("<password> -- Password\n")
    print("<operation> -- Operation to be performed: ")
    print("get/status/addCommunity/deleteCommunity \n")
    print("[<value1>] -- Depends on the operation \n")
    print("[<value2>] -- Depends on the operation \n")
    exit 
end


# SNMP Get operation
# Usage: snmp.rb <storage> <user> <password> get <value1(oid)>
def snmp_get(s)
    if (not $value1) 
	print_usage()
    end
    out = s.invoke("snmp-get", "object-id", $value1)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    print ("-------------------------------------------------------------\n")
    print("Value: " + out.child_get_string("value"))
    print("\n")
    if(out.child_get_string("is-value-hexadecimal"))
        print("Is value hexadecimal: ")
        print(out.child_get_string("is-value-hexadecimal") + "\n")
    end
    print ("-------------------------------------------------------------\n")
end

	
# SNMP Status.
# Usage: snmp.rb <storage> <user> <password> status
def snmp_status(s)
    out = s.invoke("snmp-status")
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    print("-------------------------------------------------------------\n")
    print("Contact: " + out.child_get_string("contact") + "\n")
    print("Is trap enabled: " + out.child_get_string("is-trap-enabled") + "\n")
    print("Location: " + out.child_get_string("location") + "\n")
    print("-------------------------------------------------------------\n")
    print ("Communities: \n\n")
    communities = out.child_get("communities")
    result = communities.children_get()
    for community in result do
        print("Access control: ")
        print(community.child_get_string("access-control") + "\n")
        print("Community: " + community.child_get_string("community") + "\n")
        print ("------------------------------------------------------------\n")
    end
    print ("Trap hosts: \n\n")
    traphosts = out.child_get("traphosts")
    result = traphosts.children_get()
    for traphost in result do
        print("Host name: " + traphost.child_get_string("host-name") + "\n")
        print("Ip address: " + traphost.child_get_string("ip-address") + "\n")
        print ("------------------------------------------------------------\n")
    end
end

	
# Add SNMP community
# Usage: snmp.rb <storage> <user> <password> addCommunity <value1(ro/rw)>
#               <value2(community)>
def add_community(s)
    if ($value1 == nil or $value2 == nil) 
	print_usage() 
    end
    out = s.invoke( "snmp-community-add", "access-control", $value1,"community", $value2)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    print ("Added community to the list of communities \n")
end


#Delete SNMP community
# Usage: snmp.rb <storage> <user> <password> deleteCommunity <value1(ro/rw)>
#               <value2(community)>
def delete_community(s)
    if (not $value1 or not $value2) 
	print_usage() 
    end
    out = s.invoke( "snmp-community-delete", "access-control", $value1, "community", $value2)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    print ("Deleted community from the list of communities. \n")
end


def main
    args = ARGV.length 
    if(args < 4)
	print_usage
    end
    storage = ARGV[0]
    user = ARGV[1]
    pw = ARGV[2]
    command = ARGV[3]
    if(args > 5)
	$value1 = ARGV[4]
	$value2 = ARGV[5]
    elsif (args == 5)
	$value1 = ARGV[4]
    end
    s = NaServer.new(storage, 1, 3)
    s.set_admin_user(user, pw)
    if(command == "get")
        snmp_get(s)
    elsif(command == "status")
        snmp_status(s)
    elsif(command == "addCommunity")
        add_community(s)
    elsif(command == "deleteCommunity")
        delete_community(s)
    else
        print("Invalid operation\n")
        print_usage()
    end
end


main()

