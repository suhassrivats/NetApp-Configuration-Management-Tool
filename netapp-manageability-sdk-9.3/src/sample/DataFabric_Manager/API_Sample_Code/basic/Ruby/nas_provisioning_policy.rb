#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# nas_provisioning_policy.rb                                    #
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

$:.unshift '../../../../../../lib/ruby/NetApp'
require 'NaServer'

def usage()
    print ("Usage:\n")
    print ("nas_provisioning_policy.rb <dfmserver> <user> <password> list [ <pol-name> ]\n")
    print ("nas_provisioning_policy.rb <dfmserver> <user> <password> delete <pol-name>\n")
    print ("nas_provisioning_policy.rb <dfmserver> <user> <password> create <pol-name>[ -d ] [ -c ] [ -s ] [ -r ] [ -S | -t ] [ -g <gquota> ] [ -u <uquota> ]\n")
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
    exit 
end


def create()
	group_quota = nil
	user_quota = nil
	dedupe_enable = nil
	controller_failure = nil
	subsystem_failure = nil
	snapshot_reserve = nil
	space_on_demand = nil
	thin_provision = nil
	# parsing optional parameters
	if(ARGV.length > 6)
		opt_param = ARGV[5, ARGV.length-1]	
	else
		opt_param = []
	end	
	i = 0
	while (i < opt_param.length - 1 )	
		if(opt_param[i]  == '-g')
			i = i + 1
			group_quota = opt_param[i]
			i = i + 1
		elsif(opt_param[i]  == '-u')
			i = i + 1
			user_quota  = opt_param[i]
			i = i + 1		
		elsif(opt_param[i]  == '-d' )
			dedupe_enable = "true"
			i = i + 1
		elsif(opt_param[i]  == '-c')
			controller_failure = "true"	
			i = i + 1		
		elsif(opt_param[i]  == '-s')
			subsystem_failure  = "true"
			i = i + 1
		elsif(opt_param[i]  == '-r')
			snapshot_reserve   = "false"
			i = i + 1
		elsif(opt_param[i]  == '-S')
			space_on_demand    = "true"
			i = i + 1	
		elsif(opt_param[i]  == '-t')
			thin_provision     = "true"
			i = i + 1		
		else 
			usage()
		end
	end
	
    # creating the input for api execution
    # creating a provisioning-policy-create element and adding child elements
    dfm_input  = NaElement.new("provisioning-policy-create")
    policy = NaElement.new("provisioning-policy-info")
    $dfmval = ARGV[4]
    policy.child_add_string( "provisioning-policy-name", $dfmval )
    policy.child_add_string( "provisioning-policy-type", "nas" )	
    # adding dedupe enable is its input
    if (dedupe_enable)
	policy.child_add_string( "dedupe-enabled", dedupe_enable ) 
    end
    # creating the storage reliability child and adding parameters if input
    if ( controller_failure or subsystem_failure ) 
        storage_reliability = NaElement.new("storage-reliability")
        if (controller_failure)
            storage_reliability.child_add_string( "controller-failure",controller_failure )
	end		
        if (subsystem_failure)
            storage_reliability.child_add_string( "sub-system-failure",subsystem_failure )
	end		
        # appending storage-reliability child to parent and then to policy info
        policy.child_add(storage_reliability)
    end
	
    # creating the nas container settings child and adding parameters if input
    if (group_quota or user_quota or snapshot_reserve or space_on_demand or thin_provision )
	nas_container_settings = NaElement.new("nas-container-settings")		
        if(group_quota)
            nas_container_settings.child_add_string( "default-group-quota",group_quota )
	end		
        if (user_quota)
            nas_container_settings.child_add_string( "default-user-quota",user_quota )
	end		
        if (snapshot_reserve)
            nas_container_settings.child_add_string( "snapshot-reserve",snapshot_reserve )
	end		
        if (space_on_demand)
            nas_container_settings.child_add_string( "space-on-demand",space_on_demand )
	end		
        if (thin_provision)
            nas_container_settings.child_add_string( "thin-provision",thin_provision )
	end
	#appending nas-containter-settings child to policy info
	policy.child_add(nas_container_settings)
    end
	
    dfm_input.child_add(policy)
    # invoking the api and printing the xml ouput
    output = $server.invoke_elem(dfm_input)	
    if ( output.results_status() == "failed" )
        print( "Error : " + output.results_reason() + "\n" )
        exit
    end
    print ("\nNAS Provisioning Policy creation Successful\n")
end


