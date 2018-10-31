#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# rbac.pl                                                       #
#                                                               #
# Copyright (c) 2009 NetApp, Inc. All rights reserved.          #
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
require 5.6.1;

use lib '../../../../../../lib/perl/NetApp';
use NaServer;
use NaElement;
use strict;

##### VARIABLES SECTION
my $args = $#ARGV + 1;
my ($dfmserver,$dfmuser,$dfmpw,$opr,@opt_param)= @ARGV;
my $owner;
my $description;
my $role;
my $server;

##### MAIN SECTION

# check for valid number of parameters for the respective operations
usage() if ($args < 4);

# Create the server context and set appropriate attributes for connecting to
# DFM Server
$server = NaServer->new ($dfmserver, 1, 0);
$server->set_style("LOGIN");
$server->set_transport_type("HTTP");
$server->set_server_type("DFM");
$server->set_port(8088);
$server->set_admin_user($dfmuser, $dfmpw);

# Check for the given input command and call appropriate function.
if($opr eq "operation-list") {
	operation_list();
} elsif($opr eq "operation-add") {
	operation_add()
} elsif($opr eq "operation-delete") {
	operation_delete();
} elsif($opr eq "role-add") {
	role_add();
} elsif($opr eq "role-delete") {
	role_delete();
} elsif($opr eq "role-list") {
	role_list();
} elsif($opr eq "role-capability-add") {
	role_capability_add();
} elsif($opr eq "role-capability-delete") {
	role_capability_delete();
} elsif($opr eq "admin-role-add") {
	admin_role_add();
} elsif($opr eq "admin-role-delete") {
	admin_role_delete();
} elsif($opr eq "admin-list") {
	admin_list();
} elsif($opr eq "admin-role-list") {
	role_admin_list();
} else {
	usage();
}


##### SUBROUTINE SECTION

sub role_admin_list {
	if($args < 5) {
		print "Usage: perl rbac.pl <dfm-server> <user> <password> " .
		"role-admin-list <admin-name-or-id> \n\n" .
		"List the roles assigned to an existing administratror or usergroup.";
		exit(2);
	}
	my $admin_name_id = $ARGV[4];

	# invoke the rbac-role-admin-info-list api and capture the ouput
	my $output = $server->invoke
	("rbac-role-admin-info-list","admin-name-or-id",$admin_name_id);

	# check for the api status
	print("Error : " . $output->results_reason() ."\n") and exit (-2)
	if ($output->results_status() eq "failed");

	my $admin_name = $output->child_get("admin-name-or-id")->
	child_get("rbac-admin-name-or-id")->child_get_string("admin-name");
	my $admin_id = $output->child_get("admin-name-or-id")->
	child_get("rbac-admin-name-or-id")->child_get_string("admin-id");
	print ("\nadmin id            : $admin_id\n");
	print ("admin name          : $admin_name\n\n");
	# Iterate through each admin record
	my @roles = undef;
	if($output->child_get("role-list")) {
		@roles = $output->child_get("role-list")->children_get();
	}

	foreach $role (@roles) {
		my $role_id = $role->child_get_string("rbac-role-id");
		my $role_name = $role->child_get_string("rbac-role-name");
		print ("role id             : $role_id\n");
		print ("role name           : $role_name \n\n");
	}

}

sub admin_list {
	my $admin_name_id = undef;

	# create the input rbac-admin-list-info-iter-start api request
	my $input = NaElement->new("rbac-admin-list-info-iter-start");
	if($args == 5) {
		$admin_name_id = $ARGV[4];
		$input->child_add_string("admin-name-or-id",$admin_name_id);
	}

	# invoke the api and capture the ouput
	my $output = $server->invoke_elem($input);

	# check for the api status
	print("Error : " . $output->results_reason() ."\n") and exit (-2)
		if ($output->results_status() eq "failed");

	# extract the tag and records for rbac-admin-list-info-iter-next api
	my $records = $output->child_get_string("records");
	my $tag = $output->child_get_string("tag");

	# invoke the rbac-admin-list-info-iter-next api
	my $output = $server->invoke
	("rbac-admin-list-info-iter-next","maximum",$records,"tag",$tag);

	# check for the api status
	print("Error : " . $output->results_reason() ."\n") and exit (-2)
		if ($output->results_status() eq "failed");

	# get the list of admins
	my @admins = $output->child_get("admins")->children_get();

	# Iterate through each admin record and print the admin details
	foreach my $admin (@admins){
		my $id = $admin->child_get_string("admin-id");
		my $name = $admin->child_get_string("admin-name");
		print ("\nadmin id               : $id\n");
		print ("admin name             : $name\n");
		my $email = $admin->child_get_string("email-address");
		if($email){
			print ("email address          : $email" . "\n");
		}
	}

	# finally invoke  the rbac-admin-list-info-iter-end api
	my $output = $server->invoke("rbac-admin-list-info-iter-end","tag",$tag);

	# check for the api status
	print("Error : " . $output->results_reason() ."\n") and exit (-2)
		if ($output->results_status() eq "failed");
}


