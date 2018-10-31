#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# vfiler.py                                                     #
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

import sys
sys.path.append("../../../../../../lib/python/NetApp")
from NaServer import *

def usage():
    print ("\nUsage:\n")
    print ("vfiler.py <dfmserver> <user> <password> delete <name>\n")
    print ("vfiler.py <dfmserver> <user> <password> create <name> <rpool> <ip> [ <tname> ]\n")
    print ("vfiler.py <dfmserver> <user> <password> template-list [ <tname> ]\n")
    print ("vfiler.py <dfmserver> <user> <password> template-delete <tname>\n")
    print ("vfiler.py <dfmserver> <user> <password> template-create <a-tname> [ -a <cauth> -d <cdomain> ] [ -s <csecurity> ]\n")
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
    sys.exit(2)


def  create(server):
    # invoking the create api
    output = server.invoke( "vfiler-create", "ip-address", ip, "name", dfmval, "resource-name-or-id", rpool )

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    print ("\nvFiler unit creation Successful\n")
    print ("vFiler unit created on Storage System : " + output.child_get_string("filer-name") + "\nRoot Volume : "\
           + output.child_get_string("root-volume-name"))

    if(tname):
        setup(server)


def setup(server):
    # invoking the setup api with vfiler template
    output = server.invoke( "vfiler-setup", "vfiler-name-or-id", dfmval, "vfiler-template-name-or-id", tname )

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "template not attached\n" )
        sys.exit(2)
    
    print ("\nvFiler unit setup with template " + tname + "Successful\n")


def vfiler_del(server):
    # invoking the api
    output = server.invoke( "vfiler-destroy", "vfiler-name-or-id", dfmval )

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "template not attached\n" )
        sys.exit(2)

    print ("\nvFiler unit deletion Successful\n")


def temp_create(server):
    # creating the input for api execution
    # creating a vfiler-template-create element and adding child elements
    vfiler_input = NaElement("vfiler-template-create")
    vtemp = NaElement("vfiler-template")
    vtemp_info = NaElement("vfiler-template-info")
    vtemp_info.child_add_string( "vfiler-template-name", dfmval )

    if (cifs_auth):
        vtemp_info.child_add_string( "cifs-auth-type", cifs_auth )

    if(cifs_dom):
        vtemp_info.child_add_string( "cifs-domain", cifs_dom )

    if(cifs_sec):
        vtemp_info.child_add_string( "cifs-security-style", cifs_sec )

    vtemp.child_add(vtemp_info)
    vfiler_input.child_add(vtemp)
    output = server.invoke_elem(vfiler_input)

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    print ("\nvFiler template creation Successful\n")


def temp_list(server):
    # creating a input element
    vfiler_input = NaElement("vfiler-template-list-info-iter-start")
   
    if (dfmval):
        vfiler_input.child_add_string( "vfiler-template-name-or-id", dfmval )

    # invoking the api and capturing the ouput
    output = server.invoke_elem(vfiler_input)

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    # Extracting the record and tag values and printing them
    records = output.child_get_string("records")

    if ( not records ):
        print ("\nNo templates to display\n" )

    tag = output.child_get_string("tag")
    # Iterating through each record
    # Extracting all records
    record = server.invoke( "vfiler-template-list-info-iter-next", "maximum", records, "tag", tag )

    if ( record.results_status() == "failed" ):
        print( "Error : " + record.results_reason() + " \n" )
        sys.exit(2)

    # Navigating to the vfiler-templates child element
    if(not record):
        sys.exit(0)

    else:
        stat = record.child_get("vfiler-templates")
    
    # Navigating to the vfiler-template-info child element
    if(not stat):
        sys.exit (0)

    else:
        info = stat.children_get()

    for info in info:
         print ('-'*80 + "\n")
         # extracting the resource-pool name and printing it
         print ("vFiler template Name : " + str(info.child_get_string("vfiler-template-name")) + "\n")
         print ("Template Id : "  + str(info.child_get_string("vfiler-template-id")) + "\n")
         print ("Template Description : " + str(info.child_get_string("vfiler-template-description")) + "\n")
         print ('-'*80 + "\n")

         # printing detials if only one vfiler-template is selected for listing

         if (dfmval) :
             print ("\nCIFS Authhentication  :" + str(info.child_get_string("cifs-auth-type")) + "\n")
             print ("CIFS Domain             :" + str(info.child_get_string("cifs-domain")) + "\n")
             print ("CIFS Security Style     :" + str(info.child_get_string("cifs-security-style")) + "\n")
             print ("DNS Domain              :" + str(info.child_get_string("dns-domain")) + "\n")
             print ("NIS Domain              :" + str(info.child_get_string("nis-domain")) + "\n")
   
    # invoking the iter-end zapi
    end = server.invoke( "vfiler-template-list-info-iter-end", "tag", tag )

    if(end.results_status() == "failed"):
        print( "Error : " + end.results_reason() + "\n" )
        sys.exit(2)


def temp_del(server):
    #invoking the api and printing the xml ouput
    output = server.invoke( "vfiler-template-delete", "vfiler-template-name-or-id", dfmval )

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    print ("\nvFiler Template deletion Successful\n")

               
args = len(sys.argv) - 1

if(args < 4 or args < 5 and sys.argv[4] != 'template-list'):
    usage()

dfmserver = sys.argv[1]
dfmuser = sys.argv[2]
dfmpw = sys.argv[3]
dfmop = sys.argv[4]

cifs_dom = None
cifs_auth = None
cifs_sec = None

# checking for valid number of parameters for the respective operations  
if((dfmop == "delete" and args != 5)
   or (dfmop == "create" and args < 7)
   or (dfmop == "template-list" and args < 4)
   or (dfmop == "template-delete" and args != 5)
   or (dfmop == "template-create" and args < 5)):
    usage()
    
# checking if the operation selected is valid
if((dfmop != "create") and
   (dfmop != "delete") and
   (dfmop != "template-create") and
   (dfmop != "template-list") and
   (dfmop != "template-delete")):
    usage()

if (args >= 7):
    dfmval = sys.argv[5]
    opt_param = sys.argv[6:]
    if (dfmop == "create"):
        rpool = opt_param[0]
        ip = opt_param[1]
        if(len(opt_param) > 2): 
            tname = opt_param[2]
        else :
            tname = None
        opt_param = []

elif(args == 5):
    dfmval = sys.argv[5]
    opt_param = []

else:
    dfmval = None
    opt_param = [] 

# parsing optional parameters
i = 0
while ( i < len(opt_param) - 1 ):

    if(opt_param[i]  == '-d'):
        i = i + 1
        cifs_dom    = opt_param[i]
        i = i + 1

    elif(opt_param[i]  == '-a'):
        i = i + 1
        cifs_auth  = opt_param[i]
        i = i + 1

    elif(opt_param[i]  == '-s' ):
        i = i + 1
        cifs_sec   = opt_param[i]
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

elif(dfmop == 'delete'):
    vfiler_del(serv)

elif(dfmop == 'template-create'):
    temp_create(serv)

elif(dfmop == 'template-list'):
    temp_list(serv)

elif(dfmop == 'template-delete'):
    temp_del(serv)

else:
    usage()



