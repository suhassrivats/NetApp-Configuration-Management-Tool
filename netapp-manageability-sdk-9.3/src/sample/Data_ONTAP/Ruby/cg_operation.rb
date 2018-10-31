#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# cg_operation.rb                                               #
#                                                               #
# Sample code for the usage of following APIs:                  #
#               cg-start                                        #
#               cg-commit                                       #
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
    print ("cg_operation.rb <storage> <user> <password> <operation> <value1>")
    print ("[<value2>] [<volumes>]\n")
    print ("<storage>   -- storage system name\n")
    print ("<user>      -- User name\n")
    print ("<password>  -- Password\n")
    print ("<operation> -- Operation to be performed: ")
    print ("cg-start/cg-commit\n")
    print ("<value1>    -- Depends on the operation \n")
    print ("[<value2>]  -- Depends on the operation \n")
    print ("[<volumes>] --List of volumes.Depends on the operation \n")
    exit 
end


$args = ARGV.length
if($args < 5)
    print_usage()
end
$storage = ARGV[0]
$user = ARGV[1]
$pw = ARGV[2]
$command = ARGV[3]
$value1 = ARGV[4]
if($args > 5)
    $value2 = ARGV[5]
end


def main
    # check for valid number of parameters
    $s = NaServer.new($storage, 1, 3)
    $s.set_admin_user($user, $pw)
    if($command == "cg-start")
        cg_start()
    elsif($command == "cg-commit")
        cg_commit()
    else
        print("Invalid operation\n")
        print_usage()
    end
end


# cg-start operation
# Usage: cg_operation.rb <storage> <user> <password> cg-start <snapshot> <timeout>
# <volumes>

def cg_start()
    if ($args < 7) 
        print ("cg_operation.rb <storage> <user> <password> cg-start ")
        print (" <snapshot> <timeout> <volumes> \n")
        print ("cg_operation.rb <storage> <user> <password> cg-start ")
        print (" <snapshot> <timeout> <volumes> \n")
        exit 
    end
    cg_in = NaElement.new("cg-start")
    cg_in.child_add_string("snapshot", $value1)
    cg_in.child_add_string("timeout", $value2)
    vols = NaElement.new("volumes")
    #Now store rest of the volumes as a child element of vols
    ##Here no_of_var_arguments stores the total  no of volumes
    #Note:First volume is specified at 7th position from cmd prompt input
    no_of_var_arguments = $args
    i = 6
    while(i < no_of_var_arguments)
        vols.child_add_string("volume-name", ARGV[i])
        i = i + 1
    end
    cg_in.child_add(vols)
    # # Invoke cg-start API     #
    out = $s.invoke_elem(cg_in)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit 
    end
    cg_id = out.child_get_string( "cg-id" )
    print ("Consistency Group operation started successfully with cg-id=" + cg_id + "\n")
end


# cg-commit operation
# Usage: cg_operation.rb <storage> <user> <password> cg-commit <cg-id>
def cg_commit()
    if ($args < 5)
        print ("cg_operation.rb <storage> <user> <password> cg-commit ")
        print ("<cg-id> \n")
        exit 
    end
    ## Invoke cg-commit API     #
    out = $s.invoke("cg-commit", "cg-id", $value1)
    if(out.results_status() == "failed")
        print(out.results_reason() + "\n")
        exit
    end
    print ("Consistency Group operation commited successfully\n")
end

main()

