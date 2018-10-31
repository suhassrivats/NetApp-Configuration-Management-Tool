#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# dfm_proxy.py                                                  #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to use DFM server as a proxy   #
# in sending API commands to a filer                            #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.6R2   #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

import sys
sys.path.append("../../../../../../lib/python/NetApp")
from NaServer import *


def print_usage():
   print ("Usage: dfm_proxy.py <dfmserver> <dfmuser> <dfmpassword> <filerip>\n")
   print ("<dfmserver> -- Name/IP Address of the DFM server\n")
   print ("<dfmuser> -- DFM server User name\n")
   print ("<dfmpassword> -- DFM server Password\n")
   print ("<filerip> -- Filer IP address\n")
   sys.exit (1)

args = len(sys.argv) - 1
if(args < 4):
    print_usage()

dfmserver = sys.argv[1]
dfmuser = sys.argv[2]
dfmpw	= sys.argv[3]
filerip = sys.argv[4]

s = NaServer(dfmserver, 1, 0)
s.set_style('LOGIN')
response = s.set_transport_type('HTTP')
s.set_server_type('DFM')
s.set_port(8088)
s.set_admin_user(dfmuser, dfmpw)

proxyElem = NaElement("api-proxy")
proxyElem.child_add_string("target", filerip)
requestElem = NaElement("request")
requestElem.child_add_string("name", "system-get-version")
proxyElem.child_add(requestElem)
out = s.invoke_elem(proxyElem)

if (out.results_status() == 'failed'):
    print(out.results_reason())
    print ("Error : " + out.results_reason() + "\n")
    sys.exit (1)

dfmResponse = out.child_get('response')

if (dfmResponse.child_get_string('status') == 'failed'):
    print ("Error: " + dfmResponse.child_get_string("reason") + "\n")
    sys.exit (1)

ontapiResponse = dfmResponse.child_get('results')

if (ontapiResponse.results_status() == 'failed'):
    print (ontapiResponse.results_reason() + "\n")
    sys.exit (1)

verStr = ontapiResponse.child_get_string('version')
print ("Hello world!  DOT version of " + filerip + " got from DFM-Proxy is" + verStr + "\n")

