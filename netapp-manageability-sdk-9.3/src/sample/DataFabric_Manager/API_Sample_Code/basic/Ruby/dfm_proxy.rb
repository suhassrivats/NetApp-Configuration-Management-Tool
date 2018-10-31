#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# dfm_proxy.rb                                                  #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to use DFM server as a proxy   #
# in sending API commands to a storage system                   #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.6R2   #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

$:.unshift '../../../../../../lib/ruby/NetApp'
require 'NaServer'

def print_usage
    print ("Usage: dfm_proxy.rb <dfmserver> <dfmuser> <dfmpassword> <storageip>\n")
    print ("<dfmserver> -- Name/IP Address of the DFM server\n")
    print ("<dfmuser> -- DFM server User name\n")
    print ("<dfmpassword> -- DFM server Password\n")
    print ("<storageip> -- Storage system IP address\n")
    exit 
end


args = ARGV.length 
if(args < 4)
    print_usage
end
dfmserver = ARGV[0]
dfmuser = ARGV[1]
dfmpw   = ARGV[2]
storageip = ARGV[3]
s = NaServer.new(dfmserver, 1, 0)
s.set_style('LOGIN')
s.set_server_type('DFM')
s.set_admin_user(dfmuser, dfmpw)
proxyElem = NaElement.new("api-proxy")
proxyElem.child_add_string("target", storageip)
requestElem = NaElement.new("request")
requestElem.child_add_string("name", "system-get-version")
proxyElem.child_add(requestElem)
out = s.invoke_elem(proxyElem)

if (out.results_status == 'failed')
    print ("Error : " + out.results_reason() + "\n")
    exit 
end
dfmResponse = out.child_get('response')
if (dfmResponse.child_get_string('status') == 'failed')
    print("Error: " + dfmResponse.child_get_string("reason") + "\n")
    exit 
end
ontapiResponse = dfmResponse.child_get('results')
if (ontapiResponse.results_status == 'failed')
    print(ontapiResponse.results_reason() + "\n")
    exit 
end
verStr = ontapiResponse.child_get_string('version')
print ("Hello world!  DOT version of " + storageip + " got from DFM-Proxy is" + verStr + "\n")

