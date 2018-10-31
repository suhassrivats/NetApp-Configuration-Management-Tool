#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# snapmirror.rb                                              #
#                                                            #
# Sample code for the following APIs:                        #
#               snapmirror-get-status                        #
#               snapmirror-get-volume-status                 #
#               snapmirror-off                               #
#               snapmirror-on                                #
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
    print("snapmirror.rb <storage> <user> <password> <operation> [<value1>]\n ")
    print("<storage> -- Storage system name\n")
    print("<user> -- User name\n")
    print("<password> -- Password\n")
    print("<operation> -- Operation to be performed: ")
    print("getStatus/getVolStatus/off/on \n")
    print("[<value1>] -- Depends on the operation\n")
    exit 
end


# Snapmirror get status
# Usage: snapmirror.rb <storage> <user> <password> getStatus [<value1(location)>]
def get_status(s)
    if (not $value1) 
        out = s.invoke("snapmirror-get-status")
    else
        out = s.invoke("snapmirror-get-status", "location", $value1)
    end	
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    print ("-------------------------------------------------------------\n")
    print("Is snapmirror available: " + out.child_get_string("is-available"))
    print("\n")
    print ("-------------------------------------------------------------\n\n")
    status = out.child_get("snapmirror-status")
    if(status == nil)
	exit
    else
        result = status.children_get()
    end
    for snapStat in result do
        print("Contents: " + snapStat.child_get_string("contents") + "\n")
        print("Destination location: ")
        print(snapStat.child_get_string("destination-location") + "\n")
        print("Lag time: " + snapStat.child_get_string("lag-time") + "\n")
        print("Last transfer duration: ")
        print(snapStat.child_get_string("last-transfer-duration") + "\n")
        print("Last transfer from: ")
        print(snapStat.child_get_string("last-transfer-from") + "\n")
        print("Last transfer size: ")
        print(snapStat.child_get_string("last-transfer-size") + "\n")
        print("Mirror timestamp: ")
        print(snapStat.child_get_string("mirror-timestamp") + "\n")
        print("Source location: ")
        print(snapStat.child_get_string("source-location") + "\n")
        print("State: "+snapStat.child_get_string("state") + "\n")
        print("Status: "+snapStat.child_get_string("status") + "\n")
        print("Transfer progress: ")
        print(snapStat.child_get_string("transfer-progress") + "\n")
        print("------------------------------------------------------------\n")
    end
end


def get_vol_status(s)
    if (not $value1) 
	print_usage() 
    end	
    out = s.invoke("snapmirror-get-volume-status", "volume", $value1)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end	
    print ("-------------------------------------------------------------\n")
    print("Is destination: " + out.child_get_string("is-destination") + "\n")
    print("Is source: " + out.child_get_string("is-source") + "\n")
    print("Is transfer broken: " + out.child_get_string("is-transfer-broken") + "\n")
    print("Is transfer in progress: " + out.child_get_string("is-transfer-in-progress") + "\n")
    print ("-------------------------------------------------------------\n\n")
end


# Snapmirror off
# Usage: snapmirror.rb <storage> <user> <password> off
def snapmirror_off(s)
    out = s.invoke( "snapmirror-off")
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end	
    print ("Disabled SnapMirror data transfer and turned off the SnapMirror scheduler \n")
end


# Snapmirror on
# Usage: snapmirror.rb <storage> <user> <password> on
def snapmirror_on(s)
    out = s.invoke( "snapmirror-on")
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    print ("Enabled SnapMirror data transfer and turned on the SnapMirror scheduler \n")
end


def main
    if($args < 4)
	print_usage() 
    end	
    $x = 0
    storage = ARGV[0]
    user = ARGV[1]
    pw = ARGV[2]
    command = ARGV[3]
    s = NaServer.new(storage, 1, 3)
    s.set_admin_user(user, pw)
    if(command == "getStatus")
        get_status(s)
    elsif(command == "getVolStatus")
        get_vol_status(s)
    elsif(command == "off")
        snapmirror_off(s)
    elsif(command == "on")
        snapmirror_on(s)
    else
        print("Invalid operation\n")
        print_usage()
    end
end


$args = ARGV.length
if($args > 4)
    $value1 = ARGV[4]
else
    $value1 = nil
end
main()


