#===============================================================#
#                                                               #
# ID                                                            #
#                                                               #
# dataset.rb                                                    #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
#  Sample code to demonstrate how to:                           #
#        - list/create/delete a dataset                         #
#        - list/add/delete a member in a dataset                #
#        - attach resourcepools, provisioning policy,           #
#          protection policy and multistore to a dataset        #
#        - provision storage from a dataset                     #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.8     #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

$:.unshift '../../../../../../../lib/ruby/NetApp'
require 'NaServer'

def print_usage() 
	print (" Usage:\n")
	print (" dataset.rb <dfmserver> <user> <passwd> list [<name>]\n")
	print (" dataset.rb <dfmserver> <user> <passwd> create <name> [<vfiler> <prov_pol> <prot-pol>]\n")
	print (" dataset.rb <dfmserver> <user> <passwd> destroy <name>\n")
	print (" dataset.rb <dfmserver> <user> <passwd> update <name> <prov_pol> <prot_pol> <pri_rp> <sec_rp> [<ter_rp>]\n")
	print (" dataset.rb <dfmserver> <user> <passwd> member list <name>\n")
	print (" dataset.rb <dfmserver> <user> <passwd> member add <name> <mem_add>\n")
	print (" dataset.rb <dfmserver> <user> <passwd> member del <name> <mem_del>\n")
	print (" dataset.rb <dfmserver> <user> <passwd> provision <name> <mem_prov_name> <size> [<snap-size>]\n")
	print (" <dfmserver>     -- Name/IP Address of the DFM server\n")
	print (" <user>          -- DFM server User name\n")
	print (" <passwd>        -- DFM server User Password\n")
	print (" <name>          -- Name of the dataset\n")
	print (" <vfiler>        -- Attach newly provisioned member to this vfiler\n")
	print (" <prov_pol>      -- name or id of an exisitng nas provisioning policy\n")
	print (" <prot-pol>      -- name or id of an exisitng protection policy\n")
	print (" <mem_prov_name> -- member name to be provisioned\n")
	print (" <size>          -- size of the new member to be provisioned in bytes\n")
	print (" <snap-size>     -- maximum size in bytes allocated to snapshots in SAN envs\n")
	print (" <mem_add>       -- member to be added\n")
	print (" <mem_del>       -- member to be removed\n")
	print (" <pri_rp>        -- Primary resource pool\n")
	print (" <sec_rp>        -- Secondary resource pool\n")
	print (" <ter_rp>        -- Tertiary resource pool\n")
	print (" If the protection policy is 'Mirror', specify only pri_rp and sec_rp.\n")
	print (" If protection policy is 'Back up, then Mirror', specify pri_rp, sec_rp and ter_rp\n")
	exit
end

# check for valid number of parameters
cmd_args  = ARGV.length
if ( cmd_args < 4 ) 
	print_usage() 
end

# Variables declaration
dfmserver = ARGV[0]
dfmuser   = ARGV[1]
dfmpw     = ARGV[2]
command   = ARGV[3]

# Setup DFM server connection
s = NaServer.new( dfmserver, 1, 0 )
s.set_server_type("DFM")
s.set_admin_user( dfmuser, dfmpw )

