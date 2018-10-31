
#============================================================#
#                                                            #
# $ID:$                                                      #
#                                                            #
# hello_ontapi.pl                                            #
#                                                            #
# "Hello_world" program which prints the ONTAP version       #
# number of the destination filer                            #
#                                                            #
# Copyright 2002-2003 Network Appliance, Inc. All rights     #
# reserved. Specifications subject to change without notice. #
#                                                            #
# This SDK sample code is provided AS IS, with no support or #
# warranties of any kind, including but not limited to       #
# warranties of merchantability or fitness of any kind,      #
# expressed or implied.  This code is subject to the license #
# agreement that accompanies the SDK.                        #
#                                                            #
# tab size = 8                                               #
#                                                            #
#============================================================#

my $VERSION = '1.0';	# Controls the SDK release.

use strict;

use lib '../../../../lib/perl/NetApp';
use NaServer;
use Pod::Usage;

die pod2usage( 
	verbose => 1
) unless $ARGV[2];

our $filer = $ARGV[0];
our $user = $ARGV[1];
our $password = $ARGV[2];

our $s = NaServer->new($filer, 1, 1);
$s->set_admin_user($user, $password);

our $output = $s->invoke( "system-get-version" );
if ($output->results_errno != 0) {
	our $r = $output->results_reason();
	print "Failed: $r\n";
}
else {
	our $r = $output->child_get_string( "version" );

	print "$r\n";
}

#=========================== POD ============================#

=head1 NAME

  hello_ontapi.pl - Basic ONTAPI Test

=head1 SYNOPSIS

  hello_ontapi.pl <filer name> <user> <password>

=head1 ARGUMENTS

  <filer Name>
  The name of the filer to test.

  <user>
  username. 

  <password>
  password.

=head1 SEE ALSO

  NaElement.pm, NaServer.pm

=head1 COPYRIGHT

  Copyright 2002-2003 Network Appliance, Inc. All rights 
  reserved. Specifications subject to change without notice.

  This SDK sample code is provided AS IS, with no support or 
  warranties of any kind, including but not limited to 
  warranties of merchantability or fitness of any kind, 
  expressed or implied.  This code is subject to the license 
  agreement that accompanies the SDK.

=cut





