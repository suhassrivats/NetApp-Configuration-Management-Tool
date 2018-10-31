#============================================================#
#                                                            #
# $ID:$                                                      #
#                                                            #
# hello_ontapi.rb                                            #
#                                                            #
# "Hello_world" program which prints the ONTAP version       #
# number of the destination storage system                   #
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
# tab size = 8                                               #
#                                                            #
#============================================================#

$:.unshift '../../../../lib/ruby/NetApp'
require 'NaServer'

def print_usage
    print ("Usage: hello_ontapi.rb <storage_system> <user> <password> \n")
    print ("<storage> -- storage_system\n")
    print ("<user> -- User name\n")
    print ("<password> -- Password\n")
    exit
end
	

args = ARGV.length
if(args < 3)
    print_usage
end
storage = ARGV[0]
user = ARGV[1]
password = ARGV[2]

s = NaServer.new(storage, 1, 1)
s.set_server_type("Filer")
s.set_admin_user(user, password)
s.set_transport_type("HTTP")
output = s.invoke("system-get-version")

if(output.results_errno() != 0)
    r = output.results_reason()
    print("Failed : \n" + r)
else 
    r = output.child_get_string("version")
    print ("Hello World ! DOT version is : " + r + "\n")
end
