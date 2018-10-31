#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# resource_pool.py                                              #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to manage resource pool        #
# on a DFM server                                               #
# you can create,list and delete resource pools                 #
# add,list and remove members                                   #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.6R2   #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

import sys
sys.path.append("../../../../../../lib/python/NetApp")
from NaServer import *

def usage():
    print ("Usage:\nresource_pool.py <dfmserver> <user> <password> list [ <rpool> ]\n")
    print ("resource_pool.py <dfmserver> <user> <password> delete <rpool>\n")
    print ("resource_pool.py <dfmserver> <user> <password> create <rpool>  [ -t <rtag> ][-f <rp-full-thresh>] [-n <rp-nearly-full-thresh>]\n")
    print ("resource_pool.py <dfmserver> <user> <password> member-add <a-mem-rpool> <member> [ -m mem-rtag ]\n")
    print ("resource_pool.py <dfmserver> <user> <password> member-list <mem-rpool> [ <member> ]\n")
    print ("resource_pool.py <dfmserver> <user> <password> member-remove <mem-rpool> <member>\n")
    print ("<operation>             -- create or delete or list or member-add or member-list or member-remove\n")
    print ("<dfmserver>             -- Name/IP Address of the DFM server\n")
    print ("<user>                  -- DFM server User name\n")
    print ("<password>              -- DFM server User Password\n")
    print ("<rpool>                 -- Resource pool name\n")
    print ("<rtag>                  -- resource tag to be attached to a resourcepool\n")
    print ("<rp-full-thresh>        -- fullness threshold percentage to generate a resource pool full event.Range: [0..1000]\n")
    print ("<rp-nearly-full-thresh> -- fullness threshold percentage to generate a resource pool nearly full event.Range: [0..1000]\n")
    print ("<a-mem-rpool>           -- resourcepool to which the member will be added\n")
    print ("<mem-rpool>             -- resourcepool containing the member\n")
    print ("<member>                -- name or Id of the member (host or aggregate)\n")
    print ("<mem-rtag>              -- resource tag to be attached to member\n")
    sys.exit (1)


def create(server):
    # creating the input for api execution
    # creating a resourcepool-create element and adding child elements
    resource_input = NaElement("resourcepool-create")
    resourcepool = NaElement("resourcepool")
    resourcepoolinfo = NaElement("resourcepool-info")
    resourcepoolinfo.child_add_string( "resourcepool-name", dfmval )
    resourcepoolinfo.child_add_string( "resource-tag", resource_tag )
    resourcepoolinfo.child_add_string( "resourcepool-full-threshold", full_thresh )
    resourcepoolinfo.child_add_string( "resourcepool-nearly-full-threshold", nearly_full )
    resourcepool.child_add(resourcepoolinfo)
    resource_input.child_add(resourcepool)

    #invoking the api and printing the xml ouput
    output = server.invoke_elem(resource_input)

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    print ("\nResource pool creation Successful \n")


