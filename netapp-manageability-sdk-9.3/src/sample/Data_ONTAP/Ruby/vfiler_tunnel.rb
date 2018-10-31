#============================================================
#
# $ID$
#
# vfiler_tunnel.rb
#
# Sample code for vfiler_tunneling
# This sample code demonstrates how to execute ONTAPI APIs on a
# vfiler through the physical storage 
#
# Copyright 2011 Network Appliance, Inc. All rights
# reserved. Specifications subject to change without notice.
#
# This SDK sample code is provided AS IS, with no support or
# warranties of any kind, including but not limited to
# warranties of merchantability or fitness of any kind,
# expressed or implied.  This code is subject to the license
# agreement that accompanies the SDK.
#
# tab size = 4
#
#============================================================

$:.unshift '../../../../lib/ruby/NetApp'
require 'NaServer'

def print_usage()
    print ("Usage: \nvfiler_tunnel [options] <vfiler-name> <storage> <user> \n")
    print ("<password> <ONTAPI-name> [key value] ...\n")
    print ("\noptions:\n")
    print ("-s  Use SSL\n")
    exit
end	
args = ARGV.length
dossl = 0
# check for valid number of parameters
if (args < 4) 
    print_usage() 
end
opt = ARGV.shift
if(opt =~ /-/)
    option = opt.split('-')

    if(option[1] == "s" and args > 2)
        dossl = 1
        vfiler = ARGV.shift
    else
        print_usage()
    end
	storage = ARGV.shift
    user = ARGV.shift
    password = ARGV.shift
    api = ARGV.shift
	
else
    vfiler  = opt
    storage = ARGV.shift
    user = ARGV.shift
    password = ARGV.shift
    api = ARGV.shift
end

unless(api)
    print_usage()
end

# open server
server = NaServer.new(storage, 1, 7)
if(not server.set_vfiler(vfiler))
    print ("Error: ONTAPI version must be at least 1.7 to send API to a vfiler\n")
    exit
end
server.set_admin_user(user, password)
if (dossl) 
    resp = server.set_transport_type("HTTPS")    
    if (resp and resp.results_errno() != 0) 
        r = resp.results_reason()
        print ("Unable to set HTTPS transport " + r + "\n")
        exit
    end
end

length = ARGV.length
# invoke the api with api name and any supplied key-value pairs
x = NaElement.new(api)
k = 0
if(length > 0)
	if((length - 1 & 1) != 0)
		while(k <= length)
			key = ARGV.shift
			k = k + 1
			value = ARGV.shift
			k = k + 1
			x.child_add(NaElement.new(key,value))
		end
	else
		print("Invalid number of parameters")
		print_usage()
	end
end
xo = server.invoke_elem(x)
if ( xo == nil ) 
    print ("invoke api failed to storage system as user:password.\n")
    exit
end
# format the output
print ("Output: \n" + xo.sprintf() + "\n" )




