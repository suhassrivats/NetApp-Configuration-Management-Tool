#===============================================================#
#                                                               #
# ID                                                            #
#                                                               #
# dataset_health.rb                                             #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code for providing health status of all the datasets   #
# in the system. This is provided using a dashboard which       #
# provides information about total protected and                #
# unprotected datasets, dataset protection status,              #
# space status, conformance status, resource status,  etc.      #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.8     #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

$:.unshift '../../../../../../../lib/ruby/NetApp'
require 'NaServer'

##### SUBROUTINE SECTION
def usage()
    print("Usage:\n")
    print("ruby dataset_health.rb <dfm-server> <user> <password> -d | -p | -D | <-l [<dataset-name>]>\n")
    print("<dfm-server>    --  Name/IP Address of the DFM Server\n")
    print("<user>          --  DFM Server User name\n")
    print("<password>      --  DFM Server Password\n")
    print("<dataset-name>  --  Name of the dataset\n")
    print("-d              --  Display the dataset health dashboard\n")
    print("-l              --  List all datasets and its status information\n")
    print("-p              --  List protected and Unprotected datasets\n")
    print("-D              --  List DR configured datasets\n")
    exit
end


def convert_seconds(secs)
    output = printf("%4d Days %2d Hr %2d Min %2d Sec",Time.at(secs).day,Time.at(secs).hour,Time.at(secs).min,Time.at(secs).sec)
    return output
end

	 
def list_datasets(option, dataset = nil) 
    # create the input API request
    input = NaElement.new("dataset-list-info-iter-start")
    input.child_add_string( "object-name-or-id", dataset ) if (dataset) 
    # check for the given options
    # For listing DR Configured datasets, add is-dr-capable option to TRUE
    input.child_add_string( "is-dr-capable", "True" ) if ( option == "DRConfigured" ) 
    # invoke the API request and capture the output
    output = $server.invoke_elem(input)

    # check the API status
    if(output.results_status() == "failed" )
	print( "Error : " + output.results_reason() + "\n" ) 
	exit
    end
    #Extract the record and tag values
    records = output.child_get_string("records")
    ds_total = records
    tag = output.child_get_string("tag")
    if(records.to_i == 0)
	print("\nNo datasets to display\n")
	$server.invoke( "dataset-list-info-iter-end", "tag", tag)
	exit
    end
    # now invoke the dataset-list-info-iter-next to return list of datasets
    output = $server.invoke( "dataset-list-info-iter-next", "maximum", records, "tag", tag )
    # check for the API status
    if(output.results_status() == "failed" )
	print( "Error : " + output.results_reason() + "\n" )
	exit
    end
	
    # get the list of datasets which is contained under datasets element
    dataset_info = output.child_get("datasets")
    result = dataset_info.children_get()
    prot_status     = nil
    conf_status     = nil
    resource_status = nil
    is_dr_capable   = nil
    is_protected    = nil
    dr_state        = nil
    print("\n")
    print("-" * 70)
    print("\n")

    # Iterate through each dataset record
    result.each do |dataset|
	dataset_name = dataset.child_get_string("dataset-name")
	# printing detials if only one dataset is selected for listing
        status = dataset.child_get("dataset-status")
	# check for the input option and retrieve appropriate information
	if ( option == "ProtectedUnprotected" ) 
		print("Dataset name               : "+dataset_name+"\n")
		is_protected = dataset.child_get_string("is-protected")
		if(is_protected =~ /True/i)
	    	    print("Protected                  : Yes \n")
		else 
		    print("Protected                  : No \n")
		end
		print("-" * 70)
		print("\n")
	elsif ( option == "DRconfigured" ) 
		status = dataset.child_get("dataset-status")
		is_dr_capable = dataset.child_get_string("is-dr-capable")
		if(is_dr_capable =~ /True/i)
	    	    dr_state = dataset.child_get_string("dr-state")
		    dr_prot_status = status.child_get_string("dr-status")
		    print("Dataset name               : "+dataset_name+"\n")
		    print("DR State-Status            : "+dr_state+ " - "+ dr_prot_status + "\n")
		    print("-" * 70)
		    print("\n")
		end
	elsif ( option == "All" ) 
		print("Dataset name               : "+dataset_name+"\n")
		is_protected = dataset.child_get_string("is-protected")
		if(is_protected =~ /True/i)
	    	    status = dataset.child_get("dataset-status")
		    prot_status = status.child_get_string("protection-status")
		    if(prot_status) 
			print("Protection status          : "+prot_status+"\n")
		    else 
			print("Protection status          : unknown \n")
		    end
		else 
		    print("Protection status          : No data protection policy applied.\n")
		end
		conf_status = status.child_get_string("conformance-status")
		if (conf_status) 
		    print("Conformance status         : "+conf_status+"\n")
		else 
		    print("Conformance status         : Unknown \n")
		end
		resource_status = status.child_get_string("resource-status")
		if (resource_status) 
		    print("Resource status            : "+resource_status+"\n")
		else 
		    print("Resource    status         : Unknown \n")
		end
		space_status = status.child_get_string("space-status")
		if (space_status) 
		    print("Space status               : "+space_status+"\n")
		else 
		    print("Space status               : Unknown \n")
		end
		is_dr_capable = dataset.child_get_string("is-dr-capable")
		if(is_dr_capable =~ /True/i)
		    dr_state = dataset.child_get_string("dr-state")
		    dr_prot_status = status.child_get_string("dr-status")
		    print("DR State-Status            : "+dr_state+" - " + dr_prot_status + "\n")
		else
		    print("DR State-Status            : No data protection policy applied.\n")
		end
		print("\n")
		print("-" * 70)
		print("\n")
	end
    end
	
    #finally invoke the dataset-list-info-iter-end API
    output = $server.invoke( "dataset-list-info-iter-end", "tag", tag )
    if(output.results_status() == "failed" )
	print( "Error : " + output.results_reason() + "\n" )
	exit
    end
