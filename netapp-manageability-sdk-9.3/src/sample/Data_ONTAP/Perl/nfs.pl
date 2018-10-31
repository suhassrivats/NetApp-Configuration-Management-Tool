#=======================================================================#
#									                                    #
# $ID$									                                #
#																		#
# nfs.pl																#
#																		#
# Sample code for the following APIs:									#
#		nfs-enable, nfs-disable											#
#		nfs-status, nfs-exportfs-list-rules,							#
#								      									#
#																		#
#																		#
# Copyright 2005 Network Appliance, Inc. All rights 	        		#
# reserved. Specifications subject to change without notice. 	    	#
#																		#
# This SDK sample code is provided AS IS, with no support or    		#
# warranties of any kind, including but not limited to		     		#
# warranties of merchantability or fitness of any kind,             	#
# expressed or implied.  This code is subject to the license        	#
# agreement that accompanies the SDK.				    				#
#=======================================================================#

require 5.6.1;
use lib "../../../../lib/perl/NetApp";  
use NaServer;
use NaElement;

# Variable declaration

my $args = $#ARGV + 1;
my $filer = shift;
my $user = shift;
my $pw	= shift;
my $cmd =shift;

# check for valid number of parameters
if ($args < 4)
{
	print_usage();
}

#Invoke routine to NFS operations
do_nfs();

#Do NFS Operations: enable, status, list rules
sub do_nfs(){
	
	my $out;
	my $s = NaServer->new ($filer, 1, 3);
	
	$out = $s->set_transport_type(HTTP);
	if (ref ($out) eq "NaElement") { 
		if ($out->results_errno != 0) {
			my $r = $out->results_reason();
			print "Connection to $filer failed: $r\n";
			exit (-2);
		}
	}
	$out = $s->set_style(LOGIN);
	if (ref ($out) eq "NaElement") { 
		if ($out->results_errno != 0) {
			my $r = $out->results_reason();
			print "Connection to $filer failed: $r\n";
			exit (-2);
		}
	}
	$out = $s->set_admin_user($user, $pw);
	
	if ($cmd eq "enable") {
		$out = $s->invoke( "nfs-enable" );
		if ($out->results_status() eq "failed"){
			print($out->results_reason() ."\n");
			exit (-2);
		}
		else {
			print "Operation successful\n";
		}
	} 
	elsif ($cmd eq "disable") {
		$out = $s->invoke( "nfs-disable" );
		if ($out->results_status() eq "failed"){
			print($out->results_reason() ."\n");
			exit (-2);
		}
		else {
			print "Operation successful\n";
		}
	}
	elsif ($cmd eq "status") {
		$out = $s->invoke( "nfs-status" );
		if ($out->results_status() eq "failed"){
			print($out->results_reason() ."\n");
			exit (-2);
		}
		my $enabled = $out->child_get_string("is-enabled");
		if ($enabled eq "true") {
			print "NFS Server is enabled\n";
		} 
		else {
			print "NFS Server is disabled\n";
		}
	} 
	elsif ($cmd eq "list") {
		$out = $s->invoke( "nfs-exportfs-list-rules" );
		my $export_info = $out->child_get("rules");
		my @result = $export_info->children_get();

		foreach $export (@result){
			my $path_name = $export->child_get_string("pathname");
			my $rw_list = "rw=";
			my $ro_list = "ro=";
			my $root_list = "root=";

			if($export->child_get("read-only")){
				my $ro_results = $export->child_get("read-only");
				my @ro_hosts = $ro_results->children_get();
			
				my $host_name;
				foreach $ro (@ro_hosts) {
					if($ro->child_get_string("all-hosts")){
						my $all_hosts = $ro->child_get_string("all-hosts");
						if($all_hosts eq "true") {
							$ro_list = $ro_list."all-hosts";
							break;
						}
					} 
					elsif($ro->child_get_string("name")) {
						$host_name = $ro->child_get_string("name");
						$ro_list = $ro_list.$host_name.":";
					}
				}
			}
			if($export->child_get("read-write")){
				my $rw_results = $export->child_get("read-write");
				my @rw_hosts = $rw_results->children_get();
					foreach $rw (@rw_hosts) {
						if($rw->child_get_string("all-hosts")){
							my $all_hosts = $rw->child_get_string("all-hosts");
							if($all_hosts eq "true") {
								$rw_list = $rw_list."all-hosts";
								break;
							}
						} 
						elsif($rw->child_get_string("name")) {
							$host_name = $rw->child_get_string("name");
							$rw_list = $rw_list.$host_name.":";
						}
					}
			}
			if($export->child_get("root")){
				my $root_results = $export->child_get("root");
				my @root_hosts = $root_results->children_get();
				
				foreach $root(@root_hosts) {
					if($root->child_get_string("all-hosts")){
						my $all_hosts = $root->child_get_string("all-hosts");
						if($all_hosts eq "true") {
							$root_list = $root_list."all-hosts";
							break;
						}
					} elsif($root->child_get_string("name")) {
						$host_name = $root->child_get_string("name");
						$root_list = $root_list.$host_name.":";
					}
				}
			}

			$path_name = $path_name. "  ";
			if($ro_list ne "ro=") {
				$path_name = $path_name.$ro_list;
			}
			if($rw_list ne "rw=") {
				$path_name = $path_name.",".$rw_list;
			}
			if($root_list ne "root=") {
				$path_name = $path_name.",".$root_list;
			}
			print "$path_name   \n";
		}

	} 
	else {
		print "Invalid operation\n";
		print_usage();
	}
	exit 0;	
}

sub print_usage()
{
	print "Usage:\n";
	print "nfs.pl <filer> <user> <password> <command>\n";
	print "<filer> -- Filer name\n";
	print "<user> -- User name\n";
	print "<password> -- Password\n";
	print "<command> -- enable, disable, status, list\n";
	exit 1;
}
#=========================== POD ============================#

=head1 NAME

  nfs.pl - Provides nfs group API operations

=head1 SYNOPSIS

  nfs.pl  <filer> <user> <password> <command>

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

