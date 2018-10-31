#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# nas_provisioning_policy.py                                    #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to manage provisioning policy  #
# on a DFM server                                               #
# you can create, delete and list nas provisioning policies     #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.8     #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

import sys
sys.path.append("../../../../../../lib/python/NetApp")
from NaServer import *

def usage():
    print ("Usage:\n")
    print ("nas_provisioning_policy.py <dfmserver> <user> <password> list [ <pol-name> ]\n")
    print ("nas_provisioning_policy.py <dfmserver> <user> <password> delete <pol-name>\n")
    print ("nas_provisioning_policy.py <dfmserver> <user> <password> create <pol-name>[ -d ] [ -c ] [ -s ] [ -r ] [ -S | -t ] [ -g <gquota> ] [ -u <uquota> ]\n")
    print ("<operation>     -- create or delete or list\n")
    print ("<dfmserver> -- Name/IP Address of the DFM server\n")
    print ("<user>      -- DFM server User name\n")
    print ("<password>  -- DFM server UserPassword\n")
    print ("<pol-name>  -- provisioning policy name\n")
    print ("[ -d ]      -- To enable dedupe\n")
    print ("[ -c ]      -- To enable resiliency against controller failure\n")
    print ("[ -s ]      -- To enable resiliency against sub-system failure\n")
    print ("[ -r ]      -- To disable snapshot reserve\n")
    print ("[ -S ]      -- To enable space on demand\n")
    print ("[ -t ]      -- To enable thin provisioning\n")
    print ("<gquota>    -- Default group quota setting in kb.  Range: [1..2^44-1]\n")
    print ("<uquota>    -- Default user quota setting in kb. Range: [1..2^44-1]\n")
    print ("Note : All options except provisioning policy name are optional and are required only by create operation\n")
    sys.exit (1)

	
def create(server):
    # creating the input for api execution
    # creating a provisioning-policy-create element and adding child elements
    dfm_input  = NaElement("provisioning-policy-create")
    policy = NaElement("provisioning-policy-info")
    policy.child_add_string( "provisioning-policy-name", dfmval )
    policy.child_add_string( "provisioning-policy-type", "nas" )

    # adding dedupe enable is its input
    if (dedupe_enable):
        policy.child_add_string( "dedupe-enabled", dedupe_enable )

    # creating the storage reliability child and adding parameters if input
    if ( controller_failure or subsystem_failure ) :
        storage_reliability = NaElement("storage-reliability")

        if (controller_failure):
            storage_reliability.child_add_string( "controller-failure",controller_failure )

        if (subsystem_failure):
            storage_reliability.child_add_string( "sub-system-failure",subsystem_failure )

        # appending storage-reliability child to parent and then to policy info
        policy.child_add(storage_reliability)

    # creating the nas container settings child and adding parameters if input
    if (group_quota or user_quota or snapshot_reserve or space_on_demand or thin_provision ):
        nas_container_settings = NaElement("nas-container-settings")

        if(group_quota):
            nas_container_settings.child_add_string( "default-group-quota", group_quota )

        if (user_quota):
            nas_container_settings.child_add_string( "default-user-quota", user_quota )

        if (snapshot_reserve):
            nas_container_settings.child_add_string( "snapshot-reserve", snapshot_reserve )

        if (space_on_demand):
            nas_container_settings.child_add_string( "space-on-demand", space_on_demand )

        if (thin_provision):
            nas_container_settings.child_add_string( "thin-provision", thin_provision )

        #appending nas-containter-settings child to policy info
        policy.child_add(nas_container_settings)

    dfm_input.child_add(policy)
    # invoking the api and printing the xml ouput
    output = server.invoke_elem(dfm_input)

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    print ("\nNAS Provisioning Policy creation Successful \n")