if ( command == "list" ) 
	if ( cmd_args > 4 ) 
		dsName = ARGV[4]	
	else
		dsName = nil
	end
	out = s.invoke( "dataset-list-info-iter-start", "object-name-or-id", dsName )
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	records = out.child_get_int("records")
	tag = out.child_get_string("tag")
	if(records == 0)
	    print("\nNo datasets to display\n")
	    s.invoke( "dataset-list-info-iter-end", "tag", tag)
	    exit
	end
	out = s.invoke("dataset-list-info-iter-next", "maximum", records, "tag", tag)
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	print ("\nDATASETS:\n")
	print ("===================================================================\n")
	rps     = out.child_get("datasets")
	rpInfos = rps.children_get()
        rpInfos.each do |rpi|
		print("Dataset Name\t: " + rpi.child_get_string("dataset-name"))
		print ("\n")
		dsstatus = rpi.child_get("dataset-status")
		print ("Overall Status\t: " + dsstatus.child_get_string("resource-status"))
		print ("\n")
		print ("# of Members\t: " + rpi.child_get_string("member-count").to_s)
		print ("\n")
		value = "-Not Configured-"
		if ( rpi.child_get_string("vfiler-name") != "" ) 
			value = rpi.child_get_string("vfiler-name")
		end
		print ("VFiler unit\t: " + value.to_s + "\n")
		value = "-Not Configured-"
		if ( rpi.child_get_string("protection-policy-name") != "" ) 
			value = rpi.child_get_string("protection-policy-name")
		end
		print ("Prot. Policy\t: " + value.to_s + "\n")
		value = "-Not Configured-"
		if ( rpi.child_get_string("provisioning-policy-name") != "" ) 
			value = rpi.child_get_string("provisioning-policy-name")
		end
		print ("Prov. Policy\t: " + value.to_s + "\n")
		print ("Res. pools(Pri)\t: " )
		rps = rpi.child_get("resourcepools")
		if ( rps == nil ) 
			print ("No attached Resourcepool!\n")
		else 
			dsrpi = rps.children_get()
			dsrpi.each do |rp|
				print(rp.child_get_string("resourcepool-name"))
				print (" ")
			end
		end
		print ("\n")
		print ("===================================================================\n")
	end
	
elsif ( command == "create" ) 
	if ( cmd_args < 5 ) 
		print_usage() 
	end
	dsName = ARGV[4]
	if(cmd_args > 7)
		vfiler = ARGV[5]
		prov   = ARGV[6]
		prot   = ARGV[7]
	end
	input = NaElement.new("dataset-create")
	input.child_add_string( "dataset-name", dsName )
	input.child_add_string( "protection-policy-name-or-id", prot ) if ( prot ) 
	input.child_add_string( "provisioning-policy-name-or-id", prov ) if ( prov ) 
	input.child_add_string( "vfiler-name-or-id", vfiler ) if ( vfiler ) 
	out = s.invoke_elem(input)
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	print ("Dataset " + dsName  + " created with ID " + out.child_get_int("dataset-id").to_s + "!\n")

elsif ( command == "destroy" ) 
	if ( cmd_args < 5 ) 
		print ("Usage: dataset.rb <dfmserver> <user> <password> destroy <dataset_name>\n")
	end
	dsName = ARGV[4]
	out = s.invoke( "dataset-destroy", "dataset-name-or-id", dsName )
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	print ("Dataset " + dsName + " destroyed!\n")

