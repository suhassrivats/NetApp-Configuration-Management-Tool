#===============================================================#
#								#
# $ID$								#
#								#
# flexclone.pl							#
#								#
# Sample code for the usage of flexclone:			#
# It demonstrates the following functions:			#
# create a clone for a flexible volume, estimate the size,      #
# split the clone and print the status of it.                   #
#                                                               #
#								#
# Copyright 2005 Network Appliance, Inc. All rights		#
# reserved. Specifications subject to change without notice.	#
#								#
# This SDK sample code is provided AS IS, with no support or	#
# warranties of any kind, including but not limited to		#
# warranties of merchantability or fitness of any kind,		#
# expressed or implied.  This code is subject to the license	#
# agreement that accompanies the SDK.				#
#								#
#===============================================================#

require 5.6.1;
use lib "../../../../lib/perl/NetApp";
use NaServer;
use NaElement;

# Variable declaration

my $args = $#ARGV + 1;
my $filer = shift;
my $user = shift;
my $pw  = shift;
my $command = shift;
my $clone_name = shift;
my $parent_vol = shift;

#Invoke routine
main();



sub main() 
{
	# check for valid number of parameters
	if ($args < 5) {
		print_usage();
	}
	elsif ( !(($command eq "create") || ($command eq "estimate") ||
		($command eq "split") || ($command eq "status"))) {
				printf("%s is not a valid command.\n",$command);
		print_usage();
	}

		
	if ( ($command eq "create") && ($parent_vol eq "")) {
		printf("%s operation requires <parent-volname>\n",$command);
		printf("Usage: flexclone.pl <filer> <user> <password> %s <clone-volname> <parent-volname>\n",$command);
		exit 2;
	}
	
	my $s = NaServer->new ($filer, 1, 3);
	my $resp = $s->set_style(LOGIN);
	if (ref ($resp) eq "NaElement" && $resp->results_errno != 0) {
		my $r = $resp->results_reason();
		print "Failed to set authentication style $r\n";
		exit 2;
	}
	$s->set_admin_user($user, $pw);
	
	$resp = $s->set_transport_type(HTTP);
	if (ref ($resp) eq "NaElement" && $resp->results_errno != 0) {
		my $r = $resp->results_reason();
		print "Unable to set HTTP transport $r\n";
		exit 2;
	}
	
	if($command eq "create") {
		create_flexclone($s,$parent_vol);
	}
	elsif($command eq "estimate") {
		estimate_flexclone_split($s);
	}
	elsif($command eq "split") {
		start_flexclone_split($s);
	}
	elsif($command eq "status")
	{
		flexclone_split_status($s);
	}
	else {
		print "Invalid operation\n";
		print_usage();
	}
	exit 0;	
}

sub create_flexclone
{
	my $s = $_[0];
	my $i;
	my $no_of_var_arguments;

	my $in = NaElement->new("volume-clone-create");
	$in->child_add_string("parent-volume",$parent_vol);
	$in->child_add_string("volume",$clone_name);

	#
	# Invoke volume-clone-create API
	#
	my $out = $s->invoke_elem($in);

	if($out->results_status() eq "failed") {
		print($out->results_reason() ."\n");
		exit(-2);
	}
	else {
		print("Creation of clone volume '$clone_name' has completed.\n");
	}

}

sub start_flexclone_split
{
	my $s = $_[0];

	my $in = NaElement->new("volume-clone-split-start");
	$in->child_add_string("volume",$clone_name);

	#
	# Invoke volume-clone-split-start API
	#
	my $out = $s->invoke_elem($in);

	if($out->results_status() eq "failed") {
		print($out->results_reason() ."\n");
		exit(-2);
	}
	else {
		print("Starting volume clone split on volume '$clone_name'.\nUse");
		print(" 'status' command to monitor progress\n");
	}
}

sub estimate_flexclone_split
{
	my $s = $_[0];

	my $in = NaElement->new("volume-clone-split-estimate");
	$in->child_add_string("volume",$clone_name);

	#
	# Invoke volume-clone-split-estimate API
	#
	my $out = $s->invoke_elem($in);

	if($out->results_status() eq "failed") {
		print($out->results_reason() ."\n");
		exit(-2);
	}
	else {
		my $clone_split_estimate = $out->child_get("clone-split-estimate");
		my $clone_split_estimate_info = $clone_split_estimate->child_get("clone-split-estimate-info");
		my $blk_estimate = $clone_split_estimate_info->child_get_int("estimate-blocks");
		# block estimate is given in no of 4kb blocks required 
		my $space_req_in_mb = ($blk_estimate*4*1024)/(1024*1024);
		print("An estimated of $space_req_in_mb MB available storage is required");
		print(" in the aggregate to split clone volume '$clone_name' from");
		print(" its parent.\n");
   }
}

sub flexclone_split_status
{
	my $s = $_[0];

	my $in = NaElement->new("volume-clone-split-status");
	$in->child_add_string("volume",$clone_name);

	#
	# Invoke volume-clone-split-status API
	#
	my $out = $s->invoke_elem($in);

	if($out->results_status() eq "failed") {
		print($out->results_reason() ."\n");
		exit(-2);
	}
	else {
		my $clone_split_details = $out->child_get("clone-split-details");
		my @result = $clone_split_details->children_get();
		print "\n---------------------------------------------------------------\n";
		foreach $clone (@result) {
			if($clone->child_get_string("name")) {
				$tmpCloneName = $clone->child_get_string("name");
			}
			if( $clone_name eq $tmpCloneName) {
				$blk_scanned = $clone->child_get_int("blocks-scanned");
				$blk_updated = $clone->child_get_int("blocks-updated");
				$inode_processed = $clone->child_get_int("inodes-processed");
				$inode_total = $clone->child_get_int("inodes-total");
				$inode_per_complete = $clone->child_get_int("inode-percentage-complete");
				print( "Volume '$clone_name', $inode_processed of $inode_total inodes processed");
				print(" ($inode_per_complete %).\n$blk_scanned blocks scanned. $blk_updated blocks updated.");
			}
		}
		print "\n----------------------------------------------------------------\n";
		
   }
}

sub print_usage() 
{

	print "Usage:flexclone.pl <filer> <user> <password> <command> <clone-volname>";
	print " [<volume>]\n";
	print "<filer>     -- Filer name\n";
	print "<user>      -- User name\n";
	print "<password>  -- Password\n";
	print "<command>   -- Possible commands are:\n";
	print "  create   - to create a new clone\n";
	print "  estimate - to estimate the size before splitting the clone\n";
	print "  split    - to split the clone \n";
	print "  status   - to get the clone split status\n";
	print "<clone-volname>    -- clone volume name \n";
	print "[<parent-volname] -- name of the parent volume to create the clone. \n";
	exit -1;
}

#=========================== POD ============================#

=head1 NAME

  flexclone.pl - Displays the usage of flexclone APIs 

=head1 SYNOPSIS

  flexclone.pl  <filer> <user> <password> <operation> <clone-volname> [<volume>]

=head1 ARGUMENTS

  <filer>
   Filer name.

  <user>
  username.

  <password>
  password.

  <operation>
  Operation to be performed: create/estimate/split/status

  <value1>
  Depends on the operation

  [<value2>]
  Depends on the operation

  [<volumes>]
  List of Volumes.Depends on the operation
	
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

