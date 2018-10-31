#===============================================================#
#                                                               #
# ID                                                            #
#                                                               #
# resource_pool.rb                                              #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to:                            #
#        - list/create/delete a resource pool                   #
#        - list/add/delete members from a resource pool         #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.8     #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

$:.unshift '../../../../../../../lib/ruby/NetApp'
require 'NaServer'

# Variables declaration
args      = ARGV.length
dfmserver = ARGV[0]
dfmuser   = ARGV[1]
dfmpw     = ARGV[2]
command   = ARGV[3]

# Prints the usage of this program
def print_usage() 
	print ("Usage:\n")
	print ("resource_pool.rb <dfmserver> <user> <password> list [ResPoolName]\n")
	print ("resource_pool.rb <dfmserver> <user> <password> create ResPoolName [ResourceTag]\n")
	print ("resource_pool.rb <dfmserver> <user> <password> destroy ResPoolName\n")
	print ("resource_pool.rb <dfmserver> <user> <password> member list ResPoolName\n")
	print ("resource_pool.rb <dfmserver> <user> <password> member [add|del] ResPoolName MemberName\n")
	print ("<dfmserver>       -- Name/IP Address of the DFM server\n")
	print ("<user>            -- DFM server User name\n")
	print ("<password>        -- DFM server User Password\n")
	print ("<ResPoolName>     -- Resource pool name, mandatory for create & destroy options\n")
	print ("<MemberName>      -- Member to be added/removed from a resource pool, mandatory for add  & del options\n")
	exit 
end


# check for valid number of parameters
if ( args < 4 ) 
	print_usage() 
end
# Setup DFM server connection
s = NaServer.new( dfmserver, 1, 0 )
s.set_server_type("DFM")
s.set_admin_user( dfmuser, dfmpw )
# List all resourcepools on the server
if ( command == "list" ) 
	rname = ARGV[4] if(args > 4)
	out   = s.invoke( "resourcepool-list-info-iter-start", "object-name-or-id", rname )
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	records =  out.child_get_int("records")
	tag = out.child_get_string("tag")
	if(records == 0)
		print("\nError : No Resourcepools!\n")
		s.invoke("resourcepool-list-info-iter-end", "tag", tag)
		exit
	end
	out = s.invoke("resourcepool-list-info-iter-next", "maximum", records, "tag", tag)
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	# Loop through the iteration records and print details
	print ("\nRESOURCEPOOLS:\n")
	print ("===================================================================\n")
	rps = out.child_get("resourcepools")
	if (rps == nil) 
		print ("Error: No Resourcepools!\n")
		s.invoke( "resourcepool-list-info-iter-end", "tag", tag)
		exit
	end
	rpInfos = rps.children_get()
	rpInfos.each do |rpi|
		print("Name\t\t:" + rpi.child_get_string("resourcepool-name"))
		print ("\n")
		print ("Status\t\t:" + rpi.child_get_string("resourcepool-status"))
		print ("\n")
		print ("# of Members\t:" + rpi.child_get_string("resourcepool-member-count"))
		print ("\n")
		print ("Tag\t\t:" + rpi.child_get_string("resource-tag"))
		print ("\n")
		print ("===================================================================\n")
	end
	
elsif ( command == "create" )
	# Below section creates a new resource pool
	if(args > 5) 
		rpName = ARGV[4]
		rTag   = ARGV[5]
	elsif(args > 4)
		rpName = ARGV[4]
	else 
		print_usage()
	end
	rpCreate = NaElement.new("resourcepool-create")
	rp       = NaElement.new("resourcepool")
    rpInfo   = NaElement.new("resourcepool-info")
	rpInfo.child_add_string( "resourcepool-name", rpName )
	rpInfo.child_add_string( "resource-tag",      rTag )
	rp.child_add(rpInfo)
	rpCreate.child_add(rp)
    out = s.invoke_elem(rpCreate)
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	print ("Resourcepool " + rpName  + " created with ID : " + out.child_get_int("resourcepool-id").to_s)
	# Iterate through the commandline args to see if you have mentioned
	# any members to be added, if yes add them iteratively.
	if(args > 6)
		memNames = ARGV[6,ARGV.length-1] 
	else
		memNames = []
	end
	memNames.each do |memName|
		out = s.invoke( "resourcepool-add-member", "resourcepool-name-or-id",
				rpName, "member-name-or-id", memName, "resource-tag", rTag )
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			exit
		end
		print ("\nAdded member " + memName + " to Resourcepool " + rpName + "\n")
	end
	
elsif ( command == "destroy" ) 
	# Destroy a resourcepool, but it needs to be empty.
	if(args > 4)
		rpName = ARGV[4] 
	end
	out = s.invoke( "resourcepool-destroy", "resourcepool-name-or-id", rpName )
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	print ("Resourcepool " + rpName + " destroyed!\n")
	
elsif ( command == "member" ) 
	# Member operations  on a resource pool
	if(args > 7)
		subCommand = ARGV[4]
		rpName     = ARGV[5]
		memName    = ARGV[6]
		rTag       = ARGV[7]
	elsif(args > 6)
		subCommand = ARGV[4]
		rpName     = ARGV[5]
		memName    = ARGV[6]
	elsif(args > 5)
		subCommand = ARGV[4]
		rpName     = ARGV[5]
	else
		print_usage()
	end
			
	if ( subCommand == "list" ) 
		# Begin the iterative API
		out = s.invoke( "resourcepool-member-list-info-iter-start", "resourcepool-name-or-id", rpName )
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			exit
		end
		records = out.child_get_int("records")
		tag =  out.child_get_string("tag")
		if(records == 0)
			print("\nNo members in resource pools \n")
			s.invoke("resourcepool-member-list-info-iter-end", "tag", tag)
			exit
		end
		out = s.invoke("resourcepool-member-list-info-iter-next", "maximum", records, "tag", tag)
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			exit
		end
		# Print necessary details from retrieved records
		print ("\nRESOURCEPOOL : " + rpName)
		print ("\n===================================================================\n")
		rpms = out.child_get("resourcepool-members")
		unless(rpms) 
			print ("Error: No Members in Resourcepool!\n")
			exit
		end
		rpmInfos = rpms.children_get()
		rpmInfos.each do |rpmi|
			print("Name\t:" + rpmi.child_get_string("member-name"))
			print ("\n")
			print ("Status\t:" + rpmi.child_get_string("member-status"))
			print ("\n")
			print ("Type\t:" + rpmi.child_get_string("member-type"))
			print ("\n")
			print ("Tag\t:" + rpmi.child_get_string("resource-tag"))
			print ("\n")
			print ("===================================================================\n")
		end
		
	elsif ( subCommand == "add" ) 
		# Add a new member into an existing resource pool
		if ( args < 7 ) 
			print_usage()
		end
		out = s.invoke( "resourcepool-add-member", "resourcepool-name-or-id", rpName, "member-name-or-id", memName, "resource-tag", rTag )
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			exit
		end
		print ("Added member " + memName + " to Resourcepool " + rpName + "\n")
	
	elsif ( subCommand == "del" ) 
		# Remove a  member from an existing resource pool
		if ( args < 7 ) 
			print_usage() 
		end
		out = s.invoke( "resourcepool-remove-member", "resourcepool-name-or-id",
			rpName, "member-name-or-id", memName )
		if ( out.results_status() == "failed" ) 
			print( "Error : " + out.results_reason() + "\n" )
			exit
		end
		print ("Removed member " + memName + " from Resourcepool " + rpName + "\n")
		
	else 
		print_usage()
	
	end
	
else 
	print_usage()
end


