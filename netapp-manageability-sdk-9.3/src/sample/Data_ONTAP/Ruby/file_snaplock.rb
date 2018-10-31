#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# file_snaplock.rb                                              #
#                                                               #
# Sample code for the usage of following APIs:                  #
#               file-get-snaplock-retention-time                #
#               file-snaplock-retention-time-list-info          #
#               file-set-snaplock-retention-time                #
#               file-get-snaplock-retention-time-list-info-max  #
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
    print("file_snaplock.rb <storage> <user> <password> <operation> <value1>")
    print("[<value2>]\n")
    print("<stoarge>   -- Storage system name\n")
    print("<user>      -- User name\n")
    print("<password>  -- Password\n")
    print("<operation> -- Operation to be performed: \n")
    print("\tfile-get-snaplock-retention-time\n")
    print("\tfile-set-snaplock-retention-time\n")
    print("\tfile-snaplock-retention-time-list-info\n")
    print("\tfile-get-snaplock-retention-time-list-info-max\n")
    print("<value1>    -- Depends on the operation \n")
    print("[<value2>]  -- Depends on the operation \n")
    exit 
end

$args = ARGV.length
if($args < 4) 
    print_usage()
end
$storage = ARGV[0]
$user = ARGV[1]
$pw  = ARGV[2]
$command = ARGV[3]


# file-snaplock-retention-time-list-info operation
# Usage: file_snaplock.rb <storage> <user> <password> file-snaplock-retention-time-list-info <filepath>
# <volumes>
def file_get_retention_list()
    if ($args < 5)
        print ("Usage: file_snaplock.rb <storage> <user> <password> file-snaplock-retention-time-list-info")
        print (" <filepathnames> \n")
        exit 
    end
    file_in = NaElement.new("file-snaplock-retention-time-list-info")
    pathnames = NaElement.new("pathnames")
    pathname_info = NaElement.new("pathname-info")

    #Now store rest of the volumes as a child element of pathnames
    #Here no_of_vols stores the total  no of volumes
    #Note:First volume is specified at 5th position from cmd prompt input
    i = 4
    while(i < ARGV.length)
        pathname_info.child_add_string("pathname", ARGV[i])
        i = i + 1
    end	
    pathnames.child_add(pathname_info)
    file_in.child_add(pathnames)
    # Invoke API
    out = $s.invoke_elem(file_in)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    retention_info = out.child_get("file-retention-details")
    result = retention_info.children_get()
    result.each do |path|
        formatted_date = path.child_get_string("formatted-retention-time")
        filepath = path.child_get_string("pathname")
        print("Retention date for the file" + filepath + " is " + formatted_date.to_s + "\n")
    end	
    print("\n")
end


# file-get-snaplock-retention-time operation
# Usage: file_snaplock.rb <storage> <user> <password> file-get-snaplock-retention-time <filepathnames>

def file_get_retention()
    if ($args < 5) 
        print ("Usage: file_snaplock.rb <storage> <user> <password> file-get-snaplock-retention-time")
        print (" <filepathnames> \n")
        exit 
    end	
    file_in = NaElement.new("file-get-snaplock-retention-time")
    path = ARGV[4]
    file_in.child_add_string("path", path)
    # Invoke API
    out = $s.invoke_elem(file_in)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    retention_time = out.child_get_int("retention-time")
    print ("retention time: " + retention_time.to_s + "\n")
    print ("\n")
end


# file-set-snaplock-retention-time operation
# Usage: file_snaplock.rb <storage> <user> <password> file-set-snaplock-retention-time <filepathnames>
def file_set_retention()
    if ($args < 6) 
        print ("Usage: file_snaplock.rb <storage> <user> <password> file-set-snaplock-retention-time")
        print (" <filepathnames> <retention-time>\n")
        exit 
    end
    path = ARGV[4]
    retention_time = ARGV[5]
    file_in = NaElement.new("file-set-snaplock-retention-time")
    file_in.child_add_string("path",path)
    file_in.child_add_string("retention-time",retention_time)
    # Invoke API
    out = $s.invoke_elem(file_in)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    print ("\n")
end


# file-get-snaplock-retention-time-list-info-max operation
# Usage: file_snaplock.rb <storage> <user> <password> file-get-snaplock-retention-time <filepathnames>

def file_get_retention_list_info_max()
    file_in = NaElement.new("file-get-snaplock-retention-time-list-info-max")
    # Invoke API
    out = $s.invoke_elem(file_in)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    max_entries = out.child_get_int("max-list-entries")
    print ("Max number of records = " + max_entries.to_s + "\n")
end
	
	
def main
    $s = NaServer.new($storage, 1, 3)
    $s.set_admin_user($user, $pw)
    if($command == "file-get-snaplock-retention-time")
        file_get_retention()
    elsif($command == "file-set-snaplock-retention-time")
        file_set_retention()
    elsif($command == "file-snaplock-retention-time-list-info")
        file_get_retention_list()
    elsif($command == "file-get-snaplock-retention-time-list-info-max")
        file_get_retention_list_info_max()
    else
        print("Invalid operation\n")
        print_usage()
    end
end


main()

