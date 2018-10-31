#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# protection_policy.py                                          #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to manage protection policy    #
# on a DFM server                                               #
# Create, delete and list protection policies                   #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.6R2   #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

import sys
sys.path.append("../../../../../../lib/python/NetApp")
from NaServer import *

def usage():
    print ("Usage:\nprotection_policy.py <dfmserver> <user> <password> list [ <policy> ]\n")
    print ("protection_policy.py <dfmserver> <user> <password> delete <policy>\n")
    print ("protection_policy.py <dfmserver> <user> <password> create <policy> <pol-new>\n")
    print ("<operation>     -- create or delete or list\n")
    print ("<dfmserver> -- Name/IP Address of the DFM server\n")
    print ("<user>      -- DFM server User name\n")
    print ("<password>  -- DFM server User Password\n")
    print ("<policy>    -- Existing policy name\n")
    print ("<pol-new>   -- Protection policy to be created\n")
    print ("Note: In the create operation the a copy of protection policy will be made and name changed from <pol-temp> to <pol-new>\n")
    sys.exit (1)


def dfm_list(server):

    if (dfmname):
        output = server.invoke( "dp-policy-list-iter-start", "dp-policy-name-or-id", dfmname)

    else :
        output = server.invoke( "dp-policy-list-iter-start" )

    if ( output.results_status() == "failed" ):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit(2)

    # Extracting the record and tag values and printing them
    records = output.child_get_string("records")

    if(int(records) == 0):
        print("\nNo policies to display\n")

    tag = output.child_get_string("tag")

    # Extracting records one at a time
    record = server.invoke( "dp-policy-list-iter-next",	"maximum", records, "tag", tag )

    if ( record.results_status() == "failed" ):
        print( "Error : " + record.results_reason() + "\n" )
        sys.exit(2)

    # Navigating to the dp-policy-infos child element
    if(not record):
        sys.exit(0)

    else:
        policy_infos = record.child_get("dp-policy-infos")
    
    # Navigating to the dp-policy-info child element
    if(not policy_infos):
        sys.exit (0)

    else:
        policy_info = policy_infos.children_get() 

    # Iterating through each record
    for policy_info in policy_info :
        # extracting the resource-pool name and printing it
	# Navigating to the dp-policy-content child element

        if(not policy_info):
            sys.exit(0)
        else :
            policy_content = policy_info.child_get("dp-policy-content")

        # Removing non modifiable policies
        if ( not(re.match(r'NM$', policy_content.child_get_string("name"), re.I))):
            print ('-'*80 + "\n")
            print ("Policy Name : " + str(policy_content.child_get_string("name")) + "\n")
            print ("Schedule Id : " + str(policy_content.child_get_string("id")) + "\n")
            print ("Schedule Description : " + str(policy_content.child_get_string("description")) + "\n")
            print ('-'*80 + "\n")

            # printing detials if only one policy is selected for listing
            if (dfmname) :
                # printing connection info
                dpc  = policy_content.child_get("dp-policy-connections")
                dpci = dpc.child_get("dp-policy-connection-info")
                print ("\nBackup Schedule Name :" + str(dpci.child_get_string("backup-schedule-name")) + "\n")
                print ("Backup Schedule Id   :" + str(dpci.child_get_string("backup-schedule-id")) + "\n")
                print ("Connection Id        :"  + str(dpci.child_get_string("id")) + "\n")
                print ("Connection Type      :" + str(dpci.child_get_string("type")) + "\n")
                print ("Lag Warning Threshold:" + str(dpci.child_get_string("lag-warning-threshold")) + "\n")
                print ("Lag Error Threshold  :" + str(dpci.child_get_string("lag-error-threshold")) + "\n")
                print ("From Node Name       :" + str(dpci.child_get_string("from-node-name")) + "\n")
                print ("From Node Id         :" + str(dpci.child_get_string("from-node-id")) + "\n")
                print ("To Node Name         :" + str(dpci.child_get_string("to-node-name")) + "\n")
                print ("To Node Id           :" + str(dpci.child_get_string("to-node-id")) + "\n")
        
    # invoking the iter-end zapi
    end = server.invoke( "dp-policy-list-iter-end", "tag", tag )

    if(end.results_status() == "failed"):
        print( "Error : " + end.results_reason() + "\n" )
        sys.exit(2)


