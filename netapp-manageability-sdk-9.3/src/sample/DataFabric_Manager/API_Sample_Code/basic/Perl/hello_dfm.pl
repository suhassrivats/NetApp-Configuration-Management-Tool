#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# hello_dfm.pl                                                  #
#                                                               #
# Copyright (c) 2009 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# This program will print the version number of the DFM Server  #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.6R2   #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#
require 5.6.1;

use lib '../../../../../../lib/perl/NetApp';
use NaServer;
use NaElement;

# Variables declaration
my $args = $#ARGV + 1;
my $dfmserver = shift;
my $dfmuser = shift;
my $dfmpw	= shift;

# check for valid number of parameters
if ($args != 3) {
	print_usage();
}

my $s = NaServer->new ($dfmserver, 1, 0);
$s->set_style(LOGIN);
$s->set_transport_type(HTTP);
$s->set_server_type(DFM);
$s->set_port(8088);
$s->set_admin_user($dfmuser, $dfmpw);

our $output = $s->invoke("dfm-about");
if ($output->results_errno != 0) {
	our $r = $output->results_reason();
	print "Failed: $r\n";
}
else {
	our $r = $output->child_get_string("version");
	print "Hello world!  DFM Server version is: $r\n";
}

################################################################################
sub print_usage()
{
	print "Usage: hello_dfm.pl <dfmserver> <dfmuser> <dfmpassword> \n";
	print "<dfmserver> -- Name/IP Address of the DFM server \n";
	print "<dfmuser> -- DFM server User name\n";
	print "<dfmpassword> -- DFM server Password\n";
	exit -1;
}


#=========================== POD ============================#

=head1 NAME

  hello_dfm.pl - Gets DFM DFM server version


=head1 SYNOPSIS

  hello_dfm.pl  <dfmserver> <dfmuser> <dfmpassword> 

=head1 ARGUMENTS

  <dfmserver>
   DFM server name.

  <dfmuser>
  DFM server username.

  <dfmpassword>
  DFM server password.

  
=head1 SEE ALSO

  NaElement.pm, NaServer.pm

=head1 COPYRIGHT

 Copyright (c) 2009 NetApp, Inc. All rights reserved.
 Specifications subject to change without notice.

=cut






