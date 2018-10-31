#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# dataset.pl                                                    #
#                                                               #
# Copyright (c) 2009 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to manage dataset              #
# on a DFM server                                               #
# you can create,delete and list datasets                       #
# add,list,delete and provision members                         #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.8     #
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
my ( $dfmserver, $dfmuser, $dfmpw, $dfmop, $dfmval, @opt_param ) = @ARGV;

# extracting the member if its a member operation
my $dfmmem = shift @opt_param if ( $dfmop =~ /member/ );
my $size = shift @opt_param and my $max_size = shift @opt_param
  if ( $dfmop =~ /member-provision/ );

my $provname;
my $protname=undef;
my $respool=undef;

##### MAIN SECTION
# checking for valid number of parameters for the respective operations
usage()
  if ( ( $dfmop eq "list" and $args < 4 )
	or ( $dfmop eq "delete"           and $args != 5 )
	or ( $dfmop eq "create"           and $args < 5 )
	or ( $dfmop eq "member-list"      and $args < 5 )
	or ( $dfmop eq "member-remove"    and $args != 6 )
	or ( $dfmop eq "member-add"       and $args != 6 )
	or ( $dfmop eq "member-provision" and $args < 7 ) );

# checking if the operation selected is valid
usage()
  if (  ( $dfmop ne "list" )
	and ( $dfmop ne "create" )
	and ( $dfmop ne "delete" )
	and ( $dfmop ne "member-add" )
	and ( $dfmop ne "member-list" )
	and ( $dfmop ne "member-remove" )
	and ( $dfmop ne "member-provision" ) );

# parsing optional parameters
my $i = 0;
while ( $i < scalar(@opt_param) ) {
	if   ( $opt_param[$i] eq '-v' ) { $provname = $opt_param[ ++$i ]; ++$i; }
	elsif( $opt_param[$i] eq '-t' ) { $protname = $opt_param[ ++$i ]; ++$i; }
	elsif( $opt_param[$i] eq '-r' ) { $respool  = $opt_param[ ++$i ]; ++$i; }
	else                            { usage(); };
}

# Creating a server object and setting appropriate attributes
my $serv = NaServer->new( $dfmserver, 1, 0 );
$serv->set_style("LOGIN");
$serv->set_transport_type("HTTP");
$serv->set_server_type("DFM");
$serv->set_port(8088);
$serv->set_admin_user( $dfmuser, $dfmpw );

# Calling the subroutines based on the operation selected

if   ( $dfmop eq 'create' )           { create($serv);      }
elsif( $dfmop eq 'list' )             { list($serv);        }
elsif( $dfmop eq 'delete' )           { del($serv);         }
elsif( $dfmop eq 'member-add' )       { member_add($serv);  }
elsif( $dfmop eq 'member-list' )      { member_list($serv); }
elsif( $dfmop eq 'member-remove' )    { member_rem($serv);  }
elsif( $dfmop eq 'member-provision' ) { member_prov($serv); }
else                                  { usage(); };

##### SUBROUTINE SECTION

sub result {
	my $res = shift;

	# Checking for the string "passed" in the output
	my $r = ( $res eq "passed" ) ? "Successful" : "UnSuccessful";
	return $r;
}

sub create {

	# Reading the server object
	my $server = $_[0];
	my $output;

	# creating the input for api execution
	# creating a dataset-create element and adding child elements
	if ( not $protname ) {
		$output = $server->invoke( "dataset-create", "dataset-name", $dfmval,
			"provisioning-policy-name-or-id", $provname );
	} else {
		$output =
		  $server->invoke( "dataset-create", "dataset-name", $dfmval,
			"provisioning-policy-name-or-id",
			$provname, "protection-policy-name-or-id", $protname );
	}

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	print "\nDataset creation " . result( $output->results_status() ) . "\n";
	add_resource_pool($server) if ($respool);
}

