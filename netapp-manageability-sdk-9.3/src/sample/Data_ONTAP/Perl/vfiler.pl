#==============================================================#
#						    		                           #
# $ID$						       		                       #
#							    	                           #
# vfiler.pl			       	     		                       #
#							    	                           #
# This sample code demonstrates how to create, destroy or      #
# list vfiler(s) using ONTAPI APIs                             #
#							    	                           #
# Copyright 2005 Network Appliance, Inc. All rights	  	       #
# reserved. Specifications subject to change without notice.   #
#							    	                           #
# This SDK sample code is provided AS IS, with no support or   #
# warranties of any kind, including but not limited to         #
# warranties of merchantability or fitness of any kind,        #
# expressed or implied.  This code is subject to the license   #
# agreement that accompanies the SDK.				           #
#							    	                           #
#==============================================================#

require 5.6.1;
use lib "../../../../lib/perl/NetApp";  
use NaServer;
use NaElement;

# Variable declaration

my $args = $#ARGV + 1;
my $filer = shift;
my $user = shift;
my $pw  = shift;
my $command = shift;


#Invoke routine
main();

sub main() 
{
	# check for valid number of parameters
	if ($args < 4) {
		print_usage();
	}

	my $s = NaServer->new ($filer, 1, 3);
	my $resp = $s->set_style(LOGIN);
	if (ref ($resp) eq "NaElement" && $resp->results_errno != 0) {
		my $r = $resp->results_reason();
		print "Unable to set authentication style $r\n";
		exit 2;
	}
	$s->set_admin_user($user, $pw);
	$resp = $s->set_transport_type(HTTP);
		if (ref ($resp) eq "NaElement" && $resp->results_errno != 0) {
				my $r = $resp->results_reason();
				print "Unable to set HTTP transport $r\n";
				exit 2;
		}
	
	
	if($command eq "create") {
		vfiler_create($s);
		return;
	}
	elsif($command eq "list") {
		vfiler_list($s);
		return;
	}
	
	my $vfiler = $ARGV[0];
	
	if($command eq "start" || $command eq "stop" || $command eq "status" ||
		$command eq "destroy" ) {
		if($vfiler eq "") {
			print "This operation requires <vfiler-name> \n\n";
			print_usage();
		}
	}
	
	if($command eq "start") {
		$out = $s->invoke("vfiler-start","vfiler",$vfiler);
		if($out->results_status() eq "failed") {
			print($out->results_reason() ."\n");
			exit(-2);
		}
	}
	elsif($command eq "status") {
		$out = $s->invoke("vfiler-get-status","vfiler",$vfiler);
		if($out->results_status() eq "failed") {
		  print($out->results_reason() ."\n");
		  exit(-2);
		}
		my $status = $out->child_get_string("status");
		print("status:$status\n");
	}
	elsif($command eq "stop") {
		$out = $s->invoke("vfiler-stop","vfiler",$vfiler);
		if($out->results_status() eq "failed") {
			print($out->results_reason() ."\n");
			exit(-2);
		}
	}
	elsif($command eq "destroy"){
		$out = $s->invoke("vfiler-destroy","vfiler",$vfiler);
		if($out->results_status() eq "failed"){
			print($out->results_reason() ."\n");
			exit(-2);
		}
	}
	else {
		print "Invalid operation\n";
		print_usage();
	}
	exit 0;	
}

