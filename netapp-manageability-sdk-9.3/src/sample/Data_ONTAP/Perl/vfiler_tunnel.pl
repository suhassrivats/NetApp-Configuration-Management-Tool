#============================================================
#
# $ID$
#
# vfiler_tunnel.pl
#
# Sample code for vfiler_tunneling
# This sample code demonstrates how to execute ONTAPI APIs on a
# vfiler through the physical filer
#
# Copyright 2002-2003 Network Appliance, Inc. All rights
# reserved. Specifications subject to change without notice.
#
# This SDK sample code is provided AS IS, with no support or
# warranties of any kind, including but not limited to
# warranties of merchantability or fitness of any kind,
# expressed or implied.  This code is subject to the license
# agreement that accompanies the SDK.
#
# tab size = 4
#
#============================================================

require 5.6.1;
use strict;
use lib "../../../../lib/perl/NetApp";
use NaServer;
use NaElement;

#
# figure out our own program name
#

my $dossl = 0;
my $vfiler;
my $filer;
my $user;
my $password;

#
#Print usage
# 
sub print_usage() {

	print "Usage: vfiler_tunnel [options] <vfiler-name> <filer> <user> ";
	print "<password> <ONTAPI-name> [key value] ...\n";
	print "\noptions:\n";
	print "-s 	Use SSL\n";
	exit 1;
}

# check for valid number of parameters
#
if ($#ARGV < 4) {
	print_usage();
}

my $opt = shift @ARGV;

if ($opt =~ /^-/) {
	my @option = split(/-/, $opt);
	if ($option[1] eq "s" && $#ARGV > 2 ) {
		$dossl = 1;
		$vfiler = shift @ARGV;
	} else {
		print_usage();
	}
} else  {
	$vfiler    = $opt;
}

$filer = shift @ARGV;
$user  = shift @ARGV;
$password = shift @ARGV;

#
# open server
#
my $server = new NaServer($filer, 1, 7);

if(!$server->set_vfiler($vfiler))
{
 print ("Error: ONTAPI version must be at least 1.7 to send API to a vfiler\n");
 exit 2;
}
$server->set_admin_user($user, $password);

if ($dossl) {
	my $resp = $server->set_transport_type("HTTPS");
	if (ref ($resp) eq "NaElement" && $resp->results_errno != 0) {
		my $r = $resp->results_reason();
		print "Unable to set HTTPS transport $r\n";
		exit 2;
	}
}

#
# invoke the api with api name and any supplied key-value pairs
#
my $xo = $server->invoke(@ARGV);
if ( ! defined($xo) ) {
	print "invoke_api failed to $filer as $user:$password.\n";
	exit 3;
}

#
# format the output
#
print "Output: \n" . $xo->sprintf() . "\n"; 

#=========================== POD ============================#

=head1 NAME

 vfiler_tunnel.pl - Executes ONTAPI routines on the vfiler through physical filer.

=head1 SYNOPSIS

 vfiler_tunnel.pl <vfiler-name> <filer> <user> <passwd> <ONTAPI-name> {<key> <value>}

=head1 ARGUMENTS

  <vfiler-name>
  Vfiler name.
  
  <filer>
  Filer name.

  <user>
  Username.

  <password>
  Password.

  <ONTAPI-name>
  Name of ONTAPI routine

  <key>
  Argument name. 

  <value>
  Argument value. 

=head1 EXAMPLE

 $vfiler_tunnel vf1 charminar root bread system-get-version

=head1 SEE ALSO

  NaElement.pm, NaServer.pm

=head1 COPYRIGHT

  Copyright 2005 Network Appliance, Inc. All rights
  reserved. Specifications subject to change without notice.

  This SDK sample code is provided AS IS, with no support or
  warranties of any kind, including but not limited to
  warranties of merchantability or fitness of any kind,
  expressed or implied.  This code is subject to the license
  agreement that accompanies the SDK.

=cut
