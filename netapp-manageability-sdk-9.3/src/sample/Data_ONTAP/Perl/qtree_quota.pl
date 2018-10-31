#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# qtree_quota.pl		                             #
#                                                            #
# Creates qtree on volume and adds quota entry.		     #
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
my $user  = shift;
my $pw    = shift;
my $volume = shift;
my $qtree = shift;
my $mode = shift;

#Invoke routine to create qtree & quota.

create_qtree_quota();

# Creates qtree on volume specified and adds quota entry.

sub create_qtree_quota() {

	my $out;

	# check for valid number of parameters
	if ($args < 5)
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
	$response = $s->set_transport_type(HTTPS);
	if (ref ($response) eq "NaElement" && $response->results_errno != 0)
	{
		my $r = $response->results_reason();
		print "Unable to set transport type $r\n";
		exit 2;
	}

	if($args == 6)
	{
		$out = $s->invoke( "qtree-create",
				"qtree", $qtree,
				"volume", $volume,
				"mode", $mode );
	}
	else
	{
		$out = $s->invoke( "qtree-create",
				"qtree", $qtree,
				"volume", $volume);
	}

	 if ($out->results_status() eq "failed"){
		print($out->results_reason());
		print("\n");
		exit (-2);
	}
	
	print "Created new qtree\n";
}

sub print_usage()
{
	print "Usage:\n";
	print "perl qtree_quota.pl <filer> <user> <passwd> ";
	print "<volume> <qtree> [<mode>] \n";
	print "<filer> -- Filer name\n";
	print "<user> -- User name\n";
	print "<passwd> -- Password\n";
	print "<volume> -- Volume name\n";
	print "<qtree> -- Qtree name\n";
	print "<mode> -- The file permission bits of the qtree.";
	print " Similar to UNIX permission bits: 0755 gives ";
	print "read/write/execute permissions to owner and ";
	print "read/execute to group and other users.\n";
	exit (-1);
}

#=========================== POD ============================#

=head1 NAME

 qtree_quota.pl - Creates qtree on a volume, adds quota entry

=head1 SYNOPSIS

 qtree_quota.pl <filer> <user> <passwd> <volume> <qtree> [<mode>]

=head1 ARGUMENTS

  <filer>
  Filer name.

  <user>
  username.

  <password>
  password.

  <volume>
  Volume name.

  <qtree>
  Qtree name.

  <mode>
  The file permission bits of the qtree. Similar to UNIX permission bits:
  0755 gives read/write/execute permissions to owner and read/execute
  to group and other users. 

=head1 SEE ALSO

  NaElement.pm, NaServer.pm

=head1 COPYRIGHT

  Copyright 2007 Network Appliance, Inc. All rights 
  reserved. Specifications subject to change without notice.

  This SDK sample code is provided AS IS, with no support or 
  warranties of any kind, including but not limited to 
  warranties of merchantability or fitness of any kind, 
  expressed or implied.  This code is subject to the license 
  agreement that accompanies the SDK.

=cut
