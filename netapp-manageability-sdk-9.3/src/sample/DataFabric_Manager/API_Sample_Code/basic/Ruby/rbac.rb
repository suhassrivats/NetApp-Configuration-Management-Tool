#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# rbac.rb                                                       #
#                                                               #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to manage  a                   #
# Role Based Access Control (RBAC). Using this sample code,     #
# you can create, delete and list roles,operations, etc.        #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.6R2   #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#

$:.unshift '../../../../../../lib/ruby/NetApp'
require 'NaServer'

def usage
    print ("Usage:\n")
    print (" rbac.rb <dfm-server> <user> <password> operation-add  <oper> <oper-desc> <syp><res-ype>\n")
    print (" rbac.rb <dfm-server> <user> <password> operation-list [<oper>]\n")
    print (" rbac.rb <dfm-server> <user> <password> operation-delete <oper>\n")
    print (" rbac.rb <dfm-server> <user> <password> role-add <role> [-o <owner-name-or-id>] [-d <description>]\n")
    print (" rbac.rb <dfm-server> <user> <password> role-list [<role>]\n")
    print (" rbac.rb <dfm-server> <user> <password> role-delete <role>\n")
    print (" rbac.rb <dfm-server> <user> <password> role-capability-add <role> <oper> <res-type> <res-name>\n")
    print (" rbac.rb <dfm-server> <user> <password> role-capability-delete <role> <oper> <res-type> <res-name>\n")
    print (" rbac.rb <dfm-server> <user> <password> admin-list [<admin>]\n")
    print (" rbac.rb <dfm-server> <user> <password> admin-role-add <admin> <role>\n")
    print (" rbac.rb <dfm-server> <user> <password> admin-role-list <admin>\n")
    print (" rbac.rb <dfm-server> <user> <password> admin-role-delete <admin> <role>\n")
    print (" <dfm-server>      -- Name/IP Address of the DFM Server\n")
    print (" <user>            -- DFM Server user name\n")
    print (" <password>        -- DFM Server password\n")
    print (" <oper>            -- Name of the operation. For example: DFM.SRM.Read\n")
    print (" <oper-desc>       -- operation description\n")
    print (" <role>            -- role name or id\n")
    print (" <role-desc>       - role description\n")
    print (" <syp>             -- operation synopsis\n")
    print (" <res-type>        -- resource type\n")
    print (" <res-name>        -- name of the resource\n")
    print (" <admin>           -- admin name or id\n")
    print (" Possible resource types are: dataset, filer\n")
    exit 
end


def role_admin_list
    if($args < 5)
        print ("Usage: rbac.rb <dfm-server> <user> <password> " \
		"role-admin-list <admin-name-or-id> \n\n" \
		"List the roles assigned to an existing administratror or usergroup.")
        exit
	end

    admin_name_id = ARGV[4] 

    # invoke the rbac-role-admin-info-list api and capture the ouput
    output = $server.invoke("rbac-role-admin-info-list", "admin-name-or-id", admin_name_id)

    # check for the api status
    if ( output.results_status() == "failed" )
        print( "Error : " + output.results_reason() + "\n" )
        exit
    end

    admin = output.child_get("admin-name-or-id")
    admin_rbac = admin.child_get("rbac-admin-name-or-id")
    admin_name = admin_rbac.child_get_string("admin-name")
    admin_id = admin_rbac.child_get_string("admin-id")
    print ("\nadmin id          : " + admin_id + "\n")
    print ("admin name          : " + admin_name + "\n\n")
    # Iterate through each admin record
    roles = nil
    if(output.child_get("role-list"))
        roles = output.child_get("role-list").children_get()
    end
    roles.each do |role|
        role_id = role.child_get_string("rbac-role-id")
        role_name = role.child_get_string("rbac-role-name")
        print ("role id             :" + role_id + "\n")
        print ("role name           :" + role_name + "\n\n")
    end
end




