#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# print_volume.pl                                            #
#                                                            #
# Retrieves & prints volume information.  	  	     #
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
my $pw = shift;
my $volume  =shift;

#Invoke routine to retrieve & print volume information
get_volume_info();

#Retrieve & print volume information : vol name, total size, used size
sub get_volume_info(){

	my $out;

	# check for valid number of parameters
	if ($args < 3)
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
	$s->set_transport_type(HTTP);
	if (ref ($response) eq "NaElement" && $response->results_errno != 0) 
	{
		my $r = $response->results_reason();
		print "Unable to set HTTP transport $r\n";
		exit 2;
	}

	if($args == 3)
	{
		$out = $s->invoke( "volume-list-info");
	}
	else
	{
		$out = $s->invoke( "volume-list-info",
				"volume", $volume );
	}

	if ($out->results_status() eq "failed"){
		print($out->results_reason() ."\n");
	exit (-2);
	}

	my $volume_info = $out->child_get("volumes");
	my @result = $volume_info->children_get();

	foreach $vol (@result){
		my $vol_name = $vol->child_get_string("name");
		print  "Volume name: $vol_name \n";
		my $size_total = $vol->child_get_int("size-total");
		print  "Total Size: $size_total bytes \n";
		my $size_used = $vol->child_get_int("size-used");
		print  "Used Size: $size_used bytes \n";
		print "--------------------------------------\n";
	}
}

sub print_usage()
{
	print "Usage: \n";
	print "perl print_volume.pl <filer> <user> <password>";
	print " [<volume>]\n";
	exit (-1);
}

#=========================== POD ============================#

=head1 NAME

  print_volume.pl - Print Volume Information 

=head1 SYNOPSIS

  print_volume.pl  <filer> <user> <password> [<volume>]

=head1 ARGUMENTS

  <filer>
   Filer name.

  <user>
  username.

  <password>
  password.

  <volume>
  Volume name
	
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
