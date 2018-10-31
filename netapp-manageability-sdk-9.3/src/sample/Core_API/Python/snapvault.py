#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# snapvault.py                                                  #
#                                                               #
# Sample code for the following APIs: 	                        #
#	snapvault-primary-snapshot-schedule-list-info		#
#	snapvault-secondary-relationship-status-list-iter-start	#
#	snapvault-secondary-relationship-status-list-iter-next	#
#	snapvault-secondary-relationship-status-list-iter-end	#
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

import sys
sys.path.append("../../../../lib/python/NetApp")
from NaServer import *


def print_usage() :
    print ("snapvault.py <filer> <user> <password> <operation> [<value1>]\n")
    print ("<filer> -- Filer name\n")
    print ("<user> -- User name\n")
    print ("<password> -- Password\n")
    print ("<operation> -- Operation to be performed: ")
    print ("scheduleList/relationshipStatus \n")
    print ("[<value>] -- Depends on the operation\n")
    sys.exit (1)


def schedule_list(s):

    if(not value):
        out = s.invoke("snapvault-primary-snapshot-schedule-list-info")

    else:
        out = s.invoke("snapvault-primary-snapshot-schedule-list-info","volume-name",value)

    if(out.results_status() == "failed"):
        print("Failed: \n" + str(out.results_reason()) + "\n")
        sys.exit(2)

    schedules = out.child_get("snapshot-schedules")
    result = schedules.children_get()

    for schedule in result:
        print("Retention Count: " + schedule.child_get_string("retention-count") + "\n")
        print("Schedule name: " + schedule.child_get_string("schedule-name") + "\n")
        print("Volume name: " + schedule.child_get_string("volume-name") + "\n")
        print("------------------------------------------------------------\n")


# Usage: snapvault.py <filer> <user> <password> relationshipStatus
def relationship_status(s):
    out = s.invoke("snapvault-secondary-relationship-status-list-iter-start")

    if(out.results_status() == "failed"):
        print(str(out.results_reason()) + "\n")
        sys.exit(2)

    print("-------------------------------------------------------------\n")
    records = out.child_get_string("records")
    print("Records: " + records + "\n")
    tag = out.child_get_string("tag")
    print("Tag: " + tag + "\n")
    print("-------------------------------------------------------------\n")
    i = 0

    while(i < int(records)):
        rec = s.invoke("snapvault-secondary-relationship-status-list-iter-next", "maximum", 1, "tag", tag)

        if(rec.results_status() == "failed"):
            print(rec.results_reason() + "\n")
            sys.exit(2)

        print("Records: " + rec.child_get_string("records") + "\n")
        statList = rec.child_get("status-list")

        if (statList != None):
            result = statList.children_get()

        else:
            sys.exit(0)

        for stat in result:
            print("Destination path: " + stat.child_get_string("destination-path") + "\n")
            print("Destination system: " + stat.child_get_string("destination-system") + "\n")
            print("Source path: " + stat.child_get_string("source-path") + "\n")
            print("Source system: " + stat.child_get_string("source-system") + "\n")
            print("State: " + stat.child_get_string("state") + "\n")
            print("Status: " + stat.child_get_string("status") + "\n")
            print("Source system: " + stat.child_get_string("source-system") + "\n")
            print("--------------------------------------------------------\n")

        i = i + 1

    end = s.invoke("snapvault-secondary-relationship-status-list-iter-end","tag", tag)


def main():

    s = NaServer(filer, 1, 3)
    response = s.set_style('LOGIN')

    if(response and response.results_errno() != 0 ):
        r = response.results_reason()
        print ("Unable to set authentication style " + r + "\n")
        sys.exit (2)

    s.set_admin_user(user, pw)
    response = s.set_transport_type('HTTP')

    if(response and response.results_errno() != 0 ):
        r = response.results_reason()
        print ("Unable to set HTTP transport " + r + "\n")
        sys.exit (2)

    if(command == "scheduleList"):
        schedule_list(s)

    elif(command == "relationshipStatus"):
        relationship_status(s)

    else:
        print ("Invalid operation \n")
        print_usage()


argc = len(sys.argv)-1

if(argc < 4):
   print_usage()

filer = sys.argv[1]
user = sys.argv[2]
pw = sys.argv[3]
command = sys.argv[4]
value = None

if(argc > 4):
    value = sys.argv[5]

main()