sub add_resource_pool {

	# Reading the server object
	my $server = $_[0];

	# Setting the edit lock for adding resource pool
	my $policy =
	  $server->invoke( "dataset-edit-begin", "dataset-name-or-id", $dfmval );
	print( "Error : " . $policy->results_reason() . "\n" ) and exit(-2)
	  if ( $policy->results_status() eq "failed" );

	# extracting the edit lock id
	my $lock_id = $policy->child_get_int("edit-lock-id");

	# Invoking add resource pool element
	my $output =
	  $server->invoke( "dataset-add-resourcepool", "edit-lock-id", $lock_id,
		"resourcepool-name-or-id", $respool );

	# edit-rollback has to happen else dataset will be locked
	print( "Error : " . $output->results_reason() . "\n" )
	  and $server->invoke( "dataset-edit-rollback", "edit-lock-id", $lock_id )
	  and exit(-2)
	  if ( $output->results_status() eq "failed" );

	# committing the edit and closing the lock session
	my $output2 =
	  $server->invoke( "dataset-edit-commit", "edit-lock-id", $lock_id );
	print( "Error : " . $output2->results_reason() . "\n" )
	  and $server->invoke( "dataset-edit-rollback", "edit-lock-id", $lock_id )
	  and exit(-2)
	  if ( $output2->results_status() eq "failed" );

	print "\nAdd resource pool " . result( $output2->results_status() ) . "\n";
}

sub list {

	# Reading the server object
	my $server = $_[0];

	# creating a input element
	my $input = NaElement->new("dataset-list-info-iter-start");
	$input->child_add_string( "object-name-or-id", $dfmval ) if ($dfmval);

	# invoking the api and capturing the ouput
	my $output = $server->invoke_elem($input);

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	# Extracting the record and tag values and printing them
	my $records = $output->child_get_string("records");

	print "\nNo datasets to display\n" if ( not $records );

	my $tag = $output->child_get_string("tag");

	# Iterating through each record

	# Extracting records one at a time
	my $record =
	  $server->invoke( "dataset-list-info-iter-next", "maximum", $records,
		"tag", $tag );

	print( "Error : " . $record->results_reason() . "\n" ) and exit(-2)
	  if ( $record->results_status() eq "failed" );

	# Navigating to the datasets child element
	my $stat = $record->child_get("datasets") or exit 0 if ($record);

	# Navigating to the dataset-info child element
	my @info = $stat->children_get() or exit 0 if ($stat);

	# Iterating through each record
	foreach my $info (@info) {

		# extracting the dataset name and printing it
		print "-" x 80 . "\n";
		print "Dataset Name : "
		  . $info->child_get_string("dataset-name") . "\n";
		print "Dataset Id : " . $info->child_get_string("dataset-id") . "\n";
		print "Dataset Description : "
		  . $info->child_get_string("dataset-description") . "\n";
		print "-" x 80 . "\n";

		# printing detials if only one dataset is selected for listing
		if ($dfmval) {
			print "\nDataset Contact          : "
			  . $info->child_get_string("dataset-contact") . "\n";
			print "Provisioning Policy Id   : "
			  . $info->child_get_string("provisioning-policy-id") . "\n";
			print "Provisioning Policy Name : "
			  . $info->child_get_string("provisioning-policy-name") . "\n";
			print "Protection Policy Id     : "
			  . $info->child_get_string("protection-policy-id") . "\n";
			print "Protection Policy Name   : "
			  . $info->child_get_string("protection-policy-name") . "\n";
			print "Resource Pool Name       : "
			  . $info->child_get_string("resourcepool-name") . "\n";

			my $status = $info->child_get("dataset-status");
			print "Resource Status          : "
			  . $status->child_get_string("resource-status") . "\n";
			print "Conformance Status       : "
			  . $status->child_get_string("conformance-status") . "\n";
			print "Performance Status       : "
			  . $status->child_get_string("performance-status") . "\n";
			print "Protection Status        : "
			  . $status->child_get_string("protection-status") . "\n";
			print "Space Status             : "
			  . $status->child_get_string("space-status") . "\n";

		}
	}

	# invoking the iter-end zapi
	my $end = $server->invoke( "dataset-list-info-iter-end", "tag", $tag );
	print( "Error : " . $end->results_reason() . "\n" ) and exit(-2)
	  if ( $end->results_status() eq "failed" );
}

sub del {

	# Reading the server object
	my $server = $_[0];

	# invoking the api and printing the xml ouput
	my $output =
	  $server->invoke( "dataset-destroy", "dataset-name-or-id", $dfmval );

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	print "\nDataset deletion " . result( $output->results_status() ) . "\n";
}

