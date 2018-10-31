
#============================================================
#
# $ID$
#
# apitest
#
# apitest executes ONTAP APIs.
#
# Copyright (c) 2009 NetApp, Inc. All rights reserved.
# Specifications subject to change without notice.
#
# This SDK sample code is provided AS IS, with no support or
# warranties of any kind, including but not limited to
# warranties of merchantability or fitness of any kind,
# expressed or implied.  This code is subject to the license
# agreement that accompanies the SDK.
#
# tab size = 8
#
#============================================================

require 5.6.1;
use strict;
use lib "../../../../lib/perl/NetApp";
use NaServer;
use NaElement;
use     LWP::UserAgent;
use     XML::Parser;


#
# figure out our own program name
#
my $prog = $0;
$prog =~ s@.*/@@;
my (@in, $xo, $xi, $next, $dovfiler, $vfiler_name, $originator_id, $send_oid, $remote_peer, $do_remote_peering, $option_set);
my ($dossl, $dodfm, $doocum, $doagent, $dofiler, $host_equiv, $set_timeout, $timeout);
my ($save_arg, $server_type, $index, $use_port, $showxml, $inputxml);
my ($host, $user, $password);
my ($use_cba, $cert_file, $key_file, $key_passwd, $need_server_cert_verification, 
		$need_hostname_verification, $ca_file);


#
#Print usage
#
sub print_usage() {

	print "\nUsage:\n";
	print "\t$prog [options] <host> <user> <password> <API> [ <paramname> <arg> ...]\n";
	print "\nOptions:\n";
	print "\t-i     API specified as XML input, on the command line\n";
	print "\t-I     API specified as XML input, on standard input\n";
	print "\t-t {type}      Server type(type = filer, dfm, ocum, agent)\n";
	print "\t-v {vfiler name | vserver name}       For vfiler-tunneling or vserver-tunneling \n";
	print "\t-n     Use HTTP\n";
	print "\t-p {port}      Override port to use\n";
	print "\t-x     Show the XML input and output\n";
	print "\t-X     Show the raw XML input and output\n";
	print "\t-c     Connection timeout\n";
	print "\t-h     Use Host equiv authentication mechanism.\n";
	print "\t-o {originator-id}      Pass Originator Id\n";
	print "\t-z {cluster uuid | vserver name}    Pass remote peered cluster uuid or vserver name (only with vserver-tunneling) for redirecting APIs\n";
	print "\t-C {cert-file}  Client certificate file to use. The default is not to use certificate\n";
	print "\t-K {key-file}   Private key file to use. If not specified, then the certificate file will be used\n";
	print "\t-P {key-passwd} Passphrase to access the private key file\n";
	print "\t-T {ca-file} File containing trusted certificate(s) to be used for server certificate verification\n";
	print "\t-S     Enable server certificate verification\n";
	print "\t-H     Enable hostname verification\n\n";
	print "Note: \n";
	print "     Use server type 'dfm' (-t dfm) for OnCommand Unified Manager server version 5.2 or earlier.\n";
	print "     Use server type 'ocum' (-t ocum) for OnCommand Unified Manager server version 6.0 or later.\n\n";
	print "     Use '-z' option to pass the UUID of a remote peered cluster to which the APIs are to be redirected from current cluster server context.\n";
	print "     Use '-z' option with '-v' option to pass the name of a remote peered vserver to which the APIs are to be redirected from current cluster server context.\n\n";
	print "     By default username and password shall be used for client authentication, specify\n";
	print "      -C option for using Certificate Based Authentication (CBA).\n";
	print "     Server certificate and Hostname verification is disabled by default for CBA. \n";
	print "     -T option can also be used for building the client certificate chain.\n";
	print "     All the certificates provided should be in PEM format.\n";
	print "     Do not provide username and password for -h, -r or CBA options.\n";
	print "     The username or UID of the user administering the storage systems can be passed\n";
	print "     to ONTAP as originator-id for audit logging.\n\n";
	print "Examples:\n";
	print "   $prog toaster root bread system-get-version\n";
	print "   $prog -s toaster root bread system-get-version\n";
	print "   $prog toaster root bread quota-report volume vol0\n";
	print "   $prog -z 93ae35b1-9009-11e3-8626-123478563412 toaster admin password vserver-get-iter\n";
	print "   $prog -v vs0 -z vs0_backup toaster admin password vserver-get-iter\n";
	print "   $prog -t dfm -C my_cert.pem -K my_key.pem -P keypasswd amana dfm-about\n";
	print "   $prog -t dfm -C my_cert.pem -K my_key.pem -P keypasswd -S -T server_cert.pem amana dfm-about\n";
	exit 1;
}

