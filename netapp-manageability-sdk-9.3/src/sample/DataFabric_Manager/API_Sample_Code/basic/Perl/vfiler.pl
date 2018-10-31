#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# vfiler.pl                                                     #
#                                                               #
# Copyright (c) 2009 NetApp, Inc. All rights reserved.          #
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

use lib '../../../../../../lib/perl/NetApp';
use NaServer;
use NaElement;
use Switch;
use strict;

##### VARIABLES SECTION
my $args = $#ARGV + 1;
my ( $dfmserver, $dfmuser, $dfmpw, $dfmop, $dfmval, @opt_param ) = @ARGV;
my $rpool = shift @opt_param
  and my $ip    = shift @opt_param
  and my $tname = shift @opt_param
  if ( $dfmop eq "create" );
  
my $cifs_dom = undef;
my $cifs_auth = undef;
my $cifs_sec = undef;

##### MAIN SECTION
# checking for valid number of parameters for the respective operations
usage()
  if ( ( $dfmop eq "delete" and $args != 5 )
	or ( $dfmop eq "create"          and $args < 7 )
	or ( $dfmop eq "template-list"   and $args < 4 )
	or ( $dfmop eq "template-delete" and $args != 5 )
	or ( $dfmop eq "template-create" and $args < 5 ) );

# checking if the operation selected is valid
usage()
  if (  ( $dfmop ne "create" )
	and ( $dfmop ne "delete" )
	and ( $dfmop ne "template-create" )
	and ( $dfmop ne "template-list" )
	and ( $dfmop ne "template-delete" ) );

# parsing optional parameters
my $i = 0;
while ( $i < scalar(@opt_param) ) {
	switch ( $opt_param[$i] ) {
		if   ( $opt_param[$i] eq '-d' ) { $cifs_dom  = $opt_param[ ++$i ]; ++$i; }
		elsif( $opt_param[$i] eq '-a' ) { $cifs_auth = $opt_param[ ++$i ]; ++$i; }
		elsif( $opt_param[$i] eq '-s' ) { $cifs_sec  = $opt_param[ ++$i ]; ++$i; }
		else                            { usage(); };
	}
}

# Creating a server object and setting appropriate attributes
my $serv = NaServer->new( $dfmserver, 1, 0 );
$serv->set_style("LOGIN");
$serv->set_transport_type("HTTP");
$serv->set_server_type("DFM");
$serv->set_port(8088);
$serv->set_admin_user( $dfmuser, $dfmpw );

# Calling the subroutines based on the operation selected
switch ($dfmop) {
	if   ( $dfmop eq 'create' )          { create($serv);      }
	elsif( $dfmop eq 'delete' )          { del($serv);         }
	elsif( $dfmop eq 'template-create' ) { temp_create($serv); }
	elsif( $dfmop eq 'template-list' )   { temp_list($serv);   }
	elsif( $dfmop eq 'template-delete' ) { temp_del($serv);    }
	else                                 { usage(); };
}

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

	# invoking the create api
	my $output =
	  $server->invoke( "vfiler-create", "ip-address", $ip, "name", $dfmval,
		"resource-name-or-id", $rpool );

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	print "\nvFiler unit creation "
	  . result( $output->results_status() ) . "\n";
	print "vFiler unit created on Storage System : "
	  . $output->child_get_string("filer-name")
	  . "\nRoot Volume : "
	  . $output->child_get_string("root-volume-name");
	setup($server) if ($tname);
}

sub setup {

	# Reading the server object
	my $server = $_[0];

	# invoking the setup api with vfiler template
	my $output =
	  $server->invoke( "vfiler-setup", "vfiler-name-or-id", $dfmval,
		"vfiler-template-name-or-id", $tname );

	print(
		"Error : " . $output->results_reason() . "\n template not attached\n" )
	  and exit(-2)
	  if ( $output->results_status() eq "failed" );

	print "\nvFiler unit setup with template $tname "
	  . result( $output->results_status() ) . "\n";
}

sub del {

	# Reading the server object
	my $server = $_[0];

	# invoking the api
	my $output =
	  $server->invoke( "vfiler-destroy", "vfiler-name-or-id", $dfmval );

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	print "\nvFiler unit deletion "
	  . result( $output->results_status() ) . "\n";
}

sub temp_create {

	# Reading the server object
	my $server = $_[0];
	my $output;

	# creating the input for api execution
	# creating a vfiler-template-create element and adding child elements
	my $input      = NaElement->new("vfiler-template-create");
	my $vtemp      = NaElement->new("vfiler-template");
	my $vtemp_info = NaElement->new("vfiler-template-info");
	$vtemp_info->child_add_string( "vfiler-template-name", $dfmval );
	$vtemp_info->child_add_string( "cifs-auth-type",       $cifs_auth )
	  if ($cifs_auth);
	$vtemp_info->child_add_string( "cifs-domain", $cifs_dom ) if ($cifs_dom);
	$vtemp_info->child_add_string( "cifs-security-style", $cifs_sec )
	  if ($cifs_sec);
	$vtemp->child_add($vtemp_info);
	$input->child_add($vtemp);

	$output = $server->invoke_elem($input);
	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	print "\nvFiler template creation "
	  . result( $output->results_status() ) . "\n";
}