sub admin_role_delete {

	if($args < 6) {
		usage();
	}
	my $admin_name_id = $ARGV[4];
	my $role_name_id = $ARGV[5];

	# create the input rbac-admin-role-remove API request
	my $input = NaElement->new("rbac-admin-role-remove");
	$input->child_add_string("admin-name-or-id",$admin_name_id);

	$input->child_add_string("role-name-or-id",$role_name_id);

	# invoke the api request and capture the ouput
	my $output = $server->invoke_elem($input);

	# check for the api status
	if ($output->results_status() eq "failed") {
		print("Error : " . $output->results_reason() ."\n") and exit (-2)
	}
	else {
		print("admin role(s) deleted successfully! \n");
	}
}

sub admin_role_add {

	if($args < 6) {
		usage();
	}
	my $admin_name_id = $ARGV[4];
	my $role_name_id = $ARGV[5];

	# create the input rbac-admin-role-add API
	my $input = NaElement->new("rbac-admin-role-add");
	$input->child_add_string("admin-name-or-id",$admin_name_id);
	$input->child_add_string("role-name-or-id",$role_name_id);

	# invoke the api request and capturing the ouput
	my $output = $server->invoke_elem($input);

	# check for the api status and print the admin details
	if ($output->results_status() eq "failed") {
		print("Error : " . $output->results_reason() ."\n") and exit (-2)
	}
	else {
		print("admin role added successfully! \n");
		my $new_admin_name_id = $output->child_get("admin-name-or-id")->
		child_get("rbac-admin-name-or-id");
		my $new_admin_name = $new_admin_name_id->
		child_get_string("admin-name");
		my $new_admin_id = $new_admin_name_id->child_get_string("admin-id");
		print ("new admin name                    : $new_admin_name" . "\n");
		print ("new admin id                      : $new_admin_id" . "\n");
	}
}

sub role_capability_delete {

	if($args < 8) {
		usage();
	}

	my $role_name_id = $ARGV[4];
	my $operation = $ARGV[5];
	my $resource_type = $ARGV[6];
	my $resource_name = $ARGV[7];
	my $dataset = undef;
	my $filer = undef;

	if($resource_type ne "dataset" && $resource_type ne "filer") {
		usage();
	}

	# create the input rbac-role-capability-remove api request
	my $input = NaElement->new("rbac-role-capability-remove");
	$input->child_add_string("role-name-or-id",$role_name_id);

	$input->child_add_string("operation",$operation);
	my $resource =  NaElement->new("resource");
	my $resource_identifier = NaElement->new("resource-identifier");
	$input->child_add($resource);
	$resource->child_add($resource_identifier);
	if($resource_type eq "dataset") {
		$dataset =  NaElement->new("dataset");
		my $dataset_resource = NaElement->new("dataset-resource");
		$dataset_resource->child_add_string("dataset-name",$resource_name);
		$dataset->child_add($dataset_resource);
		$resource_identifier->child_add($dataset);
	}
	elsif($resource_type eq "filer") {
		$filer =  NaElement->new("filer");
		my $filer_resource = NaElement->new("filer-resource");
		$filer_resource->child_add_string("filer-name",$resource_name);
		$filer->child_add($filer_resource);
		$resource_identifier->child_add($filer);
	}
	# invoke the api and check the results status
	my $output = $server->invoke_elem($input);
	if ($output->results_status() eq "failed") {
		print("Error : " . $output->results_reason() ."\n") and exit (-2)
	} else {
		print("capability removed successfully! \n");
	}
}

sub role_capability_add {

	if($args < 8) {
		usage();
		exit(2);
	}

	my $role_name_id = $ARGV[4];
	my $operation = $ARGV[5];
	my $resource_type = $ARGV[6];
	my $resource_name = $ARGV[7];
	my $dataset = undef;
	my $filer = undef;

	if($resource_type ne "dataset" && $resource_type ne "filer") {
		usage();
	}

	# create the input rbac-role-capability-add api request
	my $input = NaElement->new("rbac-role-capability-add");
	$input->child_add_string("operation",$operation);
	$input->child_add_string("role-name-or-id",$role_name_id);
	my $resource =  NaElement->new("resource");
	my $resource_identifier = NaElement->new("resource-identifier");
	$input->child_add($resource);
	$resource->child_add($resource_identifier);
	if($resource_type eq "dataset") {
		$dataset =  NaElement->new("dataset");
		my $dataset_resource = NaElement->new("dataset-resource");
		$dataset_resource->child_add_string("dataset-name",$resource_name);
		$dataset->child_add($dataset_resource);
		$resource_identifier->child_add($dataset);
	}
	elsif($resource_type eq "filer") {
		$filer =  NaElement->new("filer");
		my $filer_resource = NaElement->new("filer-resource");
		$filer_resource->child_add_string("filer-name",$resource_name);
		$filer->child_add($filer_resource);
		$resource_identifier->child_add($filer);
	}

	# invoking the api and check the results status
	my $output = $server->invoke_elem($input);

	if ($output->results_status() eq "failed") {
		print("Error : " . $output->results_reason() ."\n") and exit (-2)
	} else {
		print("capability added successfully! \n");
	}
}