# check for valid number of parameters
#
if ($#ARGV < 2) {
	print_usage();
}

my $use_port = -1;

$server_type = "FILER";
$vfiler_name = "";
$set_timeout = 0;
$timeout = 0;
$originator_id = "";
$use_cba = 0;
$need_server_cert_verification = 0;
$need_hostname_verification = 0;
$dossl = 1;
$cert_file = $key_file = $key_passwd = $ca_file = undef;
my $opt = shift @ARGV;
my $response;

if ($opt =~ /^-/){
$option_set = 1;
while ($opt =~ m/^-/) {
	my @option = split(/-/, $opt);
	use Switch;
	switch ($option[1]) {
		case "i" { $inputxml = 1; }
		case "n" { $dossl = 0; }
		case "x" { $showxml = 1; }
		case "X" { $showxml = 2; }
		case "I" { $inputxml = 2; }
		case "p" { $use_port = shift @ARGV; }
		case "v" { $vfiler_name = shift @ARGV; $dovfiler = 1; }
		case "t" {
				$server_type = shift @ARGV;
				use Switch;
				if ($use_port == -1){
					switch ($server_type) {
						case "dfm" { $dodfm = 1; $server_type = "DFM"; }
						case "ocum" { $doocum = 1; $dossl = 1; $server_type = "OCUM"; }
						case "agent" { $doagent = 1; $server_type = "AGENT"; }
						case "filer" { $dofiler = 1; $server_type = "FILER"; }
					}
				}
			}
		case "h" {$host_equiv = 1;}
		case "c" { $set_timeout = 1; $timeout = int(shift @ARGV); }
		case "o" { $originator_id = shift @ARGV; $send_oid = 1; }
		case "z" { $remote_peer = shift @ARGV; $do_remote_peering = 1; }
		case "C" { $cert_file = shift @ARGV; $use_cba = 1; 
					$dossl = 1; }
		case "K" { $key_file = shift @ARGV; }
		case "P" { $key_passwd = shift @ARGV; }
		case "T" { $ca_file = shift @ARGV; }
		case "S" { $need_server_cert_verification = 1; }
		case "H" { $need_hostname_verification = 1; }
		else { print_usage(); }
		}
		$opt = shift @ARGV;
		my @option = split(/-/, $opt);
	};
		$host = $option_set ? $opt : shift @ARGV;
}
else {
	$host = $opt;
}
if (($dodfm || $doocum) && $dovfiler) {
	print "The -v option is not a valid option for OnCommand Unified Manager server.\n";
	exit 2;
}

if (($dodfm || $doocum) && $send_oid) {
	print "The -o option is not a valid option for OnCommand Unified Manager server.\n";
	exit 2;
}

if ($need_hostname_verification && !$need_server_cert_verification) {
	print "Hostname verification cannot be enabled when server certificate verification is disabled.\n";
	exit 2;
}
if ($use_port == -1) {
	if ($dodfm) {
		$use_port = $dossl ? 8488 : 8088;
	}
	elsif ($doocum) {
		$use_port = 443;
	}
	elsif ($doagent) {
		$use_port = $dossl ? 4093 : 4092;
	}
	else {
		$use_port = ($dossl) ? 443 : 80;
	}
}

