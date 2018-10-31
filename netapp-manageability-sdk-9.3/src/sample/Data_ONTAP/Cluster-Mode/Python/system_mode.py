#============================================================
#
# $ID$
#
# system_mode.py
# This sample code prints the mode of the Storage system
# (7-Mode or Cluster-Mode)
#
# Copyright (c) 2011 NetApp, Inc. All rights reserved.
# Specifications subject to change without notice.
#
#============================================================

import sys
sys.path.append("../../../../../lib/python/NetApp")
from NaServer import *


def print_usage():
    print ("Usage: system_mode.py <storage-system> <user> <password> \n")
    print ("<storage-system> -- Storage System name\n")
    print ("<user> -- User name\n")
    print ("<password> -- Password\n")
    sys.exit (1)

args = len(sys.argv) - 1
if(args < 3):
   print_usage()

storage = sys.argv[1]
user = sys.argv[2]
password = sys.argv[3]

s = NaServer(storage, 1, 0)
s.set_admin_user(user, password)
output = s.invoke("system-get-version")

if(output.results_errno() != 0):
    r = output.results_reason()
    print("Failed: \n" + str(r))
else :
    clustered = output.child_get_string("is-clustered")
    if(clustered == "true"):
        print("The Storage System " + storage + " is in \"Cluster Mode\"\n")
    else :
	print("The Storage System " + storage + " is in \"7 Mode\"\n")
