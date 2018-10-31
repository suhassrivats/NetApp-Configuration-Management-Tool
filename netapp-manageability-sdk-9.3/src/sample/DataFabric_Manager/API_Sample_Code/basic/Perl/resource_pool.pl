#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# resource_pool.pl                                              #
#                                                               #
# Copyright (c) 2009 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to manage resource pool        #
# on a DFM server                                               #
# you can create,list and delete resource pools                 #
# add,list and remove members                                   #
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
my ( $dfmserver, $dfmuser, $dfmpw, $dfmop, $dfmval, @opt_param ) = @ARGV;

my $resource_tag = undef;
my $full_thresh = undef;
my $nearly_full = undef;
my $mem_rtag = undef;

# extracting the member if its a member operation
my $dfmmem = shift @opt_param if ( $dfmop =~ /member/ );

##### MAIN SECTION
# checking for valid number of parameters for the respective operations
usage()
  if ( ( $dfmop eq "list" and $args < 4 )
	or ( $dfmop eq "delete"        and $args != 5 )
	or ( $dfmop eq "create"        and $args < 5 )
	or ( $dfmop eq "member-list"   and $args < 5 )
	or ( $dfmop eq "member-remove" and $args != 6 )
	or ( $dfmop eq "member-add"    and $args < 6 ) );

# checking if the operation selected is valid
usage()
  if (  ( $dfmop ne "list" )
	and ( $dfmop ne "create" )
	and ( $dfmop ne "delete" )
	and ( $dfmop ne "member-add" )
	and ( $dfmop ne "member-list" )
	and ( $dfmop ne "member-remove" ) );

# parsing optional parameters
my $i = 0;
while ( $i < scalar(@opt_param) ) {
	if   ( $opt_param[$i] eq '-t' ) { $resource_tag = $opt_param[ ++$i ]; ++$i; }
	elsif( $opt_param[$i] eq '-f' ) { $full_thresh  = $opt_param[ ++$i ]; ++$i; }
	elsif( $opt_param[$i] eq '-n' ) { $nearly_full  = $opt_param[ ++$i ]; ++$i; }
	elsif( $opt_param[$i] eq '-m' ) { $mem_rtag     = $opt_param[ ++$i ]; ++$i; }
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
else                                  { usage(); };

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
	# creating a resourcepool-create element and adding child elements
	my $input            = NaElement->new("resourcepool-create");
	my $resourcepool     = NaElement->new("resourcepool");
	my $resourcepoolinfo = NaElement->new("resourcepool-info");
	$resourcepoolinfo->child_add_string( "resourcepool-name", $dfmval );
	$resourcepoolinfo->child_add_string( "resource-tag",      $resource_tag );
	$resourcepoolinfo->child_add_string( "resourcepool-full-threshold",
		$full_thresh );
	$resourcepoolinfo->child_add_string( "resourcepool-nearly-full-threshold",
		$nearly_full );
	$resourcepool->child_add($resourcepoolinfo);
	$input->child_add($resourcepool);

	# invoking the api and printing the xml ouput
	my $output = $server->invoke_elem($input);
	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	print "\nResource pool creation "
	  . result( $output->results_status() ) . "\n";
}

