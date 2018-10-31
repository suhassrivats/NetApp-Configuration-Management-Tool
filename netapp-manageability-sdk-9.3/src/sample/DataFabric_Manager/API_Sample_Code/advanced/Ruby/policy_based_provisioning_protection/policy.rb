#                                                               #
#                                                               #
#  policy.rb                                                    #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to:                            #
#        - list/delete protection policies                      #
#        - list/create/delete a new provisionoing policy        #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.8     #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

$:.unshift '../../../../../../../lib/ruby/NetApp'
require 'NaServer'

# Print usage of this script
def print_usage() 
	print ("Usage: \n")
	print ("policy.rb <dfmserver> <user> <password> list {-v [<prov-name>] | -t [<prot-name>]}\n")
	print ("policy.rb <dfmserver> <user> <password> destroy <prov-name>\n")
	print ("policy.rb <dfmserver> <user> <password> create <prov-name> <type> <rtag>\n")
	print ("<dfmserver>        -- Name/IP Address of the DFM server\n")
	print ("<user>             -- DFM server User name\n")
	print ("<password>         -- DFM server User Password\n")
	print ("<prov-name>        -- provisioning policy name\n")
	print ("<prot-name>        -- protection policy name\n")
	print ("<type>             -- provisioning policy type, san or nas\n")
	print ("<rtag>             -- Resource tag for policy\n")
	print ("Creates policy with default options :\n")
	print ("NAS - User-quota=Group-quota=1G,Thin-prov=True, Snapshot-reserve=False\n")
	print ("SAN - Storage-Container=Volume, Thin-prov=True.\n")
	exit
end
	

# Variables declaration
args      = ARGV.length
dfmserver = ARGV.shift
dfmuser   = ARGV.shift
dfmpw     = ARGV.shift
command   = ARGV.shift

# check for valid number of parameters
print_usage() if ( args < 4 ) 
# Setup DFM server connection
s = NaServer.new( dfmserver, 1, 0 )
s.set_server_type("DFM")
s.set_admin_user( dfmuser, dfmpw )