if($host_equiv != 1 && $use_cba != 1) {
	$user  = shift @ARGV;
	$password = shift @ARGV;
}
if ($inputxml == 2) {
	if ($#ARGV > 0) {
		print "The -I option expects no API on the command-line, it expects standard input\n";
		print_usage();
	}
	else {
		## read from stdin
		while (<>) {
			push(@in,"$_");
		}
		@ARGV = @in;
	}
}

if ($#ARGV < 0) {
	print "API not specified\n";
	print_usage();
}
#
# Open server.Vfiler tunnelling requires ONTAPI version 7.0 to work.
# NaServer is called to connect to servers and invoke API's.
# The argument passed should be:
# NaServer(hostname, major API version number, minor API version number)
#
my $s = ($dovfiler) ? new NaServer($host, 1, 7): new NaServer($host, 1, 0);
if ( ! defined($s) ) {
	print "Initializing server elements failed.\n";
	exit 3;
}
if ($dossl) {
	$response = $s->set_transport_type("HTTPS");
	if (ref ($response) eq "NaElement" && $response->results_errno != 0) { 
		my $r = $response->results_reason();
		print "Unable to set HTTPS transport $r\n";
		exit 2;
	}
} else {
	$s->set_transport_type("HTTP");
}
#
# Set the login and password used for authenticating when
# an ONTAPI API is invoked.
# When Host_equiv is  set,dont set username ,password
#
if ($host_equiv != 1 && $use_cba != 1) {
	$s->set_admin_user($user, $password);
}
#
# Set the name of the vfiler on which the API 
# commands need to be invoked.
#
if ($dovfiler) {
	$s->set_vfiler($vfiler_name);
}

if ($send_oid) {
	$s->set_originator_id($originator_id);
}

if($do_remote_peering) {
	if($dovfiler) {
		$s->set_target_vserver_name($remote_peer);
	} else {
		$s->set_target_cluster_uuid($remote_peer);
	}
}

#
# Set the Type of API Server.
#
$response = $s->set_server_type($server_type);

if (ref ($response) eq "NaElement") { 
	if ($response->results_errno != 0) {
		my $r = $response->results_reason();
		print "Unable to set server type $r\n";
		exit 2;
	}
}

if ($use_cba) {
	$response = $s->set_style("CERTIFICATE");
	if ($response) {
		print "Unable to set style: " . $response->results_reason() . "\n";
		exit 2;
	}
	$response = $s->set_client_cert_and_key($cert_file, $key_file, $key_passwd);
	if ($response) {
		print $response->results_reason() . "\n";
		exit 2;
	}
}
if ($dossl || $need_server_cert_verification) {
	$response =$s->set_server_cert_verification($need_server_cert_verification);
	if ($response) {
		print $response->results_reason() . "\n";
		exit 2;
	}
	if ($need_server_cert_verification) {
		$response = $s->set_hostname_verification($need_hostname_verification);
	}
	if ($response) {
		print $response->results_reason() . "\n";
		exit 2;
	}
} 
if ($ca_file) {
	$response = $s->set_ca_certs($ca_file);
	if ($response) {
		print $response->results_reason() . "\n";
		exit 2;
	}
}

#
# Set the TCP port used for API invocations on the server.
#
if ($use_port != -1) {
	$s->set_port($use_port);
}

if($set_timeout == 1) {
	if($timeout > 0) {
		$s->set_timeout($timeout);
	} else {
		print "Invalid value for connection timeout." . 
		" Connection timeout value should be greater than 0.\n";
		exit 2;
	}
}

#
#Set the style of the server
#
if($host_equiv == 1) {	
	$s->set_style("HOSTS");
}

