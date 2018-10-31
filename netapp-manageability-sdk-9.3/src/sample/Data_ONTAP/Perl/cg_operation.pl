#===============================================================#
#						    		#
# $ID$						       		#
#							    	#
# cg_operation.pl			       	     		#
#							    	#
# Sample code for the usage of following APIs: 		     	#
#		cg-start				     	#
#		cg-commit				     	#
#							    	#
# Copyright 2005 Network Appliance, Inc. All rights	  	#
# reserved. Specifications subject to change without notice. 	#
#							    	#
# This SDK sample code is provided AS IS, with no support or 	#
# warranties of any kind, including but not limited to       	#
# warranties of merchantability or fitness of any kind,      	#
# expressed or implied.  This code is subject to the license 	#
# agreement that accompanies the SDK.				#
#							    	#
#===============================================================#

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
my $value1 = shift;
my $value2 = shift;

#Invoke routine
main();

sub main() 
{
	# check for valid number of parameters
	if ($args < 5)
	{
		print_usage();
	}

	my $s = NaServer->new ($filer, 1, 3);
	my $response;
	$response = $s->set_style(LOGIN);
	if (ref ($response) eq "NaElement" && $response->results_errno != 0) { 
		my $r = $response->results_reason();
		print "Unable to set authentication style $r\n";
		exit 2;
	}
	$s->set_admin_user($user, $pw);
	

	$response = $s->set_transport_type(HTTP);
	if (ref ($response) eq "NaElement" && $response->results_errno != 0) { 
		my $r = $response->results_reason();
		print "Unable to set HTTP transport $r\n";
		exit 2;
	}

	if($command eq "cg-start")
	{
		cg_start($s);
	}
	elsif($command eq "cg-commit")
	{
		cg_commit($s);
	}
	else
	{
		print "Invalid operation\n";
		print_usage();
	}
	exit 0;	
}


# cg-start operation
# Usage: cg_operation.pl <filer> <user> <password> cg-start <snapshot> <timeout>
# <volumes>   
sub cg_start 
{
	my $s = $_[0];
	my $i;
	my $no_of_var_arguments;
	my $cg_id;

	if ($args < 7) 
	{
		print "cg_operation.pl <filer> <user> <password> cg-start ";
		print " <snapshot> <timeout> <volumes> \n";
		exit -1;
	}
	my $in = NaElement->new("cg-start");
	$in->child_add_string("snapshot",$value1);
	$in->child_add_string("timeout",$value2);

	my $vols= NaElement->new("volumes");

	#Now store rest of the volumes as a child element of vols
	# 
	#Here $no_of_var_arguments stores the total  no of volumes 
	#Note:First volume is specified at 7th position from cmd prompt input
	$no_of_var_arguments=$args-6;
	for($i=0;$i<$no_of_var_arguments;$i++)
	{
		$vols->child_add_string("volume-name",$ARGV[$i]);
	}
	$in->child_add($vols);

	# 
	# Invoke cg-start API
	# 
	my $out = $s->invoke_elem($in);
	
	if($out->results_status() eq "failed")
	{
		print($out->results_reason() ."\n");
		exit(-2);
	}

	$cg_id = $out->child_get_string( "cg-id" );
	print "Consistency Group operation started successfully with cg-id=$cg_id\n";
}


# cg-commit operation
# Usage: cg_operation.pl <filer> <user> <password> cg-commit <cg-id> 
sub cg_commit 
{
	my $s = $_[0];

	   if ($args < 5)
	{
		print "cg_operation.pl <filer> <user> <password> cg-commit ";
		print "<cg-id> \n";
		exit -1;
	}

	#
	# Invoke cg-commit API
	#
	my $out = $s->invoke("cg-commit","cg-id",$value1);

	if($out->results_status() eq "failed")
	{
		print($out->results_reason() ."\n");
		exit(-2);
	}

	print "Consistency Group operation commited successfully\n";

}


sub print_usage() 
{

	print "cg_operation.pl <filer> <user> <password> <operation> <value1>";
	print "[<value2>] [<volumes>]\n";
	print "<filer> 	   -- Filer name\n";
	print "<user>      -- User name\n";
	print "<password>  -- Password\n";
	print "<operation> -- Operation to be performed: ";
	print "cg-start/cg-commit\n";
	print "<value1>    -- Depends on the operation \n";
	print "[<value2>]  -- Depends on the operation \n";
	print "[<volumes>] --List of volumes.Depends on the operation \n";
	exit -1;
}

#=========================== POD ============================#

=head1 NAME

  cg_operation.pl - Displays the usage of consistency group APIs 

=head1 SYNOPSIS

  cg_operation.pl  <filer> <user> <password> <operation> <value1> [<value2>] [<volumes>]

=head1 ARGUMENTS

  <filer>
   Filer name.

  <user>
  username.

  <password>
  password.

  <operation>
  Operation to be performed: cg-start/cg-commit 

  <value1>
  Depends on the operation

  [<value2>]
  Depends on the operation

  [<volumes>]
  List of Volumes.Depends on the operation
	
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

