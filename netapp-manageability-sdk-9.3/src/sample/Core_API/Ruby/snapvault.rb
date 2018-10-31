#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# snapvault.rb                                                  #
#                                                               #
# Sample code for the following APIs:                           #
#       snapvault-primary-snapshot-schedule-list-info           #
#       snapvault-secondary-relationship-status-list-iter-start #
#       snapvault-secondary-relationship-status-list-iter-next  #
#       snapvault-secondary-relationship-status-list-iter-end   #
#                                                               #
# Copyright 2011 NetApp, Inc. All rights                        #
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
    print ("snapvault.rb <storage_system> <user> <password> <operation> [<value>]\n")
    print ("<storage> -- IP Address of storage_system\n")
    print ("<user> -- User name\n")
    print ("<password> -- Password\n")
    print ("<operation> -- Operation to be performed: ")
    print ("scheduleList/relationshipStatus \n")
    print ("[<value>] -- Depends on the operation\n")
    exit 
end

argc = ARGV.length
print_usage() if(argc < 4)
$storage = ARGV.shift
$user = ARGV.shift
$pw = ARGV.shift
$command = ARGV.shift
$value = nil
if(argc > 4)
    $value = ARGV.shift
end


def schedule_list()
    if(not $value)
        out = $s.invoke("snapvault-primary-snapshot-schedule-list-info")
    else
        out = $s.invoke("snapvault-primary-snapshot-schedule-list-info", "volume-name", $value)
    end	
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    schedules = out.child_get("snapshot-schedules")
    result = schedules.children_get()
    result.each do |schedule|
        print("Retention Count: ")
        print(schedule.child_get_string("retention-count") + "\n")
        print("Schedule name: ")
        print(schedule.child_get_string("schedule-name") + "\n")
        print("Volume name: " + schedule.child_get_string("volume-name") + "\n")
        print("------------------------------------------------------------\n")
    end
end
	
	
def relationship_status()
    out = $s.invoke("snapvault-secondary-relationship-status-list-iter-start")
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end	
    print "-------------------------------------------------------------\n"
    records = out.child_get_string("records")
    print("Records: " + records + "\n")
    tag = out.child_get_string("tag")
    print("Tag: " + tag + "\n")
    if(records.to_i > 0)
        rec = $s.invoke("snapvault-secondary-relationship-status-list-iter-next", "maximum", records, "tag", tag)
    end
    print "-------------------------------------------------------------\n"
    statList = rec.child_get("status-list")
    if (statList != nil)
        result = statList.children_get()
    else
        exit
    end
    result.each do |stat|
        print("Destination path: ")
        print(stat.child_get_string("destination-path") + "\n")
        print("Destination system: ")
        print(stat.child_get_string("destination-system") + "\n")
        print("Source path: ")
        print(stat.child_get_string("source-path") + "\n")
        print("Source system: ")
        print(stat.child_get_string("source-system") + "\n")
        print("State: ")
        print(stat.child_get_string("state") + "\n")
        print("Status: ")
        print(stat.child_get_string("status") + "\n")
        print("Source system: ")
        print(stat.child_get_string("source-system") + "\n")
        print "--------------------------------------------------------\n"
    end
    output = $s.invoke("snapvault-secondary-relationship-status-list-iter-end", "tag", tag)
end


def main()
    $s = NaServer.new($storage, 1, 3)
    $s.set_admin_user($user, $pw)
    if($command == "scheduleList")
        schedule_list()
    elsif($command == "relationshipStatus")
        relationship_status()
    else
        print("Invalid operation \n")
        print_usage()
    end
end


main()
