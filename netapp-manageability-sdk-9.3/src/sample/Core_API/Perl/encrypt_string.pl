#============================================================#
#                                                            #
# $ID:$                                                      #
#                                                            #
# encrypt_string.pl                                          #
#                                                            #
# Demonstrates the usage of child_add_string_encrypted       #
#  and child_get_string_encrypted encryption core APIs.      # 
#                                                            #
# Copyright (c) 2010 NetApp, Inc. All rights reserved.       #
# Specifications subject to change without notice.           #
#                                                            #
#============================================================#

my $VERSION = '1.0';

use strict;

use lib '../../../../lib/perl/NetApp';
use NaServer;
use Pod::Usage;

die pod2usage( 
	verbose => 1
) unless $ARGV[3];

our $filer = $ARGV[0];
our $user = $ARGV[1];
our $passwd = $ARGV[2];
our $test_passwd = $ARGV[3];

our $s = NaServer->new($filer, 1, 1);
$s->set_admin_user($user, $passwd);

our $input = NaElement->new("test-password-set");
$input->child_add_string_encrypted("password", $test_passwd, undef);
our $dec_passwd = $input->child_get_string_encrypted("password", undef);

print "Expected decrypted password:$dec_passwd\n";

our $output = $s->invoke_elem($input);
if ($output->results_errno != 0) {
	our $r = $output->results_reason();
	print "Error:$r\n";
}
else {
	our $ret_passwd = $output->child_get_string("decrypted-password");
	print "Returned decrypted password:$ret_passwd\n";
}


#=========================== POD ============================#

=head1 NAME

  encrypt_string.pl - Basic encrypt string test program

=head1 SYNOPSIS

  encrypt_string.pl <filer> <user> <password> <test-password>

=head1 ARGUMENTS

  <filer>
  Name or IP Address of the filer.

  <user>
  username. 

  <password>
  password.
  
  <test-password>
  password to test.

=head1 SEE ALSO

  NaElement.pm, NaServer.pm

=head1 COPYRIGHT

  Copyright 2010 NetApp, Inc. All rights reserved. 
  Specifications subject to change without notice.

=cut

