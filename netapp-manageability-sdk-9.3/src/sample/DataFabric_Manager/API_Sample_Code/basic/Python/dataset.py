#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# dataset.py                                                    #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to manage dataset              #
# on a DFM server                                               #
# you can create,delete and list datasets                       #
# add,list,delete and provision members                         #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.8     #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

import time
import sys
sys.path.append("../../../../../../lib/python/NetApp")
from NaServer import *

def usage():
    print ("Usage:\n")
    print ("dataset.py <dfmserver> <user> <password> list [ <dataset name> ]\n")
    print ("dataset.py <dfmserver> <user> <password> delete <dataset name>\n")
    print ("dataset.py <dfmserver> <user> <password> create <dataset name> [ -v <prov-pol> ] [ -t <prot-pol> ] [ -r <rpool>]\n")
    print ("dataset.py <dfmserver> <user> <password> member-add <a-mem-dset> <member>\n")
    print ("dataset.py <dfmserver> <user> <password> member-list <mem-dset> [ <member> ]\n")
    print ("dataset.py <dfmserver> <user> <password> member-remove <mem-dset> <member>\n")
    print ("dataset.py <dfmserver> <user> <password> member-provision <p-mem-dset> <member> <size> [ <snap-size> | <data-size> ]\n")
    print ("<operation>    -- create or delete or list\n")
    print ("<dfmserver>    -- Name/IP Address of the DFM server\n")
    print ("<user>         -- DFM server User name\n")
    print ("<password>     -- DFM server User Password\n")
    print ("<dataset name> -- dataset name\n")
    print ("<prov-pol>     -- name or id of an exisitng nas provisioning policy\n")
    print ("<prot-pol>     -- name or id of an exisitng protection policy\n")
    print ("<rpool>        -- name or id of an exisitng resourcepool\n")
    print ("<a-mem-dset>   -- dataset to which the member will be added\n")
    print ("<mem-dset>     -- dataset containing the member\n")
    print ("<p-mem-dset>   -- dataset with resourcepool and provisioning policy attached\n")
    print ("<member>       -- name or Id of the member (volume/LUN or qtree)\n")
    print ("<size>         -- size of the member to be provisioned\n")
    print ("<snap-size>    -- maximum snapshot space required only for provisioning using \"san\" provision policy\n")
    print ("<data-size>    -- Maximum storage space space for the dataset member required only for provisioning using  \"nas\" provision policy with nfs\n")
    print ("Note : All size in bytes\n")
    sys.exit (1)


def create(server):
    # creating the input for api execution
    # creating a dataset-create element and adding child elements
    if ( not protname ):
        output = server.invoke( "dataset-create", "dataset-name", dfmval,"provisioning-policy-name-or-id", provname )

    else :
        output = server.invoke( "dataset-create", "dataset-name", dfmval,"provisioning-policy-name-or-id",
			provname, "protection-policy-name-or-id", protname )

    if (output.results_status() == "failed") :
        print("Error : " + output.results_reason() + "\n")
        sys.exit (2)

    print ("\nDataset creation Successful\n")

    if (respool):
        add_resource_pool(server)