def create(server):
    policy_id = server.invoke( "dp-policy-copy", "template-dp-policy-name-or-id",dfmname, "dp-policy-name", "copy of " + dfmname )

    if(policy_id.results_status() == "failed"):
        print( "Error : " + policy_id.results_reason() + "\n" )
        sys.exit(2)

    #### Modify section
    # Setting the edit lock for modifcation on the copied policy
    policy = server.invoke( "dp-policy-edit-begin", "dp-policy-name-or-id","copy of " + dfmname)

    if(policy.results_status() == "failed"):
        print( "Error : " + policy.results_reason() + "\n" )
        server.invoke( "dp-policy-edit-rollback", "edit-lock-id", policy.child_get_int("edit-lock-id"))
        sys.exit(2)

    # extracting the edit lock id
    lock_id = policy.child_get_int("edit-lock-id")

    # modifying the policy name
    # creating a dp-policy-modify element and adding child elements
    policy_input = NaElement("dp-policy-modify")
    policy_input.child_add_string( "edit-lock-id", lock_id )

    # getting the policy content deailts of the original policy
    orig_policy_content = get_policy_content(server)#check perl

    # Creating a new dp-policy-content element and adding name and desc
    policy_content = NaElement("dp-policy-content")
    policy_content.child_add_string( "name", dfmnewname )
    policy_content.child_add_string( "description", "Added by sample code" )

    # appending the original connections and nodes children
    policy_content.child_add(orig_policy_content.child_get("dp-policy-connections") )
    policy_content.child_add(orig_policy_content.child_get("dp-policy-nodes") )

    # Attaching the new policy content child to modify element
    policy_input.child_add(policy_content)

    # Invoking the modify element
    output = server.invoke_elem(policy_input)

    if(output.results_status() == "failed"):
        print( "Error : " + output.results_reason() + "\n" )
        server.invoke( "dp-policy-edit-rollback", "edit-lock-id", lock_id )
        sys.exit (2)

    # committing the edit and closing the lock session
    output3 = server.invoke( "dp-policy-edit-commit", "edit-lock-id", lock_id )

    if(output3.results_status() == "failed"):
        print( "Error : " + output.results_reason() + "\n" )
        server.invoke( "dp-policy-edit-rollback", "edit-lock-id", lock_id )
        sys.exit (2)

    print ("\nProtection Policy creation Successful\n")


# this function is to extract the policy contents of original policy
def get_policy_content(server) :
    # invoking the api and capturing the ouput for original input policy
    output = server.invoke( "dp-policy-list-iter-start",  "dp-policy-name-or-id", dfmname )

    if(output.results_status() == "failed"):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit (2)

    # Extracting the tag for iterating api
    tag = output.child_get_string("tag")

    # Exrtacting the original policy record
    record = server.invoke( "dp-policy-list-iter-next", "maximum", 1, "tag", tag )

    if(record.results_status() == "failed"):
        print( "Error : " + record.results_reason() + "\n" )
        sys.exit (2)
    
    # Navigating to the dp-policy-infos child element
    if(not record):
        sys.exit (0)

    else :
        policy_infos = record.child_get("dp-policy-infos")

    # Navigating to the dp-policy-info child element
    if(not policy_infos):
        sys.exit (0)

    else:
        policy_info = policy_infos.child_get("dp-policy-info")
	  
    #Navigating to the dp-policy-content child element
    if(not policy_info):
        sys.exit (0)

    else:
        policy_content = policy_info.child_get("dp-policy-content")
	  
    # invoking the iter-end zapi
    end = server.invoke( "dp-policy-list-iter-end", "tag", tag )

    if(end.results_status() == "failed"):
        print( "Error : " + end.results_reason() + "\n" )
        sys.exit(2)

    # Returning the original policy content
    return (policy_content)


def policy_del(server):
    policy = server.invoke( "dp-policy-edit-begin", "dp-policy-name-or-id", dfmname )

    if(policy.results_status() == "failed"):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit (2)

    # extracting the edit lock
    lock_id = policy.child_get_int("edit-lock-id")

    # Deleting the policy name
    # creating a dp-policy-destroy element and adding edit-lock
    output = server.invoke( "dp-policy-destroy", "edit-lock-id", lock_id )

    if(output.results_status() == "failed"):
        print( "Error : " + output.results_reason() + "\n" )
        sys.exit (2)
        
    output3 = server.invoke( "dp-policy-edit-commit", "edit-lock-id", lock_id )

    if(output3.results_status() == "failed"):
        print( "Error : " + output3.results_reason() + "\n" )
        server.invoke( "dp-policy-edit-rollback", "edit-lock-id", lock_id )
        sys.exit (2)
	
    print ("\nProtection Policy deletion Successful\n")


##### VARIABLES SECTION
args = len(sys.argv) - 1

if(args < 4):
    usage()
    
dfmserver = sys.argv[1]
dfmuser = sys.argv[2]
dfmpw = sys.argv[3]
dfmop = sys.argv[4]
dfmname = None


##### MAIN SECTION
# checking for valid number of parameters for the respective operations  
if(dfmop == "list" and args < 4): 
    usage()

if(dfmop == "delete" and args != 5):
    usage()

if(args > 5):
    dfmname = sys.argv[5]
    dfmnewname = sys.argv[6]

if(args == 5):
    dfmname = sys.argv[5]

if(dfmop == "create" and args < 6):
    usage()
    
    
# checking if the operation selected is valid
if((dfmop != "list") and (dfmop != "create") and (dfmop != "delete")):
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

elif(dfmop == 'list'):
    dfm_list(serv)

elif(dfmop == 'delete'):
    policy_del(serv)

else:
    usage()





