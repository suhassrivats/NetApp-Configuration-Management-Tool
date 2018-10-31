#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# vfiler.rb                                                     #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to manage vFiler               #
# on a DFM server                                               #
# you can create and delete vFiler units, create,list and       #
# delete vFiler Templates                                       #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.7.1   #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

$:.unshift '../../../../../../lib/ruby/NetApp'
require 'NaServer'

def usage
    print ("\nUsage:\n")
    print ("vfiler.rb <dfmserver> <user> <password> delete <name>\n")
    print ("vfiler.rb <dfmserver> <user> <password> create <name> <rpool> <ip> [ <tname> ]\n")
    print ("vfiler.rb <dfmserver> <user> <password> template-list [ <tname> ]\n")
    print ("vfiler.rb <dfmserver> <user> <password> template-delete <tname>\n")
    print ("vfiler.rb <dfmserver> <user> <password> template-create <a-tname> [ -a <cauth> -d <cdomain> ] [ -s <csecurity> ]\n")
    print ("<dfmserver> -- Name/IP Address of the DFM server\n")
    print ("<user>      -- DFM server User name\n")
    print ("<password>  -- DFM server User Password\n")
    print ("<rpool>     -- Resource pool in which vFiler is to be created\n")
    print ("<ip>        -- ip address of the new vFiler\n")
    print ("<name>      -- name of the new vFiler to be created\n")
    print ("<tname>     -- Existing Template name\n")
    print ("<a-tname>   -- Template to be created\n")
    print ("<cauth>     -- CIFS authentication mode Possible values: active_directory,workgroup.Default value: workgroup\n")
    print ("<cdomain>   -- Active Directory domain .This field is applicable only when cifs-auth-type is set to active-directory\n")
    print ("<csecurity> -- The security style Possible values: ntfs, multiprotocol.Default value is: multiprotocol\n")
    exit
end


def  create()
    # invoking the create api
    output = $server.invoke( "vfiler-create", "ip-address", $ip, "name", $dfmval,"resource-name-or-id", $rpool )

    if ( output.results_status() == "failed" )
        print( "Error : " + output.results_reason() + "\n" )
        exit
	end

    print ("\nvFiler unit creation " + result( output.results_status() ) + "\n")
    print ("vFiler unit created on Storage System : " + output.child_get_string("filer-name") + "\nRoot Volume : "\
            + output.child_get_string("root-volume-name"))
    
	if($tname)
	    setup()
        end
end


def setup()
    # invoking the setup api with vfiler template
    output = $server.invoke( "vfiler-setup", "vfiler-name-or-id", $dfmval,"vfiler-template-name-or-id", $tname )

    if ( output.results_status() == "failed" )
        print( "Error : " + output.results_reason() + "template not attached\n" )
        exit
	end
	
	print ("\nvFiler unit setup with template " + $tname + "Successful\n")
end


def vfiler_del()
    # invoking the api
    output = $server.invoke( "vfiler-destroy", "vfiler-name-or-id", $dfmval )

    if ( output.results_status() == "failed" )
        print( "Error : " + output.results_reason() + "template not attached\n" )
        exit
	end
	
    print ("\nvFiler unit deletion Successful\n")
end


def temp_create()
    # creating the input for api execution
    # creating a vfiler-template-create element and adding child elements
    vfiler_input = NaElement.new("vfiler-template-create")
    vtemp = NaElement.new("vfiler-template")
    vtemp_info = NaElement.new("vfiler-template-info")
    vtemp_info.child_add_string( "vfiler-template-name", $dfmval )
	
    vtemp_info.child_add_string( "cifs-auth-type",$cifs_auth ) if ($cifs_auth)
	vtemp_info.child_add_string( "cifs-domain", $cifs_dom )  if($cifs_dom)
    vtemp_info.child_add_string( "cifs-security-style",$cifs_sec )  if($cifs_sec)
    vtemp.child_add(vtemp_info)
    vfiler_input.child_add(vtemp)
    output = $server.invoke_elem(vfiler_input)

    if ( output.results_status() == "failed" )
        print( "Error : " + output.results_reason() + "\n" )
        exit
	end

    print ("\nvFiler template creation Successful\n")
end


