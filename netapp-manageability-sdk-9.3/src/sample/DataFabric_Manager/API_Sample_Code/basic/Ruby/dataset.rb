#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# dataset.rb                                                    #
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

$:.unshift '../../../../../../lib/ruby/NetApp'
require 'NaServer'

def usage
    print ("Usage:\n")
    print ("dataset.rb <dfmserver> <user> <password> list [ <dataset name> ]\n")
    print ("dataset.rb <dfmserver> <user> <password> delete <dataset name>\n")
    print ("dataset.rb <dfmserver> <user> <password> create <dataset name>[ -v <prov-pol> ] [ -t <prot-pol> ] [ -r <rpool>]\n")
    print ("dataset.rb <dfmserver> <user> <password> member-add <a-mem-dset> <member>\n")
    print ("dataset.rb <dfmserver> <user> <password> member-list <mem-dset> [ <member> ]\n")
    print ("dataset.rb <dfmserver> <user> <password> member-remove <mem-dset> <member>\n")
    print ("dataset.rb <dfmserver> <user> <password> member-provision <p-mem-dset> <member><size> [ <snap-size> | <data-size> ]\n")
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
    exit 
end


args = ARGV.length
if(args < 4 or args < 5 and ARGV[3] != "list")
    usage()
end
dfmserver = ARGV[0]
dfmuser = ARGV[1]
dfmpw = ARGV[2]
dfmop = ARGV[3]
$dfmval = nil
opt_param = nil

if(args > 5)
    $dfmval = ARGV[4]
    opt_param = ARGV[5,ARGV.length-1]
elsif(args == 5)
    $dfmval = ARGV[4]
end

# extracting the member if its a member operation
if(dfmop =~ /member/i and opt_param != nil)
    $dfmmem = opt_param[0]
end

if(dfmop =~ /member-provision/i)
    $size = opt_param[1]
    $max_size = opt_param[2]
end
$protname = nil
$respool = nil
$provname = nil


def create(server)
    # creating the input for api execution
    # creating a dataset-create element and adding child elements
    if ( not $protname )
        output = server.invoke( "dataset-create", "dataset-name", $dfmval,"provisioning-policy-name-or-id", $provname )
    else 
        output = server.invoke( "dataset-create", "dataset-name", $dfmval,"provisioning-policy-name-or-id", $provname, "protection-policy-name-or-id", $protname )
    end	
    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        exit 
    end
    print ("\nDataset creation passed\n")
    add_resource_pool(server) if ($respool) 
end
        

