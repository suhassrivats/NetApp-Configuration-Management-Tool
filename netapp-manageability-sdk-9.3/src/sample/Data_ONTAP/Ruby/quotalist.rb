#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# quotalist.rb                                                  #
#                                                               #
# Sample code for the following APIs:                           #
#               quota-list-entries                              #
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
    print ("quotalist.rb <storage> <user> <password>\n")
    print ("<storage> -- Storage system name\n")
    print ("<user> -- User name\n")
    print ("<password> -- Password\n")
    exit 
end
	
args = ARGV.length
if(args < 3)
    print_usage
end
$storage = ARGV[0]
$user = ARGV[1]
$pw = ARGV[2]


def get_quota_info
    s = NaServer.new($storage, 1, 3)
    s.set_admin_user($user, $pw)
    out = s.invoke( "quota-list-entries" )
    if (out.results_status == "failed")
        print(out.results_reason() + "\n")
        exit 
    end
    quota_info = out.child_get("quota-entries")
    result = quota_info.children_get()
    print "-----------------------------------------------------\n"

    for quota in result do
        if(quota.child_get_string("quota-target"))
            quota_target = quota.child_get_string("quota-target")
            print  ("Quota Target: " + quota_target + " \n")
	end
        if(quota.child_get_string("volume"))
            volume = quota.child_get_string("volume")
            print  ("Volume: " + volume + "\n")
        end
        if(quota.child_get_string("quota-type"))
            quota_type = quota.child_get_string("quota-type")
            print  ("Quota Type: " + quota_type + "\n")
	end
        print ("-----------------------------------------------------\n")
    end
end

get_quota_info()

