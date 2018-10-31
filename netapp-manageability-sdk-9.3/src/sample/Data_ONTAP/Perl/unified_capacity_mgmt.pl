#==============================================================#
#                                                              #
# $ID$                                                         #
#                                                              #
# user_capacity_mgmt.pl                                        #
#                                                              #
# This sample code demonstrates the usage of ONTAPI APIs       #   
# for doing capacity management for NetApp storage systems.    #
#                                                              #
# Copyright 2005 Network Appliance, Inc. All rights            #
# reserved. Specifications subject to change without notice.   #
#                                                              #
# This SDK sample code is provided AS IS, with no support or   #
# warranties of any kind, including but not limited to         #
# warranties of merchantability or fitness of any kind,        #
# expressed or implied.  This code is subject to the license   #
# agreement that accompanies the SDK.                          #
#                                                              #
#==============================================================#

require 5.6.1;
use lib "../../../../lib/perl/NetApp";  
use NaServer;
use NaElement;
use Math::BigInt; 

use constant RAID_OVERHEAD => 1;
use constant WAFL_OVERHEAD => 2;
use constant SYNC_MIRROR => 3;     


# Variable declaration

my $args = $#ARGV + 1;
my $filer = shift;
my $user = shift;
my $pw  = shift;
my $command = shift;


#Invoke routine
main();

sub main() 
{

	# check for valid number of parameters
	if ($args < 4) {
		print_usage();
	}
	my $s = NaServer->new ($filer, 1, 3);
	my $response = $s->set_style(LOGIN);
	if (ref ($response) eq "NaElement" && $response->results_errno != 0) {
		my $r = $response->results_reason();
		print "Unable to set authentication style $r\n";
		exit 2;
	}
	$s->set_admin_user($user, $pw);
	$response = $s->set_transport_type(HTTP);
	if (ref ($response) eq "NaElement" && $response->results_errno != 0) {
		my $r = $response->results_reason();
		print "Unable to set HTTP transport $r\n";
		exit 2;
	}
	

	if(($command eq "raw-capacity") || ($command eq "formatted-capacity")
		|| ($command eq "spare-capacity")) {
		calc_raw_fmt_spare_capacity($s);
	}
	elsif(($command eq "raid-overhead") || ($command eq "wafl-overhead")) {
		calc_raid_wafl_overhead($s);
	}
	elsif($command eq "allocated-capacity") {
		calc_allocated_capacity($s);
	}
	elsif($command eq "avail-user-data-capacity") {
		calc_avail_user_data_capacity($s);
	}
	elsif($command eq "provisioning-capacity") {
		calc_provisioning_capacity($s);
	}
	else {
		print "Invalid operation\n";
		print_usage();
	}
}

sub calc_allocated_capacity
{
	my $s = $_[0];
	my $total_alloc_cap = 0;
	my $out_str = "total";

	my $in = NaElement->new("aggr-space-list-info");
	if( $args > 4) {
		$in->child_add_string("aggregate",$ARGV[$i]);
		$out_str = "";
	}
	my $out = $s->invoke_elem($in);
	if($out->results_status() eq "failed") {
		print($out->results_reason() ."\n");
		exit(-2);
	}
	my $aggrs = $out->child_get("aggregates");
	my @result = $aggrs->children_get();

	foreach $aggr (@result){
		$total_alloc_cap+= $aggr->child_get_int("size-volume-allocated");
		
	}
	print "$out_str allocated capacity (bytes): $total_alloc_cap\n";
}

sub calc_avail_user_data_capacity
{
	my $s = $_[0];
	my $total_avail_udcap = 0;
	my $out_str = "total";
	my $in = NaElement->new("volume-list-info");
	
	if( $args > 4) {
		$in->child_add_string("volume",$ARGV[$i]);
		$out_str = "";
	}
	my $out = $s->invoke_elem($in);
	if($out->results_status() eq "failed") {
		print($out->results_reason() ."\n");
		exit(-2);
	}
	my $vols = $out->child_get("volumes");
	my @result = $vols->children_get();

	foreach $vol (@result){
		$total_avail_udcap+= $vol->child_get_int("size-available");
	}
	print "$out_str available user data capacity (bytes): $total_avail_udcap\n";
}

sub calc_raw_fmt_spare_capacity
{
	my $s = $_[0];
	my $total_raw_cap = 0;
	my $total_format_cap = 0;
	my $total_spare_cap = 0;
	my $out_str = "total";
	
	my $in = NaElement->new("disk-list-info");
	if( $args > 4) {
		if($command eq "spare-capacity") {
			print_usage();
		}
		$out_str = "";
		$in->child_add_string("disk",$ARGV[$i]);
	}
	my $out = $s->invoke_elem($in);
	if($out->results_status() eq "failed") {
		print($out->results_reason() ."\n");
		exit(-2);
	}
	my $disk_info = $out->child_get("disk-details");
	my @result = $disk_info->children_get();

	foreach $disk (@result){
		my $raid_state = $disk->child_get_string("raid-state");
		if($command eq "raw-capacity") {
			if($raid_state ne "broken") {
				$total_raw_cap+= $disk->child_get_int("physical-space");
			}
		}
		elsif($command eq "formatted-capacity") {
			if($raid_state ne "broken") {
				$total_format_cap+= $disk->child_get_int("used-space");
			}
		}
		elsif($command eq "spare-capacity") {
			if(($raid_state eq "spare") ||  ($raid_state eq "pending") || ($raid_state eq "reconstructing")) {
				$total_spare_cap+= $disk->child_get_int("used-space");
			}
		}
	}
	if($command eq "raw-capacity") {
		print "$out_str raw capacity (bytes): $total_raw_cap\n";
	}
	elsif($command eq "formatted-capacity") {
		print "$out_str formatted capacity (bytes): $total_format_cap\n";
	}
	elsif($command eq "spare-capacity") {
		print "$out_str spare capacity (bytes): $total_spare_cap\n";
	}
}

