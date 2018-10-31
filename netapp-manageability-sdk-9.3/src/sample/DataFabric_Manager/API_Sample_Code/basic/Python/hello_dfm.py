#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# hello_dfm.py                                                  #
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

import sys
sys.path.append("../../../../../../lib/python/NetApp")
from NaServer import *


def print_usage():
    print ("Usage: hello_dfm.py <dfmserver> <dfmuser> <dfmpassword> \n")
    print ("<dfmserver> -- Name/IP Address of the DFM server \n")
    print ("<dfmuser> -- DFM server User name\n")
    print ("<dfmpassword> -- DFM server Password\n")
    sys.exit (1)

args = len(sys.argv)-1

if(args != 3):
    print_usage()

dfmserver = sys.argv[1]
dfmuser = sys.argv[2]
dfmpw = sys.argv[3]
s = NaServer(dfmserver, 1, 0)
s.set_style('LOGIN')
s.set_transport_type('HTTP')
s.set_server_type('DFM')
s.set_port(8088)
s.set_admin_user(dfmuser, dfmpw)
output = s.invoke("dfm-about")

if(output.results_errno() != 0):
    r = output.results_reason()
    print("Failed " + str(r) + "\n")

else :
    r = output.child_get_string("version")
    print("Hello World ! DFM Server version is: " + r + "\n")