sub temp_list {

	# Reading the server object
	my $server = $_[0];

	# creating a input element
	my $input = NaElement->new("vfiler-template-list-info-iter-start");
	$input->child_add_string( "vfiler-template-name-or-id", $dfmval )
	  if ($dfmval);

	# invoking the api and capturing the ouput
	my $output = $server->invoke_elem($input);

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	# Extracting the record and tag values and printing them
	my $records = $output->child_get_string("records");

	print "\nNo templates to display\n" if ( not $records );

	my $tag = $output->child_get_string("tag");

	# Iterating through each record
	# Extracting all records
	my $record = $server->invoke( "vfiler-template-list-info-iter-next",
		"maximum", $records, "tag", $tag );

	print( "Error : " . $record->results_reason() . "\n" ) and exit(-2)
	  if ( $record->results_status() eq "failed" );

	# Navigating to the vfiler-templates child element
	my $stat = $record->child_get("vfiler-templates") or exit 0 if ($record);

	# Navigating to the vfiler-template-info child element
	my @info = $stat->children_get() or exit 0 if ($stat);

	for my $info (@info) {
		print "-" x 80 . "\n";

		# extracting the resource-pool name and printing it
		print "vFiler Template Name : "
		  . $info->child_get_string("vfiler-template-name") . "\n";
		print "Template Id : "
		  . $info->child_get_string("vfiler-template-id") . "\n";
		print "Template Description : "
		  . $info->child_get_string("vfiler-template-description") . "\n";
		print "-" x 80 . "\n";

		# printing detials if only one vfiler-template is selected for listing
		if ($dfmval) {
			print "CIFS Authhentication     : "
			  . $info->child_get_string("cifs-auth-type") . "\n";
			print "CIFS Domain              : "
			  . $info->child_get_string("cifs-domain") . "\n";
			print "CIFS Security Style      : "
			  . $info->child_get_string("cifs-security-style") . "\n";
			print "DNS Domain               : "
			  . $info->child_get_string("dns-domain") . "\n";
			print "NIS Domain               : "
			  . $info->child_get_string("nis-domain") . "\n";
		}
	}

	# invoking the iter-end zapi
	my $end =
	  $server->invoke( "vfiler-template-list-info-iter-end", "tag", $tag );
	print( "Error : " . $end->results_reason() . "\n" ) and exit(-2)
	  if ( $end->results_status() eq "failed" );
}

sub temp_del {

	# Reading the server object
	my $server = $_[0];

	# invoking the api and printing the xml ouput
	my $output =
	  $server->invoke( "vfiler-template-delete", "vfiler-template-name-or-id",
		$dfmval );

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	print "\nvFiler Template deletion "
	  . result( $output->results_status() ) . "\n";
}

sub usage {
	print <<MSG;

Usage:
vfiler.pl <dfmserver> <user> <password> delete <name>

vfiler.pl <dfmserver> <user> <password> create <name> <rpool> <ip> [ <tname> ]

vfiler.pl <dfmserver> <user> <password> template-list [ <tname> ]

vfiler.pl <dfmserver> <user> <password> template-delete <tname>

vfiler.pl <dfmserver> <user> <password> template-create <a-tname>
[ -a <cauth> -d <cdomain> ] [ -s <csecurity> ]

<dfmserver> -- Name/IP Address of the DFM server
<user>      -- DFM server User name
<password>  -- DFM server User Password
<rpool>     -- Resource pool in which vFiler is to be created
<ip>        -- ip address of the new vFiler
<name>      -- name of the new vFiler to be created
<tname>     -- Existing Template name
<a-tname>   -- Template to be created
<cauth>     -- CIFS authentication mode Possible values: "active_directory",
			   "workgroup". Default value: "workgroup"
<cdomain>   -- Active Directory domain .This field is applicable only when
			   cifs-auth-type is set to "active-directory".
<csecurity> -- The security style Possible values: "ntfs", "multiprotocol".
			   Default value is: "multiprotocol"
MSG
	exit 1;
}

#=========================== POD ============================#

=head1 NAME

  vfiler.pl - Manages resource pool on a dfm server


=head1 SYNOPSIS

  vfiler.pl <dfmserver> <user> <password> delete <name>

  vfiler.pl <dfmserver> <user> <password> create <name> <rpool> <ip> [ <tname> ]

  vfiler.pl <dfmserver> <user> <password> template-list [ <tname> ]

  vfiler.pl <dfmserver> <user> <password> template-delete <tname>

  vfiler.pl <dfmserver> <user> <password> template-create <a-tname>
  [ -a <cauth> -d <cdomain> ] [ -s <csecurity> ]



=head1 ARGUMENTS

  <dfmserver>
   DFM server name.

  <user>
  DFM server username.

  <password>
  DFM server user password.

  {create | list | delete}
  Operation

  <rpool>
  Resource pool in which vFiler is to be created

  <ip>
  ip address of the new vFiler

  <name>
  name of the new vFiler to be created

  <tname>
  Existing Template name

  <a-tname>
  Template to be created

  <cauth>
  CIFS authentication mode Possible values: "active_directory", "workgroup".
  Default value: "workgroup"

  <cdomain>
  Active Directory domain .This field is applicable only when cifs-auth-type is
  set to "active-directory".

  <csecurity>
  The security style Possible values: "ntfs", "multiprotocol".
  Default value is: "multiprotocol"

=head1 SEE ALSO

  NaElement.pm, NaServer.pm

=head1 COPYRIGHT

 Copyright (c) 2009 NetApp, Inc. All rights reserved.
 Specifications subject to change without notice.

=cut
