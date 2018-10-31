#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# snapvault.pl                                            #
#                                                            #
# Sample code for the following APIs: 	      #
#	snapvault-primary-snapshot-schedule-list-info		#
#	snapvault-secondary-relationship-status-list-iter-start	#
#	snapvault-secondary-relationship-status-list-iter-next	#
#	snapvault-secondary-relationship-status-list-iter-end	#
#                                                            #
# Copyright 2005 Network Appliance, Inc. All rights          #
# reserved. Specifications subject to change without notice. #
#                                                            #
# This SDK sample code is provided AS IS, with no support or #
# warranties of any kind, including but not limited to       #
# warranties of merchantability or fitness of any kind,      #
# expressed or implied.  This code is subject to the license #
# agreement that accompanies the SDK.                        #
#                                                            #
#============================================================#

require 5.6.1;
use lib "../../../../lib/perl/NetApp";  
use NaServer;
use NaElement;

# Variable declaration

my $argc = $#ARGV + 1;
my $filer = shift;
my $user = shift;
my $pw	= shift;
my $command = shift;
my $value = shift;

#Invoke routine
main();

sub main() 
{
	# check for valid number of parameters
	if ($argc < 4) 
	{
		print_usage();
	}

	my $s = NaServer->new ($filer, 1, 3);
	my $response = $s->set_style(LOGIN);
	if (ref ($response) eq "NaElement" && $response->results_errno != 0) 
	{
		my $r = $response->results_reason();
		print "Unable to set authentication style $r\n";
		exit 2;
	}
	$s->set_admin_user($user, $pw);
	$response = $s->set_transport_type(HTTP);
	if (ref ($response) eq "NaElement" && $response->results_errno != 0) 
	{
		my $r = $response->results_reason();
		print "Unable to set HTTP transport $r\n";
		exit 2;
	}
	
	if($command eq "scheduleList")
	{
		schedule_list($s);
	}
	elsif($command eq "relationshipStatus")
	{
		relationship_status($s);
	}
	else
	{
		print "Invalid operation \n";
		print_usage();
	}

	exit 0;	
}


# List the configured snapshot schedules
# Usage: snapshot.pl <filer> <user> <password> scheduleList [<value1(volume)>]
sub schedule_list
{
	my $s = $_[0];
	my $out;
	
	if (!$value) 
	{
		$out = $s->invoke("snapvault-primary-snapshot-schedule-list-info");
	}
	else
	{
		$out = $s->invoke("snapvault-primary-snapshot-schedule-list-info",
				"volume-name", $value);
	}

	if($out->results_status() eq "failed")
	{
		print($out->results_reason() ."\n");
		exit(-2);
	}

	my $schedules = $out->child_get("snapshot-schedules");
	my @result = $schedules->children_get();

	foreach $schedule (@result){
		print("Retention count: ");
		print($schedule->child_get_string("retention-count")."\n");
		
		print("Schedule name: ");
		print($schedule->child_get_string("schedule-name")."\n");

		print("Volume name: ".$schedule->child_get_string("volume-name")."\n");
		
		print "------------------------------------------------------------\n";
	}
}


# Usage: snapvault.pl <filer> <user> <password> relationshipStatus
sub relationship_status($)
{
	my $s = $_[0];
	my $records;
	my $tag;
	my $i;
	my @result;
	
	my $out = $s->invoke
		("snapvault-secondary-relationship-status-list-iter-start");

	if($out->results_status() eq "failed")
	{
		print($out->results_reason() ."\n");
		exit(-2);
	}

	print "-------------------------------------------------------------\n";
	$records = $out->child_get_string("records");
	print("Records: $records \n");

	$tag = $out->child_get_string("tag");
	print("Tag: $tag \n");
	print "-------------------------------------------------------------\n";

	for ($i = 0; $i < $records; $i++)
	{
		my $rec = $s->invoke
			("snapvault-secondary-relationship-status-list-iter-next",
				"maximum", 1, "tag", $tag);

		if($rec->results_status() eq "failed")
		{
			print($rec->results_reason() ."\n");
			exit(-2);
		}

		print("Records: ".$rec->child_get_string("records")."\n");

		my $statList = $rec->child_get("status-list");
		if(!($statList eq undef))
		{
			@result = $statList->children_get();
		}
		else
		{
			exit(0);
		}

		foreach $stat (@result)
		{
			print("Destination path: ");
			print($stat->child_get_string("destination-path")."\n");

			print("Destination system: ");
			print($stat->child_get_string("destination-system")."\n");

			print("Source path: ");
			print($stat->child_get_string("source-path")."\n");

			print("Source system: ");
			print($stat->child_get_string("source-system")."\n");

			print("State: ");
			print($stat->child_get_string("state")."\n");

			print("Status: ");
			print($stat->child_get_string("status")."\n");

			print("Source system: ");
			print($stat->child_get_string("source-system")."\n");

			print "--------------------------------------------------------\n";
		}
	}

	my $end = $s->invoke
		("snapvault-secondary-relationship-status-list-iter-end",
			"tag", $tag);
}

sub print_usage() 
{
	print "snapvault.pl <filer> <user> <password> <operation> [<value1>]\n";
	print "<filer> -- Filer name\n";
	print "<user> -- User name\n";
	print "<password> -- Password\n";
	print "<operation> -- Operation to be performed: ";
	print "scheduleList/relationshipStatus \n";
	print "[<value>] -- Depends on the operation\n";
	exit 1;
}

#=========================== POD ============================#

=head1 NAME

  snapvault.pl - List the configured snapshot schedules, Relationship status.

=head1 SYNOPSIS

  snapvault.pl  <filer> <user> <password> <operation> [<value>]

=head1 ARGUMENTS

  <filer>
   Filer name.

  <user>
  username.

  <password>
  password.

  <operation>
  Operation to be performed: scheduleList/relationshipStatus

  [<value>]
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