sub list {

	# Reading the server object
	my $server = $_[0];
	my $output;

	# invoking the api and capturing the ouput
	if ($dfmval) {
		$output = $server->invoke( "resourcepool-list-info-iter-start",
			"object-name-or-id", $dfmval, );
	} else {
		$output = $server->invoke("resourcepool-list-info-iter-start");
	}

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	# Extracting the record and tag values and printing them
	my $records = $output->child_get_string("records");

	print "\nNo resourcepools to display\n" if ( not $records );

	my $tag = $output->child_get_string("tag");

	# Iterating through each record

	# Extracting records one at a time
	my $record = $server->invoke( "resourcepool-list-info-iter-next",
		"maximum", $records, "tag", $tag );

	print( "Error : " . $record->results_reason() . "\n" ) and exit(-2)
	  if ( $record->results_status() eq "failed" );

	# Navigating to the resourcepools child element
	my $stat = $record->child_get("resourcepools") or exit 0 if ($record);

	# Navigating to the resourcepool-info child element
	my @info = $stat->children_get() or exit 0 if ($stat);

	# Iterating through each record
	foreach my $info (@info) {

		# extracting the resource-pool name and printing it
		print "-" x 80 . "\n";
		print "Resourcepool Name : "
		  . $info->child_get_string("resourcepool-name") . "\n";
		print "Resourcepool Id : "
		  . $info->child_get_string("resourcepool-id") . "\n";
		print "Resourcepool Description : "
		  . $info->child_get_string("resourcepool-description") . "\n";
		print "-" x 80 . "\n";

		# printing detials if only one resource-pool is selected for listing
		if ($dfmval) {
			print "\nResourcepool Status                      : "
			  . $info->child_get_string("resourcepool-status") . "\n";
			print "Resourcepool Perf Status                 : "
			  . $info->child_get_string("resourcepool-perf-status") . "\n";
			print "Resource Tag                             : "
			  . $info->child_get_string("resource-tag") . "\n";
			print "Resourcepool Member Count                : "
			  . $info->child_get_string("resourcepool-member-count") . "\n";
			print "Resourcepool Full Threshold              : "
			  . $info->child_get_string("resourcepool-full-threshold") . "%\n";
			print "Resourcepool Nearly Full Threshold       : "
			  . $info->child_get_string("resourcepool-nearly-full-threshold")
			  . "%\n";
			print "Aggregate Nearly Overcommitted Threshold : "
			  . $info->child_get_string(
				"aggregate-nearly-overcommitted-threshold")
			  . "%\n";
			print "Aggregate Overcommitted Threshold        : "
			  . $info->child_get_string("aggregate-overcommitted-threshold")
			  . "%\n";
		}
	}

	# invoking the iter-end zapi
	my $end =
	  $server->invoke( "resourcepool-list-info-iter-end", "tag", $tag );
	print( "Error : " . $end->results_reason() . "\n" ) and exit(-2)
	  if ( $end->results_status() eq "failed" );
}

sub del {

	# Reading the server object
	my $server = $_[0];

	# invoking the api and printing the xml ouput
	my $output =
	  $server->invoke( "resourcepool-destroy", "resourcepool-name-or-id",
		$dfmval );

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	print "\nResource pool deletion "
	  . result( $output->results_status() ) . "\n";
}

sub member_add {

	# Reading the server object
	my $server = $_[0];

	# creating the input for api execution
	# creating a resourcepool add member element and adding child elements
	my $input = NaElement->new("resourcepool-add-member");
	$input->child_add_string( "member-name-or-id",       $dfmmem );
	$input->child_add_string( "resourcepool-name-or-id", $dfmval );
	$input->child_add_string( "resource-tag", $mem_rtag ) if ($mem_rtag);
	
	# invoking the api and printing the xml ouput
	my $output = $server->invoke_elem($input);
	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	print "\nMember Add " . result( $output->results_status() ) . "\n";
}

sub member_list {

	# Reading the server object
	my $server = $_[0];
	my $output;

	# invoking the api and capturing the ouput
	if ($dfmmem) {
		$output = $server->invoke(
			"resourcepool-member-list-info-iter-start",
			"resourcepool-member-name-or-id",
			$dfmmem, "resourcepool-name-or-id", $dfmval
		);
	} else {
		$output = $server->invoke( "resourcepool-member-list-info-iter-start",
			"resourcepool-name-or-id", $dfmval );
	}

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	# Extracting the record and tag values and printing them
	my $records = $output->child_get_string("records");

	print "\nNo members to display\n" if ( not $records );

	my $tag = $output->child_get_string("tag");

	# Iterating through each record

	# Extracting records one at a time
	my $record = $server->invoke( "resourcepool-member-list-info-iter-next",
		"maximum", $records, "tag", $tag );
	print( "Error : " . $record->results_reason() . "\n" ) and exit(-2)
	  if ( $record->results_status() eq "failed" );

	# Navigating to the resourcepools member element
	my $stat = $record->child_get("resourcepool-members")
	  or exit 0
	  if ($record);

	# reading resource pool info children into array
	my @info = $stat->children_get() or exit 0 if ($stat);

	# Iterating through each record
	foreach my $info (@info) {

		# extracting the member name and printing it
		my $name = $info->child_get_string("member-name");
		my $id   = $info->child_get_string("member-id");
		if ( not $dfmmem
			or ( $dfmmem and ( $name eq $dfmmem or $id eq $dfmmem ) ) )
		{
			print "-" x 80 . "\n";
			print "Member Name : " . $name . "\n";
			print "Member Id : " . $id . "\n";
			print "-" x 80 . "\n";
		} else {
			die "Member $dfmmem not found";
		}

		# printing detials if only one member is selected for listing
		# This is a work around because list api wont return single child for
		# adding the member element
		if ( $dfmmem and ( $name eq $dfmmem or $id eq $dfmmem ) ) {
			print "\nMember Type            : "
			  . $info->child_get_string("member-type") . "\n";
			print "Member Status          : "
			  . $info->child_get_string("member-status") . "\n";
			print "Member Perf Status     : "
			  . $info->child_get_string("member-perf-status") . "\n";
			print "Resource Tag           : "
			  . $info->child_get_string("resource-tag") . "\n";
			print "Member Member Count    : "
			  . $info->child_get_string("member-member-count") . "\n";
			print "Member Used Space      : "
			  . $info->child_get_string("member-used-space")
			  . " bytes\n";
			print "Member Committed Space : "
			  . $info->child_get_string("member-committed-space")
			  . " bytes\n";
			print "Member Size            : "
			  . $info->child_get_string("member-size")
			  . " bytes\n";
		}
	}

	# invoking the iter-end zapi
	my $end =
	  $server->invoke( "resourcepool-member-list-info-iter-end", "tag", $tag );
	print( "Error : " . $end->results_reason() . "\n" ) and exit(-2)
	  if ( $end->results_status() eq "failed" );
}

