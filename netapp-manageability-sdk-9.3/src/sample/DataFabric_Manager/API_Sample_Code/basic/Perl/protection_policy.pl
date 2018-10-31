#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# protection_policy.pl                                          #
#                                                               #
# Copyright (c) 2009 NetApp, Inc. All rights reserved.          #
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

use lib '../../../../../../lib/perl/NetApp';
use NaServer;
use NaElement;
use strict;

##### VARIABLES SECTION
my $args = $#ARGV + 1;
my ( $dfmserver, $dfmuser, $dfmpw, $dfmop, $dfmname, $dfmnewname ) = @ARGV;

##### MAIN SECTION
# checking for valid number of parameters for the respective operations
usage()
  if ( ( $dfmop eq "list" and $args < 4 )
	or ( $dfmop eq "delete" and $args != 5 )
	or ( $dfmop eq "create" and $args != 6 ) );

# checking if the operation selected is valid
usage()
  if (  ( $dfmop ne "list" )
	and ( $dfmop ne "create" )
	and ( $dfmop ne "delete" ) );

# Creating a server object and setting appropriate attributes
my $serv = NaServer->new( $dfmserver, 1, 0 );
$serv->set_style("LOGIN");
$serv->set_transport_type("HTTP");
$serv->set_server_type("DFM");
$serv->set_port(8088);
$serv->set_admin_user( $dfmuser, $dfmpw );

# Calling the subroutines based on the operation selected
if   ( $dfmop eq 'create' ) { create($serv);      }
elsif( $dfmop eq 'list' )   { list($serv);        }
elsif( $dfmop eq 'delete' ) { del($serv);         }
else                        { usage(); };

##### SUBROUTINE SECTION

sub result {
	my $res = shift;

	# Checking for the string "passed" in the output
	my $r = ( $res =~ /passed/ ) ? "Successful" : "UnSuccessful";
	return $r;
}

sub list {

	# Reading the server object
	my $server = $_[0];
	my $output;

	# invoking the api and capturing the ouput
	if ($dfmname) {
		$output =
		  $server->invoke( "dp-policy-list-iter-start", "dp-policy-name-or-id",
			$dfmname );
	} else {
		$output = $server->invoke("dp-policy-list-iter-start");
	}
	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	# Extracting the record and tag values and printing them
	my $records = $output->child_get_string("records");

	print "\nNo policies to display\n" if ( not $records );

	my $tag = $output->child_get_string("tag");

	# Extracting records one at a time
	my $record =
	  $server->invoke( "dp-policy-list-iter-next", "maximum", $records, "tag",
		$tag );

	print( "Error : " . $record->results_reason() . "\n" ) and exit(-2)
	  if ( $record->results_status() eq "failed" );

	#print $record->sprintf();
	# Navigating to the dp-policy-infos child element
	my $policy_infos = $record->child_get("dp-policy-infos")
	  or exit 0
	  if ($record);

	# Navigating to the dp-policy-info child element
	my @policy_info = $policy_infos->children_get()
	  or exit 0
	  if ($policy_infos);

	# Iterating through each record
	foreach my $policy_info (@policy_info) {

		# extracting the resource-pool name and printing it
		# Navigating to the dp-policy-content child element
		my $policy_content = $policy_info->child_get("dp-policy-content")
		  or exit 0
		  if ($policy_info);

		# Removing non modifiable policies
		if ( $policy_content->child_get_string("name") !~ /NM$/ ) {
			print "-" x 80 . "\n";
			print "Policy Name : "
			  . $policy_content->child_get_string("name") . "\n";
			print "Id : " . $policy_info->child_get_string("id") . "\n";
			print "Description : "
			  . $policy_content->child_get_string("description") . "\n";
			print "-" x 80 . "\n";

			# printing detials if only one policy is selected for listing
			if ($dfmname) {

				# printing connection info
				my $dpc  = $policy_content->child_get("dp-policy-connections");
				my $dpci = $dpc->child_get("dp-policy-connection-info");
				print "\nBackup Schedule Name :"
				  . $dpci->child_get_string("backup-schedule-name") . "\n";
				print "Backup Schedule Id   :"
				  . $dpci->child_get_string("backup-schedule-id") . "\n";
				print "Connection Id        :"
				  . $dpci->child_get_string("id") . "\n";
				print "Connection Type      :"
				  . $dpci->child_get_string("type") . "\n";
				print "Lag Warning Threshold:"
				  . $dpci->child_get_string("lag-warning-threshold") . "\n";
				print "Lag Error Threshold  :"
				  . $dpci->child_get_string("lag-error-threshold") . "\n";
				print "From Node Name       :"
				  . $dpci->child_get_string("from-node-name") . "\n";
				print "From Node Id         :"
				  . $dpci->child_get_string("from-node-id") . "\n";
				print "To Node Name         :"
				  . $dpci->child_get_string("to-node-name") . "\n";
				print "To Node Id           :"
				  . $dpci->child_get_string("to-node-id") . "\n";
			}
		}
	}

	# invoking the iter-end zapi
	my $end = $server->invoke( "dp-policy-list-iter-end", "tag", $tag );
	print( "Error : " . $end->results_reason() . "\n" ) and exit(-2)
	  if ( $end->results_status() eq "failed" );
}

