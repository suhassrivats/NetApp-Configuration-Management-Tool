#========================================================================#
#                                                                        #
# $Id: //depot/prod/zephyr/Rlufthansaair/src/perl/bin/perl_bindings/sample/DataFabric_Manager/API_Sample_Code/basic/resource_pool.pl#1 $                                                                   #
#                                                                        #
# resource_pool.pl                                                       #
#                                                                        #
# Copyright (c) 2013 NetApp, Inc. All rights reserved.                   #
# Specifications subject to change without notice.                       #
#                                                                        #
# Sample code to demonstrate how to manage resource pool                 #
# on a OnCommand Unified Manager Core Package (5.2 or earlier)           #
# server. You can create,list and delete resource pools                  #
# add,list and remove members                                            #
#                                                                        #
# This Sample code is supported on OnCommand Unified Manager 5.2         #
# or earlier (till DataFabric Manager 3.6R2). However, a few of          #
# the functionalities of the sample code may work on older versions of   #
# OnCommand Unified Manager Core package(previouly DataFabric Manager).  #
#========================================================================#

use lib '../../../../../../lib/perl/NetApp';
use NaServer;
use strict;

##### VARIABLES SECTION
my $args = $#ARGV + 1;
my ( $ocumserver, $ocumuser, $ocumpw, $ocumop, $ocumval, @opt_param ) = @ARGV;

my $resource_tag = undef;
my $full_thresh = undef;
my $nearly_full = undef;
my $mem_rtag = undef;

# extracting the member if its a member operation
my $ocummem = shift @opt_param if ( $ocumop =~ /member/ );

##### MAIN SECTION
# checking for valid number of parameters for the respective operations
usage()
  if ( ( $ocumop eq "list" and $args < 4 )
	or ( $ocumop eq "delete"        and $args != 5 )
	or ( $ocumop eq "create"        and $args < 5 )
	or ( $ocumop eq "member-list"   and $args < 5 )
	or ( $ocumop eq "member-remove" and $args != 6 )
	or ( $ocumop eq "member-add"    and $args < 6 ) );

# checking if the operation selected is valid
usage()
  if (  ( $ocumop ne "list" )
	and ( $ocumop ne "create" )
	and ( $ocumop ne "delete" )
	and ( $ocumop ne "member-add" )
	and ( $ocumop ne "member-list" )
	and ( $ocumop ne "member-remove" ) );

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
my $serv = NaServer->new( $ocumserver, 1, 0 );
$serv->set_style("LOGIN");
$serv->set_transport_type("HTTP");
$serv->set_server_type("DFM");
$serv->set_port(8088);
$serv->set_admin_user( $ocumuser, $ocumpw );
$serv->set_bindings_family( "OCUM-Classic" );

# Calling the subroutines based on the operation selected
if   ( $ocumop eq 'create' )           { create($serv);      }
elsif( $ocumop eq 'list' )             { list($serv);        }
elsif( $ocumop eq 'delete' )           { del($serv);         }
elsif( $ocumop eq 'member-add' )       { member_add($serv);  }
elsif( $ocumop eq 'member-list' )      { member_list($serv); }
elsif( $ocumop eq 'member-remove' )    { member_rem($serv);  }
else                                  { usage(); };

##### SUBROUTINE SECTION

sub create {

	# Reading the server object
	my $server = $_[0];
	my $output;

	# creating the input for api execution
	# creating a resourcepool-create element and adding child elements
	my $input            = {};
	my $resourcepool     = {};
	my $resourcepoolinfo = {};
	$resourcepoolinfo->{'resourcepool-name'} = $ocumval;
	$resourcepoolinfo->{'resource-tag'} = $resource_tag;
	$resourcepoolinfo->{'resourcepool-full-threshold'} = $full_thresh;
	$resourcepoolinfo->{'resourcepool-nearly-full-threshold'} = $nearly_full;
	$resourcepool->{'resourcepool-info'} = $resourcepoolinfo;
	$input->{'resourcepool'} = $resourcepool;

	# invoking the api binding for creating the resoucepool.
	eval {
		$output = $server->resourcepool_create(%{$input});
	};
	if($@) {
		print ("Error : " . $@ . "\n");
		exit(-2);
	}

	print "\nResource pool creation Successful.\n"
}