sub vfiler_create
{
	my $s = $_[0];
	my $i = 0;
	my $parse_ip_addr = 1;
	my $no_of_var_arguments;
	$no_of_var_arguments=$args-4;
	if( $args < 9 || $ARGV[1] ne "-ip")
	{
		print "Usage: vfiler <filer> <user> <password> create <vfiler-name> \n";
		print "-ip <ip-address1> [<ip-address2>..] -su <storage-unit1> ";
		print "[<storage-unit2]..] \n";
		exit -1;
	}

	my $in = NaElement->new("vfiler-create");
	my $ip_addrs = NaElement->new("ip-addresses");
	my $st_units = NaElement->new("storage-units");

	#ARGV[0] contains vfiler-name
	$in->child_add_string("vfiler",$ARGV[$i]);

	# start parsing from <ip-address1>
	for($i=2;$i<$no_of_var_arguments;$i++)
	{

		if($ARGV[$i] eq "-su")
		{
			$parse_ip_addr = 0;
		}
		else
		{
			if($parse_ip_addr == 1)
			{
				$ip_addrs->child_add_string("ip-address",$ARGV[$i]);
			}
			else
			{
				$st_units->child_add_string("storage-unit",$ARGV[$i]);
			}
		}
	}

	$in->child_add($ip_addrs);
	$in->child_add($st_units);

	#
	# Invoke vfiler-create API
	#
	my $out = $s->invoke_elem($in);

	if($out->results_status() eq "failed")
	{
		print($out->results_reason() ."\n");
		exit(-2);
	}

	 print "vfiler created successfully\n";
}


sub vfiler_list
{

	my $s = $_[0];
	my $vfiler = $ARGV[0];
	my $out;

	if($vfiler eq "")
	{
		$out = $s->invoke( "vfiler-list-info");
	}
	else
	{
		$out = $s->invoke( "vfiler-list-info","vfiler", $vfiler);
	}

	if ($out->results_status() eq "failed")
	{
	   print($out->results_reason() ."\n");
	   exit (-2);
	}

	my $vfiler_info = $out->child_get("vfilers");
	my @result = $vfiler_info->children_get();


	foreach $vfiler (@result)
	{
		my $vfiler_name = $vfiler->child_get_string("name");
		print  "Vfiler name: $vfiler_name \n";
		my $ip_space = $vfiler->child_get_string("ip_space");
		if($ip_space ne "")
		{
		  print  "ipspace: $ip_space \n";
		}
		my $uuid = $vfiler->child_get_string("uuid");
		print  "uuid: $uuid \n";
		
		my $vfnet_info = $vfiler->child_get("vfnets");
		my @vfnet_result = $vfnet_info->children_get();

		foreach $vfnet (@vfnet_result)
		{
			print("network resources:\n");
			my $ip_addr = $vfnet->child_get_string("ipaddress");
			if($ip_addr ne "")
			{
			  print  "  ip-address: $ip_addr \n";
			}
			my $interface = $vfnet->child_get_string("interface");
			if($interface ne "")
			{
			  print  "  interface: $interface \n";
			}
		}
		my $vfstore_info = $vfiler->child_get("vfstores");
		my @vfstore_result = $vfstore_info->children_get();

		foreach $vfstore (@vfstore_result)
		{
			print("storage resources:\n");
			my $path = $vfstore->child_get_string("path");
			if($path ne "")
			{
			  print  "  path: $path \n";
			}
			my $status = $vfstore->child_get_string("status");
			if($status ne "")
			{
			  print  "  status: $status \n";
			}
			my $etc = $vfstore->child_get_string("is-etc");
			if($etc ne "")
			{
			  print  "  is-etc: $etc \n";
			}
		}
		
		print "--------------------------------------------\n";
	}
}


sub print_usage() 
{

	print "Usage: vfiler.pl <filer> <user> <password> <operation> <value1>";
	print "[<value2>] ..\n";
	print "<filer>     -- Name/IP address of the filer\n";
	print "<user>      -- User name\n";
	print "<password>  -- Password\n";
	print "<operation> -- Operation to be performed: ";
	print "create/destroy/list/status/start/stop\n";
	print "[<value1>]    -- Depends on the operation \n";
	print "[<value2>]  -- Depends on the operation \n";
	exit -1;
}

#=========================== POD ============================#

=head1 NAME

  vfiler.pl - Displays the usage of configuring vfiler 

=head1 SYNOPSIS

  vfiler.pl  <filer> <user> <password> <operation> [<value1>] [<value2>] ...

=head1 ARGUMENTS

  <filer>
   Filer name.

  <user>
  username.

  <password>
  password.

  <operation>
  Operation to be performed: 

  [<value1>]
  Depends on the operation

  [<value2>]
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