sub create {

	#Reading the server object
	my $server = $_[0];

	#### Copy section
	# Making a copy of the policy in the format copy of <policy name>
	my $id =
	  $server->invoke( "dp-policy-copy", "template-dp-policy-name-or-id",
		$dfmname, "dp-policy-name", "copy of $dfmname" );
	print( "Error : " . $id->results_reason() . "\n" ) and exit(-2)
	  if ( $id->results_status() eq "failed" );
	####

	#### Modify section
	# Setting the edit lock for modifcation on the copied policy

	my $policy =
	  $server->invoke( "dp-policy-edit-begin", "dp-policy-name-or-id",
		"copy of $dfmname" );
	print( "Error : " . $policy->results_reason() . "\n" )
	  and $server->invoke( "dp-policy-edit-rollback", "edit-lock-id", 
			$policy->child_get_int("edit-lock-id")) and exit(-2)
	  if ( $policy->results_status() eq "failed" );

	# extracting the edit lock id
	my $lock_id = $policy->child_get_int("edit-lock-id");

	# modifying the policy name
	# creating a dp-policy-modify element and adding child elements
	my $input = NaElement->new("dp-policy-modify");
	$input->child_add_string( "edit-lock-id", $lock_id );

	# getting the policy content deailts of the original policy
	my $orig_policy_content = get_policy_content($serv);

	# Creating a new dp-policy-content element and adding name and desc
	my $policy_content = NaElement->new("dp-policy-content");
	$policy_content->child_add_string( "name",        $dfmnewname );
	$policy_content->child_add_string( "description", "Added by sample code" );

	# appending the original connections and nodes children
	$policy_content->child_add(
		$orig_policy_content->child_get("dp-policy-connections") );
	$policy_content->child_add(
		$orig_policy_content->child_get("dp-policy-nodes") );

	# Attaching the new policy content child to modify element
	$input->child_add($policy_content);

	# Invoking the modify element
	my $output = $server->invoke_elem($input);
	print( "Error : " . $output->results_reason() . "\n" )
	  and $server->invoke( "dp-policy-edit-rollback", "edit-lock-id", $lock_id )
	  and exit(-2)
	  if ( $output->results_status() eq "failed" );

	# committing the edit and closing the lock session
	my $output3 =
	  $server->invoke( "dp-policy-edit-commit", "edit-lock-id", $lock_id );
	print( "Error : " . $output3->results_reason() . "\n" )
	  and $server->invoke( "dp-policy-edit-rollback", "edit-lock-id", $lock_id )
	  and exit(-2)
	  if ( $output3->results_status() eq "failed" );

	print "\nProtection Policy creation "
	  . result( $output->results_status() ) . "\n";
}

