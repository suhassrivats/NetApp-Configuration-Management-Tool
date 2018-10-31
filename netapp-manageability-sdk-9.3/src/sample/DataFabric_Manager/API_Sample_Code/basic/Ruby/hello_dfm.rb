#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# hello_dfm.rb                                                  #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# This program will print the version number of the DFM Server  #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.6R2   #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

$:.unshift '../../../../../../lib/ruby/NetApp'
require 'NaServer'

def print_usage
    print ("Usage: hello_dfm.rb <dfmserver> <dfmuser> <dfmpassword> \n")
    print ("<dfmserver> -- Name/IP Address of the DFM server \n")
    print ("<dfmuser> -- DFM server User name\n")
    print ("<dfmpassword> -- DFM server Password\n")
    exit 
end


args = ARGV.length
if(args != 3)
    print_usage()
end
dfmserver = ARGV[0]
dfmuser = ARGV[1]
dfmpw = ARGV[2]

s = NaServer.new(dfmserver, 1, 0)
s.set_style('LOGIN')
s.set_transport_type('HTTP')
s.set_server_type('DFM')
s.set_port(8088)
s.set_admin_user(dfmuser, dfmpw)
output = s.invoke("dfm-about")
if(output.results_errno != 0)
    r = output.results_reason()
    print("Failed "  + r + "\n")
else 
    r = output.child_get_string("version")
    print("Hello World ! DFM Server version is: " + r + "\n")
end