sub member_add {

	# Reading the server object
	my $server = $_[0];

	# beginning the edit session
	my $dataset =
	  $server->invoke( "dataset-edit-begin", "dataset-name-or-id", "$dfmval" );
	print( "Error : " . $dataset->results_reason() . "\n" ) and exit(-2)
	  if ( $dataset->results_status() eq "failed" );

	# extracting the edit lock
	my $lock_id = $dataset->child_get_int("edit-lock-id");

	# creating a add datsaet element
	my $input = NaElement->new("dataset-add-member");
	$input->child_add_string( "edit-lock-id", $lock_id );
	my $mem   = NaElement->new("dataset-member-parameters");
	my $param = NaElement->new("dataset-member-parameter");
	$param->child_add_string( "object-name-or-id", $dfmmem );
	$mem->child_add($param);
	$input->child_add($mem);

	# invoking the api and printing the xml ouput
	my $output = $server->invoke_elem($input);
	print( "Error : " . $output->results_reason() . "\n" )
	  and $server->invoke( "dataset-edit-rollback", "edit-lock-id", $lock_id )
	  and exit(-2)
	  if ( $output->results_status() eq "failed" );

	my $output3 =
	  $server->invoke( "dataset-edit-commit", "edit-lock-id", $lock_id );
	print( "Error : " . $output3->results_reason() . "\n" )
	  and $server->invoke( "dataset-edit-rollback", "edit-lock-id", $lock_id )
	  and exit(-2)
	  if ( $output3->results_status() eq "failed" );

	print "\nMember Add " . result( $output->results_status() ) . "\n";
}

sub member_list {

	# Reading the server object
	my $server = $_[0];
	my $output;

	# invoking the api and capturing the ouput
	if ($dfmmem) {
		$output = $server->invoke(
			"dataset-member-list-info-iter-start", "dataset-name-or-id",
			$dfmval,                               "member-name-or-id",
			$dfmmem,                               "include-indirect",
			"true",                                "include-space-info",
			"true"
		);
	} else {
		$output = $server->invoke( "dataset-member-list-info-iter-start",
			"dataset-name-or-id", $dfmval, "include-indirect", "true",
			"include-space-info", "true" );
	}

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	# Extracting the record and tag values and printing them
	my $records = $output->child_get_string("records");

	print "\nNo members in the dataset\n" if ( not $records );

	my $tag = $output->child_get_string("tag");

	# Iterating through each record

	# Extracting records one at a time
	my $record = $server->invoke( "dataset-member-list-info-iter-next",
		"maximum", $records, "tag", $tag );
	print( "Error : " . $record->results_reason() . "\n" ) and exit(-2)
	  if ( $record->results_status() eq "failed" );

	# Navigating to the datasets child element
	my $stat = $record->child_get("dataset-members") or exit 0 if ($record);

	# Navigating to the dataset-info child element
	my @info = $stat->children_get() or exit 0 if ($stat);

	# Iterating through each record
	foreach my $info (@info) {

		# extracting the member name and printing it
		my $name = $info->child_get_string("member-name");
		my $id   = $info->child_get_string("member-id");
		if ( $name !~ /-$/ ) {
			print "-" x 80 . "\n";
			print "Member Name : " . $name . "\n";
			print "Member Id : " . $id . "\n";
			print "-" x 80 . "\n";

			# printing detials if only one member is selected for listing
			if ($dfmmem) {
				print "\nMember Type            : "
				  . $info->child_get_string("member-type") . "\n";
				print "Member Status          : "
				  . $info->child_get_string("member-status") . "\n";
				print "Member Perf Status     : "
				  . $info->child_get_string("member-perf-status") . "\n";
				print "Storageset Id          : "
				  . $info->child_get_string("storageset-id") . "\n";
				print "Storageset Name        : "
				  . $info->child_get_string("storageset-name") . "\n";
				print "Node Name              : "
				  . $info->child_get_string("dp-node-name") . "\n";
			}
		}
	}

	# invoking the iter-end zapi
	my $end =
	  $server->invoke( "dataset-member-list-info-iter-end", "tag", $tag );
	print( "Error : " . $end->results_reason() . "\n" ) and exit(-2)
	  if ( $end->results_status() eq "failed" );
}