sub list {

	# Reading the server object
	my $server = $_[0];
	my ($output, $record);

	# invoking the api and capturing the ouput
	eval {
		if ($ocumval) {
			$output = $server->resourcepool_list_info_iter_start(
				'object-name-or-id' => $ocumval);
		} else {
			$output = $server->resourcepool_list_info_iter_start();
		}
	};
	if($@) {
		print ("Error : " . $@ . "\n");
		exit(-2);
	}

	# Extracting the record and tag values and printing them
	my $records = $output->{'records'};

	print "\nNo resourcepools to display\n" if ( not $records );

	my $tag = $output->{'tag'};

	# Iterating through each record

	# Extracting records one at a time
	eval {
		$record = $server->resourcepool_list_info_iter_next(
			'maximum' => $records, 'tag' => $tag );
	};
	if($@) {
		print ("Error : " . $@ . "\n");
		exit(-2);
	}

	# Navigating to the resourcepools child element
	my $stat = $record->{'resourcepools'} or exit 0 if ($record);

	# Navigating to the resourcepool-info child element
	my $info = $stat->{'resourcepool-info'} or exit 0 if ($stat);

	# Iterating through each record
	foreach my $info (@{$info}) {

		# extracting the resource-pool name and printing it
		print "-" x 80 . "\n";
		print "Resourcepool Name : "
		  . $info->{'resourcepool-name'} . "\n";
		print "Resourcepool Id : "
		  . $info->{'resourcepool-id'} . "\n";
		print "Resourcepool Description : "
		  . $info->{'resourcepool-description'} . "\n";
		print "-" x 80 . "\n";

		# printing detials if only one resource-pool is selected for listing
		if ($ocumval) {
			print "\nResourcepool Status                      : "
			  . $info->{'resourcepool-status'} . "\n";
			print "Resourcepool Perf Status                 : "
			  . $info->{'resourcepool-perf-status'} . "\n";
			print "Resource Tag                             : "
			  . $info->{'resource-tag'} . "\n";
			print "Resourcepool Member Count                : "
			  . $info->{'resourcepool-member-count'} . "\n";
			print "Resourcepool Full Threshold              : "
			  . $info->{'resourcepool-full-threshold'} . "%\n";
			print "Resourcepool Nearly Full Threshold       : "
			  . $info->{'resourcepool-nearly-full-threshold'}
			  . "%\n";
			print "Aggregate Nearly Overcommitted Threshold : "
			  . $info->{'aggregate-nearly-overcommitted-threshold'}
			  . "%\n";
			print "Aggregate Overcommitted Threshold        : "
			  . $info->{'aggregate-overcommitted-threshold'}
			  . "%\n";
		}
	}

	# invoking the iter-end zapi
	eval {
	my $end =
		$server->resourcepool_list_info_iter_end('tag' => $tag);
	};
	if($@) {
		print ("Error : " . $@ . "\n");
		exit(-2);
	}
}

sub del {

	# Reading the server object
	my $server = $_[0];

	# invoking the api binding for deleting the resourcepool.
	eval {
		my $output = $server->resourcepool_destroy(
	 		'resourcepool-name-or-id' => $ocumval );
	};
	if($@) {
		print ("Error : " . $@ . "\n");
		exit(-2);
	}

	print "\nResource pool deletion Successful.\n";
}

sub member_add {

	# Reading the server object
	my $server = $_[0];

	# creating the input for api execution
	# creating a resourcepool add member element and adding child elements
	my %input = ();
	$input{'member-name-or-id'} = $ocummem;
	$input{'resourcepool-name-or-id'} = $ocumval;
	if($mem_rtag) {
		$input{'resource-tag'} = $mem_rtag;
	}
	
	# invoking the api binding for adding a member to resourcepool.
	eval {
		my $output = $server->resourcepool_add_member(%input);
	};
	if($@) {
		print ("Error : " . $@ . "\n");
		exit(-2);
	}

	print "\nMember Add Successful.\n";
}

sub member_list {

	# Reading the server object
	my $server = $_[0];
	my $output;

	# invoking the api binding and capturing the ouput
	eval {
		if ($ocummem) {
			$output = $server->resourcepool_member_list_info_iter_start(
				'resourcepool-member-name-or-id' => $ocummem,
				'resourcepool-name-or-id' => $ocumval
			);
		} else {
			$output = $server->resourcepool_member_list_info_iter_start(
				'resourcepool-name-or-id' => $ocumval );
		}
	};
	if($@) {
		print ("Error : " . $@ . "\n");
		exit(-2);
	}

	# Extracting the record and tag values and printing them
	my $records = $output->{'records'};

	print "\nNo members to display\n" if ( not $records );

	my $tag = $output->{'tag'};

	# Iterating through each record

	# Extracting records one at a time
	my $record;
	
	# Disabling bindings validation before executing this API.
	$server->set_bindings_validation(0);

	eval {
		$record = $server->resourcepool_member_list_info_iter_next(
		'maximum' => $records, 'tag' => $tag );
	};
	if($@) {
		print ("Error : " . $@ . "\n");
		exit(-2);
	}

	# Enabling bindings validation again after executing the API.
	$server->set_bindings_validation(1);

	# Navigating to the resourcepools member element
	my $stat = $record->{'resourcepool-members'}
	  or exit 0
	  if ($record);

	# reading resource pool info children into array
	my $info = $stat->{'resourcepool-member-info'} or exit 0 if ($stat);

	if(ref($info) eq "HASH") {
		my @temp_array = $stat->{'resourcepool-member-info'};
		$info = \@temp_array;
	}

	# Iterating through each record
	foreach my $info (@{$info}) {

		# extracting the member name and printing it
		my $name = $info->{'member-name'};
		my $id   = $info->{'member-id'};
		if ( not $ocummem
			or ( $ocummem and ( $name eq $ocummem or $id eq $ocummem ) ) )
		{
			print "-" x 80 . "\n";
			print "Member Name : " . $name . "\n";
			print "Member Id : " . $id . "\n";
			print "-" x 80 . "\n";
		} else {
			die "Member $ocummem not found";
		}

		# printing detials if only one member is selected for listing
		# This is a work around because list api wont return single child for
		# adding the member element
		if ( $ocummem and ( $name eq $ocummem or $id eq $ocummem ) ) {
			print "\nMember Type            : "
			  . $info->{'member-type'} . "\n";
			print "Member Status          : "
			  . $info->{'member-status'}. "\n";
			print "Member Perf Status     : "
			  . $info->{'member-perf-status'}. "\n";
			print "Resource Tag           : "
			  . $info->{'resource-tag'}. "\n";
			print "Member Member Count    : "
			  . $info->{'member-member-count'}. "\n";
			print "Member Used Space      : "
			  . $info->{'member-used-space'}
			  . " bytes\n";
			print "Member Committed Space : "
			  . $info->{'member-committed-space'}
			  . " bytes\n";
			print "Member Size            : "
			  . $info->{'member-size'}
			  . " bytes\n";
		}
	}

	# invoking the iter-end api binding
	eval {
		my $end = $server->resourcepool_member_list_info_iter_end('tag' => $tag);
	};
	if($@) {
		print ("Error : " . $@ . "\n");
		exit(-2);
	}
}

