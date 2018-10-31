#============================================================#
#							 #
# $ID$							 #
#							 #
# snapmirror.pl 					   #
#							 #
# Sample code for the following APIs:		  	#
#		snapmirror-get-status			#
#		snapmirror-get-volume-status		#
#		snapmirror-off				#
#		snapmirror-on				#
#							 #
# Copyright 2005 Network Appliance, Inc. All rights 	 #
# reserved. Specifications subject to change without notice. #
#							 #
# This SDK sample code is provided AS IS, with no support or #
# warranties of any kind, including but not limited to	 #
# warranties of merchantability or fitness of any kind,	 #
# expressed or implied.  This code is subject to the license #
# agreement that accompanies the SDK.			 #
#							 #
#============================================================#

require 5.6.1;
use lib "../../../../lib/perl/NetApp";  
use NaServer;
use NaElement;

# Variable declaration

my $argc = $#ARGV + 1; 
my $filer = shift;
my $user = shift;
my $pw	= shift;
my $command = shift;
my $value1 = shift;

#Invoke routine
main();

sub main() 
{
	# check for valid number of parameters
	if ($argc < 4) 
	{
		print_usage();
	}

	my $s = NaServer->new ($filer, 1, 3);
	my $response = $s->set_style(LOGIN);
	if (ref ($response) eq "NaElement" && $response->results_errno != 0) 
	{
		my $r = $response->results_reason();
		print "Unable to set authentication style $r\n";
		exit 2;
	}
	$s->set_admin_user($user, $pw);
	$response = $s->set_transport_type(HTTP);
	if (ref ($response) eq "NaElement" && $response->results_errno != 0) 
	{
		my $r = $response->results_reason();
		print "Unable to set HTTP transport $r\n";
		exit 2;
	}
	
	if($command eq "getStatus")
	{
		get_status($s);
	}
	elsif($command eq "getVolStatus")
	{
		get_vol_status($s);
	}
	elsif($command eq "off")
	{
		snapmirror_off($s);
	}
	elsif($command eq "on")
	{
		snapmirror_on($s);
	}
	else
	{
		print "Invalid operation\n";
		print_usage();
	}
	
	exit 0;	
}


# Snapmirror get status
# Usage: snapmirror.pl <filer> <user> <password> getStatus [<value1(location)>]
sub get_status
{
	my $s = $_[0];
	my $out;
	my @result;

	if (!$value1) 
	{
		$out = $s->invoke("snapmirror-get-status");
	}
	else
	{
		$out = $s->invoke("snapmirror-get-status", "location", $value1);
	}

	if($out->results_status() eq "failed")
	{
		print($out->results_reason() ."\n");
		exit(-2);
	}

	print "-------------------------------------------------------------\n";
	print("Is snapmirror available: ".$out->child_get_string("is-available"));
	print("\n");
	print "-------------------------------------------------------------\n\n";

	my $status = $out->child_get("snapmirror-status");
	if(!($status eq undef))
	{
		@result = $status->children_get();
	}
	else
	{
		exit(0);
	}

	foreach $snapStat (@result){
		print("Contents: ".$snapStat->child_get_string("contents")."\n");
		
		print("Destination location: ");
		print($snapStat->child_get_string("destination-location")."\n");

		print("Lag time: ".$snapStat->child_get_string("lag-time")."\n");

		print("Last transfer duration: ");
		print($snapStat->child_get_string("last-transfer-duration")."\n");

		print("Last transfer from: ");
		print($snapStat->child_get_string("last-transfer-from")."\n");

		print("Last transfer size: ");
		print($snapStat->child_get_string("last-transfer-size")."\n");

		print("Mirror timestamp: ");
		print($snapStat->child_get_string("mirror-timestamp")."\n");

		print("Source location: ");
		print($snapStat->child_get_string("source-location")."\n");

		print("State: ".$snapStat->child_get_string("state")."\n");

		print("Status: ".$snapStat->child_get_string("status")."\n");

		print("Transfer progress: ");
		print($snapStat->child_get_string("transfer-progress")."\n");
		
		print "------------------------------------------------------------\n";
	}
}


# Snapmirror get volume status
# Usage: 
#	snapmirror.pl <filer> <user> <password> getVolStatus <value1(volume)>
sub get_vol_status
{
	my $s = $_[0];

	if (!$value1) 
	{
		print_usage();
	}

	my $out = $s->invoke("snapmirror-get-volume-status", "volume", $value1);

	if($out->results_status() eq "failed")
	{
		print($out->results_reason() ."\n");
		exit(-2);
	}

	print "-------------------------------------------------------------\n";
	print("Is destination: ".$out->child_get_string("is-destination")."\n");
	print("Is source: ".$out->child_get_string("is-source")."\n");
	print("Is transfer broken: ".$out->child_get_string("is-transfer-broken"));
	print("\nIs transfer in progress: ");
	print($out->child_get_string("is-transfer-in-progress")."\n");
	print "-------------------------------------------------------------\n\n";	
}


# Snapmirror off
# Usage: snapmirror.pl <filer> <user> <password> off
sub snapmirror_off
{
	my $s = $_[0];
		
	my $out = $s->invoke( "snapmirror-off");

	if ($out->results_status() eq "failed"){
		print($out->results_reason() ."\n");
	exit (-2);
	}

	print "Disabled SnapMirror data transfer and ";
	print "turned off the SnapMirror scheduler \n";
}


# Snapmirror on
# Usage: snapmirror.pl <filer> <user> <password> on
sub snapmirror_on
{
	my $s = $_[0];

	my $out = $s->invoke( "snapmirror-on");

	if ($out->results_status() eq "failed"){
		print($out->results_reason() ."\n");
	exit (-2);
	}

	print "Enabled SnapMirror data transfer and ";
	print "turned on the SnapMirror scheduler \n";
}


sub print_usage() 
{
	print "snapmirror.pl <filer> <user> <password> <operation> [<value1>]\n ";
	print "<filer> -- Filer name\n";
	print "<user> -- User name\n";
	print "<password> -- Password\n";
	print "<operation> -- Operation to be performed: ";
	print "getStatus/getVolStatus/off/on \n";
	print "[<value1>] -- Depends on the operation\n";
	exit 1;
}

#=========================== POD ============================#

=head1 NAME

  snapmirror.pl - Snapmirro get status, Snapmirror get volume status, 
				  Snapmirror off, Snapmirror on
  
=head1 SYNOPSIS

  snapmirror.pl  <filer> <user> <password> <operation> [<value1>]

=head1 ARGUMENTS

  <filer>
   Filer name.

  <user>
  username.

  <password>
  password.

  <operation>
  Operation to be performed: getStatus/getVolStatus/off/on

  [<value1>]
  Depends on the operation

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