def resource_list(server):
    # invoking the api and capturing the ouput

    if (dfmval):
        output = server.invoke( "resourcepool-list-info-iter-start","object-name-or-id", dfmval )

    else :
        output = server.invoke("resourcepool-list-info-iter-start")

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    # Extracting the record and tag values and printing them
    records = output.child_get_string("records")

    if(int(records) == 0):
        print ("\nNo resourcepools to display\n")
        
    tag = output.child_get_string("tag")

    # Iterating through each record
    # Extracting records one at a time
    record = server.invoke( "resourcepool-list-info-iter-next", "maximum",  records,  "tag",  tag )

    if ( record.results_status() == "failed" ):
        print( "Error : " + record.results_reason() + "\n" )
        sys.exit(2)

    # Navigating to the resourcepools child element
    if(not record):
        sys.exit(0)

    else:
        stat = record.child_get("resourcepools")
        
    # Navigating to the resourcepool-info child element
    if(not stat):
        sys.exit (0)

    else:
        info = stat.children_get() 

    # Iterating through each record
    for info in info :
        # extracting the schedule details and printing it
        print ('-'*80 + "\n")
        print ("Resourcepool Name : " + str(info.child_get_string("resourcepool-name")) + "\n")
        print ("Resourcepool Id : "  + str(info.child_get_string("resourcepool-id")) + "\n")
        print ("Resource Description : " + str(info.child_get_string("resource-description")) + "\n")
        print ('-'*80 + "\n")

	# printing detials if only one resource-pool is selected for listing
        if (dfmval) :
            print ("\nResourcepool Status                      : " + str(info.child_get_string("resourcepool-status")) + "\n")
            print ("Resourcepool Perf Status                 : " + str(info.child_get_string("resourcepool-perf-status")) + "\n")
            print ("Resource Tag                             : " + str(info.child_get_string("resource-tag")) + "\n")
            print ("Resourcepool Member Count                : " + str(info.child_get_string("resourcepool-member-count")) + "\n")
            print ("Resourcepool Full Threshold              : " + str(info.child_get_string("resourcepool-full-threshold")) + "%\n")
            print ("Resourcepool Nearly Full Threshold       : " + str(info.child_get_string("resourcepool-nearly-full-threshold")) + "%\n")
            print ("Aggregate Nearly Overcommitted Threshold : " + str(info.child_get_string("aggregate-nearly-overcommitted-threshold")) + "%\n")
            print ("Aggregate Overcommitted Threshold        : " + info.child_get_string("aggregate-overcommitted-threshold") + "%\n")

    # invoking the iter-end zapi
    end = server.invoke( "resourcepool-list-info-iter-end", "tag", tag )

    if ( end.results_status() == "failed" ):
        print( "Error : " + end.results_reason() + "\n" )
        sys.exit(2)
    

def resource_del(server):
    # invoking the api and printing the xml ouput
    output = server.invoke( "resourcepool-destroy", "resourcepool-name-or-id", dfmval )

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    print ("\nResource pool deletion Successful \n")


def member_add(server):
    # creating the input for api execution
    # creating a resourcepool add member element and adding child elements
    resource_input = NaElement("resourcepool-add-member")
    resource_input.child_add_string( "member-name-or-id", dfmmem )
    resource_input.child_add_string( "resourcepool-name-or-id", dfmval )

    if(mem_rtag):
        resource_input.child_add_string( "resource-tag", mem_rtag )

    # invoking the api and printing the xml ouput
    output = server.invoke_elem(resource_input)

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    print ("\nMember Add Successful \n")


