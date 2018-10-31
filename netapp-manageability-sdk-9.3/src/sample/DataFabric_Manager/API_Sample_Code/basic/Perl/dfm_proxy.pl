#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# dfm_proxy.pl                                                  #
#                                                               #
# Copyright (c) 2009 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to use DFM server as a proxy   #
# in sending API commands to a filer                            #
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
my $filerip = shift;

# check for valid number of parameters
if ($args != 4)
{
	print_usage();
}

my $s = NaServer->new ($dfmserver, 1, 0);
$s->set_style(LOGIN);
$s->set_transport_type(HTTP);
$s->set_server_type(DFM);
$s->set_port(8088);
$s->set_admin_user($dfmuser, $dfmpw);

my $proxyElem = NaElement->new("api-proxy");
$proxyElem->child_add_string("target",$filerip);
	
my $requestElem = NaElement->new("request");
	$requestElem->child_add_string("name", "system-get-version");
	
	$proxyElem->child_add($requestElem);

	my $out = $s->invoke_elem($proxyElem);
	if ($out->results_status() eq "failed"){
		print("Error : " . $out->results_reason() ."\n");
		exit (-2);
	}

	my $dfmResponse = $out->child_get("response");
	if ($dfmResponse->child_get_string("status") eq "failed"){
		print("Error: ".$dfmResponse->child_get_string("reason") ."\n");
		exit (-2);
	}

	my $ontapiResponse = $dfmResponse->child_get("results");
	if ($ontapiResponse->results_status() eq "failed"){
		print($ontapiResponse->results_reason() ."\n");
		return -3;
	}

	my $verStr = $ontapiResponse->child_get_string("version");
	print "Hello world!  DOT version of $filerip got from DFM-Proxy is $verStr\n";


################################################################################
# Name: print_usage
#
# Description: Prints the usage of this program
# 	      
# Parameters: None
#            
# Return value: None
#
################################################################################
sub print_usage()
{
	print "Usage: dfm_proxy.pl <dfmserver> <dfmuser> <dfmpassword> <filerip>\n";
	print "<dfmserver> -- Name/IP Address of the DFM server\n";
	print "<dfmuser> -- DFM server User name\n";
	print "<dfmpassword> -- DFM server Password\n";
	print "<filerip> -- Filer IP address\n";
	exit 1;
}


#=========================== POD ============================#

=head1 NAME

  dfm_proxy.pl - Gets filer ONTAP version using DFM server as a proxy


=head1 SYNOPSIS

  dfm_proxy.pl  <dfmserver> <dfmuser> <dfmpassword> <filerip>

=head1 ARGUMENTS

  <dfmserver>
   DFM server name.

  <dfmuser>
  DFM server username.

  <dfmpassword>
  DFM server password.

  <filerip>
  Filer IP address

=head1 SEE ALSO

  NaElement.pm, NaServer.pm

=head1 COPYRIGHT

 Copyright (c) 2009 NetApp, Inc. All rights reserved.
 Specifications subject to change without notice.

=cut

