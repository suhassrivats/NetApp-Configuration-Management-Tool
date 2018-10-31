#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# print_volume.rb                                            #
#                                                            #
# Retrieves & prints volume information.                     #
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
    print ("Usage: \n")
    print ("ruby print_volume.rb <storage> <user> <password>")
    print (" [<volume>]\n")
    exit 
end


def get_volume_info
    args = ARGV.length
    if(args < 3)
        print_usage
    end
    storage = ARGV[0]
    user = ARGV[1]
    pw = ARGV[2]	
    if(args == 4)
        volume = ARGV[3]
    end
    s = NaServer.new(storage, 1, 3)
    s.set_admin_user(user, pw)
    if(args == 3)
        out = s.invoke("volume-list-info")
    else
        out = s.invoke("volume-list-info", "volume", volume)
    end
    if(out.results_status == "failed")
        print (out.results_reason + "\n")
        exit 
    end
    volume_info = out.child_get("volumes")
    result = volume_info.children_get()
    result.each do |vol|
        vol_name = vol.child_get_string("name")
        print ("Volume name :" + vol_name + "\n")
        size_total = vol.child_get_int("size-total")
        print ("Total size: " + size_total.to_s + " bytes \n")
        size_used = vol.child_get_int("size-used")
        print ("Used Size : " + size_used.to_s + " bytes\n")
        print ("-------------------------------------------\n")
	end
end


get_volume_info()