def add_resource_pool(server):
    policy = server.invoke( "dataset-edit-begin", "dataset-name-or-id", dfmval )

    if (policy.results_status() == "failed") :
        print("Error : " + policy.results_reason() + "\n")
        sys.exit (2)

    # extracting the edit lock id
    lock_id = policy.child_get_int("edit-lock-id")

    # Invoking add resource pool element
    output = server.invoke( "dataset-add-resourcepool", "edit-lock-id", lock_id,"resourcepool-name-or-id", respool )

    # edit-rollback has to happen else dataset will be locked
    if (output.results_status() == "failed") :
        print("Error : " + output.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        sys.exit (2)

    # committing the edit and closing the lock session
    output2 = server.invoke( "dataset-edit-commit", "edit-lock-id", lock_id )

    if (output2.results_status() == "failed") :
        print("Error : " + output2.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        sys.exit(2)
  
    print ("\nAdd resource pool Successful\n")


def dataset_list(server):
    # creating a input element
    input_element = NaElement("dataset-list-info-iter-start")

    if(dfmval):
        input_element.child_add_string( "object-name-or-id", dfmval )

    # invoking the api and capturing the ouput
    output = server.invoke_elem(input_element)

    if (output.results_status() == "failed") :
        print("Error : " + output.results_reason() + "\n")
        sys.exit (2)

    # Extracting the record and tag values and printing them
    records = output.child_get_string("records")

    if(int(records) == 0):
        print ("\nNo datasets to display\n")

    tag = output.child_get_string("tag")

    # Iterating through each record
    # Extracting records one at a time
    record = server.invoke( "dataset-list-info-iter-next", "maximum", records, "tag", tag )

    if (record.results_status() == "failed") :
        print("Error : " + record.results_reason() + "\n")
        sys.exit (2)
    
    # Navigating to the datasets child element
    if(not record):
        sys.exit(0)

    else:
        stat = record.child_get("datasets")
    
    # Navigating to the dataset-info child element
    if(not stat):
        sys.exit (0)

    else:
        info = stat.children_get()

    # Iterating through each record
    for info in info:
        # extracting the dataset name and printing it
        print ("-"*80 +"\n")
        print ("Dataset Name : " + info.child_get_string("dataset-name") + "\n")
        print ("Dataset Id : " + info.child_get_string("dataset-id") + "\n")
        print ("Dataset Description : " + info.child_get_string("dataset-description") + "\n")
        print ("-"*80 + "\n")

	# printing detials if only one dataset is selected for listing
        if (dfmval) :
            print ("\nDataset Contact        : " + info.child_get_string("dataset-contact") + "\n")
            print ("Provisioning Policy Id   : " + str(info.child_get_string("provisioning-policy-id")) + "\n")
            print ("Provisioning Policy Name : " + str(info.child_get_string("provisioning-policy-name")) + "\n")
            print ("Protection Policy Id     : " + str(info.child_get_string("protection-policy-id")) + "\n")
            print ("Protection Policy Name   : " + str(info.child_get_string("protection-policy-name")) + "\n")
            print ("Resource Pool Name       : " +  str(info.child_get_string("resourcepool-name")) + "\n")
            status = info.child_get("dataset-status")
            print ("Resource Status          : " + str(status.child_get_string("resource-status")) + "\n")
            print ("Conformance Status       : " + str(status.child_get_string("conformance-status")) + "\n")
            print ("Performance Status       : " + str(status.child_get_string("performance-status")) + "\n")
            print ("Protection Status        : " + str(status.child_get_string("protection-status")) + "\n")
            print ("Space Status             : " + str(status.child_get_string("space-status")) + "\n")

    # invoking the iter-end zapi
    end = server.invoke( "dataset-list-info-iter-end", "tag", tag )
    if (end.results_status() == "failed") :
        print("Error : " + end.results_reason() + "\n")
        sys.exit (2)


def dataset_del(server):
    # invoking the api and printing the xml ouput
    output = server.invoke( "dataset-destroy", "dataset-name-or-id",dfmval )

    if (output.results_status() == "failed") :
        print("Error : " + output.results_reason() + "\n")
        sys.exit (2)

    print ("\nDataset deletion Successful\n")


def member_add(server):
    # beginning the edit session
    dataset = server.invoke( "dataset-edit-begin", "dataset-name-or-id", dfmval )

    if (dataset.results_status() == "failed") :
        print("Error : " + output.results_reason() + "\n")
        sys.exit (2)

    # extracting the edit lock
    lock_id = dataset.child_get_int("edit-lock-id")

    # creating a add datsaet element
    input_element = NaElement("dataset-add-member")
    input_element.child_add_string( "edit-lock-id", lock_id )
    mem   = NaElement("dataset-member-parameters")
    param = NaElement("dataset-member-parameter")
    param.child_add_string( "object-name-or-id", dfmmem )
    mem.child_add(param)
    input_element.child_add(mem)

    # invoking the api and printing the xml ouput
    output = server.invoke_elem(input_element)

    if (output.results_status() == "failed") :
        print("Error : " + output.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        sys.exit (2)

    output3 = server.invoke( "dataset-edit-commit", "edit-lock-id", lock_id )

    if (output3.results_status() == "failed") :
        print("Error : " + output3.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        sys.exit (2)

    print ("\nMember Add Successful \n")


def member_list(server):
    # invoking the api and capturing the ouput
    if (dfmmem) :
        output = server.invoke("dataset-member-list-info-iter-start", "dataset-name-or-id",dfmval,"member-name-or-id",dfmmem,"include-indirect",
                               "true","include-space-info","true")
    else :
        output = server.invoke( "dataset-member-list-info-iter-start","dataset-name-or-id", dfmval, "include-indirect", "true",
                                "include-space-info", "true" )

    if (output.results_status() == "failed") :
        print("Error : " + output.results_reason() + "\n")
        sys.exit (2)

    # Extracting the record and tag values and printing them
    records = output.child_get_string("records")

    if(not records):
        print ("\nNo members in the dataset\n")

    tag = output.child_get_string("tag")

    # Iterating through each record
    # Extracting records one at a time
    record = server.invoke( "dataset-member-list-info-iter-next","maximum", records, "tag", tag )

    if (record.results_status() == "failed") :
        print("Error : " + record.results_reason() + "\n")
        sys.exit (2)

    # Navigating to the datasets child element
    if(not record):
        sys.exit(0)

    else:
        stat = record.child_get("dataset-members")
    
    # Navigating to the dataset-info child element
    if(not stat):
        sys.exit (0)

    else:
        info = stat.children_get()

    # Iterating through each record
    for info in info:
        # extracting the member name and printing it
        name = info.child_get_string("member-name")
        member_id   = info.child_get_string("member-id")

        if(not (re.match(r'-',name,re.I))):
            print ("-" *80 + "\n")
            print ("Member Name : " + name + "\n")
            print ("Member Id : " + member_id + "\n")
            print ("-" *80 + "\n")
            # printing details if only one member is selected for listing
            if (dfmmem) :
                print ("\nMember Type          : " + info.child_get_string("member-type") + "\n")
                print ("Member Status          : " + info.child_get_string("member-status") + "\n")
                print ("Member Perf Status     : " + info.child_get_string("member-perf-status") + "\n")
                print ("Storageset Id          : " + info.child_get_string("storageset-id") + "\n")
                print ("Storageset Name        : " + info.child_get_string("storageset-name") + "\n")
                print ("Node Name              : " + info.child_get_string("dp-node-name") + "\n")

    # invoking the iter-end zapi
    end = server.invoke( "dataset-member-list-info-iter-end", "tag", tag )

    if (end.results_status() == "failed") :
        print("Error : " + end.results_reason() + "\n")
        sys.exit (2)
    

def member_rem(server):
    dataset = server.invoke( "dataset-edit-begin", "dataset-name-or-id", dfmval )

    if (dataset.results_status() == "failed") :
        print("Error : " + dataset.results_reason() + "\n")
        sys.exit (2)
     
    # extracting the edit lock
    lock_id = dataset.child_get_int("edit-lock-id")

    # creating a remove dataset member element
    input_element = NaElement("dataset-remove-member")
    input_element.child_add_string( "edit-lock-id", lock_id )
    mem   = NaElement("dataset-member-parameters")
    param = NaElement("dataset-member-parameter")
    param.child_add_string( "object-name-or-id", dfmmem )
    mem.child_add(param)
    input_element.child_add(mem)

    # invoking the api and printing the xml ouput
    output = server.invoke_elem(input_element)

    if (output.results_status() == "failed") :
        print("Error : " + output.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        sys.exit (2)

    output3 = server.invoke( "dataset-edit-commit", "edit-lock-id", lock_id )

    if (output3.results_status() == "failed") :
        print("Error : " + output3.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        sys.exit (2)

    print ("\nMember remove " + output.results_status() + "\n")


def member_prov(server):
    dataset = server.invoke( "dataset-edit-begin", "dataset-name-or-id", dfmval )

    if (dataset.results_status() == "failed") :
        print("Error : " + dataset.results_reason() + "\n")
        sys.exit (2)

    # extracting the edit lock
    lock_id = dataset.child_get_int("edit-lock-id")

    # creating a provision member element
    input_element = NaElement("dataset-provision-member")
    input_element.child_add_string( "edit-lock-id", lock_id )
    prov_mem = NaElement("provision-member-request-info")
    prov_mem.child_add_string( "name", dfmmem )
    prov_mem.child_add_string( "size", size )

    if(max_size != None):
        # snapshot space is not needed for nas policies
        prov_mem.child_add_string( "maximum-snapshot-space", max_size )

        # snapshot space is not needed nas policies with nfs
        prov_mem.child_add_string( "maximum-data-size", max_size )
    input_element.child_add(prov_mem)

    # invoking the api and printing the xml ouput
    output = server.invoke_elem(input_element)
    if (output.results_status() == "failed") :
        print("Error : " + output.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        sys.exit (2)

    output3 = server.invoke( "dataset-edit-commit", "edit-lock-id", lock_id )
    if (output3.results_status() == "failed") :
        print("Error : " + output3.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        sys.exit (2)

    # getting the job id for the commit
    job_id =( ( output3.child_get("job-ids") ).child_get("job-info") ).child_get_string("job-id")

    # tracking the job
    track_job(server,job_id)


def track_job(server, jobId):
    print ("Job ID\t\t: " + jobId + " \n")
    jobStatus = "running"
    print ("Job Status\t: " + jobStatus)

    while (jobStatus == "queued" or jobStatus == "running" or jobStatus == "aborting" ):
        out = server.invoke( "dp-job-list-iter-start", "job-id", jobId )
        if ( out.results_status() == "failed" ) :
            print( "Error : " + out.results_reason() + "\n" )
            sys.exit(2)

        out = server.invoke("dp-job-list-iter-next","maximum",out.child_get_string("records"), "tag",out.child_get_string("tag"))

        if ( out.results_status() == "failed" ) :
            print( "Error : " + out.results_reason() + "\n" )
            sys.exit(2)

        dpJobs = out.child_get("jobs")
        dpJobInfo = dpJobs.child_get("dp-job-info")
        jobStatus = dpJobInfo.child_get_string("job-state")
        time.sleep(5)
        print (".")
        if ( jobStatus == "completed" or jobStatus == "aborted" ) :
            print ("\nOverall Status\t: " + dpJobInfo.child_get_string("job-overall-status") + "\n")

    out = server.invoke( "dp-job-progress-event-list-iter-start","job-id", jobId )
    if ( out.results_status() == "failed" ) :
        print( "Error : " + out.results_reason() + "\n" )
        sys.exit(2)

    out = server.invoke("dp-job-progress-event-list-iter-next",  "tag", out.child_get_string("tag"), "maximum", out.child_get_string("records"))

    if ( out.results_status() == "failed" ):
        print( "Error : " + out.results_reason() + "\n" )
        sys.exit(2)

    progEvnts     = out.child_get("progress-events")
    progEvntsInfo = progEvnts.children_get()
    print ("\nProvision Details:\n")
    print ("=" *19 + "\n")

    for evnt in progEvntsInfo:
        event_type = evnt.child_get_string("event-type")
        event_message = evnt.child_get_string("event-message")
        if(event_type == None):
            event_type = ""
        if(event_message == None):
            event_message = ""
        print_str = event_type + "\t: " + event_message + "\n\n"
        print (print_str)



args = len(sys.argv) - 1
if(args < 4 or args < 5 and sys.argv[4] != "list"):
    usage()

dfmserver = sys.argv[1]
dfmuser = sys.argv[2]
dfmpw = sys.argv[3]
dfmop = sys.argv[4]
dfmmem = None

if(args > 5):
    dfmval = sys.argv[5]
    opt_param = sys.argv[6:]

elif(args == 5):
    dfmval = sys.argv[5]
    opt_param = None

else :
    dfmval = None
    opt_param = None


# extracting the member if its a member operation
if(re.match(r'member', dfmop, re.I) and opt_param != None):
    dfmmem = opt_param[0]  

if(re.match(r'member-provision', dfmop, re.I) and opt_param != None):
    size = opt_param[1]
    if(len(opt_param) > 2):
        max_size = opt_param[2]
    else:
        max_size = None

protname = None
respool = None
provname = None
##### MAIN SECTION
# checking for valid number of parameters for the respective operations
if((dfmop == "list" and args < 4)
   or (dfmop == "delete" and args != 5)
   or (dfmop == "create" and args < 5)
   or (dfmop == "member-list" and args < 5)
   or (dfmop == "member-remove" and args != 6)
   or (dfmop == "member-add" and args != 6)
   or (dfmop == "member-provision" and args < 7 )):
    usage()

# checking if the operation selected is valid
if ( (dfmop != "list" )
	and ( dfmop != "create" )
	and ( dfmop != "delete" )
	and ( dfmop != "member-add" )
	and ( dfmop != "member-list" )
	and ( dfmop != "member-remove" )
	and ( dfmop != "member-provision" ) ):
    usage()
# parsing optional parameters for create operation
if(dfmop == "create"):
    i = 0
    while ( i < len(opt_param) ):

        if(opt_param[i]  == '-v'):
            i = i + 1
            provname    = opt_param[i]
            i = i + 1

        elif(opt_param[i]  == '-t'):
            i = i + 1
            protname  = opt_param[i]
            i = i + 1

        elif(opt_param[i]  == '-r' ):
            i = i + 1
            respool   = opt_param[i]
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
    dataset_list(serv)
    
elif(dfmop == 'delete'):
    dataset_del(serv)

elif(dfmop == 'member-add'):
    member_add(serv)

elif(dfmop == 'member-list'):
    member_list(serv)

elif(dfmop == 'member-remove'):
    member_rem(serv)

elif(dfmop == 'member-provision'):
    member_prov(serv)

else:
    usage()



