#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# hello_dfm.pl                                                  #
#                                                               #
# Copyright (c) 2013 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# This program will print the version number of the OCUM Server #
#                                                               #
# This Sample code is supported from OnCommand Unified Manager  #
# 6.0 onwards.                                                  #
#===============================================================#
require 5.6.1;

use lib '../../../../../../lib/perl/NetApp';
use NaServer;

# Variables declaration
my $args = $#ARGV + 1;
my $ocumserver = shift;
my $ocumuser = shift;
my $ocumpw	= shift;

# check for valid number of parameters
if ($args != 3) {
	print_usage();
}

my $s = NaServer->new ($ocumserver, 1, 0);
$s->set_style(LOGIN);
$s->set_admin_user($ocumuser, $ocumpw);
$s->set_server_type(OCUM);

eval {
    our $output = $s->system_about();
};

if($@) {
    print "Failed : $@";
} 
else {
    our $version = $output->{'version'};
    print "Hello world!  OCUM Server version is: $version\n";
}
################################################################################
sub print_usage()
{
	print "Usage: hello_dfm.pl <ocumserver> <ocumuser> <ocumpassword> \n";
	print "<ocumserver> -- Name/IP Address of the OCUM server \n";
	print "<ocumuser> -- OCUM server User name\n";
	print "<ocumpassword> -- OCUM server Password\n";
	exit -1;
}


#=========================== POD ============================#

=head1 NAME

  hello_dfm.pl - Gets OCUM server version


=head1 SYNOPSIS

  hello_dfm.pl  <ocumserver> <ocumuser> <ocumpassword>

=head1 ARGUMENTS

  <ocumserver>
   OCUM server name.

  <ocumuser>
  OCUM server username.

  <ocumpassword>
  OCUM server password.

  
=head1 SEE ALSO

  NaElement.pm, NaServer.pm, OCUMAPI.pm

=head1 COPYRIGHT

 Copyright (c) 2013 NetApp, Inc. All rights reserved.
 Specifications subject to change without notice.

=cut