def temp_list()
    # creating a input element
	
    vfiler_input = NaElement.new("vfiler-template-list-info-iter-start")
		
    if ($dfmval)
		vfiler_input.child_add_string( "vfiler-template-name-or-id", $dfmval ) 
	end
	
	# invoking the api and capturing the ouput
    output = $server.invoke_elem(vfiler_input)
	
    if ( output.results_status() == "failed" )
        print( "Error : " + output.results_reason() + "\n" )
    end    
	
	# Extracting the record and tag values and printing them
    records = output.child_get_string("records")
    tag = output.child_get_string("tag")
    if(records.to_i == 0)
	print("\nNo templates to display")
	$server.invoke( "vfiler-template-list-info-iter-end", "tag", tag)
	exit
    end

    # Iterating through each record
    # Extracting all records
    record = $server.invoke( "vfiler-template-list-info-iter-next","maximum", records, "tag", tag )

    if ( record.results_status() == "failed" )
        print( "Error : " + record.results_reason() + " \n" )
        exit
	end

    # Navigating to the vfiler-templates child element
    if(not record)
        exit
    else
	stat = record.child_get("vfiler-templates")
    end
    # Navigating to the vfiler-template-info child element
    if(not stat)
        exit
    else
        information = stat.children_get()
    end
    information.each do |info|
         print('-'*80 + "\n")
         # extracting the resource-pool name and printing it
         print ("vFiler template Name : " + info.child_get_string("vfiler-template-name").to_s + "\n")
         print ("Template Id : " + info.child_get_string("vfiler-template-id").to_s + "\n")
         print ("Template Description : " + info.child_get_string("vfiler-template-description").to_s + "\n")
         print ('-'*80 + "\n")

         # printing detials if only one vfiler-template is selected for listing

         if ($dfmval) 
             print ("\nCIFS Authhentication  :" + info.child_get_string("cifs-auth-type").to_s + "\n")
             print ("CIFS Domain             :" + info.child_get_string("cifs-domain").to_s + "\n")
             print ("CIFS Security Style     :" + info.child_get_string("cifs-security-style").to_s + "\n")
             print ("DNS Domain              :" + info.child_get_string("dns-domain").to_s + "\n")
             print ("NIS Domain              :" + info.child_get_string("nis-domain").to_s + "\n")
		 end
	end
	
    # invoking the iter-end zapi
    output = $server.invoke( "vfiler-template-list-info-iter-end", "tag", tag )

    if(output.results_status() == "failed")
        print( "Error : " + output.results_reason() + "\n" )
        exit
	end
end


def temp_del()
    #invoking the api and printing the xml ouput
    output = $server.invoke( "vfiler-template-delete", "vfiler-template-name-or-id",$dfmval )

    if ( output.results_status() == "failed" )
        print( "Error : " + output.results_reason() + "\n" )
        exit
	end

    print ("\nvFiler Template deletion Successful\n")
end


args = ARGV.length

if(args < 4 or args < 5 and ARGV[3] != 'template-list')
    usage()
end
dfmserver = ARGV[0]
dfmuser = ARGV[1]
dfmpw = ARGV[2]
dfmop = ARGV[3]
$dfmval = nil
opt_param = []

if(args > 4)
    $dfmval = ARGV[4]
    opt_param = ARGV[5,args-1]
	
	if(dfmop == "create")
	    $rpool = opt_param[0]
	    $ip = opt_param[1]
	    $tname = opt_param[2]
	end
end

$cifs_dom = nil
$cifs_auth = nil
$cifs_sec = nil

# checking for valid number of parameters for the respective operations
if((dfmop == "delete" and args != 5) or (dfmop == "create" and args < 7) \
   or (dfmop == "template-list" and args < 4) or (dfmop == "template-delete" and args != 5) \
   or (dfmop == "template-create" and args < 5))
   usage() 
end

# checking if the operation selected is valid
if((dfmop != "create") and (dfmop != "delete") and (dfmop != "template-create") \
	and (dfmop != "template-list") and (dfmop != "template-delete"))
	usage() 
end

# parsing optional parameters in case of template-create
if(dfmop == "template-create")
    i = 0
    while (i < opt_param.length )

        if(opt_param[i]  == '-d')
            i = i + 1
            $cifs_dom    = opt_param[i]
            i = i + 1

        elsif(opt_param[i]  == '-a')
            i = i + 1
            $cifs_auth  = opt_param[i]
            i = i + 1

        elsif(opt_param[i]  == '-s' )
            i = i + 1
            $cifs_sec   = opt_param[i]
            i = i + 1

        else 
            usage()
	    end
        end
end

# Creating a server object and setting appropriate attributes
$server = NaServer.new(dfmserver, 1, 0 )
$server.set_server_type('DFM')
$server.set_admin_user( dfmuser, dfmpw )

# Calling the subroutines based on the operation selected
if(dfmop == 'create')
    create()

elsif(dfmop == 'delete')
    vfiler_del()

elsif(dfmop == 'template-create')
    temp_create()

elsif(dfmop == 'template-list')
	temp_list()

elsif(dfmop == 'template-delete')
    temp_del()

else
    usage()
end