sub member_rem {

	# Reading the server object
	my $server = $_[0];

	# invoking the api binding for removing a member from resourcepool.
	eval {
	my $output =
		$server->resourcepool_remove_member('member-name-or-id' => $ocummem,
			'resourcepool-name-or-id' => $ocumval);
	};
	if($@) {
		print ("Error : " . $@ . "\n");
		exit(-2);
	}

	print "\nMember remove Successful.\n";
}

sub usage {
	print <<MSG;

Usage:
resource_pool.pl <ocumserver> <user> <password> list [ <rpool> ]

resource_pool.pl <ocumserver> <user> <password> delete <rpool>

resource_pool.pl <ocumserver> <user> <password> create <rpool>  [ -t <rtag> ] [-f <rp-full-thresh>] [-n <rp-nearly-full-thresh>]

resource_pool.pl <ocumserver> <user> <password> member-add <a-mem-rpool> <member> [ -m mem-rtag ]

resource_pool.pl <ocumserver> <user> <password> member-list <mem-rpool> [ <member> ]

resource_pool.pl <ocumserver> <user> <password> member-remove <mem-rpool> <member>


<operation>             -- create or delete or list or member-add or member-list or member-remove
<ocumserver>            -- Name/IP Address of the OCUM server
<user>                  -- OCUM server User name
<password>              -- OCUM server User Password
<rpool>                 -- Resource pool name
<rtag>                  -- resource tag to be attached to a resourcepool
<rp-full-thresh>        -- fullness threshold percentage to generate a "resource pool full" event.Range: [0..100]
<rp-nearly-full-thresh> -- fullness threshold percentage to generate a "resource pool nearly full" event.Range: [0..100]
<a-mem-rpool>           -- resourcepool to which the member will be added
<mem-rpool>             -- resourcepool containing the member
<member>                -- name or Id of the member (host or aggregate)
<mem-rtag>              -- resource tag to be attached to member

MSG
	exit 1;
}

#=========================== POD ============================#

=head1 NAME

  resource_pool.pl - Manages resource pool on a ocum server


=head1 SYNOPSIS

  resource_pool.pl <ocumserver> <user> <password> list [ <rpool> ]

  resource_pool.pl <ocumserver> <user> <password> delete <rpool>

  resource_pool.pl <ocumserver> <user> <password> create <rpool>  [ -t <rtag> ] [-f <rp-full-thresh>] [-n <rp-nearly-full-thresh>]

  resource_pool.pl <ocumserver> <user> <password> member-add <mem-rpool> <member> [ -m mem-rtag ]

  resource_pool.pl <ocumserver> <user> <password> member-list <mem-rpool> [ <member> ]

  resource_pool.pl <ocumserver> <user> <password> member-remove <mem-rpool> <member>

=head1 ARGUMENTS

  <ocumserver>
   OCUM server name.

  <user>
  OCUM server username.

  <password>
  OCUM server user password.

  [ <rpool> ]
  resource pool name

  [ <rtag> ]
  resource tag to be attached to a resourcepool

  [ <rp-full-thresh> ]
  fullness threshold percentage to generate a "resource pool full" event.Range: [0..100]

  [ <rp-nearly-full-thresh> ]
  fullness threshold percentage to generate a "resource pool nearly full" event.Range: [0..100]

  <mem-rpool>
  resourcepool with respect to the member

  <a-mem-rpool>
  resourcepool to which the member will be added

  [ <member> ]
  name or Id of the member

  [ <mem-rtag> ]
  resource tag to be attached to member

=head1 SEE ALSO

  NaServer.pm, OCUMClassicAPI.pm

=head1 COPYRIGHT

 Copyright (c) 2013 NetApp, Inc. All rights reserved.
 Specifications subject to change without notice.

=cut

