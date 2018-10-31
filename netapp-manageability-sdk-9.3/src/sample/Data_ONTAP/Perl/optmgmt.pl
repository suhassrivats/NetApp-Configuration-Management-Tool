#============================================================#
#							 #
# $ID$							 #
#							 #
# optmgmt.pl						#
#							 #
# Sample code for the following APIs:		  #
#		options-get					#
#		options-set					#
#		options-list-info				#
#								 #
# Copyright 2005 Network Appliance, Inc. All rights 		 #
# reserved. Specifications subject to change without notice. #
#								 #
# This SDK sample code is provided AS IS, with no support or #
# warranties of any kind, including but not limited to		 #
# warranties of merchantability or fitness of any kind, 	 #
# expressed or implied.  This code is subject to the license #
# agreement that accompanies the SDK.				 #
#								 #
#============================================================#

require 5.6.1;
use lib "../../../../lib/perl/NetApp";  
use NaServer;
use NaElement;

# Variable declaration

my $args = $#ARGV + 1;
my $filer = shift;
my $user = shift;
my $pw	= shift;
my $option = shift;
my $value1 = shift;
my $value2 = shift;

#Invoke routine for the option management
main();

sub main() 
{
	# check for valid number of parameters
	if ($args < 4) 
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
		print "Unable to set transport type $r\n";
		exit 2;
	}


	if($option eq "get")
	{
		get_option_info($s);
	}
	elsif($option eq "set")
	{
		set_option_info($s);
	}
	elsif($option eq "optionsList")
	{
		options_list_info($s);
	}
	else
	{
		print "Invalid Option \n"; 
		print_usage();
	}

	exit 0;	
}


#Get information of the given option
sub get_option_info
{
	my $s = $_[0];
	
	if (!$value1) 
	{
		print_usage();
	}

	my $out = $s->invoke("options-get", "name", $value1);

	if($out->results_status() eq "failed")
	{
		print($out->results_reason() ."\n");
		exit(-2);
	}

	print "-------------------------------------------------------------\n";
	print("Cluster constraint: ".$out->child_get_string("cluster-constraint"));
	print("\n");

	print("Value: ".$out->child_get_string("value")."\n");
	print "-------------------------------------------------------------\n";
}


# Set value for the given option
sub set_option_info
{
	my $s = $_[0];

	if (!$value1 || !$value2) 
	{
		print_usage();
	}

	my $out = $s->invoke("options-set", "name", $value1, "value", $value2);

	if($out->results_status() eq "failed")
	{
		print($out->results_reason() ."\n");
		exit(-2);
	}

	print "-------------------------------------------------------------\n";
	print("Cluster constraint: ".$out->child_get_string("cluster-constraint"));
	print("\n");

	if($out->child_get_string("message"))
	{
		print("Message: ".$out->child_get_string("message")."\n");
	}
	print "-------------------------------------------------------------\n";
}


#Retrieve & print options information : cluster constraint, option name, value
sub options_list_info
{
	my $s = $_[0];
		
	my $out = $s->invoke( "options-list-info");

	if ($out->results_status() eq "failed"){
		print($out->results_reason() ."\n");
	exit (-2);
	}
	
	my $options_info = $out->child_get("options");
	my @result = $options_info->children_get();

	foreach $opt (@result){
		print "------------------------------------------------------------\n";
		print("Cluster constraint: ");
		print($opt->child_get_string("cluster-constraint")."\n");
		
		print("Name: ".$opt->child_get_string("name")."\n");

		print("Value: ".$opt->child_get_string("value")."\n");
		
	}
}


sub print_usage() 
{
	print "optmgmt.pl <filer> <user> <password> <operation> [<value1>] ";
	print "[<value2>] \n";
	print "<filer> -- Filer name\n";
	print "<user> -- User name\n";
	print "<password> -- Password\n";
	print "<operation> -- Operation to be performed: get/set/optionsList\n";
	print "[<value1>] -- Name of the option\n";
	print "[<value2>] -- Value to be set\n";
	exit 1;
}

#=========================== POD ============================#

=head1 NAME

  optmgmt.pl - Get specific option information, Set value of an option, 
			   Display all the available options 

=head1 SYNOPSIS

  optmgmt.pl  <filer> <user> <password> <operation> [<value1>] [<value2>]

=head1 ARGUMENTS

  <filer>
   Filer name.

  <user>
  username.

  <password>
  password.

  <operation>
  Operation to be performed: get/set/optionsList

  [<value1>]
  Name of the option

  [<value2>]
  Value to be set
	
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