def admin_list
    # create the input rbac-admin-list-info-iter-start api request
    dfm_input = NaElement.new("rbac-admin-list-info-iter-start")

    if($args == 5) 
        dfm_input.child_add_string("admin-name-or-id", ARGV[4])
    end

    # invoke the api and capture the ouput
    output = $server.invoke_elem(dfm_input)

    # check for the api status
    if ( output.results_status() == "failed" )
        print( "Error : " + output.results_reason() + "\n" )
        exit
    end

    # extract the tag and records for rbac-admin-list-info-iter-next api
    records = output.child_get_string("records")
    tag = output.child_get_string("tag")
    if(records.to_i == 0)
        $server.invoke("rbac-admin-list-info-iter-end", "tag", tag)
        exit
    end
    # invoke the rbac-admin-list-info-iter-next api
    output = $server.invoke("rbac-admin-list-info-iter-next", "maximum", records, "tag", tag)

    # check for the api status
    if ( output.results_status() == "failed" )
        print( "Error : " + output.results_reason() + "\n" )
        exit
    end

    # get the list of admins
    admins = output.child_get("admins").children_get()

    # Iterate through each admin record and print the admin details
    admins.each do |admin|
        admin_id = admin.child_get_string("admin-id")
        name = admin.child_get_string("admin-name")
        print ("\nadmin id             :" + admin_id + "\n")
        print ("admin name           :" + name + "\n")
        email = admin.child_get_string("email-address")

        if(email)
            print ("email address          :" + email + "\n")
	end
    end
	
    # finally invoke  the rbac-admin-list-info-iter-end api
    output = $server.invoke("rbac-admin-list-info-iter-end", "tag", tag)

    # check for the api status
    if ( output.results_status() == "failed" )
        print( "Error : " + output.results_reason() + "\n" )
        exit
	end
end


def admin_role_delete() 
    if($args < 6) 
		usage()
	end

    admin_name_id = ARGV[4]
    role_name_id = ARGV[5]

    # create the input rbac-admin-role-remove API request
    dfm_input = NaElement.new("rbac-admin-role-remove")
    dfm_input.child_add_string("admin-name-or-id",admin_name_id)
    dfm_input.child_add_string("role-name-or-id",role_name_id)

    # invoke the api request and capture the ouput
    output = $server.invoke_elem(dfm_input)

    # check for the api status
    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        exit 

    else 
        print("admin role(s) deleted successfully! \n")
	end
end


def admin_role_add 
    if($args < 6)
	usage() 
    end

    # create the input rbac-admin-role-add API
    dfm_input = NaElement.new("rbac-admin-role-add")
    dfm_input.child_add_string("admin-name-or-id", ARGV[4])
    dfm_input.child_add_string("role-name-or-id", ARGV[5])

    # invoke the api request and capturing the ouput
    output = $server.invoke_elem(dfm_input)

    # check for the api status and print the admin details
    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        exit 
		
    else 
        print("admin role added successfully! \n")
        new_admin_name_id = output.child_get("admin-name-or-id").child_get("rbac-admin-name-or-id")
        new_admin_name = new_admin_name_id.child_get_string("admin-name")
        new_admin_id = new_admin_name_id.child_get_string("admin-id")
        print ("new admin name                    :" + new_admin_name + " \n")
        print ("new admin id                      :" + new_admin_id + "\n")
	end
end


def role_capability_delete
    if($args < 8)
		usage() 
	end

    role_name_id = ARGV[4]
    operation = ARGV[5]
    resource_type = ARGV[6]
    resource_name = ARGV[7]
    dataset = nil
    filer = nil

    if(resource_type != "dataset" and resource_type != "filer") 
        usage() 
    end

    # create the input rbac-role-capability-remove api request
    dfm_input = NaElement.new("rbac-role-capability-remove")
    dfm_input.child_add_string("role-name-or-id",role_name_id)
    dfm_input.child_add_string("operation",operation)
    resource =  NaElement.new("resource")
    resource_identifier = NaElement.new("resource-identifier")
    dfm_input.child_add(resource)
    resource.child_add(resource_identifier)

    if(resource_type == "dataset") 
        dataset =  NaElement.new("dataset")
        dataset_resource = NaElement.new("dataset-resource")
        dataset_resource.child_add_string("dataset-name",resource_name)
        dataset.child_add(dataset_resource)
        resource_identifier.child_add(dataset)

    elsif(resource_type == "filer") 
        filer =  NaElement.new("filer")
        filer_resource = NaElement.new("filer-resource")
        filer_resource.child_add_string("filer-name",resource_name)
        filer.child_add(filer_resource)
        resource_identifier.child_add(filer)
	end
	
    # invoke the api and check the results status
    output = $server.invoke_elem(dfm_input)
    
	if (output.results_status() == "failed") 
        print("Error : " + output.results_reason()+ "\n")
        exit 
	
    else 
        print("capability removed successfully! \n")
	end
end