def add_resource_pool(server)
    policy = server.invoke( "dataset-edit-begin", "dataset-name-or-id", $dfmval )
    if (policy.results_status() == "failed") 
        print("Error : " + policy.results_reason() + "\n")
        exit 
    end
    # extracting the edit lock id
    lock_id = policy.child_get_int("edit-lock-id")
    # Invoking add resource pool element
    output = server.invoke( "dataset-add-resourcepool", "edit-lock-id", lock_id, "resourcepool-name-or-id", $respool )
    # edit-rollback has to happen else dataset will be locked
    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        exit 
	end
    # committing the edit and closing the lock session
    output2 = server.invoke( "dataset-edit-commit", "edit-lock-id", lock_id )
    if (output2.results_status() == "failed") 
        print("Error : " + output2.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        exit
    end
    print ("\nAdd resource pool Successful \n")
end


def dataset_list(server)
    # creating a input element
    input_element = NaElement.new("dataset-list-info-iter-start")
    if($dfmval)
	input_element.child_add_string( "object-name-or-id", $dfmval ) 
    end
    # invoking the api and capturing the ouput
    output = server.invoke_elem(input_element)
    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        exit 
    end
    # Extracting the record and tag values and printing them
    records = output.child_get_string("records")
    tag = output.child_get_string("tag")
    if(records.to_i == 0)
        print("\nNo datasets to display\n")
        record = server.invoke("dataset-list-info-iter-end", "tag", tag)
        exit
    end

    # Iterating through each record
    # Extracting records one at a time
    record = server.invoke( "dataset-list-info-iter-next", "maximum", records, "tag", tag )
    if (record.results_status() == "failed") 
        print("Error : " + record.results_reason() + "\n")
        exit 
    end
    # Navigating to the datasets child element
    if(not record)
        exit
    else
        stat = record.child_get("datasets")
    end
    # Navigating to the dataset-info child element
    if(not stat)
	exit 
    else
        info = stat.children_get()
    end
    # Iterating through each record
    info.each do |element|
        # extracting the dataset name and printing it
        print("-"*80 + "\n")
        print ("Dataset Name : " + element.child_get_string("dataset-name") + "\n")
        print ("Dataset Id : " + element.child_get_string("dataset-id") + "\n")
        print ("Dataset Description : " + element.child_get_string("dataset-description") + "\n")
        print ("-"*80 + "\n")

        # printing detials if only one dataset is selected for listing
        if ($dfmval) 
            print("\nDataset Contact        : " + element.child_get_string("dataset-contact") + "\n")
            print ("Provisioning Policy Id   : " + element.child_get_string("provisioning-policy-id").to_s + "\n")
            print ("Provisioning Policy Name : " + element.child_get_string("provisioning-policy-name").to_s + "\n")
            print ("Protection Policy Id     : " + element.child_get_string("protection-policy-id").to_s + "\n")
            print ("Protection Policy Name   : " + element.child_get_string("protection-policy-name").to_s + "\n")
            print ("Resource Pool Name       : " + element.child_get_string("resourcepool-name").to_s + "\n")
            status = element.child_get("dataset-status")
            print ("Resource Status          : " + status.child_get_string("resource-status").to_s + "\n")
            print ("Conformance Status       : " + status.child_get_string("conformance-status").to_s + "\n")
            print ("Performance Status       : " + status.child_get_string("performance-status").to_s + "\n")
            print ("Protection Status        : " + status.child_get_string("protection-status").to_s + "\n")
            print ("Space Status             : " + status.child_get_string("space-status").to_s + "\n")
	end
    end
    # invoking the iter-end zapi
    out = server.invoke( "dataset-list-info-iter-end", "tag", tag )	
    if (out.results_status() == "failed") 
        print("Error : " + out.results_reason() + "\n")
        exit 
    end
end


def dataset_del(server)
    # invoking the api and printing the xml ouput
    output = server.invoke( "dataset-destroy", "dataset-name-or-id", $dfmval )
    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        exit 
    end
    print ("\nDataset deletion Successful\n" )
end


def member_add(server)
    # beginning the edit session
    dataset = server.invoke( "dataset-edit-begin", "dataset-name-or-id", $dfmval )
    if (dataset.results_status() == "failed") 
        print("Error : " + dataset.results_reason() + "\n")
        exit 
    end
    # extracting the edit lock
    lock_id = dataset.child_get_int("edit-lock-id")
    # creating a add datsaet element
    input_element = NaElement.new("dataset-add-member")
    input_element.child_add_string( "edit-lock-id", lock_id )
    mem   = NaElement.new("dataset-member-parameters")
    param = NaElement.new("dataset-member-parameter")
    param.child_add_string( "object-name-or-id", $dfmmem )
    mem.child_add(param)
    input_element.child_add(mem)
    # invoking the api and printing the xml ouput
    output = server.invoke_elem(input_element)

    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        exit 
    end	
    output3 = server.invoke( "dataset-edit-commit", "edit-lock-id", lock_id )

    if (output3.results_status() == "failed") 
        print("Error : " + output3.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        exit
    end	
    print ("\nMember Add Successful\n" )
end


def member_list(server)
    # invoking the api and capturing the ouput
    if ($dfmmem) 
        output = server.invoke("dataset-member-list-info-iter-start", "dataset-name-or-id", $dfmval, "member-name-or-id", $dfmmem, "include-indirect","true", "include-space-info", "true")
    else 
        output = server.invoke("dataset-member-list-info-iter-start", "dataset-name-or-id", $dfmval, "include-indirect", "true", "include-space-info", "true" )
    end	
    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        exit 
    end	
    # Extracting the record and tag values and printing them
    records = output.child_get_string("records")
    tag = output.child_get_string("tag")
    if(records.to_i == 0)
	print ("\nNo members in the dataset\n")
	server.invoke("dataset-member-list-info-iter-end", "tag", tag)
	exit
    end
    # Iterating through each record
    # Extracting records one at a time
    record = server.invoke( "dataset-member-list-info-iter-next","maximum", records, "tag", tag )
    if (record.results_status() == "failed") 
        print("Error : " + record.results_reason() + "\n")
        exit 
    end
    # Navigating to the datasets child element
    if(not record)
        exit
    else
        stat = record.child_get("dataset-members")
    end
    # Navigating to the dataset-info child element
    if(not stat)
        exit 
    else
        information = stat.children_get()
    end
    # Iterating through each record
    information.each do |info|
        # extracting the member name and printing it
        name = info.child_get_string("member-name")
        member_id   = info.child_get_string("member-id")
        if(not (name =~ /-/i))
	    print ("-" *80 + "\n")
            print ("Member Name : " + name + "\n")
            print ("Member Id : " + member_id + "\n")
            print ("-" *80 + "\n")
	    # printing details if only one member is selected for listing
            if ($dfmmem) 
                print ("\nMember Type          : " + info.child_get_string("member-type") + "\n")
                print ("Member Status          : " + info.child_get_string("member-status") + "\n")
                print ("Member Perf Status     : " + info.child_get_string("member-perf-status") + "\n")
                print ("Storageset Id          : " + info.child_get_string("storageset-id") + "\n")
                print ("Storageset Name        : " + info.child_get_string("storageset-name") + "\n")
                print ("Node Name              : " + info.child_get_string("dp-node-name") + "\n")
	    end
	end
    end
    # invoking the iter-end zapi
    out = server.invoke( "dataset-member-list-info-iter-end", "tag", tag )
    if (out.results_status() == "failed") 
        print("Error : " + out.results_reason() + "\n")
        exit 
    end
end


def member_rem(server)
    dataset = server.invoke( "dataset-edit-begin", "dataset-name-or-id", $dfmval )
    if (dataset.results_status() == "failed") 
        print("Error : " + dataset.results_reason() + "\n")
        exit 
    end
    # extracting the edit lock
    lock_id = dataset.child_get_int("edit-lock-id")
    # creating a remove dataset member element
    input_element = NaElement.new("dataset-remove-member")
    input_element.child_add_string( "edit-lock-id", lock_id )
    mem   = NaElement.new("dataset-member-parameters")
    param = NaElement.new("dataset-member-parameter")
    param.child_add_string( "object-name-or-id", $dfmmem )
    mem.child_add(param)
    input_element.child_add(mem)
    # invoking the api and printing the xml ouput
    output = server.invoke_elem(input_element)

    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        exit 
    end
    output3 = server.invoke( "dataset-edit-commit", "edit-lock-id", lock_id )
    if (output3.results_status() == "failed") 
        print("Error : " + output3.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        exit
    end	
    print ("\nMember remove Successful\n" )
end


def member_prov(server)
    dataset = server.invoke( "dataset-edit-begin", "dataset-name-or-id", $dfmval )
    if (dataset.results_status() == "failed") 
        print("Error : " + dataset.results_reason() + "\n")
        exit 
    end	
    # extracting the edit lock
    lock_id = dataset.child_get_int("edit-lock-id")
    # creating a provision member element
    input_element = NaElement.new("dataset-provision-member")
    input_element.child_add_string( "edit-lock-id", lock_id )
    prov_mem = NaElement.new("provision-member-request-info")
    prov_mem.child_add_string( "name", $dfmmem )
    prov_mem.child_add_string( "size", $size )
    # snapshot space is not needed for nas policies
    prov_mem.child_add_string( "maximum-snapshot-space", $max_size )
    # snapshot space is not needed nas policies with nfs
    prov_mem.child_add_string( "maximum-data-size", $max_size )
    input_element.child_add(prov_mem)
    # invoking the api and printing the xml ouput
    output = server.invoke_elem(input_element)
	
    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        exit 
    end
    output3 = server.invoke( "dataset-edit-commit", "edit-lock-id", lock_id )    
	if (output3.results_status() == "failed") 
        print("Error : " + output3.results_reason() + "\n")
        server.invoke( "dataset-edit-rollback", "edit-lock-id", lock_id )
        exit 
    end
    # getting the job id for the commit
    job_id =( ( output3.child_get("job-ids") ).child_get("job-info") ).child_get_string("job-id")
    # tracking the job
    track_job(server,job_id)
end


def track_job(server, jobId)
    print ("Job ID\t\t: " + jobId + " \n")
    jobStatus = "running"
    print ("Job Status\t: " + jobStatus)
    while (jobStatus == "queued" or jobStatus == "running" or jobStatus == "aborting" )
        out = server.invoke( "dp-job-list-iter-start", "job-id", jobId )
        if ( out.results_status() == "failed" ) 
            print( "Error : " + out.results_reason() + "\n" )
            exit
	end	
	record = out.child_get_int("records")
	tag = out.child_get_string("tag")
	if(record == 0)
		print("\nError\n")
		server.invoke("dp-job-list-iter-end", "tag", tag)
		exit
	end
	out = server.invoke("dp-job-list-iter-next","maximum", record, "tag", tag)
        if ( out.results_status() == "failed" ) 
            print( "Error : " + out.results_reason() + "\n" )
            exit
	end
        #print out.sprintf()
        dpJobs = out.child_get("jobs")
        dpJobInfo = dpJobs.child_get("dp-job-info")
        jobStatus = dpJobInfo.child_get_string("job-state")
        sleep 5
        print (".")
        if ( jobStatus == "completed" or jobStatus == "aborted" ) 
            print ("\nOverall Status\t: " + dpJobInfo.child_get_string("job-overall-status") + "\n")
	end
    end
    out = server.invoke( "dp-job-progress-event-list-iter-start","job-id", jobId )
    if ( out.results_status() == "failed" ) 
        print( "Error : " + out.results_reason() + "\n" )
        exit
    end
    record = out.child_get_int("records")
    tag = out.child_get_string("tag")
    if(record == 0)
        print("\nError\n")
  	server.invoke("dp-job-progress-event-list-iter-end", "tag", tag)
	exit
    end	
    out = server.invoke("dp-job-progress-event-list-iter-next", "tag", tag, "maximum", record)
    if ( out.results_status() == "failed" )
        print( "Error : " + out.results_reason() + "\n" )
        exit
    end	
    progEvnts     = out.child_get("progress-events")
    progEvntsInfo = progEvnts.children_get("dp-job-progress-event-info")
    print ("\nProvision Details:\n")
    print ("=" *19 + "\n")
    progEvntsInfo.each do |evnt|
        if ( evnt.child_get_string("event-type") != "" ) 
            print (evnt.child_get_string("event-type"))
	end
        print ("\t: " + evnt.child_get_string("event-message") + "\n\n")
    end
end


##### MAIN SECTION
# checking for valid number of parameters for the respective operations
if((dfmop == "list" and args < 4) or (dfmop == "delete" and args != 5) or (dfmop == "create" and args < 5) \
   or (dfmop == "member-list" and args < 5) or (dfmop == "member-remove" and args != 6) \
   or (dfmop == "member-add" and args != 6) or (dfmop == "member-provision" and args < 7 ))
    usage()
end
# checking if the operation selected is valid
if ( (dfmop != "list" ) and ( dfmop != "create" ) and ( dfmop != "delete" ) \
        and ( dfmop != "member-add" ) and ( dfmop != "member-list" ) \
        and ( dfmop != "member-remove" ) and ( dfmop != "member-provision" ) )
    usage() 
end
# parsing optional parameters
i = 0
while (dfmop == "create" and args > 5 and  i < opt_param.length )
    if(opt_param[i]  == '-v')
        i = i + 1
        $provname = opt_param[i]
        i = i + 1
    elsif(opt_param[i]  == '-t')
        i = i + 1
        $protname  = opt_param[i]
        i = i + 1
    elsif(opt_param[i]  == '-r' )
        i = i + 1
        $respool   = opt_param[i]
        i = i + 1
    else 
        usage()
    end
end

# Creating a server object and setting appropriate attributes
serv = NaServer.new(dfmserver, 1, 0 )
serv.set_style('LOGIN')
serv.set_server_type('DFM')
serv.set_admin_user( dfmuser, dfmpw )
# Calling the subroutines based on the operation selected
if(dfmop == 'create')
    create(serv)
elsif(dfmop == 'list')
    dataset_list(serv)
elsif(dfmop == 'delete')
    dataset_del(serv)
elsif(dfmop == 'member-add')
   member_add(serv)
elsif(dfmop == 'member-list')
    member_list(serv)
elsif(dfmop == 'member-remove')
    member_rem(serv)
elsif(dfmop == 'member-provision')
    member_prov(serv)
else
    usage()
end

