#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# optmgmt.rb                                                 #
#                                                            #
# Sample code for the following APIs:                        #
#               options-get                                  #
#               options-set                                  #
#               options-list-info                            #
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
    print ("optmgmt.rb <storage> <user> <password> <operation> [<value1>] ")
    print ("[<value2>] \n")
    print ("<storage> -- Storage system name\n")
    print ("<user> -- User name\n")
    print ("<password> -- Password\n")
    print ("<operation> -- Operation to be performed: get/set/optionsList\n")
    print ("[<value1>] -- Name of the option\n")
    print ("[<value2>] -- Value to be set\n")
    exit 
end


$args = ARGV.length
if($args < 4)
    print_usage()
end
$storage = ARGV[0]
$user = ARGV[1]
$pw = ARGV[2]
$option = ARGV[3]
$value1 = nil
$value2 = nil

if($args > 5)
    $value1 = ARGV[4]
    $value2 = ARGV[5]	
elsif($args == 5)
    $value1 = ARGV[4]
end


def get_option_info()
    if($args < 5)
        print_usage
    end
    out = $s.invoke("options-get", "name", $value1)
    if(out.results_status == "failed")
        print(out.results_reason() + "\n")
        exit
    end	
    print("-------------------------------------------------------------\n")
    print("Cluster constraint: " + out.child_get_string("cluster-constraint"))
    print("\n")
    print("Value: " + out.child_get_string("value") + "\n")
    print("-------------------------------------------------------------\n")
end


def set_option_info()
    if($args < 6)
        print_usage
    end
    out = $s.invoke("options-set", "name", $value1, "value", $value2)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end	
    print ("-------------------------------------------------------------\n")
    print("Cluster constraint: "+out.child_get_string("cluster-constraint"))
    print("\n")
    if(out.child_get_string("message"))
        print("Message: " + out.child_get_string("message") + "\n")
        print("-------------------------------------------------------------\n")
    end
end


def options_list_info()
    out = $s.invoke("options-list-info")
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    options_info = out.child_get("options")
    result = options_info.children_get()
    result.each do |opt|
	print("------------------------------------------------------------\n")
        print("Cluster constraint: ")
        print(opt.child_get_string("cluster-constraint") + "\n")
        print("Name: " + opt.child_get_string("name") + "\n")
        print("Value: " + opt.child_get_string("value") + "\n")
    end
end


def main
    $s = NaServer.new($storage, 1, 3)
    $s.set_admin_user($user, $pw)
    if($option == "get")
        get_option_info()
    elsif($option == "set")
        set_option_info()
    elsif($option == "optionsList")
        options_list_info()
    else
        print("Invalid Option \n")
        print_usage()
    end
end
	
main()