def role_capability_add
    if($args < 8)
		usage()
	end

    role_name_id = ARGV[4]
    operation = ARGV[5]
    resource_type = ARGV[6]
    resource_name = ARGV[7]
    dataset = nil
    filer = nil

    if(resource_type != "dataset" and resource_type != "filer")
       usage()
    end
    # create the input rbac-role-capability-add api request
    dfm_input = NaElement.new("rbac-role-capability-add")
    dfm_input.child_add_string("operation",operation)
    dfm_input.child_add_string("role-name-or-id",role_name_id)
    resource =  NaElement.new("resource")
    resource_identifier = NaElement.new("resource-identifier")
    dfm_input.child_add(resource)
    resource.child_add(resource_identifier)

    if(resource_type == "dataset") 
        dataset =  NaElement.new("dataset")
        dataset_resource = NaElement.new("dataset-resource")
        dataset_resource.child_add_string("dataset-name",resource_name)
        dataset.child_add(dataset_resource)
        resource_identifier.child_add(dataset)

    elsif(resource_type == "filer")
        filer =  NaElement.new("filer")
        filer_resource = NaElement.new("filer-resource")
        filer_resource.child_add_string("filer-name",resource_name)
        filer.child_add(filer_resource)
        resource_identifier.child_add(filer)
	end
	
    # invoking the api and check the results status
    output = $server.invoke_elem(dfm_input)

    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        exit 

    else 
        print("capability added successfully! \n")
	end
end


def role_add() 
    role_add_usage = "Usage: rbac.rb <dfm-server> <user> <password> " \
                     "role-add <role-name> [-o <owner-name-or-id>] [-d <description>] \n"

    if($args < 4)
	usage() 
    elsif($args < 5)
	print(role_add_usage) 
	exit 
    end
    role = ARGV[4]
    opt_param = ARGV[5,ARGV.length]
	
    # create the input rbac-role-add api request
    dfm_input = NaElement.new("rbac-role-add")
    dfm_input.child_add_string("role-name",role)
    j = 0
    while(j < opt_param.length)
	if(opt_param[j] == '-o')
		owner_name = opt_param[j+1]
		dfm_input.child_add_string("owner-name-or-id", owner_name)
		j = j + 2
		
	elsif(opt_param[j] == '-d')
		description = opt_param[j+1]
		dfm_input.child_add_string("description", description)
		j = j + 2
		
	else
		print(role_add_usage)
		exit
	end
    end
    # invoke the api and check the results status
    output = $server.invoke_elem(dfm_input)
    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        exit 
    else 
        print("\n Role added successfully! \n new role-id:" + output.child_get_int("role-id").to_s + "\n")
    end
end


def role_delete() 
    if($args < 5)
	usage()
    end
    role = ARGV[4]
    # create the input rbac-role-delete api request
    dfm_input = NaElement.new("rbac-role-delete")
    dfm_input.child_add_string("role-name-or-id",role)

    # invoke the api and check the results status
    output = $server.invoke_elem(dfm_input)

    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        exit 
    else 
        print("role deleted successfully!" + "\n")
    end
end

	
def role_list() 
    role = nil
    if($args > 4) 
	role = ARGV[4]
    end

    # create the input rbac-role-info-list api request
    dfm_input = NaElement.new("rbac-role-info-list")

    if(role)
        dfm_input.child_add_string("role-name-or-id",role)
    end
    # invoke the api and capture the ouput
    output = $server.invoke_elem(dfm_input)
    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        exit 
    end
    # retrieve the role attributes
    attributes = output.child_get("role-attributes").children_get()

    # iterate through each attribute record
    attributes.each do |attribute|
        print("-"*80)
        role_name_id = attribute.child_get("role-name-and-id").child_get("rbac-role-resource")
        role_id = role_name_id.child_get_string("rbac-role-id")
        role_name = role_name_id.child_get_string("rbac-role-name")
        description = attribute.child_get_string("description")
        print ("\nrole name                         :" + role_name + "\n")
        print ("role id                           :" + role_id + "\n")
        print ("role description                  :" + description + "\n\n")
        inherited_roles = attribute.child_get("inherited-roles").children_get()
        print ("inherited role details:\n\n")

        #iterate throught each inherited roles record
	inherited_roles.each do |inherited_role|
            inh_role_id = inherited_role.child_get_string("rbac-role-id")
            inh_role_name = inherited_role.child_get_string("rbac-role-name")
            print ("\ninherited role name                :" + inh_role_name + "\n")
            print ("inherited role id                  : " + inh_role_id + "\n")
	end

        print ("operation details:\n\n")
        capabilities = 		attribute.child_get("capabilities").children_get()

        # iterate through each capability record
        capabilities.each do |capability|
            operation = capability.child_get("operation").child_get("rbac-operation")
            operation_name = operation.child_get_string("operation-name")
            operation_name_details = operation.child_get("operation-name-details").child_get("rbac-operation-name-details")
            operation_description = operation_name_details.child_get_string("operation-description")
            operation_synopsis = operation_name_details.child_get_string("operation-synopsis")
            resource_type = operation_name_details.child_get_string("resource-type")
            print ("operation name                    :" + operation_name + "\n")
            print ("operation description             :" + operation_description + "\n")
            print ("operation synopsis                :" + operation_synopsis + "\n")
            print ("resource type                     :" + resource_type + "\n\n")
		end
	end
	
    print ("-"*80+"\n")