elsif ( command == "update" ) 
	if ( cmd_args < 9 ) 
		print_usage() 
	end
	dsName = ARGV[4]
	provp  = ARGV[5]
	protp  = ARGV[6]
	priRp  = ARGV[7]
	secRp  = ARGV[8]
	if(cmd_args > 9)
		terRp  = ARGV[9]
	end
	out = s.invoke( "dataset-edit-begin", "dataset-name-or-id", dsName )
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	editLock = out.child_get_int("edit-lock-id")
	print ("Adding protection policy...\n")
	out = s.invoke( "dataset-modify", "edit-lock-id", editLock, "protection-policy-name-or-id", protp )
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		print("Attempting to roll-back...\n")
		out = s.invoke( "dataset-edit-rollback", "edit-lock-id", editLock )
		exit
	end
	print ("Adding provisioning policy...\n")
	out = s.invoke( "dataset-modify-node", "edit-lock-id", editLock, "provisioning-policy-name-or-id", provp )
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		print("Attempting to roll-back...\n")
		out = s.invoke( "dataset-edit-rollback", "edit-lock-id", editLock )
		exit
	end
	print ("Gathering Node names from protection policy...\n")
	out = s.invoke( "dp-policy-list-iter-start", "dp-policy-name-or-id", protp )
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		print("Attempting to roll-back...\n")
		out = s.invoke( "dataset-edit-rollback", "edit-lock-id", editLock )
		exit
	end
        records = out.child_get_int("records")
	tag = out.child_get_string("tag")
    	if(records == 0)
	    s.invoke("dp-policy-list-iter-end", "tag", tag)
	    print("Error: No Provisioning Policies!\n")
            print("Attempting to roll-back...\n")
            out = s.invoke( "dataset-edit-rollback", "edit-lock-id", editLock )
            exit
        end
	out = s.invoke(	"dp-policy-list-iter-next", "maximum", records, "tag", tag)
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		print("Attempting to roll-back...\n")
		out = s.invoke( "dataset-edit-rollback", "edit-lock-id", editLock )
		exit
	end
	dps = out.child_get("dp-policy-infos")
	unless(dps) 
		print ("Error: No Provisioning Policies!\n")
		print("Attempting to roll-back...\n")
		out = s.invoke( "dataset-edit-rollback", "edit-lock-id", editLock )
		exit
	end
	
	dpInfo     = dps.child_get("dp-policy-info")
	dpContent  = dpInfo.child_get("dp-policy-content")
	dpNodes    = dpContent.child_get("dp-policy-nodes")
	dpNodeInfo = dpNodes.children_get()
	count = 1
	rpool = priRp
	size  = dpNodeInfo.length
	if ( size != ( cmd_args - 7 ) ) 
		print("Error: Missing resource pool! No of resource pools required are : size \n")
		print("Attempting to roll-back...\n")
		out = s.invoke( "dataset-edit-rollback", "edit-lock-id", editLock )
		exit
	end
	dpNodeInfo.each do |dpni|
		if ( count == 2 ) 
			rpool = secRp
		end
		if ( count == 3 ) 
			rpool = terRp 
		end
		dpNode = dpni.child_get_string("name")
		print ("Adding Resourcepool "  + rpool  + " to DP Node Name "  + dpNode + "\n")
		out = s.invoke( "dataset-add-resourcepool", "edit-lock-id", editLock, "dp-node-name", dpNode, "resourcepool-name-or-id", rpool )
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			print("Attempting to roll-back...\n")
			out = s.invoke( "dataset-edit-rollback", "edit-lock-id", editLock )
			exit
		end
		count = count + 1
	end
	print ("Committing... \n")
	out = s.invoke( "dataset-edit-commit", "edit-lock-id", editLock )
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		print("Attempting to roll-back...\n")
		out = s.invoke( "dataset-edit-rollback", "edit-lock-id", editLock )
		exit
	end
	
