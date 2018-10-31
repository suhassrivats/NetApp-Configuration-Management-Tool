#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# qtree_quota.rb                                             #
#                                                            #
# Creates qtree on volume and adds quota entry.              #
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
    print ("Usage:\n")
    print ("qtree_quota.rb <storage> <user> <passwd> ")
    print ("<volume> <qtree> [<mode>] \n")
    print ("<storage> -- Storage system name\n")
    print ("<user> -- User name\n")
    print ("<passwd> -- Password\n")
    print ("<volume> -- Volume name\n")
    print ("<qtree> -- Qtree name\n")
    print ("<mode> -- The file permission bits of the qtree.")
    print (" Similar to UNIX permission bits: 0755 gives ")
    print ("read/write/execute permissions to owner and ")
    print (" Similar to UNIX permission bits: 0755 gives ")
    print ("read/write/execute permissions to owner and ")
    print ("read/execute to group and other users.\n")
    exit 
end


def create_qtree_quota
    args = ARGV.length
    if(args < 5)
	print_usage
    end
    storage = ARGV[0]
    user = ARGV[1]
    pw = ARGV[2]
    volume = ARGV[3]
    qtree = ARGV[4]	
    if(args > 5)
	mode = ARGV[5]
    end	
    s = NaServer.new(storage, 1, 3)
    s.set_admin_user(user, pw)
    if(args >  5)
	out = s.invoke("qtree-create", "qtree", qtree, "volume", volume, "mode", mode )
    else 
        out = s.invoke( "qtree-create", "qtree", qtree, "volume", volume)
    end	
    if (out.results_status() == "failed")
        print(out.results_reason())
        print("\n")
        exit 
    end
    print ("Created new qtree\n")
end


create_qtree_quota()