end


def operation_add()
    if($args < 8)
		usage() 
	end

    name = ARGV[4]
    desc = ARGV[5]
    synopsis = ARGV[6]
    operation_type = ARGV[7]

    # create the input rbac-operation-add api request
    dfm_input = NaElement.new("rbac-operation-add")
    operation = NaElement.new("operation")
    rbac_operation = NaElement.new("rbac-operation")

    # add the operation desc,synopsis and type to the api request
    rbac_operation.child_add_string("operation-name",name)
    operation_name_details = NaElement.new("operation-name-details")
    rbac_operation_name_details = NaElement.new("rbac-operation-name-details")
    rbac_operation_name_details.child_add_string("operation-description",desc)
    rbac_operation_name_details.child_add_string("operation-synopsis",synopsis)
    rbac_operation_name_details.child_add_string("resource-type",operation_type)
    dfm_input.child_add(operation)
    operation.child_add(rbac_operation)
    rbac_operation.child_add(operation_name_details)
    operation_name_details.child_add(rbac_operation_name_details)

    # invoke the api request and check the results status.
    output = $server.invoke_elem(dfm_input)

    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        exit 

    else 
        print("Operation added successfully!" + "\n")
	end
end
	

def operation_delete()
    if($args < 5)
		usage()
	end

    name = ARGV[4] 

    # invoke the rbac-operation-delete api request with given operation
    output = $server.invoke("rbac-operation-delete","operation",name)

    # capture the api status
    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        exit 

    else 
        print("Operation deleted successfully!" + "\n")
	end
end

	
def operation_list
    operation = ARGV[4]
    # creating the input rbac-operation-info-list api request
    dfm_input = NaElement.new("rbac-operation-info-list")

    if(operation)
        dfm_input.child_add_string("operation", operation)
    end
    # invoke the api request and capture the output
    output = $server.invoke_elem(dfm_input)
    if (output.results_status() == "failed") 
        print("Error : " + output.results_reason() + "\n")
        exit 
    end
    # get the list of operations
    operation_list = output.child_get("operation-list")
    operations = operation_list.children_get()
    # Iterate through each operation record
    operations.each do |operation|
        name = operation.child_get_string("operation-name")
	print ("Name             :" + name + "\n")
        name_details = operation.child_get("operation-name-details")
        details = name_details.children_get()
	
	details.each do |detail|	
            desc = detail.child_get_string("operation-description")
            resource_type = detail.child_get_string("resource-type")
            synopsis = detail.child_get_string("operation-synopsis")
            print ("Description      :" + desc + "\n")
            print ("Resource type    :" + resource_type + "\n")
            print ("Synopsis         :" + synopsis + "\n\n")
	end
    end
end


$args = ARGV.length
# check for valid number of parameters for the respective operations
if($args < 4)
	usage()
end

dfmserver = ARGV[0]
dfmuser = ARGV[1]
dfmpw = ARGV[2]
opr = ARGV[3]

# Create the server context and set appropriate attributes for connecting to
# DFM Server
$server = NaServer.new(dfmserver, 1, 0 )
$server.set_style('LOGIN')
$server.set_server_type('DFM')
$server.set_admin_user( dfmuser, dfmpw )

# Check for the given input command and call appropriate function.
if(opr == "operation-list")
    operation_list()

elsif(opr == "operation-add") 
    operation_add()

elsif(opr == "operation-delete")
    operation_delete()

elsif(opr == "role-add")
    role_add()

elsif(opr == "role-delete")
    role_delete()

elsif(opr == "role-list")
    role_list()

elsif(opr == "role-capability-add")
    role_capability_add()

elsif(opr == "role-capability-delete")
    role_capability_delete()

elsif(opr == "admin-role-add")
    admin_role_add()

elsif(opr == "admin-role-delete")
    admin_role_delete()

elsif(opr == "admin-list")
    admin_list()

elsif(opr == "admin-role-list")
    role_admin_list()

else
    usage()
end