# this function is to extract the policy contents of original policy
sub get_policy_content {

	# Reading the server object
	my $server = $_[0];

	# invoking the api and capturing the ouput for original input policy
	my $output =
	  $server->invoke( "dp-policy-list-iter-start", "dp-policy-name-or-id",
		$dfmname );
	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	# Extracting the tag for iterating api
	my $tag = $output->child_get_string("tag");

	# Exrtacting the original policy record
	my $record =
	  $server->invoke( "dp-policy-list-iter-next", "maximum", 1, "tag", $tag );
	print( "Error : " . $record->results_reason() . "\n" ) and exit(-2)
	  if ( $record->results_status() eq "failed" );

	# Navigating to the dp-policy-infos child element
	my $policy_infos = $record->child_get("dp-policy-infos")
	  or exit 0
	  if ($record);

	# Navigating to the dp-policy-info child element
	my $policy_info = $policy_infos->child_get("dp-policy-info")
	  or exit 0
	  if ($policy_infos);

	# Navigating to the dp-policy-content child element
	my $policy_content = $policy_info->child_get("dp-policy-content")
	  or exit 0
	  if ($policy_info);

	# invoking the iter-end zapi
	my $end = $server->invoke( "dp-policy-list-iter-end", "tag", $tag );
	print( "Error : " . $end->results_reason() . "\n" ) and exit(-2)
	  if ( $end->results_status() eq "failed" );

	# Returning the original policy content
	return ($policy_content);
}

sub del {

	# Reading the server object
	my $server = $_[0];

	my $policy =
	  $server->invoke( "dp-policy-edit-begin", "dp-policy-name-or-id",
		"$dfmname" );
	print( "Error : " . $policy->results_reason() . "\n" ) and exit(-2)
	  if ( $policy->results_status() eq "failed" );

	# extracting the edit lock
	my $lock_id = $policy->child_get_int("edit-lock-id");

	# Deleting the policy name
	# creating a dp-policy-destroy element and adding edit-lock
	my $output =
	  $server->invoke( "dp-policy-destroy", "edit-lock-id", $lock_id );
	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	my $output3 =
	  $server->invoke( "dp-policy-edit-commit", "edit-lock-id", $lock_id );
	print( "Error : " . $output3->results_reason() . "\n" )
	  and $server->invoke( "dp-policy-edit-rollback", "edit-lock-id", $lock_id )
	  and exit(-2)
	  if ( $output3->results_status() eq "failed" );

	print "\nProtection Policy deletion "
	  . result( $output->results_status() ) . "\n";

}

sub usage {
	print <<MSG;

Usage:
protection_policy.pl <dfmserver> <user> <password> list [ <policy> ]

protection_policy.pl <dfmserver> <user> <password> delete <policy>

protection_policy.pl <dfmserver> <user> <password> create <policy> <pol-new>

<operation> -- create or delete or list

<dfmserver> -- Name/IP Address of the DFM server
<user>      -- DFM server User name
<password>  -- DFM server User Password
<policy>    -- Exisiting policy name
<pol-new>   -- Protection policy to be created


Note: In the create operation the a copy of protection policy will be made and
name changed from <pol-temp> to <pol-new>

MSG
	exit 1;
}

#=========================== POD ============================#

=head1 NAME

  protection_policy.pl - Manages protection policy on a dfm server


=head1 SYNOPSIS

  protection_policy.pl <dfmserver> <user> <password> list [ <pol-new> ]

  protection_policy.pl <dfmserver> <user> <password> delete <pol-new>

  protection_policy.pl <dfmserver> <user> <password> create <pol-temp> <pol-new>

=head1 ARGUMENTS

  <dfmserver>
   DFM server name.

  <user>
  DFM server username.

  <password>
  DFM server user password.

  <pol-temp>
  existing protection policy name to be used for cloning and creating new template

  <pol-new>
  protection policy name to be created

=head1 SEE ALSO

  NaElement.pm, NaServer.pm

=head1 COPYRIGHT

 Copyright (c) 2009 NetApp, Inc. All rights reserved.
 Specifications subject to change without notice.

=cut