def member_list(server) :
    # invoking the api and capturing the ouput
    if (dfmmem) :
        output = server.invoke("resourcepool-member-list-info-iter-start","resourcepool-member-name-or-id", dfmmem, "resourcepool-name-or-id", dfmval)

    else :        
        output = server.invoke( "resourcepool-member-list-info-iter-start","resourcepool-name-or-id", dfmval )

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    # Extracting the record and tag values and printing them
    records = output.child_get_string("records")
    
    if(not records):
        print ("\nNo members to display\n")
        
    tag = output.child_get_string("tag")

    # Iterating through each record
    # Extracting records one at a time
    record = server.invoke( "resourcepool-member-list-info-iter-next","maximum", records, "tag", tag )

    if ( record.results_status() == "failed" ):
        print( "Error : " + record.results_reason() + "\n" )
        sys.exit(2)

    # Navigating to the resourcepools member element
    if(not record):
        sys.exit(0)

    else:
        stat = record.child_get("resourcepools")
        
    # Reading resourcepool-info child into array
    if(not stat):
        sys.exit (0)

    else:
        info = stat.children_get() 

    # Iterating through each record
    for info in info:
        # extracting the member name and printing it
        name = info.child_get_string("member-name")
        resource_id = info.child_get_string("member-id")

        if ( not dfmmem or ( dfmmem and ( name == dfmmem or resource_id == dfmmem ) ) ):
            print ('-'*80 + "\n")
            print ("Member Name : " + name + "\n")
            print ("Member Id : "  + resource_id + "\n")
            print ('-'*80 + "\n")

        else :
            print("\nMemeber " + dfmmem + " not found \n")
            sys.exit(1)

        # printing detials if only one member is selected for listing
        # This is a work around because list api wont return single child for
        # adding the member element
        if ( dfmmem and ( name == dfmmem or resource_id == dfmmem)):
            print ("\nMember Type            : " + info.child_get_string("member-type") + "\n")
            print ("Member Status          : " + info.child_get_string("member-status") + "\n")
            print ("Member Perf Status     : " + info.child_get_string("member-perf-status") + "\n")
            print ("Resource Tag           : " + info.child_get_string("resource-tag") + "\n")
            print ("Member Member Count    : " + info.child_get_string("member-member-count") + "\n")
            print ("Member Used Space      : " + info.child_get_string("member-used-space") + " bytes\n")
            print ("Member Committed Space : " + info.child_get_string("member-committed-space") + " bytes\n")
            print ("Member Size            : " + info.child_get_string("member-size") + " bytes\n")
            

    # invoking the iter-end zapi
    end = server.invoke( "resourcepool-member-list-info-iter-end", "tag", tag )

    if ( end.results_status() == "failed" ):
        print( "Error : " + end.results_reason() + "\n" )
        sys.exit(2)


def member_rem(server) :
    # invoking the api and printing the xml ouput
    output = server.invoke( "resourcepool-remove-member", "member-name-or-id", dfmmem, "resourcepool-name-or-id", dfmval )

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    print ("\nMember remove Successful n")



args = len(sys.argv) - 1

if(args < 4 ):
    usage()

dfmserver = sys.argv[1]
dfmuser = sys.argv[2]
dfmpw = sys.argv[3]
dfmop = sys.argv[4]

if(args > 5):
    dfmval = sys.argv[5]
    opt_param = sys.argv[6:]

    # extracting the member if its a member operation
    if(re.match(r'member', dfmop, re.I)):
        dfmmem = opt_param[0]

elif(args == 5):
    dfmval = sys.argv[5]
    dfmmem = None

else:
    dfmval = None
    dfmmem = None

resource_tag = None
full_thresh = None
nearly_full = None
mem_rtag = None

##### MAIN SECTION
# checking for valid number of parameters for the respective operations
if((dfmop == "list" and args < 4) or (dfmop == "delete" and args != 5) or (dfmop == "create" and args < 5) or (dfmop == "member-list" and args < 5) or (dfmop == "member-remove" and args != 6 ) or (dfmop == "member-add" and args < 6)):
    usage()

# checking if the operation selected is valid
if((dfmop != "list") and (dfmop != "create") and (dfmop != "delete") and (dfmop != "member-add") and (dfmop != "member-list") and (dfmop != "member-remove")):
    usage()
    
# parsing optional parameters
i = 0
while (dfmop == "create" and args > 5 and i < len(opt_param) ):

    if(opt_param[i]  == '-t'):
        i = i + 1
        resource_tag  = opt_param[i]
        i = i + 1

    elif(opt_param[i]  == '-f'):
        i = i + 1
        full_thresh = opt_param[i]
        i = i + 1

    elif(opt_param[i]  == '-n' ):
        i = i + 1
        nearly_full  = opt_param[i]
        i = i + 1

    elif(opt_param[i]  == '-m'):
        i = i + 1      
        mem_rtag  = opt_param[i]
        i = i + 1

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
    resource_list(serv)

elif(dfmop == 'delete'):
    resource_del(serv)

elif(dfmop == 'member-add'):
    member_add(serv)

elif(dfmop == 'member-list'):
    member_list(serv)

elif(dfmop == 'member-remove'):
    member_rem(serv)

else:
    usage()