def dfm_list()	
    if ($dfmval)
        output = $server.invoke( "provisioning-policy-list-iter-start", "provisioning-policy-name-or-id", $dfmval, "provisioning-policy-type", "nas") 
	else 
        output = $server.invoke( "provisioning-policy-list-iter-start", "provisioning-policy-type", "nas"  )
    end	
    if ( output.results_status() == "failed" )
        print( "Error : " + output.results_reason() + "\n" )
        exit
    end
    # Extracting the record and tag values and printing them
    records = output.child_get_string("records")	
    tag = output.child_get_string("tag")
    if(records.to_i == 0)
        print("\nNo policies to display\n")
        $server.invoke("provisioning-policy-list-iter-end", "tag", tag)
        exit
    end

    # Extracting records one at a time
    record = $server.invoke( "provisioning-policy-list-iter-next", "maximum", records, "tag", tag )
    if ( record.results_status() == "failed" )
        print( "Error : " + record.results_reason() + "\n" )
        exit
    end
    # Navigating to the provisioning-policys child element
    if(not record)
        exit
    else
        stat = record.child_get("provisioning-policies")
    end
    # Navigating to the provisioning-policy-info child element
    if(not stat)
	exit 
    else
       info = stat.children_get() 
    end
	
    # Iterating through each record
    info.each do |element|
        nas_container_settings = element.child_get("nas-container-settings")
        if (nas_container_settings) 
            print ('-'*80 + "\n")
            # extracting the provisioning policy name and printing it
            print ("Policy Name : " + element.child_get_string("provisioning-policy-name") + "\n")
            print ("Policy Id : "  + element.child_get_string("provisioning-policy-id") + "\n")
            print ("Policy Description : " + element.child_get_string("provisioning-policy-description") + "\n")
            print ('-'*80 + "\n")
		
            # printing detials if only one policy is selected for listing
            if ($dfmval) 
                print ("\nPolicy Type      :" + element.child_get_string("provisioning-policy-type") + "\n")
                print ("Dedupe Enabled     :" + element.child_get_string("dedupe-enabled") + "\n")
                storage_reliability = element.child_get("storage-reliability")
                print ("Disk Failure       :" + storage_reliability.child_get_string("disk-failure") + "\n")
                print ("Subsystem Failure  :" + storage_reliability.child_get_string("sub-system-failure") + "\n")
                print ("Controller Failure :" + storage_reliability.child_get_string("controller-failure") + "\n")
                print ("Default User Quota : " + nas_container_settings.child_get_string("default-user-quota") + " kb\n")
                print ("Default Group Quota: " + nas_container_settings.child_get_string("default-group-quota") + " kb\n")
                print ("Snapshot Reserve   : " + nas_container_settings.child_get_string("snapshot-reserve") + "\n")
                print ("Space On Demand    : " + nas_container_settings.child_get_string("space-on-demand") + "\n")
                print ("Thin Provision     : " + nas_container_settings.child_get_string("thin-provision") + "\n")
            end
	end		
        if ( $dfmval and not nas_container_settings ) 
            print ("\nsan type of provisioning policy is not supported for listing\n")
	end
    end	
    output = $server.invoke( "provisioning-policy-list-iter-end", "tag", tag )
    if(output.results_status() == "failed")
        print( "Error : " + output.results_reason() + "\n" )
        exit
    end	
end


def policy_del()
    # invoking the api and printing the xml ouput
    output = $server.invoke( "provisioning-policy-destroy","provisioning-policy-name-or-id", $dfmval)
    if ( output.results_status() == "failed" )
        print( "Error : " + output.results_reason() + "\n" )
        exit
    end     
    print ("\nNAS Provisioning Policy deletion Successful\n")
end


args = ARGV.length
if(args < 4)
    usage()
end    
dfmserver = ARGV[0]
dfmuser = ARGV[1]
dfmpw = ARGV[2]
dfmop = ARGV[3]
$dfmval = nil
opt_param = nil

if(args == 5)
	$dfmval = ARGV[4]
end	
# checking for valid number of parameters for the respective operations  
if((dfmop == "list" and args < 4) or (dfmop == "delete" and args != 5) or (dfmop == "create" and args < 5))
    usage()
end
# checking if the operation selected is valid
if((dfmop != "list") and (dfmop != "create") and (dfmop != "delete"))
    usage()
end
# Creating a server object and setting appropriate attributes
$server = NaServer.new(dfmserver, 1, 0 )
$server.set_server_type('DFM')
$server.set_admin_user( dfmuser, dfmpw )
# Calling the subroutines based on the operation selected
if(dfmop == 'create')
    create()
elsif(dfmop == 'list')
    dfm_list()
elsif(dfmop == 'delete')
    policy_del()
else
    usage()
end