sub member_rem {

	# Reading the server object
	my $server = $_[0];

	# beginning the edit session
	my $dataset =
	  $server->invoke( "dataset-edit-begin", "dataset-name-or-id", "$dfmval" );
	print( "Error : " . $dataset->results_reason() . "\n" ) and exit(-2)
	  if ( $dataset->results_status() eq "failed" );

	# extracting the edit lock
	my $lock_id = $dataset->child_get_int("edit-lock-id");

	# creating a remove dataset member element
	my $input = NaElement->new("dataset-remove-member");
	$input->child_add_string( "edit-lock-id", $lock_id );
	my $mem   = NaElement->new("dataset-member-parameters");
	my $param = NaElement->new("dataset-member-parameter");
	$param->child_add_string( "object-name-or-id", $dfmmem );
	$mem->child_add($param);
	$input->child_add($mem);

	# invoking the api and printing the xml ouput
	my $output = $server->invoke_elem($input);
	print( "Error : " . $output->results_reason() . "\n" )
	  and $server->invoke( "dataset-edit-rollback", "edit-lock-id", $lock_id )
	  and exit(-2)
	  if ( $output->results_status() eq "failed" );

	my $output3 =
	  $server->invoke( "dataset-edit-commit", "edit-lock-id", $lock_id );
	print( "Error : " . $output3->results_reason() . "\n" )
	  and $server->invoke( "dataset-edit-rollback", "edit-lock-id", $lock_id )
	  and exit(-2)
	  if ( $output3->results_status() eq "failed" );

	print "\nMember remove " . result( $output->results_status() ) . "\n";
}

sub member_prov {

	# Reading the server object
	my $server = $_[0];

	# beginning the edit session
	my $dataset =
	  $server->invoke( "dataset-edit-begin", "dataset-name-or-id", "$dfmval" );
	print( "Error : " . $dataset->results_reason() . "\n" ) and exit(-2)
	  if ( $dataset->results_status() eq "failed" );

	# extracting the edit lock
	my $lock_id = $dataset->child_get_int("edit-lock-id");

	# creating a provision member element
	my $input = NaElement->new("dataset-provision-member");
	$input->child_add_string( "edit-lock-id", $lock_id );
	my $prov_mem = NaElement->new("provision-member-request-info");
	$prov_mem->child_add_string( "name", $dfmmem );
	$prov_mem->child_add_string( "size", $size );

	# snapshot space is not needed for nas policies
	$prov_mem->child_add_string( "maximum-snapshot-space", $max_size );

	# snapshot space is not needed nas policies with nfs
	$prov_mem->child_add_string( "maximum-data-size", $max_size );
	$input->child_add($prov_mem);

	# invoking the api and printing the xml ouput
	my $output = $server->invoke_elem($input);
	print( "Error : " . $output->results_reason() . "\n" )
	  and $server->invoke( "dataset-edit-rollback", "edit-lock-id", $lock_id )
	  and exit(-2)
	  if ( $output->results_status() eq "failed" );

	my $output3 =
	  $server->invoke( "dataset-edit-commit", "edit-lock-id", $lock_id );
	print( "Error : " . $output3->results_reason() . "\n" )
	  and $server->invoke( "dataset-edit-rollback", "edit-lock-id", $lock_id )
	  and exit(-2)
	  if ( $output3->results_status() eq "failed" );

	# getting the job id for the commit
	my $job_id =
	  ( ( $output3->child_get("job-ids") )->child_get("job-info") )
	  ->child_get_string("job-id");

	# tracking the job
	track_job($server,$job_id);
}

sub track_job {
	my $server = shift;
	my $jobId = shift;

	print "Job ID\t\t: " . $jobId . " \n";
	my $jobStatus = "running";
	print "Job Status\t: " . $jobStatus;

	while ($jobStatus eq "queued"
		|| $jobStatus eq "running"
		|| $jobStatus eq "aborting" )
	{
		my $out = $server->invoke( "dp-job-list-iter-start", "job-id", $jobId );
		if ( $out->results_status() eq "failed" ) {
			print( "Error : " . $out->results_reason() . "\n" );
			exit(-2);
		}
		$out = $server->invoke(
			"dp-job-list-iter-next",           "maximum",
			$out->child_get_string("records"), "tag",
			$out->child_get_string("tag")
		);
		if ( $out->results_status() eq "failed" ) {
			print( "Error : " . $out->results_reason() . "\n" );
			exit(-2);
		}

		#print $out->sprintf();
		my $dpJobs = $out->child_get("jobs");
		our $dpJobInfo = $dpJobs->child_get("dp-job-info");
		$jobStatus = $dpJobInfo->child_get_string("job-state");
		sleep 5;
		print ".";
		if ( $jobStatus eq "completed" || $jobStatus eq "aborted" ) {
			print "\nOverall Status\t: "
			  . $dpJobInfo->child_get_string("job-overall-status") . "\n";
		}
	}

	my $out = $server->invoke( "dp-job-progress-event-list-iter-start",
		"job-id", $jobId );
	if ( $out->results_status() eq "failed" ) {
		print( "Error : " . $out->results_reason() . "\n" );
		exit(-2);
	}
	$out = $server->invoke(
		"dp-job-progress-event-list-iter-next", "tag",
		$out->child_get_string("tag"),          "maximum",
		$out->child_get_string("records")
	);
	if ( $out->results_status() eq "failed" ) {
		print( "Error : " . $out->results_reason() . "\n" );
		exit(-2);
	}
	my $progEvnts     = $out->child_get("progress-events");
	my @progEvntsInfo = $progEvnts->children_get();
	print "\nProvision Details:\n";
	print "=" x 19 . "\n";

	foreach my $evnt (@progEvntsInfo) {
		if ( $evnt->child_get_string("event-type") ne "" ) {
			print $evnt->child_get_string("event-type");
		}
		print "\t: " . $evnt->child_get_string("event-message") . "\n\n";
	}
}