def dfm_list(server):
    if (dfmval):
        output = server.invoke( "provisioning-policy-list-iter-start",
			"provisioning-policy-name-or-id",
			dfmval, "provisioning-policy-type", "nas")
    else :
        output = server.invoke( "provisioning-policy-list-iter-start",
			"provisioning-policy-type", "nas"  )

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    # Extracting the record and tag values and printing them
    records = output.child_get_string("records")
    if(int(records) == 0):
        print("\nNo policies to display\n")

    tag = output.child_get_string("tag")

    # Extracting records one at a time
    record = server.invoke( "provisioning-policy-list-iter-next",
		"maximum", records, "tag", tag )

    if ( record.results_status() == "failed" ):
        print( "Error : " + record.results_reason() + "\n" )
        sys.exit(2)
    
    #Navigating to the provisioning-policys child element
    if(not record):
        sys.exit(0)

    else:
        stat = record.child_get("provisioning-policies")
    
    # Navigating to the provisioning-policy-info child element
    if(not stat):
        sys.exit (0)

    else:
       info = stat.children_get() 

    # Iterating through each record
    for info in info:
        nas_container_settings = info.child_get("nas-container-settings")

        if (nas_container_settings) :
            print ('-'*80 + "\n")
            # extracting the provisioning policy name and printing it
            print ("Policy Name : " + info.child_get_string("provisioning-policy-name") + "\n")
            print ("Policy Id : "  + info.child_get_string("provisioning-policy-id") + "\n")
            print ("Policy Description : " + info.child_get_string("provisioning-policy-description") + "\n")
            print ('-'*80 + "\n")

            # printing detials if only one policy is selected for listing
            if (dfmval) :
                print ("\nPolicy Type      :" + info.child_get_string("provisioning-policy-type") + "\n")
                print ("Dedupe Enabled     :" + info.child_get_string("dedupe-enabled") + "\n")
                storage_reliability = info.child_get("storage-reliability")
                print ("Disk Failure       :" + storage_reliability.child_get_string("disk-failure") + "\n")
                print ("Subsystem Failure  :" + storage_reliability.child_get_string("sub-system-failure") + "\n")
                print ("Controller Failure :" + storage_reliability.child_get_string("controller-failure") + "\n")
                print ("Default User Quota : " + nas_container_settings.child_get_string("default-user-quota") + " kb\n")
                print ("Default Group Quota: " + nas_container_settings.child_get_string("default-group-quota") + " kb\n")
                print ("Snapshot Reserve   : " + nas_container_settings.child_get_string("snapshot-reserve") + "\n")
                print ("Space On Demand    : " + nas_container_settings.child_get_string("space-on-demand") + "\n")
                print ("Thin Provision     : " + nas_container_settings.child_get_string("thin-provision") + "\n")
                
        if ( dfmval and not nas_container_settings ) :
            print ("\nsan type of provisioning policy is not supported for listing\n")

    end = server.invoke( "provisioning-policy-list-iter-end", "tag", tag )

    if(end.results_status() == "failed"):
        print( "Error : " + end.results_reason() + "\n" )
        sys.exit(2)


def policy_del(server):
    # invoking the api and printing the xml ouput
    output = server.invoke( "provisioning-policy-destroy","provisioning-policy-name-or-id", dfmval)

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)
     
    print ("\nNAS Provisioning Policy deletion Successful\n")


args = len(sys.argv) - 1

if(args < 4):
    usage()
    
dfmserver = sys.argv[1]
dfmuser = sys.argv[2]
dfmpw = sys.argv[3]
dfmop = sys.argv[4]
dfmval = None
opt_param = [] 

if(args > 5):
    dfmval = sys.argv[5]
    opt_param = sys.argv[6:]

elif(args == 5):
    dfmval = sys.argv[5]
    
group_quota = None
user_quota = None
dedupe_enable = None
controller_failure = None
subsystem_failure = None
snapshot_reserve = None
space_on_demand = None
thin_provision = None

# checking for valid number of parameters for the respective operations  
if((dfmop == "list" and args < 4) or (dfmop == "delete" and args != 5) or (dfmop == "create" and args < 5)):
    usage()
    
# checking if the operation selected is valid
if((dfmop != "list") and (dfmop != "create") and (dfmop != "delete")):
    usage()

# parsing optional parameters
i = 0
while (i < len(opt_param)):
    if(opt_param[i]  == '-g'):
        i = i + 1
        group_quota = opt_param[i]
        i = i + 1
        
    elif(opt_param[i]  == '-u'):
        i = i + 1
        user_quota  = opt_param[i]
        i = i + 1

    elif(opt_param[i]  == '-d' ):
        i = i + 1
        dedupe_enable = "true"

    elif(opt_param[i]  == '-c'):
        i = i + 1      
        controller_failure = "true"

    elif(opt_param[i]  == '-s'):
        i = i + 1
        subsystem_failure  = "true"

    elif(opt_param[i]  == '-r'):
        i = i + 1
        snapshot_reserve = "false"

    elif(opt_param[i]  == '-S'):
        i = i + 1
        space_on_demand = "true"

    elif(opt_param[i]  == '-t'):
        i = i + 1
        thin_provision = "true"

    else :
        usage()


# Creating a server object and setting appropriate attributes
serv = NaServer(dfmserver, 1, 0 )
serv.set_style('LOGIN')
serv.set_transport_type('HTTP')
serv.set_server_type('DFM')
serv.set_port(8088)
serv.set_admin_user( dfmuser, dfmpw )

# Calling the subroutines based on the operation selected
if(dfmop == 'create'):
    create(serv)

elif(dfmop == 'list'):
    dfm_list(serv)

elif(dfmop == 'delete'):
    policy_del(serv)

else:
    usage()