sub role_add {
	my $i = 0;
	my $role_add_usage = "Usage: perl rbac.pl <dfm-server> <user> <password> " .
	"role-add <role-name> [-o <owner-name-or-id>] [-d <description>] \n";
	if($args < 6) {
		usage();
	}
	my $role = $ARGV[4];
	my $description = $ARGV[5];

	# create the input rbac-role-add api request
	my $input = NaElement->new("rbac-role-add");
	$input->child_add_string("role-name",$role);
	$input->child_add_string("description",$description);

	# invoke the api and check the results status
	my $output = $server->invoke_elem($input);

	if ($output->results_status() eq "failed") {
		print("Error : " . $output->results_reason() ."\n") and exit (-2)
	} else {
		print("\n Role added successfully! \n new role-id:" .
		$output->child_get_int("role-id") . "\n");
	}
}

sub role_delete {

	if($args < 5) {
		usage();
	}
	$role = $ARGV[4];

	# create the input rbac-role-delete api request
	my $input = NaElement->new("rbac-role-delete");
	$input->child_add_string("role-name-or-id",$role);

	# invoke the api and check the results status
	my $output = $server->invoke_elem($input);

	if ($output->results_status() eq "failed") {
		print("Error : " . $output->results_reason() ."\n") and exit (-2)
	} else {
		print("role deleted successfully!" . "\n");
	}
}

sub role_list {

	my $role = undef;
	if($args == 5) {
		$role = $ARGV[4];
	}

	# create the input rbac-role-info-list api request
	my $input = NaElement->new("rbac-role-info-list");

	if($role){
		$input->child_add_string("role-name-or-id",$role);
	}

	# invoke the api and capture the ouput
	my $output = $server->invoke_elem($input);

	print("Error : " . $output->results_reason() ."\n") and exit (-2)
		if ($output->results_status() eq "failed");

	# retrieve the role attributes
	my @attributes = $output->child_get("role-attributes")->children_get();

	# iterate through each attribute record
	foreach my $attribute (@attributes){
		print "-" x 80;
		my $role_name_id = $attribute->
		child_get("role-name-and-id")->child_get("rbac-role-resource");
		my $role_id = $role_name_id->child_get_string("rbac-role-id");
		my $role_name = $role_name_id->child_get_string("rbac-role-name");

		my $description = $attribute->child_get_string("description");
		print ("role name                         : $role_name" . "\n");
		print ("role id                           : $role_id" . "\n");
		print ("role description                  : $description" . "\n\n");

		my @inherited_roles =
		$attribute->child_get("inherited-roles")->children_get();

		print ("inherited role details:\n\n");
		#iterate throught each inherited roles record
		foreach my $inherited_role (@inherited_roles){
			my $inh_role_id = $inherited_role->child_get_string("rbac-role-id");
			my $inh_role_name =
			$inherited_role->child_get_string("rbac-role-name");
			print ("inherited role name                : $inh_role_name \n\n");
			print ("inherited role id                  : $inh_role_id \n");
		}

		print ("operation details:\n\n");
		my @capabilities =
		$attribute->child_get("capabilities")->children_get();
		# iterate through each capability record
		foreach my $capability (@capabilities){
			my $operation =
			$capability->child_get("operation")->child_get("rbac-operation");
			my $operation_name = $operation->child_get_string("operation-name");
			my $operation_name_details = $operation->
			child_get("operation-name-details")->
			child_get("rbac-operation-name-details");
			my $operation_description = $operation_name_details->
			child_get_string("operation-description");
			my $operation_synopsis = $operation_name_details->
			child_get_string("operation-synopsis");
			my $resource_type = $operation_name_details->
			child_get_string("resource-type");
			print ("operation name                    : $operation_name \n");
			print ("operation description             : $operation_description \n");
			print ("operation synopsis                : $operation_synopsis \n");
			print ("resource type                     : $resource_type \n\n");

		}
	}
	print "-" x 80;
}

