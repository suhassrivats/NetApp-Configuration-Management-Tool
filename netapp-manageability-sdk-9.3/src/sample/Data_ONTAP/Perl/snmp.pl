#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# snmp.pl                               	             #
#                                                            #
# Sample code for the following APIs: 	      		     #
#		snmp-get				     #
#		snmp-status				     #
#		snmp-community-add			     #
#		snmp-community-delete			     #
#                                                            #
# Copyright 2005 Network Appliance, Inc. All rights          #
# reserved. Specifications subject to change without notice. #
#                                                            #
# This SDK sample code is provided AS IS, with no support or #
# warranties of any kind, including but not limited to       #
# warranties of merchantability or fitness of any kind,      #
# expressed or implied.  This code is subject to the license #
# agreement that accompanies the SDK.                        #
#                                                            #
#============================================================#

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
		print "Unable to set HTTP transport $r\n";
		exit 2;
	}
	
	if($command eq "get")
	{
		snmp_get($s);
	}
	elsif($command eq "status")
	{
		snmp_status($s);
	}
	elsif($command eq "addCommunity")
	{
		add_community($s);
	}
	elsif($command eq "deleteCommunity")
	{
		delete_community($s);
	}
	else
	{
		print "Invalid operation\n";
		print_usage();
	}
	exit 0;	
}


# SNMP Get operation
# Usage: snmp.pl <filer> <user> <password> get <value1(oid)>
sub snmp_get
{
	my $s = $_[0];

	if (!$value1) 
	{
		print_usage();
	}

	my $out = $s->invoke("snmp-get", "object-id", $value1);

	if($out->results_status() eq "failed")
	{
		print($out->results_reason() ."\n");
		exit(-2);
	}

	print "-------------------------------------------------------------\n";
	print("Value: ".$out->child_get_string("value"));
	print("\n");

	if($out->child_get_string("is-value-hexadecimal"))
	{
		print("Is value hexadecimal: ");
		print($out->child_get_string("is-value-hexadecimal")."\n");
	}
	print "-------------------------------------------------------------\n";
}


# SNMP Status.
# Usage: snmp.pl <filer> <user> <password> status
sub snmp_status
{
	my $s = $_[0];

	my $out = $s->invoke("snmp-status");

	if($out->results_status() eq "failed")
	{
		print($out->results_reason() ."\n");
		exit(-2);
	}

	print "-------------------------------------------------------------\n";
	print("Contact: ".$out->child_get_string("contact")."\n");
	print("Is trap enabled: ".$out->child_get_string("is-trap-enabled")."\n");
	print("Location: ".$out->child_get_string("location")."\n");
	print "-------------------------------------------------------------\n";

	print "Communities: \n\n";

	my $communities = $out->child_get("communities");
	my @result = $communities->children_get();

	foreach $community (@result){
		print("Access control: ");
		print($community->child_get_string("access-control")."\n");
		
		print("Community: ".$community->child_get_string("community")."\n");
		print "------------------------------------------------------------\n";
	}

	print "Trap hosts: \n\n";

	my $traphosts = $out->child_get("traphosts");
	my @result = $traphosts->children_get();

	foreach $traphost (@result){
		print("Host name: ".$traphost->child_get_string("host-name")."\n");		
		print("Ip address: ".$traphost->child_get_string("ip-address")."\n");
		print "------------------------------------------------------------\n";
	}
}


# Add SNMP community
# Usage: snmp.pl <filer> <user> <password> addCommunity <value1(ro/rw)> 
#		<value2(community)>
sub add_community
{
	my $s = $_[0];

	if (!$value1 || !$value2) 
	{
		print_usage();
	}
		
	my $out = $s->invoke( "snmp-community-add", "access-control", $value1,
				"community", $value2);

	if ($out->results_status() eq "failed"){
		print($out->results_reason() ."\n");
	exit (-2);
	}

	print "Added community to the list of communities \n";	
}


#Delete SNMP community
# Usage: snmp.pl <filer> <user> <password> deleteCommunity <value1(ro/rw)> 
#		<value2(community)>

sub delete_community
{
	my $s = $_[0];

	if (!$value1 || !$value2) 
	{
		print_usage();
	}
		
	my $out = $s->invoke( "snmp-community-delete", "access-control", $value1,
				"community", $value2);

	if ($out->results_status() eq "failed"){
		print($out->results_reason() ."\n");
	exit (-2);
	}

	print "Deleted community from the list of communities. \n";
}


sub print_usage() 
{
	print "snmp.pl <filer> <user> <password> <operation> [<value1>] ";
	print "[<value2>] \n";
	print "<filer> -- Filer name\n";
	print "<user> -- User name\n";
	print "<password> -- Password\n";
	print "<operation> -- Operation to be performed: ";
	print "get/status/addCommunity/deleteCommunity \n";
	print "[<value1>] -- Depends on the operation \n";
	print "[<value2>] -- Depends on the operation \n";
	exit 1;
}

#=========================== POD ============================#

=head1 NAME

  snmp.pl - Get the value of specific Object identifier, SNMP status 
			information, Enable/Disable SNMP interface.

=head1 SYNOPSIS

  snmp.pl  <filer> <user> <password> <operation> [<value1>] [<value2>]

=head1 ARGUMENTS

  <filer>
   Filer name.

  <user>
  username.

  <password>
  password.

  <operation>
  Operation to be performed: get/status/addCommunity/deleteCommunity

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

