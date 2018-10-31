#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# protection_policy.rb                                          #
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

$:.unshift '../../../../../../lib/ruby/NetApp'
require 'NaServer'

def usage()
    print ("Usage:\nprotection_policy.rb <dfmserver> <user> <password> list [ <policy> ]\n")
    print ("protection_policy.rb <dfmserver> <user> <password> delete <policy>\n")
    print ("protection_policy.rb <dfmserver> <user> <password> create <policy> <pol-new>\n")
    print ("<dfmserver> -- Name/IP Address of the DFM server\n")
    print ("<user>      -- DFM server User name\n")
    print ("<password>  -- DFM server User Password\n")
    print ("<policy>    -- Existing policy name\n")
    print ("<pol-new>   -- Protection policy to be created\n")
    print ("Note: In the create operation the a copy of protection policy will be made and name changed from <pol-temp> to <pol-new>\n")
    exit 
end


def dfm_list()
    if ($dfmname)
        output = $server.invoke( "dp-policy-list-iter-start", "dp-policy-name-or-id", $dfmname)

    else 
        output = $server.invoke( "dp-policy-list-iter-start" )
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
        $server.invoke("dp-policy-list-iter-end", "tag", tag)
        exit
    end
    # Extracting records one at a time
    record = $server.invoke( "dp-policy-list-iter-next", "maximum", records, "tag", tag )

    if ( record.results_status() == "failed" )
        print( "Error : " +record.results_reason() + "\n" )
        exit
    end
	
    # Navigating to the dp-policy-infos child element
    if(not record)
        exit

    else
        policy_infos = record.child_get("dp-policy-infos")
    end
	
    # Navigating to the dp-policy-info child element
    if(not policy_infos)
        exit 

    else
        policy_info = policy_infos.children_get()
    end
	
    # Iterating through each record
    policy_info.each do |element|
        # extracting the resource-pool name and printing it
        # Navigating to the dp-policy-content child element

        if(not element)
            exit
        else 
            policy_content = element.child_get("dp-policy-content")
	end
		
        # Removing non modifiable policies
	if(not (policy_content.child_get_string("name") =~ /NM$/i))
            print ('-'*80 + "\n")
            print ("Policy Name : "+policy_content.child_get_string("name").to_s+ "\n")
            print("Schedule Id : ",policy_content.child_get_string("id"),"\n")
            print ("Schedule Description : "+policy_content.child_get_string("description").to_s + "\n")
            print ('-'*80 + "\n")

            # printing detials if only one policy is selected for listing
            if ($dfmname) 
                # printing connection info
                dpc  = policy_content.child_get("dp-policy-connections")
                dpci = dpc.child_get("dp-policy-connection-info")
                print("\nBackup Schedule Name :"+(dpci.child_get_string("backup-schedule-name")).to_s,"\n")
                print("Backup Schedule Id   :" +(dpci.child_get_string("backup-schedule-id")).to_s,"\n")
                print ("Connection Id        :"+dpci.child_get_string("id").to_s+ "\n")
                print ("Connection Type      :"+dpci.child_get_string("type").to_s+ "\n")
                print ("Lag Warning Threshold:"+dpci.child_get_string("lag-warning-threshold").to_s+"\n")
                print ("Lag Error Threshold  :"+dpci.child_get_string("lag-error-threshold").to_s+"\n")
                print ("From Node Name       :"+dpci.child_get_string("from-node-name").to_s+ "\n")
                print ("From Node Id         :"+dpci.child_get_string("from-node-id").to_s+"\n")
                print ("To Node Name         :"+dpci.child_get_string("to-node-name").to_s+"\n")
                print ("To Node Id           :"+dpci.child_get_string("to-node-id").to_s+"\n")
	    end
	end
    end
	
    # invoking the iter-end zapi
    output = $server.invoke( "dp-policy-list-iter-end", "tag", tag )

    if(output.results_status() == "failed")
        print( "Error : " + output.results_reason()+ "\n" )
        exit
    end
end