elsif ( command == "member" ) 
	if(cmd_args < 5)
		print_usage() 
	end
	subCommand = ARGV[4]
	
	if ( subCommand == "list" ) 
		if ( cmd_args < 6 ) 
			print_usage() 
		end
		dsName = ARGV[5]
		out = s.invoke("dataset-member-list-info-iter-start", "include-exports-info", "true", 
						"include-indirect",	"true", "include-space-info", "true", "dataset-name-or-id",	dsName )
		
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			exit
		end
		records = out.child_get_int("records")
		tag = out.child_get_string("tag")
		if(records == 0)
		    s.invoke("dataset-member-list-info-iter-end", "tag", tag)
		    print("\nError : No Dataset members!\n")
		    exit
		end
		out = s.invoke("dataset-member-list-info-iter-next", "maximum", records, "tag", tag)
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			exit
		end
		print ("\nDATASET : " + dsName + "\n")
		print ("===================================================================\n")
		dms  = out.child_get("dataset-members")
		dmis = dms.children_get()
		dmis.each do |dmi|
			member_name = dmi.child_get_string("member-name")
			# Display all member details.  Avoid displaying the non-qtree member i.e members ending with "-"
			if(member_name[-1,1] != "-")
				print ("Member Name\t\t: " + member_name)
				print ("\n")
				print ("Member Status\t\t: " + dmi.child_get_string("member-status"))
				print ("\n")
				print ("DP node name\t\t: "  + dmi.child_get_string("dp-node-name"))
				print ("\n")
				mtype = dmi.child_get_string("member-type")
				print ("Member Type\t\t: " + mtype)
				print ("\n")
				if ( mtype != "qtree" ) 
					spinfo = dmi.child_get("space-info")
					print ("Space used\t\t: " + ( spinfo.child_get_int("used-space") ).to_s + " ("  +
						  (spinfo.child_get_int("used-space") / ( 1024 * 1024 ) ).to_s  + "MB)\n")
					print("Space(Avail/Total)\t: " + (spinfo.child_get_int("available-space")/( 1024 * 1024 )).to_s + "MB / " +
						  (spinfo.child_get_int("total-space") / ( 1024 * 1024 )).to_s + "MB")
					print ("\n")
				end
				
				print ("\n")
				print ("===================================================================\n")
			end
		end
		
	elsif (subCommand == "add") 
		if ( cmd_args < 7 ) 
			print_usage() 
		end
		dsName = ARGV[5]
		mem    = ARGV[6]
		out = s.invoke( "dataset-edit-begin", "dataset-name-or-id", dsName )
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			exit
		end
		editLock = out.child_get_int("edit-lock-id")
		input = NaElement.new("dataset-add-member")
		input.child_add_string( "edit-lock-id", editLock )
		dmps = NaElement.new("dataset-member-parameters")
		i = 6
		while ( i < cmd_args ) 
			print ("Adding member " + mem + "...\n")
			dmp = NaElement.new("dataset-member-parameter")
			dmp.child_add_string( "object-name-or-id", mem )
			mem = ARGV[i]
			i = i + 1
			dmps.child_add(dmp)
		end
		input.child_add(dmps)
		out = s.invoke_elem(input)
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			print("Attempting to roll-back...\n")
			out = s.invoke( "dataset-edit-rollback", "edit-lock-id", editLock )
			exit
		end
		print ("Committing... \n")
		out = s.invoke( "dataset-edit-commit", "edit-lock-id", editLock )
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			print("Attempting to roll-back...\n")
			out = s.invoke( "dataset-edit-rollback", "edit-lock-id", editLock )
			exit
		end
		print ("Addition of Members to Dataset " + dsName + " Successful!\n")
	
	elsif ( subCommand == "del" ) 
		if ( cmd_args < 7 ) 
			print_usage() 
		end
		dsName = ARGV[5]
		mem    = ARGV[6]
		out = s.invoke( "dataset-edit-begin", "dataset-name-or-id", dsName )
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			exit
		end
		editLock = out.child_get_int("edit-lock-id")
		input = NaElement.new("dataset-remove-member")
		input.child_add_string( "edit-lock-id", editLock )
		dmps = NaElement.new("dataset-member-parameters")
		i = 6
		
		while ( i < cmd_args) 
			print ("Removing member " + mem + "...\n")
			dmp = NaElement.new("dataset-member-parameter")
			dmp.child_add_string( "object-name-or-id", mem )
			mem = ARGV[i]
			i = i+1
			dmps.child_add(dmp)
		end
		input.child_add(dmps)
		out = s.invoke_elem(input)
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			print("Attempting to roll-back...\n")
			out = s.invoke( "dataset-edit-rollback", "edit-lock-id", editLock )
			exit
		end
		print ("Committing... \n")
		out = s.invoke( "dataset-edit-commit", "edit-lock-id", editLock )
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			print("Attempting to roll-back...\n")
			out = s.invoke( "dataset-edit-rollback", "edit-lock-id", editLock )
			exit
		end
		print ("Removal of Members from Dataset " + dsName + " Successful!\n")
	
	else 
		print("Invalid Option selected...\n")
		print_usage()
	end
	