sub member_rem {

	# Reading the server object
	my $server = $_[0];

	# invoking the api and printing the xml ouput
	my $output =
	  $server->invoke( "resourcepool-remove-member", "member-name-or-id",
		$dfmmem, "resourcepool-name-or-id", $dfmval );

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	print "\nMember remove " . result( $output->results_status() ) . "\n";
}

sub usage {
	print <<MSG;

Usage:
resource_pool.pl <dfmserver> <user> <password> list [ <rpool> ]

resource_pool.pl <dfmserver> <user> <password> delete <rpool>

resource_pool.pl <dfmserver> <user> <password> create <rpool>  [ -t <rtag> ]
[-f <rp-full-thresh>] [-n <rp-nearly-full-thresh>]

resource_pool.pl <dfmserver> <user> <password> member-add <a-mem-rpool>
<member> [ -m mem-rtag ]

resource_pool.pl <dfmserver> <user> <password> member-list <mem-rpool>
[ <member> ]

resource_pool.pl <dfmserver> <user> <password> member-remove <mem-rpool>
<member>


<operation>             -- create or delete or list or member-add or
						   member-list or member-remove

<dfmserver>             -- Name/IP Address of the DFM server
<user>                  -- DFM server User name
<password>              -- DFM server User Password
<rpool>                 -- Resource pool name
<rtag>                  -- resource tag to be attached to a resourcepool
<rp-full-thresh>        -- fullness threshold percentage to generate a
						   "resource pool full" event.Range: [0..1000]
<rp-nearly-full-thresh> -- fullness threshold percentage to generate a
						   "resource pool nearly full" event.Range: [0..1000]
<a-mem-rpool>           -- resourcepool to which the member will be added
<mem-rpool>             -- resourcepool containing the member
<member>                -- name or Id of the member (host or aggregate)
<mem-rtag>              -- resource tag to be attached to member

MSG
	exit 1;
}

#=========================== POD ============================#

=head1 NAME

  resource_pool.pl - Manages resource pool on a dfm server


=head1 SYNOPSIS

  resource_pool.pl <dfmserver> <user> <password> list [ <rpool> ]

  resource_pool.pl <dfmserver> <user> <password> delete <rpool>

  resource_pool.pl <dfmserver> <user> <password> create <rpool>  [ -t <rtag> ]
  [-f <rp-full-thresh>] [-n <rp-nearly-full-thresh>]

  resource_pool.pl <dfmserver> <user> <password> member-add <mem-rpool>
  <member> [ -m mem-rtag ]

  resource_pool.pl <dfmserver> <user> <password> member-list <mem-rpool>
  [ <member> ]

  resource_pool.pl <dfmserver> <user> <password> member-remove <mem-rpool>
  <member>

=head1 ARGUMENTS

  <dfmserver>
   DFM server name.

  <user>
  DFM server username.

  <password>
  DFM server user password.

  [ <rpool> ]
  resource pool name

  [ <rtag> ]
  resource tag to be attached to a resourcepool

  [ <rp-full-thresh> ]
  fullness threshold percentage to generate a "resource pool full" event.Range: [0..1000]

  [ <rp-nearly-full-thresh> ]
  fullness threshold percentage to generate a "resource pool nearly full" event.Range: [0..1000]

  <mem-rpool>
  resourcepool with respect to the member

  <a-mem-rpool>
  resourcepool to which the member will be added

  [ <member> ]
  name or Id of the member

  [ <mem-rtag> ]
  resource tag to be attached to member

=head1 SEE ALSO

  NaElement.pm, NaServer.pm

=head1 COPYRIGHT

 Copyright (c) 2009 NetApp, Inc. All rights reserved.
 Specifications subject to change without notice.

=cut