end

	
def list_dashboard
    # Dataset protection status parameters 
    ps_baseline_failure = 0
    ps_lag_error        = 0
    ps_lag_warning      = 0
    ps_suspended        = 0
    ps_uninitialized    = 0
    ds_total_protected   = 0
    ds_total_unprotected = 0
    ds_total             = 0
    # Dataset conformance status counters
    ds_conformant     = 0
    ds_non_conformant = 0
    # Dataset protected/unprotected counters
    ps_protected   = 0
    ps_unprotected = 0
    # DR configured datasets
    dr_count           = 0
    ds_resource_status = 0
    # Dataset resource status variables
    rs_emergency = 0
    rs_critical  = 0
    rs_error     = 0
    rs_warning   = 0
    rs_normal    = 0
    # Dataset space status variables
    space_status = 0
    ss_error     = 0
    ss_warning   = 0
    ss_normal    = 0
    ss_unknown   = 0
    # create the input dataset-list-info-iter-start API request for listing
    # through all datasets
    input = NaElement.new("dataset-list-info-iter-start")
    # invoke the api and capture the ouput
    output = $server.invoke_elem(input)
    # check the status of the API request
    if(output.results_status() == "failed" )
	print( "Error : " + output.results_reason() + "\n" )
	exit
    end
    # Extract the record and tag values
    records = output.child_get_string("records")
    ds_total = records
    tag = output.child_get_string("tag")
    if(records.to_i == 0)
	print("\nNo datasets to display\n")
	$server.invoke( "dataset-list-info-iter-end", "tag", tag)
	exit
    end
    output = $server.invoke( "dataset-list-info-iter-next", "maximum", records, "tag", tag )
    if(output.results_status() == "failed" )
	print( "Error : " + output.results_reason() + "\n" )
	exit
    end
    # get the list of datasets which is contained under datasets element
    dataset_info = output.child_get("datasets")
    result = dataset_info.children_get()
    prot_status     = nil
    conf_status     = nil
    resource_status = nil

    # Iterate through each dataset record
    result.each do |dataset|
	dataset_name = dataset.child_get_string("dataset-name")
	status = dataset.child_get("dataset-status")
	# get the protection status information
	prot_status = status.child_get_string("protection-status")
	if ( prot_status == "protected" ) 
	    ps_protected = ps_protected + 1
	elsif ( prot_status == "uninitialized" ) 
	    conf_status = status.child_get_string("conformance-status")
	    if ( conf_status != "conforming" ) 
		ps_uninitialized = ps_uninitialized + 1
	    end
	elsif ( prot_status == "protection_suspended" ) 
	    ps_suspended = ps_suspended + 1
	elsif ( prot_status == "lag_warning" ) 
	    ps_lag_warning = ps_lag_warning + 1
	elsif ( prot_status == "lag_error" ) 
	    ps_lag_error = ps_lag_error + 1
	elsif ( prot_status == "baseline_failure" ) 
	    ps_baseline_failure = ps_baseline_failure + 1
	end
	# get the conformance status information
	conf_status = status.child_get_string("conformance-status")
	if ( conf_status == "conformant" ) 
	    ds_conformant = ds_conformant + 1
	elsif ( conf_status == "nonconformant" ) 
	    ds_non_conformant = ds_non_conformant + 1
	end
	# get the resource status information
	resource_status = status.child_get_string("resource-status")
	if ( resource_status == "emergency" ) 
	    rs_emergency = rs_emergency + 1
	elsif ( resource_status == "critical" ) 
	    rs_critical = rs_critical + 1
	elsif ( resource_status == "error" ) 
	    rs_error = rs_error + 1
	elsif ( resource_status == "normal" ) 
	    rs_normal = rs_normal + 1
	end
	# get the space status information
	space_status = status.child_get_string("space-status")
	if ( space_status == "error" ) 
	    ss_error = ss_error + 1
	elsif ( space_status == "warning" ) 
	    ss_warning = ss_warning + 1
	elsif ( space_status == "ok" ) 
	    ss_normal = ss_normal + 1
	elsif ( space_status == "unknown" ) 
	    ss_unknown = ss_unknown + 1
	end
    end	
    # invoke the iter-end zapi
    output = $server.invoke( "dataset-list-info-iter-end", "tag", tag )
    if(output.results_status() == "failed" )
	print( "Error : " + output.results_reason() + "\n" )
	exit
    end
    # invoke the dp-dashboard-get-protected-data-counts API request to get
    # the protected and unprotected dataset counts
    output = $server.invoke("dp-dashboard-get-protected-data-counts")
    if(output.results_status() == "failed" )
	print( "Error : " + output.results_reason() + "\n" )
	exit
    end
    ds_total_protected = output.child_get_string("protected-dataset-count")
    ds_total_unprotected = output.child_get_string("unprotected-dataset-count")
    # invoke the dp-dashboard-get-dr-dataset-counts API request to get
    # the DR configured datasets and its state and status information
    output = $server.invoke("dp-dashboard-get-dr-dataset-counts")
    if(output.results_status() == "failed" )
	print( "Error : " + output.results_reason() + "\n" )
	exit
    end
    dr_state_status_counts = output.child_get("dr-state-status-counts")
    dr_counts_results      = dr_state_status_counts.children_get()
    dr_count               = 0
    dr_state               = ""
    state_status           = ""
    dr_status               = ""
    dr_hash = Hash.new
    # iterate through each DR dataset
    dr_counts_results.each do |dr_state_status_count|
	count = dr_state_status_count.child_get_string("count")
	dr_state  = dr_state_status_count.child_get_string("dr-state")
	dr_status = dr_state_status_count.child_get_string("dr-status")
	if ( dr_status == "warning" )
	    dr_status = "warnings" 
        end
	state_status = dr_state +" - "+dr_status
	dr_hash[state_status] = count
	dr_count = dr_count + count
    end
    print("\n\n  Datasets\n")
    print(" |")
    print("-" *60 )
    print("-|\n")
    printf(" |Protected                 : %-33s|\n",ds_total_protected)
    printf(" |Unprotected               : %-33s|\n",ds_total_unprotected)
    print(" |")
    print("-" * 60)
    print("-|\n")
    print("              Total datasets : " + ds_total + "\n\n\n")
    print("  Dataset protection status \n")
    print(" |")
    print("-" * 60)
    print("-|\n")
    printf(" |Baseline Failure          : %-33s|\n",ps_baseline_failure)
    printf(" |Lag Error                 : %-33s|\n",ps_lag_error)
    printf(" |Lag Warning               : %-33s|\n",ps_lag_warning)
    printf(" |Protection Suspended      : %-33s|\n",ps_suspended)
    printf(" |Uninitialized             : %-33s|\n",ps_uninitialized)
    printf(" |Protected                 : %-33s|\n",ps_protected)
    print(" |")
    print("-" * 60)
    print("-|\n\n\n")
    print("  Dataset Lags \n")
    print(" |")
    print("-" * 60)
    print("-|\n")
    output2 = $server.invoke("dp-dashboard-get-lagged-datasets")
    if ( output.results_status() == "failed" )
	print( "Error : " + output.results_reason() + "\n" )
	exit
    end
    dataset_lags = output2.child_get("dp-datasets").children_get()
    count        = 0
    dataset_lags.each do |dataset_lag|
	name      = dataset_lag.child_get_string("dataset-name")
	worst_lag = dataset_lag.child_get_string("worst-lag")
	time      = convert_seconds(worst_lag)
	printf(" | %-20s  %-38s|\n" , name, time )
	count = count + 1
	if ( count >= 5 ) 
	    break 
	end
    end
    if ( count == 0 ) 
	printf(" | %-60s|\n" ,"No data available" )
    end
    print(" |")
    print("-" * 60)
    print("-|\n\n\n")
    print("  Failover readiness \n")
    print(" |")
    print("-" * 60)
    print("-|\n")
    if ( dr_count != 0 ) 
	dr_hash.each do|name,dr|
	    value = dr
	    printf(" | %-60s|\n" ,name,("            : "),dr)
	end
    else 
	printf(" | %-60s|\n" ,"Normal" ) 
    end
    print(" |")
    print("-" * 60)
    print("-|\n")
    print("   Total DR enabled datasets : "+dr_count.to_s+"\n\n\n")
    print("  Dataset conformance status \n")
    print(" |")
    print("-" * 60)
    print("-|\n")
    printf(" |Conformant                : %-33s|\n", ds_conformant)
    printf(" |Non Conformant            : %-33s|\n", ds_non_conformant)
    print(" |")
    print("-" * 60)
    print("-|\n\n\n")
    print("  Dataset resource status \n")
    print(" |")
    print("-" * 60)
    print("-|\n")
    printf(" |Emergency                 : %-33s|\n", rs_emergency)
    printf(" |Critical                  : %-33s|\n", rs_critical)
    printf(" |Error                     : %-33s|\n", rs_error)
    printf(" |Warning                   : %-33s|\n", rs_warning)
    printf(" |Normal                    : %-33s|\n", rs_normal)
    print(" |")
    print("-" * 60)
    print("-|\n\n\n")
    print("  Dataset space status \n")
    print(" |")
    print("-" * 60)
    print("-|\n")
    printf(" |Error                     : %-33s|\n", ss_error)
    printf(" |Warning                   : %-33s|\n", ss_warning)
    printf(" |Normal                    : %-33s|\n", ss_normal)
    printf(" |Unknown                   : %-33s|\n", ss_unknown)
    print(" |")
    print("-" * 60)
    print("-|\n\n\n")
end



##### VARIABLES SECTION
args = ARGV.length

# checke for valid number of arguments
if ( args < 3 )
    usage() 
end

dfmserver = ARGV[0]
dfmuser = ARGV[1]
dfmpw = ARGV[2]
opt = ARGV[3,ARGV.length-1] 
$server = ""

# Create the server context and set appropriate attributes for DFMServer
$server = NaServer.new( dfmserver, 1, 0 )
$server.set_style("LOGIN")
$server.set_server_type("DFM")
$server.set_admin_user(dfmuser, dfmpw )

# parse the input options and call appropriate function
if ( opt[0].eql?("-d" ) )
	list_dashboard()
elsif ( opt[0] == "-p" ) 
	list_datasets("ProtectedUnprotected")
elsif ( opt[0] == "-D" ) 
	list_datasets("DRconfigured")
elsif ( opt[0] == "-l" ) 
	list_datasets( "All", ARGV[4] )
else 
	usage()
end

	