# List provisioning or protection policy
if ( command == "list" ) 
	subCommand = ARGV.shift
	#List provisioning policy
	if ( subCommand == "-v" ) 
		pname = ARGV.shift
		# Begin the iterator APIs
		input = NaElement.new("provisioning-policy-list-iter-start")
		unless(pname) 
			input.child_add_string( "provisioning-policy-name-or-id", pname )
		end
		out = s.invoke_elem(input)
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			exit
		end
		records = out.child_get_int("records")
		tag = out.child_get_string("tag")
		if(records == 0)
		    s.invoke("provisioning-policy-list-iter-end", "tag", tag)
                    print("\nError: No Provisioning Policies!\n")
		    exit
		end
   		out = s.invoke("provisioning-policy-list-iter-next", "maximum", records, "tag", tag)
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			exit
		end
		print ("\nProvisioning Policies:\n")
		print ("===================================================================\n")
		pps = out.child_get("provisioning-policies")
		unless(pps) 
			print ("Error: No Provisioning Policies!\n")
			exit 
		end
		ppInfos = pps.children_get()
	
		# Print details from the records retrieved iteratively
		ppInfos.each do |ppi|
			print("Policy Name\t: " + ppi.child_get_string("provisioning-policy-name"))
			print ("\n")
			pType = ppi.child_get_string("provisioning-policy-type")
			print ("Policy Type\t: " + pType)
			print ("\n")
			print ("Resource Tag\t: " + ppi.child_get_string("resource-tag"))
			print ("\n")
			# If it is a NAS policy
			if ( pType == "nas" ) 
				print ("NAS container Settings:\n")
				nas = ppi.child_get("nas-container-settings")
				print ("\t\tDefault User Quota  : "+ nas.child_get_int("default-user-quota").to_s)
				print ("\n")
				print ("\t\tDefault Group Quota : "+ nas.child_get_int("default-group-quota").to_s)
				print ("\n")
				print ("\t\tSnapshot Reserve    : "+ nas.child_get_string("snapshot-reserve"))
				print ("\n")
				print ("\t\tThin Provision      : "+ nas.child_get_string("thin-provision"))
				print ("\n")
			
			elsif ( pType == "san" ) 
				# If it is a SAN policy
				print ("SAN container Settings:\n")
				san = ppi.child_get("san-container-settings")
				print ("\t\tStorage Container Type\t: "+ san.child_get_string("storage-container-type"))
				print ("\n")
				print ("\t\tThin Provision\t\t: "+ san.child_get_string("thin-provision"))
				print ("\n")
				print ("\t\tThin Prov+ Config.\t: "+ san.child_get_string("thin-provisioning-configuration"))
				print ("\n")
			end
			
			srel = ppi.child_get("storage-reliability")
			print ("Availability Features:\n")
			print ("\t\tStorage Sub-system Failure (aggr SyncMirror): " + srel.child_get_string("sub-system-failure"))
			print ("\n")
			print ("\t\tStorage Controller Failure (active/active)  : " + srel.child_get_string("controller-failure"))
			print ("\n")
			print ("\t\tDisk Failure Protection (RAID Level)        : " + srel.child_get_string("disk-failure"))
			print ("\n")
			print ("\n")
			print ("===================================================================\n")
		end
		
	elsif ( subCommand == "-t" ) 
		# List Data Protection policies
		pname = ARGV.shift
		input = NaElement.new("dp-policy-list-iter-start")
		
		unless(pname) 
			input.child_add_string( "dp-policy-name-or-id", pname )
		end
		out = s.invoke_elem(input)
		
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			exit
		end
		records = out.child_get_int("records")
		tag = out.child_get_string("tag")
		if(records == 0)
		    s.invoke("dp-policy-list-iter-end", "tag", tag)
		    print ("Error: No Provisioning Policies!\n")
		    exit
		end
                out = s.invoke("dp-policy-list-iter-next", "maximum", records, "tag", tag)
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			exit
		end
		
		print ("\nProtection Policies:\n")
		print ("===================================================================\n")
		dps = out.child_get("dp-policy-infos")
		unless(dps) 
			print ("Error: No Provisioning Policies!\n")
			exit 
		end
		dpInfo = dps.children_get()
		dpInfo.each do |ppi|
			dpContent = ppi.child_get("dp-policy-content")
			print ("Policy Name\t: " + dpContent.child_get_string("name") + "\n")
			dpCons     = dpContent.child_get("dp-policy-connections")
			dpConInfos = dpCons.children_get()
			dpConInfos.each do |dpi|
				if ( dpi != "" ) 
					print ("-----------------------------------\n")
					print ("Connection Type\t: " + dpi.child_get_string("type"))
					print ("\n")
					print ("Source Node\t: " + dpi.child_get_string("from-node-name"))
					print ("\n")
					print ("To Node\t\t: " + dpi.child_get_string("to-node-name"))
					print ("\n")
				end
			end
			print ("\n===================================================================\n")
		end
		print ("\n")
		print ("===================================================================\n")
	
	else 
		print_usage()
	end
	
elsif ( command == "create" ) 
	# Create a new Provisioning Policy
	if ( args < 7 )
		print_usage()
	end
	ppname = ARGV.shift
	pptype = ARGV.shift
	rtag   = ARGV.shift
	input  = NaElement.new("provisioning-policy-create")
	ppi = NaElement.new("provisioning-policy-info")
	ppi.child_add_string( "provisioning-policy-name", ppname )
	ppi.child_add_string( "provisioning-policy-type", pptype )
	ppi.child_add_string( "resource-tag",             rtag )
	# Set default options for a NAS policy.  You can otherwise collect these 
	# details on commandline or a config file
	if ( pptype == "nas" ) 
		nas = NaElement.new("nas-container-settings")
		nas.child_add_string( "default-user-quota",  "1000000000" )
		nas.child_add_string( "default-group-quota", "1000000000" )
		nas.child_add_string( "thin-provision",      "true" )
		nas.child_add_string( "snapshot-reserve",    "false" )
		ppi.child_add(nas)
	
	elsif ( pptype == "san" ) 
		# Set default options for a SAN policy.  You can otherwise collect 
		# these details on commandline or a config file
		san = NaElement.new("san-container-settings")
		san.child_add_string( "storage-container-type", "volume" )
		san.child_add_string( "thin-provision",         "true" )
		ppi.child_add(san)
	end
	
	input.child_add(ppi)
	out = s.invoke_elem(input)
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	print("New Provisioning Policy " + ppname + " created with ID : " + out.child_get_string("provisioning-policy-id") + "\n")

elsif ( command == "destroy" ) 
	if ( args < 5 ) 
		print_usage() 
	end
	pname = ARGV.shift
	out = s.invoke( "provisioning-policy-destroy", "provisioning-policy-name-or-id", pname )
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	print ("Provisioning Policy " + pname + " destroyed!\n")

else 
	print_usage()
end

