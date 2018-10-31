
#============================================================#
#							     *
# $Id$
#                                                            #
# snapman.pl                                                 #
#                                                            #
# Snapshot management using ONTAPI interfaces in Perl        #
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
) unless $ARGV[4];

our $opt = $ARGV[0];
our $filer = $ARGV[1];
our $user = $ARGV[2];
our $password = $ARGV[3];
our $vol = $ARGV[4];

our $s = NaServer->new($filer, 1, 1);
$s->set_admin_user($user, $password);

#
# snapshot-get-schedule
#
if ($opt eq "-g") {
	my $output = $s->invoke("snapshot-get-schedule", 
		"volume", $vol);
	if ($output->results_errno != 0) {
		my $r = $output->results_reason();
		print "snapshot-get-schedule failed: $r\n";
	}

	my $minutes = $output->child_get_int("minutes", 0);
	my $hours =   $output->child_get_int("hours", 0);
	my $days =    $output->child_get_int("days", 0);
	my $weeks =   $output->child_get_int("weeks", 0);

	my $whichhours = $output->child_get_string("which-hours");
	my $whichminutes = $output->child_get_string("which-minutes");

	printf("\n");
	printf("Snapshot schedule for volume %s on filer %s:\n", $vol, $filer);
	printf("\n");
	if ($minutes > 0) {
		printf("Snapshots are taken on minutes [%s] of each hour (%d kept)\n",
			$whichminutes, $minutes);
	}
	if ($hours > 0) {
		printf("Snapshots are taken on hours [%s] of each day (%d kept)\n", 
			$whichhours, $hours);
	}
	if ($days > 0) {
		printf("%d nightly snapshots are kept\n", $days);
	}
	if ($weeks) {
		printf("%d weekly snapshots are kept\n", $weeks);
	}

	if ($minutes == 0 && $hours == 0 && $days == 0 && $weeks == 0) {
		printf("No snapshot schedule\n");
	}
	printf("\n");
}

#
# snapshot-list-info
#
elsif ($opt eq "-l") {
	my $output = $s->invoke("snapshot-list-info", "volume", $vol);

	if ($output->results_errno != 0) {
		my $r = $output->results_reason();
		print "snapshot-list-info failed: $r\n";
	}

	# 
	# get snapshot list
	#
	my $snapshotlist = $output->child_get("snapshots");
	if (!defined($snapshotlist) || ($snapshotlist eq "")) {
		# no snapshots to report
		printf("No snapshots on volume %s \n\n", $vol);
		exit(0);
	}

	#
	# print header
	#
	printf("Snapshots on volume %s: \n\n", $vol);         
	printf("NAME                    DATE                    BUSY   NBLOCKS CUMNBLOCKS  DEPENDENCY\n");
	printf("-------------------------------------------------------------------------------------\n");

	# 
	# iterate through snapshot list
	#
	my @snapshots = $snapshotlist->children_get();
	foreach my $ss (@snapshots) {

		my $accesstime = $ss->child_get_int("access-time", 0);
		my $total =		 $ss->child_get_int("total", 0);
		my $cumtotal =   $ss->child_get_int("cumulative-total", 0);

		my $busy = ($ss->child_get_string("busy") eq "true");
		
		my $dependency = $ss->child_get_string("dependency");
		my $name =		 $ss->child_get_string("name");

		my $date = localtime($accesstime);

		#
		# print a line
		#
		printf("%-23s %-24s  %d %10d %10d  %s\n",
				$name,
				$date,
				$busy,
				$total,
				$cumtotal,
				$dependency); 
	}
}

#
# snapshot-create
#
elsif ($opt eq "-c") {
	
	die pod2usage( 
		verbose => 1
	) unless $ARGV[5];

	my $name = $ARGV[5];

	my $output = $s->invoke("snapshot-create",
				"volume", $vol,
				"snapshot", $name);

	if ($output->results_errno != 0) {
		my $r = $output->results_reason();
		print "snapshot-create failed: $r\n";
	}
}

#
# snapshot-rename
#
elsif ($opt eq "-r") {

	die pod2usage( 
		verbose => 1
	) unless $ARGV[6];

	my $currname = $ARGV[5];
	my $newname = $ARGV[6];

	my $output = $s->invoke("snapshot-rename",
				"volume", $vol,
				"current-name", $currname,
				"new-name", $newname);

	if ($output->results_errno != 0) {
		my $r = $output->results_reason();
		print "snapshot-rename failed: $r\n";
	}
}

#
# snapshot-delete
#
elsif ($opt eq "-d") {

	die pod2usage( 
		verbose => 1
	) unless $ARGV[5];

	my $name = $ARGV[5];

	my $output = $s->invoke("snapshot-delete",
				"volume", $vol,
				"snapshot", $name);

	if ($output->results_errno != 0) {
		my $r = $output->results_reason();
		print "snapshot-rename failed: $r\n";
	}
}

else {
	
	die pod2usage(verbose => 1);
}


#=========================== POD ============================#

=head1 NAME

  snapman.pl - Snapshot management using ONTAPI

=head1 SYNOPSIS

  snapman.pl <filer name> <user> <password>
  snapman.pl -g <filer> <user> <pw> <vol> 
			 -l <filer> <user> <pw> <vol> 
			 -c <filer> <user> <pw> <vol> <snapshotname> 
			 -r <filer> <user> <pw> <vol> <oldsnapshotname> <newname> 
			 -d <filer> <user> <pw> <vol> <snapshotname>
			 
  E.g. snapman.pl -l filer1 root 6a55w0r9 vol0

  Use -g to get the snapshot schedule
	  -l to list snapshot info 
	  -c to create a snapshot 
	  -r to rename one 
	  -d to delete one 


=head1 ARGUMENTS

  <option>
  -g, -l, -c, -r, or -d
  
  <filer Name>
  The name of the filer to test.

  <user>
  username.

  <password>
  password.

  <vol>
  Name of volume for this operation

  <snapshotname>
  Name of snapshot to create or delete

  <oldsnapshotname>
  Name of snapshot to rename

  <newsnapshotname>
  Name to rename snapshot to


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