elsif ( command == "provision" ) 
	if ( cmd_args < 7 ) 
		print_usage() 
	end
	dsName  = ARGV[4]
	name    = ARGV[5]
	size    = ARGV[6]
	ssspace = ARGV[7]
	
	#Determine the provisioning policy attached to the dataset
	out = s.invoke( "dataset-list-info-iter-start", "object-name-or-id", dsName )
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	records = out.child_get_int("records")
	tag = out.child_get_string("tag")
        if(records == 0)
	    print("Error: No Datasets!\n")
	    s.invoke( "dataset-list-info-iter-end" , "tag", tag)
	    exit
	end
        out = s.invoke("dataset-list-info-iter-next", "maximum", records, "tag", tag)
	rps = out.child_get("datasets")
	rpInfos = rps.child_get("dataset-info")
	provpId = rpInfos.child_get_string("provisioning-policy-id")
	print ("Prov Policy\t: " + rpInfos.child_get_string("provisioning-policy-name") + "\n")
	input = NaElement.new("provisioning-policy-list-iter-start")
	input.child_add_string( "provisioning-policy-name-or-id", provpId )
	out = s.invoke_elem(input)
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	records = out.child_get_int("records")
	tag = out.child_get_string("tag")
	if(records == 0)
	    print("Error: No Provisioning Policies!\n")
	    s.invoke("provisioning-policy-list-iter-end", "tag", tag)
	    exit
	end
        out = s.invoke("provisioning-policy-list-iter-next", "maximum", records, "tag", tag)
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	pps = out.child_get("provisioning-policies")
	ppInfos = pps.child_get("provisioning-policy-info")
	pptype  = ppInfos.child_get_string("provisioning-policy-type")
	out = s.invoke( "dataset-edit-begin", "dataset-name-or-id", dsName )
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	editLock = out.child_get_int("edit-lock-id")
	input = NaElement.new("dataset-provision-member")
	input.child_add_string( "edit-lock-id", editLock )
	pmri = NaElement.new("provision-member-request-info")
	pmri.child_add_string( "name", name )
	pmri.child_add_string( "size", size )

	if ( pptype == "san" ) 
		pmri.child_add_string( "maximum-snapshot-space", ssspace )
	end
	input.child_add(pmri)
	print ("Provisioning storage...\n")
	out = s.invoke_elem(input)
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	print ("Committing... \n")
	out = s.invoke( "dataset-edit-commit", "edit-lock-id", editLock )
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		print("Attempting to roll-back...\n")
		out = s.invoke( "dataset-edit-rollback", "edit-lock-id", editLock )
		exit
	end
	jobId = ( ( out.child_get("job-ids") ).child_get("job-info") ).child_get_string("job-id")
	print ("Job ID\t\t: " + jobId + " \n")
	jobStatus = "running"
	print ("Job Status\t: " + jobStatus)

	while ( jobStatus == "queued" or jobStatus == "running" ) 
		out = s.invoke( "dp-job-list-iter-start", "job-id", jobId )
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			exit
		end
		records = out.child_get_int("records")
	        tag = out.child_get_string("tag")
		if(records == 0)
            		s.invoke("dp-job-list-iter-end", "tag", tag)
			print("\nError\n")
			exit
		end
		out = s.invoke("dp-job-list-iter-next", "maximum", records, "tag", tag)
		
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			exit
		end
		#print out.sprintf()
		dpJobs = out.child_get("jobs")
		dpJobInfo = dpJobs.child_get("dp-job-info")
		jobStatus = dpJobInfo.child_get_string("job-state")
		sleep (5)
		print (".")
		
		if ( jobStatus == "completed" or jobStatus == "aborted" ) 
			print ("\nOverall Status\t: " + dpJobInfo.child_get_string("job-overall-status") + "\n")
		end
	end	
	out = s.invoke( "dp-job-progress-event-list-iter-start", "job-id", jobId )
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	records = out.child_get_int("records")
	tag = out.child_get_string("tag")
	if(records == 0)
	    s.invoke("dp-job-progress-event-list-iter-end", "tag", tag)
	    print("\nError\n")
	    exit
	end
	out = s.invoke("dp-job-progress-event-list-iter-next", "tag", tag, "maximum", records)
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	progEvnts     = out.child_get("progress-events")
	progEvntsInfo = progEvnts.children_get()
	print ("\nProvision Details:\n")
	print ("=" * 19 + "\n")
        progEvntsInfo.each do |evnt|
		print(evnt.child_get_string("event-type")) if ( evnt.child_get_string("event-type") != "" ) 
		print ("\t: " + evnt.child_get_string("event-message") + "\n")
	end
	
else 
	print("Invalid Option...\n")
	print_usage()
end

