#===============================================================#
#                                                               #
# ID                                                            #
#                                                               #
# multistore.rb                                                 #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to:                            #
#        - create/destroy/setup a multistore                    #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.8     #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

$:.unshift '../../../../../../../lib/ruby/NetApp'
require 'NaServer'

def print_usage() 
	print ("Usage:\n")
	print ("multistore.rb <dfmserver> <user> <password> create <vfiler> <ip> <protocol> <rpool>\n")
	print ("multistore.rb <dfmserver> <user> <password> destroy <vfiler>\n")
	print ("multistore.rb <dfmserver> <user> <password> setup <vfiler> <if> <ip> <nm> [-c]\n")
	print ("<dfmserver>  -- Name/IP Address of the DFM server\n")
	print ("<user>       -- DFM server User name\n")
	print ("<password>   -- DFM server User Password\n")
	print ("<vfiler>     -- Vfiler name to be created or setup\n")
	print ("<ip>         -- IP Address to be assigned to the vfiler\n")
	print ("<protocol>   -- nas - for NFS & CIFS\n")
	print ("san - for iSCSI\n")
	print ("all - for both NFS & CIFS\n")
	print ("<rpool>      -- Resource pool in which vfiler will be created\n")
	print ("<if>         -- interface on the vfiler to be used, for e.g e0a, e0b\n")
	print ("<nm>         -- netmask on the vfiler to be used, for e.g 255.255.255.0\n")
	print ("-c           -- specify this flag to run cifs setup for nas & all protocols\n")
	exit (1)
end

# Variables declaration
args      = ARGV.length
dfmserver = ARGV[0]
dfmuser   = ARGV[1]
dfmpw     = ARGV[2]
command   = ARGV[3]
# check for valid number of parameters
if ( args < 4 ) 
	print_usage() 
end
# Setup DFM server connection
s = NaServer.new( dfmserver, 1, 0 )
s.set_server_type("DFM")
s.set_admin_user( dfmuser, dfmpw )

# Create a new Multistore
if ( command == "create" ) 
	if ( args < 8 ) 
		print_usage() 
	end
	vfiler_name = ARGV[4]
	ip          = ARGV[5]
	protocols   = ARGV[6]
	rpool       = ARGV[7]
	# Create multistore with ip and choose the resourcepool to be created from.
	input = NaElement.new("vfiler-create")
	input.child_add_string( "name", vfiler_name )
	input.child_add_string( "ip-address", ip )
	input.child_add_string( "resource-name-or-id", rpool )
	# Based on the option on the commandline setup the right protocols
	# needed on the multistore
	allproto = NaElement.new("allowed-protocols")
	if( protocols == "all" ) 
		allproto.child_add_string( "protocols", "nfs" )
		allproto.child_add_string( "protocols", "cifs" )
		allproto.child_add_string( "protocols", "iscsi" )
	elsif( protocols == "nas" ) 
		allproto.child_add_string( "protocols", "nfs" )
		allproto.child_add_string( "protocols", "cifs" )
	elsif( protocols == "san" ) 
		allproto.child_add_string( "protocols", "iscsi" )
	else 
		print("Protocols allowed are: nfs, cifs, all\n" )
		exit 
	end
	input.child_add(allproto)
	out = s.invoke_elem(input)
	if (out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	print ("VFiler '" + vfiler_name  + "' created on " + out.child_get_string("filer-name") + ":" + out.child_get_string("root-volume-name"))

# After a multistore creation, you need to set it up with right IPs and CIFS
# as needed.  With out this step Multistore is not completely operational.
elsif ( command == "setup" ) 
	if ( args < 8 ) 
		print_usage() 
	end
	vfiler_name = ARGV[4]
	interface   = ARGV[5]
	ip          = ARGV[6]
	netmask     = ARGV[7]
	if(args > 8)
		cifs = ARGV[8]
	else 
		cifs = nil
	end
	input = NaElement.new("vfiler-setup")
	input.child_add_string( "vfiler-name-or-id", vfiler_name )
	if ( cifs == "-c" ) 
		input.child_add_string( "run-cifs-setup", "true" ) 
	end
	# Have to manually choose the interface on the storage system,
	# that needs to host the IP of this multistore
	ipbind     = NaElement.new("ip-bindings")
	ipbindinfo = NaElement.new("ip-binding-info")
	ipbindinfo.child_add_string( "interface",  interface )
	ipbindinfo.child_add_string( "ip-address", ip )
	ipbindinfo.child_add_string( "netmask",    netmask )
	ipbind.child_add(ipbindinfo)
	input.child_add(ipbind)
	out = s.invoke_elem(input)
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	print ("VFiler '" + vfiler_name + "' setup!\n")

elsif ( command == "destroy" ) 
	# Destroy an existing multistore.  This will stop and delete the multistore.
	if ( args < 5 ) 
		print_usage() 
	end
	vfiler_name = ARGV[4]
	out = s.invoke( "vfiler-destroy", "vfiler-name-or-id", vfiler_name )
	if ( out.results_status() == "failed" ) 
		print( "Error : " + out.results_reason() + "\n" )
		exit
	end
	print ("VFiler " + vfiler_name + " destroyed! \n")

else 
	print_usage()
end