# This is needed for -X option.
if ($showxml == 2) {
	$s->set_debug_style("NA_PRINT_DONT_PARSE");
}
if ($inputxml > 0) {
	$ARGV = join(" ",@ARGV);
	my $rxi = $s->parse_raw_xml($ARGV);
	if ($showxml == 1) {
		print "INPUT:\n" . $rxi->sprintf() . "\n";
	}
	my $rxo = $s->invoke_elem($rxi);
	if ($showxml != 2) {
		print $rxo->sprintf();
	}
	exit 5;
}
# Create a XML element to print 
if ($showxml == 1) {
	my @save_arg = @ARGV;
	$xi = new NaElement(shift @save_arg);
	for ($index = 0;$index < @save_arg;$index++){
		$next = shift @save_arg;
		$xi->child_add_string($next, shift @save_arg);
	}
	print "\nINPUT: \n" . $xi->sprintf() . "\n";
}
#
# invoke the api with api name and any supplied key-value pairs
#
my $xo = $s->invoke(@ARGV);
if ( ! defined($xo) ) {
	print "invoke_api failed to $host as $user:$password.\n";
	exit 6;
}

if ($showxml != 2) {
	print "\nOUTPUT: \n" . $xo->sprintf() . "\n";
} elsif ($showxml == 2 &&  
		$xo->results_reason() ne "debugging bypassed xml parsing") {
	print "\nOUTPUT: \n" . $xo->sprintf() . "\n";
}

#=========================== POD ============================#

=head1 NAME

 apitest.pl - Executes ONTAPI routines on the host specified.

=head1 SYNOPSIS

 apitest.pl [options] <host> <user> <password> <API> [ <paramname> <arg> ...]

=head1 ARGUMENTS
  [options]
  -i	API specified as XML input, on the command line
  -I	API specified as XML input, on standard input
  -t (type)      Server type(type = filer, dfm, agent)
  -v (vfiler name)       Vfiler name, if the API has to be executed in the context of a vfiler
  -n     Use HTTP
  -p (port)      Override port to use
  -x     Show the XML input and output
  -X     Show the raw XML input and output
  -c     Connection timeout
  -h	 Use Host equiv authentication mechanism. Do not provide username, password with -h option
  -z {cluster uuid | vserver name}    Pass remote peered cluster uuid or vserver name (only with vserver-tunneling) for redirecting APIs
  -C {cert-file}  Client certificate file to use. The default is not to use certificate
  -K {key-file}   Private key file to use. If not specified, then the certificate file will be used
  -P {key-passwd} Passphrase to access the private key file
  -T {ca-file} File containing trusted certificate(s) to be used for server certificate verification
  -S   Enable server certificate verification
  -H   Enable hostname verification
  Note: 
     Use '-z' option to pass the UUID of a remote peered cluster to which the APIs are redirected from current cluster server context.
     Use '-z' option with '-v' option to pass the name of a remote peered vserver to which the APIs are redirected from current cluster server context.
     By default username and password shall be used for client authentication, specify 
      -C option for using Certificate Based Authentication (CBA).
     Server certificate and Hostname verification is disabled by default for CBA. 
     -T option can also be used for building the client certificate chain.
     All the certificates provided should be in PEM format.
     Do not provide username and password for -h, -r or CBA options.
  Examples:
     $prog toaster root bread system-get-version
     $prog -s toaster root bread system-get-version
     $prog toaster root bread quota-report volume vol0
     $prog -z 93ae35b1-9009-11e3-8626-123478563412 toaster admin password vserver-get-iter
     $prog -v vs0 -z vs0_backup toaster admin password vserver-get-iter
     $prog -t dfm -C my_cert.pem -K my_key.pem -P keypasswd amana dfm-about
     $prog -t dfm -C my_cert.pem -K my_key.pem -P keypasswd -S -T server_cert.pem amana dfm-about

  <host>
  filer, dfm, agent

  <user>
  Username.

  <password>
  Password.

  <ONTAPI-name>
  Name of ONTAPI routine

  <key>
  Argument name.

  <value>
  Argument value.

=head1 EXAMPLE

 $apitest toaster root bread quota-report volume vol0

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