sub get_disk_used_space
{
	my $disk_name = shift;
	my $overhead = shift;
	my $s = shift;
	my $used_space = 0;
	
	my $in = NaElement->new("disk-list-info");
	$in->child_add_string("disk",$disk_name);
	
	my $out = $s->invoke_elem($in);
	if($out->results_status() eq "failed") {
		print($out->results_reason() ."\n");
		exit(-2);
	}
	my $disk_info = $out->child_get("disk-details");
	my $disk = $disk_info->child_get("disk-detail-info");
	my $raid_type = $disk->child_get_string("raid-type");
	
	if($overhead eq RAID_OVERHEAD) {
		if(($raid_type eq "parity") || ($raid_type eq "dparity")) {
			$used_space = $disk->child_get_int("used-space");
		}
	}
	elsif($overhead eq WAFL_OVERHEAD) {
		if($raid_type eq "data") {
			$used_space = $disk->child_get_int("used-space");
		}
	}
	elsif($overhead eq SYNC_MIRROR) {
		$used_space = $disk->child_get_int("used-space");
	}
	return $used_space;
}

sub calc_raid_wafl_overhead
{
	my $s = $_[0];
	my $total_raid_oh = 0;
	my $total_wafl_oh = 0;
	my $out_str = "total";
		
	my $in = NaElement->new("aggr-list-info");
	if( $args > 4) {
		$in->child_add_string("aggregate",$ARGV[$i]);
		$out_str = "";
	}
	$in->child_add_string("verbose","true");
	my $out = $s->invoke_elem($in);
	if($out->results_status() eq "failed") {
		print($out->results_reason() ."\n");
		exit(-2);
	}
	my $aggrs = $out->child_get("aggregates");
	my @aresult = $aggrs->children_get();
	
	foreach $aggr (@aresult){
		my $plexes = $aggr->child_get("plexes");
		if($plexes ne undef) {
			my @presult = $plexes->children_get();
			 my $numPlexes = 0;
			foreach $plex (@presult){
					 $numPlexes++;
					my $rgroups = $plex->child_get("raid-groups");
					if($rgroups ne undef) {
						my @rresult = $rgroups->children_get();
						foreach $rgroup (@rresult){
							my $disks = $rgroup->child_get("disks");
							if($disks ne undef) {
								my @dresult = $disks->children_get();
								foreach $disk (@dresult){
									my $disk_name = $disk->child_get_string("name");
									if($command eq "raid-overhead") {
										if($numPlexes == 1) {
											$total_raid_oh+= get_disk_used_space($disk_name,RAID_OVERHEAD,$s);
										}
										else {
											$total_raid_oh+=get_disk_used_space($disk_name,SYNC_MIRROR,$s);
										}
									}
									elsif($command eq "wafl-overhead") {
										$total_wafl_oh+= get_disk_used_space($disk_name,WAFL_OVERHEAD,$s);
									}
								}
							}
						}
					}
			}
		}
	}
	if($command eq "raid-overhead") {
		print "$out_str raid overhead (bytes): $total_raid_oh\n";
	}
	if($command eq "wafl-overhead") {
		$total_wafl_oh*=0.1;
		print "$out_str wafl overhead (bytes): $total_wafl_oh\n";
	}
}

sub calc_provisioning_capacity
{
my $s = $_[0];
	my $total_prov_cap = 0;
	my $out_str = "total";
	my $in = NaElement->new("aggr-list-info");
	
	if( $args > 4) {
		$in->child_add_string("aggregate",$ARGV[$i]);
		$out_str = "";
	}
	my $out = $s->invoke_elem($in);
	if($out->results_status() eq "failed") {
		print($out->results_reason() ."\n");
		exit(-2);
	}
	my $aggrs = $out->child_get("aggregates");
	my @result = $aggrs->children_get();

	foreach $aggr (@result){
		$total_prov_cap+= $aggr->child_get_int("size-available");
	}
	print "$out_str provisioning capacity (bytes): $total_prov_cap\n";
}

sub print_usage() 
{

	print "Usage: user_capacity_mgmt.pl <filer> <user> <password> <command> \n";
	print "<filer>     -- Name/IP address of the filer\n";
	print "<user>      -- User name\n";
	print "<password>  -- Password\n\n";
	print "Possible commands are:\n";
	print "raw-capacity [<disk>] \n";
	print "formatted-capacity [<disk>] \n";
	print "spare-capacity \n";
	print "raid-overhead [<aggregate>] \n";
	print "wafl-overhead [<aggregate>] \n";
	print "allocated-capacity [<aggregate>] \n";
	print "provisioning-capacity [<aggregate>] \n";
	print "avail-user-data-capacity [<volume>] \n";
	exit -1;
}

#=========================== POD ============================#

=head1 NAME

  user_capacity_mgmt.pl - Displays the usage of consistency group APIs 

=head1 SYNOPSIS

 user_capacity_mgmt.pl  <filer> <user> <password> <command> [<optional-args>]

=head1 ARGUMENTS

  <filer>
   Filer name.

  <user>
  username.

  <password>
  password.

  <command>
  Operation to be performed: raw-capacity/formatted-capacity/spare-capacity etc.

  <optional-args>
  Depends on the operation

  
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

