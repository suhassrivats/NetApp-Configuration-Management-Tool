#============================================================#
#                                                            #
# $ID:$                                                      #
#                                                            #
# hello_ontapi.pl                                            #
#                                                            #
# "Hello_world" program which prints the ONTAP version       #
# number of the destination Storage                          #
#                                                            #
# Copyright 2013 Network Appliance, Inc. All rights          #
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

my $VERSION = '9.3';	# Controls the SDK release.
use strict;

use lib '../../../../lib/perl/NetApp';
use NaServer;
use Pod::Usage;

die pod2usage( 
	verbose => 1
) unless $ARGV[2];

our $server = $ARGV[0];
our $user = $ARGV[1];
our $password = $ARGV[2];
our $output ;

our $s = NaServer->new($server, 1, 1);
$s->set_admin_user($user, $password);

eval {
    $output = $s->system_get_version();
};

if($@) {
    print "Failed : $@";
}
else {
    our $version = $output->{'version'};
    print "$version\n";
}
#=========================== POD ============================#

=head1 NAME

  hello_ontapi.pl - Basic ONTAPI Test

=head1 SYNOPSIS

  hello_ontapi.pl <server name> <user> <password>

=head1 ARGUMENTS

  <server Name>
  The name of the Storage Server to test.

  <user>
  username. 

  <password>
  password.

=head1 SEE ALSO

  NaServer.pm, OntapClusterAPI.pm, Ontap7ModeAPI.pm

=head1 COPYRIGHT

  Copyright 2013 Network Appliance, Inc. All rights 
  reserved. Specifications subject to change without notice.

  This SDK sample code is provided AS IS, with no support or 
  warranties of any kind, including but not limited to 
  warranties of merchantability or fitness of any kind, 
  expressed or implied.  This code is subject to the license 
  agreement that accompanies the SDK.

=cut





