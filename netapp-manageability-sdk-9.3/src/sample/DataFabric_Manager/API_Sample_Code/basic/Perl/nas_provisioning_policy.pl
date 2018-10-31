#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# nas_provisioning_policy.pl                                    #
#                                                               #
# Copyright (c) 2009 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to manage provisioning policy  #
# on a DFM server                                               #
# you can create, delete and list nas provisioning policies     #
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

my $group_quota = undef;
my $user_quota = undef;
my $dedupe_enable = undef;
my $controller_failure = undef;
my $subsystem_failure = undef;
my $snapshot_reserve = undef;
my $space_on_demand = undef;
my $thin_provision = undef;

##### MAIN SECTION
# checking for valid number of parameters for the respective operations
usage()
  if ( ( $dfmop eq "list" and $args < 4 )
	or ( $dfmop eq "delete" and $args != 5 )
	or ( $dfmop eq "create" and $args < 5 ) );

# checking if the operation selected is valid
usage()
  if (  ( $dfmop ne "list" )
	and ( $dfmop ne "create" )
	and ( $dfmop ne "delete" ) );

# parsing optional parameters
my $i = 0;
while ( $i < scalar(@opt_param) ) {
	if   ( $opt_param[$i] eq '-g' ) { $group_quota        = $opt_param[++$i]; ++$i; }
	elsif( $opt_param[$i] eq '-u' ) { $user_quota         = $opt_param[++$i]; ++$i; }
	elsif( $opt_param[$i] eq '-d' ) { $dedupe_enable      = "true";           ++$i; }
	elsif( $opt_param[$i] eq '-c' ) { $controller_failure = "true";           ++$i; }
	elsif( $opt_param[$i] eq '-s' ) { $subsystem_failure  = "true";           ++$i; }
	elsif( $opt_param[$i] eq '-r' ) { $snapshot_reserve   = "false";          ++$i; }
	elsif( $opt_param[$i] eq '-S' ) { $space_on_demand    = "true";           ++$i; }
	elsif( $opt_param[$i] eq '-t' ) { $thin_provision     = "true";           ++$i; }
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

sub create {

	# Reading the server object
	my $server = $_[0];

	# creating the input for api execution
	# creating a provisioning-policy-create element and adding child elements
	my $input  = NaElement->new("provisioning-policy-create");
	my $policy = NaElement->new("provisioning-policy-info");
	$policy->child_add_string( "provisioning-policy-name", $dfmval );
	$policy->child_add_string( "provisioning-policy-type", "nas" );

	# adding dedupe enable is its input
	$policy->child_add_string( "dedupe-enabled", "$dedupe_enable" )
	  if ($dedupe_enable);

	# creating the storage reliability child and adding parameters if input
	if ( $controller_failure or $subsystem_failure ) {
		my $storage_reliability = NaElement->new("storage-reliability");
		$storage_reliability->child_add_string( "controller-failure",
			"$controller_failure" )
		  if ($controller_failure);
		$storage_reliability->child_add_string( "sub-system-failure",
			"$subsystem_failure" )
		  if ($subsystem_failure);

		# appending storage-reliability child to parent and then to policy info
		$policy->child_add($storage_reliability);
	}

	# creating the nas container settings child and adding parameters if input
	if (   $group_quota
		or $user_quota
		or $snapshot_reserve
		or $space_on_demand
		or $thin_provision )
	{
		my $nas_container_settings =
		  NaElement->new("nas-container-settings");
		$nas_container_settings->child_add_string( "default-group-quota",
			$group_quota )
		  if ($group_quota);
		$nas_container_settings->child_add_string( "default-user-quota",
			$user_quota )
		  if ($user_quota);
		$nas_container_settings->child_add_string( "snapshot-reserve",
			$snapshot_reserve )
		  if ($snapshot_reserve);
		$nas_container_settings->child_add_string( "space-on-demand",
			$space_on_demand )
		  if ($space_on_demand);
		$nas_container_settings->child_add_string( "thin-provision",
			$thin_provision )
		  if ($thin_provision);

		# appending nas-containter-settings child to policy info
		$policy->child_add($nas_container_settings);
	}

	$input->child_add($policy);

	# invoking the api and printing the xml ouput
	my $output = $server->invoke_elem($input);

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	print "\nNAS Provisioning Policy creation "
	  . result( $output->results_status() ) . "\n";
}

sub list {

	# Reading the server object
	my $server = $_[0];
	my $output;

	# invoking the api and capturing the ouput
	if ($dfmval) {
		$output = $server->invoke(
			"provisioning-policy-list-iter-start",
			"provisioning-policy-name-or-id",
			$dfmval, "provisioning-policy-type", "nas"
		);
	} else {
		$output = $server->invoke( "provisioning-policy-list-iter-start",
			"provisioning-policy-type", "nas" );
	}

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	# Extracting the record and tag values and printing them
	my $records = $output->child_get_string("records");

	print "\nNo policies to display\n" if ( not $records );

	my $tag = $output->child_get_string("tag");

	# Extracting records one at a time
	my $record = $server->invoke( "provisioning-policy-list-iter-next",
		"maximum", $records, "tag", $tag );

	print( "Error : " . $record->results_reason() . "\n" ) and exit(-2)
	  if ( $record->results_status() eq "failed" );

	# Navigating to the provisioning-policys child element
	my $stat = $record->child_get("provisioning-policies")
	  or exit 0
	  if ($record);

	# Navigating to the provisioning-policy-info child element
	my @info = $stat->children_get() or exit 0 if ($stat);

	# Iterating through each record
	foreach my $info (@info) {

		my $nas_container_settings =
		  $info->child_get("nas-container-settings");
		if ($nas_container_settings) {
			print "-" x 80 . "\n";

			# extracting the provisioning policy name and printing it
			print "Policy Name : "
			  . $info->child_get_string("provisioning-policy-name") . "\n";
			print "Policy Id : "
			  . $info->child_get_string("provisioning-policy-id") . "\n";
			print "Policy Description : "
			  . $info->child_get_string("provisioning-policy-description")
			  . "\n";
			print "-" x 80 . "\n";

			# printing detials if only one policy is selected for listing
			if ($dfmval) {
				print "Policy Type        : "
				  . $info->child_get_string("provisioning-policy-type") . "\n";
				print "Dedupe Enabled     : "
				  . $info->child_get_string("dedupe-enabled") . "\n";

				my $storage_reliability =
				  $info->child_get("storage-reliability");
				print "Disk Failure       : "
				  . $storage_reliability->child_get_string("disk-failure")
				  . "\n";
				print "Subsystem Failure  : "
				  . $storage_reliability->child_get_string("sub-system-failure")
				  . "\n";
				print "Controller Failure : "
				  . $storage_reliability->child_get_string("controller-failure")
				  . "\n";

				# Checking if the container is nas before printing the details

				print "Default User Quota : "
				  . $nas_container_settings->child_get_string(
					"default-user-quota")
				  . " kb\n";
				print "Default Group Quota: "
				  . $nas_container_settings->child_get_string(
					"default-group-quota")
				  . " kb\n";
				print "Snapshot Reserve   : "
				  . $nas_container_settings->child_get_string(
					"snapshot-reserve")
				  . "\n";
				print "Space On Demand    : "
				  . $nas_container_settings->child_get_string("space-on-demand")
				  . "\n";
				print "Thin Provision     : "
				  . $nas_container_settings->child_get_string("thin-provision")
				  . "\n";
			}
		}
		if ( $dfmval and not $nas_container_settings ) {
			print
"\nsan type of provisioning policy is not supported for listing\n";
		}
	}

	# invoking the iter-end zapi
	my $end =
	  $server->invoke( "provisioning-policy-list-iter-end", "tag", $tag );
	print( "Error : " . $end->results_reason() . "\n" ) and exit(-2)
	  if ( $end->results_status() eq "failed" );
}

sub del {

	# Reading the server object
	my $server = $_[0];

	# invoking the api and printing the xml ouput
	my $output = $server->invoke( "provisioning-policy-destroy",
		"provisioning-policy-name-or-id", $dfmval );

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	print "\nNAS Provisioning Policy deletion "
	  . result( $output->results_status() ) . "\n";
}

sub usage {
	print <<MSG;

Usage:
nas_provisioning_policy.pl <dfmserver> <user> <password> list [ <pol-name> ]

nas_provisioning_policy.pl <dfmserver> <user> <password> delete <pol-name>

nas_provisioning_policy.pl <dfmserver> <user> <password> create <pol-name>
[ -d ] [ -c ] [ -s ] [ -r ] [ -S | -t ] [ -g <gquota> ] [ -u <uquota> ]

<operation>     -- create or delete or list

<dfmserver> -- Name/IP Address of the DFM server
<user>      -- DFM server User name
<password>  -- DFM server UserPassword
<pol-name>  -- provisioning policy name
[ -d ]      -- To enable dedupe
[ -c ]      -- To enable resiliency against controller failure
[ -s ]      -- To enable resiliency against sub-system failure
[ -r ]      -- To disable snapshot reserve
[ -S ]      -- To enable space on demand
[ -t ]      -- To enable thin provisioning
<gquota>    -- Default group quota setting in kb.  Range: [1..2^44-1]
<uquota>    -- Default user quota setting in kb. Range: [1..2^44-1]

Note : All options except provisioning policy name are optional and are
required only by create operation

MSG
	exit 1;
}

#=========================== POD ============================#

=head1 NAME

  nas_provisioning_policy.pl - Manages nas provisioning policy on a dfm server


=head1 SYNOPSIS

nas_provisioning_policy.pl <dfmserver> <user> <password> list [ <pol-name> ]

nas_provisioning_policy.pl <dfmserver> <user> <password> delete <pol-name>

nas_provisioning_policy.pl <dfmserver> <user> <password> create <pol-name> [ -d ]
[ -c ] [ -s ] [ -r ] [ -S | -t ] [ -g <gquota> ] [ -u <uquota> ]

=head1 ARGUMENTS

  <dfmserver>
   DFM server name.

  <user>
  DFM server username.

  <password>
  DFM server user password.

  <prov-pol>
  provisioning policy name

  -d
  To enable dedupe

  -c
  To enable resiliency against controller failure

  -s
  To enable resiliency against sub-system failure

  -r
  To disable snapshot reserve

  -o
  To enable space on demand

  -t
  To enable thin provisioning

  <gquota>
  Default group quota setting on the dataset members.
  The value is expressed in kb. Range: [1..2^44-1]

  <uquota>
  Default user quota setting on the dataset members.
  The value is expressed in kb. Range: [1..2^44-1]

=head1 SEE ALSO

  NaElement.pm, NaServer.pm

=head1 COPYRIGHT

 Copyright (c) 2009 NetApp, Inc. All rights reserved.
 Specifications subject to change without notice.

=cut