sub usage {
	print <<MSG;

Usage:
dataset.pl <dfmserver> <user> <password> list [ <dataset name> ]

dataset.pl <dfmserver> <user> <password> delete <dataset name>

dataset.pl <dfmserver> <user> <password> create <dataset name>
[ -v <prov-pol> ] [ -t <prot-pol> ] [ -r <rpool>]

dataset.pl <dfmserver> <user> <password> member-add <a-mem-dset> <member>

dataset.pl <dfmserver> <user> <password> member-list <mem-dset> [ <member> ]

dataset.pl <dfmserver> <user> <password> member-remove <mem-dset> <member>

dataset.pl <dfmserver> <user> <password> member-provision <p-mem-dset> <member>
<size> [ <snap-size> | <data-size> ]

<operation>    -- create or delete or list

<dfmserver>    -- Name/IP Address of the DFM server
<user>         -- DFM server User name
<password>     -- DFM server User Password
<dataset name> -- dataset name
<prov-pol>     -- name or id of an exisitng nas provisioning policy
<prot-pol>     -- name or id of an exisitng protection policy
<rpool>        -- name or id of an exisitng resourcepool
<a-mem-dset>   -- dataset to which the member will be added
<mem-dset>     -- dataset containing the member
<p-mem-dset>   -- dataset with resourcepool and provisioning policy attached
<member>       -- name or Id of the member (volume/LUN or qtree)
<size>         -- size of the member to be provisioned
<snap-size>    -- maximum snapshot space required only for provisioning using
				  "san" provision policy
<data-size>    -- Maximum storage space space for the dataset member required
				  only for provisioning using "nas" provision policy with nfs

Note : All size in bytes
MSG
	exit 1;
}

#=========================== POD ============================#

=head1 NAME

  dataset.pl - Manages resource pool on a dfm server


=head1 SYNOPSIS

  dataset.pl <dfmserver> <user> <password> list [ <dataset name> ]

  dataset.pl <dfmserver> <user> <password> delete <dataset name>

  dataset.pl <dfmserver> <user> <password> create <dataset name>
  [ -v <prov-pol> ] [ -t <prot-pol> ] [ -r <rpool>]

  dataset.pl <dfmserver> <user> <password> member-add <mem-dset> <member>

  dataset.pl <dfmserver> <user> <password> member-list <mem-dset> [ <member> ]

  dataset.pl <dfmserver> <user> <password> member-remove <mem-dset> <member>

  dataset.pl <dfmserver> <user> <password> member-provision <p-mem-dset> <member>
  <size> [ <snap-size> | <data-size> ]

=head1 ARGUMENTS

  <dfmserver>
   DFM server name.

  <user>
  DFM server username.

  <password>
  DFM server user password.

  <dataset name>
  resource pool name

  <prov-pol>
  name or id of an exisitng provisioning policy

  <prot-pol>
  name or id of an exisitng protection policy

  <rpool>
  name or id of an exisitng resource pool

  <a-mem-dset>
  dataset to which the member will be added

  <mem-dset>
  dataset with respect to the member

  <p-mem-dset>
  dataset with resourcepool and provisioning policy attached

  <member>
  name or Id of the member

  <memb-rtag>
  resource tag to be attached to member

  <size>
  size of the member to be provisioned in bytes

  <snap-size>
  maximum snapshot space required only for provisioning using
  "san" provision policy

  <data-size>
  Maximum storage space space for the dataset member required
  only for provisioning using "nas" provision policy with nfs

=head1 SEE ALSO

  NaElement.pm, NaServer.pm

=head1 COPYRIGHT

 Copyright (c) 2009 NetApp, Inc. All rights reserved.
 Specifications subject to change without notice.

=cut