sub operation_add {

	if($args < 8) {
		usage();
	}
	my $name = $ARGV[4];
	my $desc = $ARGV[5];
	my $synopsis = $ARGV[6];
	my $type = $ARGV[7];

	# create the input rbac-operation-add api request
	my $input = NaElement->new("rbac-operation-add");
	my $operation = NaElement->new("operation");
	my $rbac_operation = NaElement->new("rbac-operation");

	# add the operation desc,synopsis and type to the api request
	$rbac_operation->child_add_string("operation-name",$name);
	my $operation_name_details = NaElement->new("operation-name-details");
	my $rbac_operation_name_details =
	NaElement->new("rbac-operation-name-details");
	$rbac_operation_name_details->
	child_add_string("operation-description",$desc);
	$rbac_operation_name_details->
	child_add_string("operation-synopsis",$synopsis);
	$rbac_operation_name_details->child_add_string("resource-type",$type);
	$input->child_add($operation);
	$operation->child_add($rbac_operation);
	$rbac_operation->child_add($operation_name_details);
	$operation_name_details->child_add($rbac_operation_name_details);

	# invoke the api request and check the results status.
	my $output = $server->invoke_elem($input);

	if ($output->results_status() eq "failed") {
		print("Error : " . $output->results_reason() ."\n") and exit (-2)
	}
	else {
		print("Operation added successfully!" . "\n");
	}
}

	sub operation_delete {
	if($args < 5) {
		usage();
	}
	my $name = $ARGV[4];
	# invoke the rbac-operation-delete api request with given operation
	my $output = $server->invoke("rbac-operation-delete","operation",$name);

	# capture the api status
	if ($output->results_status() eq "failed") {
		print("Error : " . $output->results_reason() ."\n") and exit (-2)
	}
	else {
		print("Operation deleted successfully!" . "\n");
	}
}


sub operation_list {
	my $operation = $ARGV[4];

	# creating the input rbac-operation-info-list api request
	my $input = NaElement->new("rbac-operation-info-list");

	if($operation){
		$input->child_add_string("operation",$operation);
	}

	# invoke the api request and capture the output
	my $output = $server->invoke_elem($input);

	print("Error : " . $output->results_reason() ."\n") and exit (-2)
		if ($output->results_status() eq "failed");

	# get the list of operations
	my $operation_list = $output->child_get("operation-list");
	my @operations = $operation_list->children_get();

	my $desc ;
	my $type;
	my $synopsis;
	# Iterate through each operation record
	foreach $operation (@operations){
		my $name = $operation->child_get_string("operation-name");
		print ("Name             : $name" . "\n");
		my $name_details = $operation->child_get("operation-name-details");
		my @details = $name_details->children_get();
		foreach my $detail (@details){
			$desc = $detail->child_get_string("operation-description");
			$type = $detail->child_get_string("resource-type");
			$synopsis = $detail->child_get_string("operation-synopsis");
			print ("Description      : $desc" . "\n");
			print ("Resource type    : $type" . "\n");
			print ("Synopsis         : $synopsis" . "\n\n");
		}
	}
}

sub usage()
{
	print <<MSG;
Usage:
 rbac.pl <dfm-server> <user> <password> operation-add  <oper> <oper-desc> <syp>
         <res-ype>
 rbac.pl <dfm-server> <user> <password> operation-list [<oper>]
 rbac.pl <dfm-server> <user> <password> operation-delete <oper>
 rbac.pl <dfm-server> <user> <password> role-add <role> <role-desc>
 rbac.pl <dfm-server> <user> <password> role-list [<role>]
 rbac.pl <dfm-server> <user> <password> role-delete <role>
 rbac.pl <dfm-server> <user> <password> role-capability-add <role> <oper> 
         <res-type> <res-name> 
 rbac.pl <dfm-server> <user> <password> role-capability-delete <role> <oper> 
         <res-type> <res-name>
 rbac.pl <dfm-server> <user> <password> admin-list [<admin>]
 rbac.pl <dfm-server> <user> <password> admin-role-add <admin> <role>
 rbac.pl <dfm-server> <user> <password> admin-role-list <admin>
 rbac.pl <dfm-server> <user> <password> admin-role-delete <admin> <role>

 <dfm-server>      -- Name/IP Address of the DFM Server 
 <user>            -- DFM Server user name
 <password>        -- DFM Server password
 <oper>            -- Name of the operation. For example: "DFM.SRM.Read" 
 <oper-desc>       -- operation description
 <role>            -- role name or id
 <role-desc>       - role description
 <syp>             -- operation synopsis
 <res-type>        -- resource type
 <res-name>        -- name of the resource
 <admin>           -- admin name or id
 
 Possible resource types are: dataset, filer

MSG
exit 1;
}
