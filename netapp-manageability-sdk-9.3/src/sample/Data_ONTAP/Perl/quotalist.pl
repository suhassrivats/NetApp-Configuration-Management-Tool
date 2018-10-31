#===============================================================#
#							 	#
# $ID$							 	#
#							 	#
# quotalist.pl						 	#
#							 	#
# Sample code for the following APIs:		         	#
#		quota-list-entries				#
#								#
# Copyright 2005 Network Appliance, Inc. All rights 		#
# reserved. Specifications subject to change without notice. 	#
#								#
# This SDK sample code is provided AS IS, with no support or 	#
# warranties of any kind, including but not limited to		#
# warranties of merchantability or fitness of any kind, 	#
# expressed or implied.  This code is subject to the license 	#
# agreement that accompanies the SDK.				#
#								#
#===============================================================#

require 5.6.1;
use lib "../../../../lib/perl/NetApp";  
use NaServer;
use NaElement;

# Variable declaration

my $args = $#ARGV + 1;
my $filer = shift;
my $user = shift;
my $pw	= shift;

#Invoke routine to retrieve & print quota information
get_quota_info();

#Retrieve & print quota information : quota-target,vol name,quota-type
sub get_quota_info(){

	# check for valid number of parameters
	if ($args < 3)
	{
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

		my $out = $s->invoke( "quota-list-entries" );

		if ($out->results_status() eq "failed"){
				print($out->results_reason() ."\n");
		exit (-2);
		}

		my $quota_info = $out->child_get("quota-entries");
		my @result = $quota_info->children_get();

	print "-----------------------------------------------------\n";
		foreach $quota (@result){
		if($quota->child_get_string("quota-target"))
		{
					my $quota_target = $quota->child_get_string("quota-target");
					print  "Quota Target: $quota_target \n";
		}
		if($quota->child_get_string("volume"))
		{
					my $volume = $quota->child_get_int("volume");
					print  "Volume: $volume \n";
		}
		if($quota->child_get_string("quota-type"))
		{
					my $quota_type = $quota->child_get_int("quota-type");
					print  "Quota Type: $quota_type \n";
		}
		print "-----------------------------------------------------\n";
		}
}

sub print_usage()
{
	print "quotalist.pl <filer> <user> <password>\n";
	print "<filer> -- Filer name\n";
	print "<user> -- User name\n";
	print "<password> -- Password\n";
	exit 1;
}
#=========================== POD ============================#

=head1 NAME

  quotalist.pl - Displays quotas information 

=head1 SYNOPSIS

  quotalist.pl  <filer> <user> <password>

=head1 ARGUMENTS

  <filer>
   Filer name.

  <user>
  username.

  <password>
  password.

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