def create()
    policy_id = $server.invoke( "dp-policy-copy", "template-dp-policy-name-or-id", $dfmname, "dp-policy-name", "copy of " + $dfmname )


    if(policy_id.results_status() == "failed")
        print( "Error : " + policy_id.results_reason()+ "\n" )
        exit
    end

    #### Modify section
    # Setting the edit lock for modifcation on the copied policy
    policy = $server.invoke( "dp-policy-edit-begin", "dp-policy-name-or-id","copy of " + $dfmname)

    if(policy.results_status() == "failed")
        print( "Error : " + policy.results_reason() + "\n" )
        $server.invoke( "dp-policy-edit-rollback", "edit-lock-id", policy.child_get_int("edit-lock-id"))
        exit
    end

    # extracting the edit lock id
    lock_id = policy.child_get_int("edit-lock-id")

    # modifying the policy name
    # creating a dp-policy-modify element and adding child elements
    policy_input = NaElement.new("dp-policy-modify")
    policy_input.child_add_string( "edit-lock-id", lock_id )

    # getting the policy content deailts of the original policy
    orig_policy_content = get_policy_content()

    # Creating a new dp-policy-content element and adding name and desc
    policy_content = NaElement.new("dp-policy-content")
    policy_content.child_add_string( "name", $dfmnewname )
    policy_content.child_add_string( "description", "Added by sample code" )

    # appending the original connections and nodes children
    policy_content.child_add(orig_policy_content.child_get("dp-policy-connections") )
    policy_content.child_add(orig_policy_content.child_get("dp-policy-nodes") )

    # Attaching the new policy content child to modify element
    policy_input.child_add(policy_content)

    # Invoking the modify element
    output = $server.invoke_elem(policy_input)

    if(output.results_status() == "failed")
        print( "Error : " + output.results_reason() + "\n" )
        $server.invoke( "dp-policy-edit-rollback", "edit-lock-id", lock_id )
        exit 
    end

    # committing the edit and closing the lock session
    output3 = $server.invoke( "dp-policy-edit-commit", "edit-lock-id", lock_id )

    if(output3.results_status() == "failed")
        print( "Error : " + output.results_reason() + "\n" )
        $server.invoke( "dp-policy-edit-rollback", "edit-lock-id", lock_id )
        exit 
    end

    print ("\nProtection Policy creation Successful\n")
end


# this function is to extract the policy contents of original policy
def get_policy_content() 
    # invoking the api and capturing the ouput for original input policy
    output = $server.invoke( "dp-policy-list-iter-start", "dp-policy-name-or-id", $dfmname )

    if(output.results_status() == "failed")
        print( "Error : " + output.results_reason() + "\n" )
        exit 
    end
    
    records = output.child_get_string("records")
    # Extracting the tag for iterating api
    tag = output.child_get_string("tag")
    # Exrtacting the original policy record
    record = $server.invoke( "dp-policy-list-iter-next", "maximum", records, "tag", tag )

    if(record.results_status() == "failed")
        print( "Error : " + record.results_reason() + "\n" )
        exit 
    end

    # Navigating to the dp-policy-infos child element
    if(not record)
        exit 

    else 
        policy_infos = record.child_get("dp-policy-infos")
    end
	
    # Navigating to the dp-policy-info child element
    if(not policy_infos)
        exit 

    else
        policy_info = policy_infos.child_get("dp-policy-info")
    end
	
    #Navigating to the dp-policy-content child element
    if(not policy_info)
        exit 

    else
        policy_content = policy_info.child_get("dp-policy-content")
    end
	
    # invoking the iter-end zapi
    output = $server.invoke( "dp-policy-list-iter-end", "tag", tag )

    if(output.results_status() == "failed")
        print( "Error : " +output.results_reason()+"\n" )
        exit
    end

    # Returning the original policy content
    return (policy_content)
end


def policy_del()
    policy = $server.invoke( "dp-policy-edit-begin", "dp-policy-name-or-id", $dfmname )

    if(policy.results_status() == "failed")
        print( "Error : " + policy.results_reason() + "\n" )
        exit 
    end

    # extracting the edit lock
    lock_id = policy.child_get_int("edit-lock-id")

    # Deleting the policy name
    # creating a dp-policy-destroy element and adding edit-lock
    output = $server.invoke( "dp-policy-destroy", "edit-lock-id", lock_id )

    if(output.results_status() == "failed")
        print( "Error : " + output.results_reason() + "\n" )
        exit 
    end

    output3 = $server.invoke( "dp-policy-edit-commit", "edit-lock-id", lock_id )

    if(output3.results_status() == "failed")
        print( "Error : " + output3.results_reason() + "\n" )
        $server.invoke( "dp-policy-edit-rollback", "edit-lock-id", lock_id )
        exit 
    end

    print ("\nProtection Policy deletion Successful \n")
end

##### VARIABLES SECTION
args = ARGV.length

if(args < 4)
    usage() 
end

dfmserver = ARGV[0]
dfmuser = ARGV[1]
dfmpw = ARGV[2]
dfmop = ARGV[3]
$dfmname = nil

##### MAIN SECTION
# checking for valid number of parameters for the respective operations
if(dfmop == "list" and args < 4)
    usage() 
end
if(dfmop == "delete" and args != 5)
    usage() 
end

if(args > 5)
    $dfmname = ARGV[4]
    $dfmnewname = ARGV[5]
end

if(args == 5)
    $dfmname = ARGV[4] 
end
if(dfmop == "create" and args < 6)
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

