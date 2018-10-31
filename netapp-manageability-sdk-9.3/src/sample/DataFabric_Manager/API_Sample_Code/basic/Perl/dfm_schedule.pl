#===============================================================#
#                                                               #
# $ID$                                                          #
#                                                               #
# dfm_schedule.pl                                               #
#                                                               #
# Copyright (c) 2009 NetApp, Inc. All rights reserved.          #
# Specifications subject to change without notice.              #
#                                                               #
# Sample code to demonstrate how to manage dfm schedule         #
# on a DFM server                                               #
# You can create, list and delete dfm schedules                 #
#                                                               #
# This Sample code is supported from DataFabric Manager 3.6R2   #
# onwards.                                                      #
# However few of the functionalities of the sample code may     #
# work on older versions of DataFabric Manager.                 #
#===============================================================#
use lib '../../../../../../lib/perl/NetApp';
use NaServer;
use NaElement;
use strict;

##### VARIABLES SECTION
my $args = $#ARGV + 1;
my ( $dfmserver, $dfmuser, $dfmpw, $dfmop, $dfmname, $dfmtype, @opt_param ) =
  @ARGV;

my $start_hour = undef;
my $start_minute  = undef;
my $day_of_week = undef;
my $day_of_month  = undef;
my $week_of_month = undef;
  
##### MAIN SECTION
# checking for valid number of parameters for the respective operations
usage()
  if ( ( $dfmop eq "list" and $args < 4 )
	or ( $dfmop eq "delete" and $args != 5 )
	or ( $dfmop eq "create" and $args < 6 ) );

# checking if the operation selected is valid
usage()
  if (  ( $dfmop ne "list" )
	and ( $dfmop ne "create" )
	and ( $dfmop ne "delete" ) );

# Checking if the type selected is valid
usage()
  if (  ( $dfmop eq "create" )
	and ( $dfmtype ne "daily" )
	and ( $dfmtype ne "weekly" )
	and ( $dfmtype ne "monthly" ) );

# parsing optional parameters
my $i = 0;
while ( $i < scalar(@opt_param) ) {
	if   ( $opt_param[$i]  eq '-h' ) { $start_hour    = $opt_param[ ++$i ]; ++$i; }
	elsif( $opt_param[$i]  eq '-m' ) { $start_minute  = $opt_param[ ++$i ]; ++$i; }
	elsif( $opt_param[$i]  eq '-d' ) { $day_of_week   = $opt_param[ ++$i ]; ++$i; }
	elsif( $opt_param[$i]  eq '-D' ) { $day_of_month  = $opt_param[ ++$i ]; ++$i; }
	elsif( $opt_param[$i]  eq '-w' ) { $week_of_month = $opt_param[ ++$i ]; ++$i; }
	else                             { usage(); };
}

# Creating a server object and setting appropriate attributes
my $serv = NaServer->new( $dfmserver, 1, 0 );
$serv->set_style("LOGIN");
$serv->set_transport_type("HTTP");
$serv->set_server_type("DFM");
$serv->set_port(8088);
$serv->set_admin_user( $dfmuser, $dfmpw );

# Calling the subroutines based on the operation selected
if   ( $dfmop eq 'create' ) { create($serv);      }
elsif( $dfmop eq 'list' )   { list($serv);        }
elsif( $dfmop eq 'delete' ) { del($serv);         }
else                        { usage(); };

##### SUBROUTINE SECTION

sub result {
	my $res = shift;

	# Checking for the string "passed" in the output
	my $r = ( $res =~ /passed/ ) ? "Successful" : "UnSuccessful";
	return $r;
}

sub create {

	# Reading the server object
	my $server = $_[0];

	# creating the input for api execution
	# creating a dfm-schedule-create element and adding child elements
	my $input    = NaElement->new("dfm-schedule-create");
	my $schedule = NaElement->new("schedule-content-info");
	$schedule->child_add_string( "schedule-name",     $dfmname );
	$schedule->child_add_string( "schedule-type",     $dfmtype );
	$schedule->child_add_string( "schedule-category", "dfm_schedule" );

	# creating a daily-list element
	if ( $dfmtype eq "daily" and ( $start_hour or $start_minute ) ) {
		my $daily      = NaElement->new("daily-list");
		my $daily_info = NaElement->new("daily-info");
		$daily_info->child_add_string( "start-hour", $start_hour )
		  if ($start_hour);
		$daily_info->child_add_string( "start-minute", $start_minute )
		  if ($start_minute);
		$daily->child_add($daily_info);

		# appending daily list to schedule
		$schedule->child_add($daily);
	}

	# creating a weekly-list element
	if ( $dfmtype eq "weekly"
		and ( $start_hour or $start_minute or $day_of_week ) )
	{
		my $weekly      = NaElement->new("weekly-list");
		my $weekly_info = NaElement->new("weekly-info");
		$weekly_info->child_add_string( "start-hour", $start_hour )
		  if ($start_hour);
		$weekly_info->child_add_string( "start-minute", $start_minute )
		  if ($start_minute);
		$weekly_info->child_add_string( "day-of-week", $day_of_week )
		  if ($day_of_week);
		$weekly->child_add($weekly_info);

		# appending weekly list to schedule
		$schedule->child_add($weekly);
	}

	# creating 2 monthly-list element
	if (
		$dfmtype eq "monthly"
		and (  $start_hour
			or $start_minute
			or $day_of_week
			or $day_of_month
			or $week_of_month )
	  )
	{
		my $monthly      = NaElement->new("monthly-list");
		my $monthly_info = NaElement->new("monthly-info");
		$monthly_info->child_add_string( "start-hour", $start_hour )
		  if ($start_hour);
		$monthly_info->child_add_string( "start-minute", $start_minute )
		  if ($start_minute);
		$monthly_info->child_add_string( "day-of-month", $day_of_month )
		  if ($day_of_month);
		$monthly_info->child_add_string( "day-of-week", $day_of_week )
		  if ($day_of_week);
		$monthly_info->child_add_string( "week-of-month", $week_of_month )
		  if ($week_of_month);
		$monthly->child_add($monthly_info);

		# appending monthly list to schedule
		$schedule->child_add($monthly);
	}

	# appending schedule to main input
	$input->child_add($schedule);

	# invoking the api and printing the xml ouput
	my $output = $server->invoke_elem($input);

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	print "\nSchedule creation " . result( $output->results_status() ) . "\n";
}

sub list {

	# Reading the server object
	my $server = $_[0];
	my $output;

	# invoking the api and capturing the ouput
	if ($dfmname) {
		$output = $server->invoke( "dfm-schedule-list-info-iter-start",
			"schedule-category", "dfm_schedule", "schedule-name-or-id",
			$dfmname );
	} else {
		$output = $server->invoke( "dfm-schedule-list-info-iter-start",
			"schedule-category", "dfm_schedule" );
	}
	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	# Extracting the record and tag values and printing them
	my $records = $output->child_get_string("records");

	print "\nNo schedules to display\n" if ( not $records );

	my $tag = $output->child_get_string("tag");

	# Extracting records one at a time
	my $record = $server->invoke( "dfm-schedule-list-info-iter-next",
		"maximum", $records, "tag", $tag );

	print( "Error : " . $record->results_reason() . "\n" ) and exit(-2)
	  if ( $record->results_status() eq "failed" );

	# Navigating to the schedule-content-list child element
	my $stat = $record->child_get("schedule-content-list")
	  or exit 0
	  if ($record);

	# Navigating to the schedule-info child element
	my @info = $stat->children_get() or exit 0 if ($stat);

	# Iterating through each record
	foreach my $info (@info) {

		# extracting the schedule details and printing it
		print "-" x 80 . "\n";
		print "Schedule Name : "
		  . $info->child_get_string("schedule-name") . "\n";
		print "Schedule Id : " . $info->child_get_string("schedule-id") . "\n";
		print "Schedule Description : "
		  . $info->child_get_string("schedule-description") . "\n";
		print "-" x 80 . "\n";

		# printing detials if only one schedule is selected for listing
		if ($dfmname) {
			print "\nSchedule Type        : "
			  . $info->child_get_string("schedule-type") . "\n";
			print "Schedule Category    : "
			  . $info->child_get_string("schedule-category") . "\n";
			my $type      = $info->child_get_string("schedule-type");
			my $type_list = $info->child_get("$type-list");
			if ($type_list) {
				my $type_info = $type_list->child_get("$type-info");
				if  ( $type  eq 'daily' )     {
					print "Item Id              : "
						. $type_info->child_get_string("item-id") . "\n";
					print "Start Hour           : "
						. $type_info->child_get_string("start-hour") . "\n";
					print "Start Minute         : "
						. $type_info->child_get_string("start-minute") . "\n";
				} elsif( $type  eq 'weekly' ) {
					print "Item Id              : "
						. $type_info->child_get_string("item-id") . "\n";
					print "Start Hour           : "
						. $type_info->child_get_string("start-hour") . "\n";
					print "Start Minute         : "
						. $type_info->child_get_string("start-minute") . "\n";
					print "Day Of Week          : "
						. $type_info->child_get_string("day-of-week") . "\n";
				} elsif( $type  eq 'monthly' ) {
					print "Item Id              : "
						. $type_info->child_get_string("item-id") . "\n";
					print "Start Hour           : "
						. $type_info->child_get_string("start-hour") . "\n";
					print "Start Minute         : "
						. $type_info->child_get_string("start-minute") . "\n";
					print "Day Of Week          : "
						. $type_info->child_get_string("day-of-week") . "\n";
					print "Week Of Month        : "
						. $type_info->child_get_string("week-of-month")
						. "\n";
					print "Day Of Month         : "
						. $type_info->child_get_string("day-of-month") . "\n";
				}
			}
		}
	}

	# invoking the iter-end zapi
	my $end =
	  $server->invoke( "dfm-schedule-list-info-iter-end", "tag", $tag );
	print( "Error : " . $end->results_reason() . "\n" ) and exit(-2)
	  if ( $end->results_status() eq "failed" );
}

sub del {

	# Reading the server object
	my $server = $_[0];

	# invoking the api and printing the xml ouput
	my $output =
	  $server->invoke( "dfm-schedule-destroy", "schedule-name-or-id", $dfmname,
		"schedule-category", "dfm_schedule" );

	print( "Error : " . $output->results_reason() . "\n" ) and exit(-2)
	  if ( $output->results_status() eq "failed" );

	print "\nSchedule deletion " . result( $output->results_status() ) . "\n";
}

sub usage {
	print <<MSG;

Usage:
dfm_schedule.pl <dfmserver> <user> <password> list [ <schedule> ]

dfm_schedule.pl <dfmserver> <user> <password> delete <schedule>

dfm_schedule.pl <dfmserver> <user> <password> create <schedule> daily
[ -h <shour> -m <sminute> ]

dfm_schedule.pl <dfmserver> <user> <password> create <schedule> weekly
[ -d <dweek>] [ -h <shour> -m <sminute> ]

dfm_schedule.pl <dfmserver> <user> <password> create <schedule> monthly
{ [ -D <dmonth> ] | [ -d <dweek> -w <wmonth> ] } [ -h <shour> -m <sminute>]

<operation>     -- create or delete or list
<schedule type> -- daily or weekly or monthly

<dfmserver> -- Name/IP Address of the DFM server
<user>      -- DFM server User name
<password>  -- DFM server User Password
<schedule>  -- Schedule name
<dmonth>    -- Day of the month. Range: [1..31]
<dweek>     -- Day of week for the schedule. Range: [0..6] (0 = "Sun")
<shour>     -- Start hour of schedule. Range: [0..23]
<sminute>   -- Start minute of schedule. Range: [0..59]
<wmonth>    -- A value of 5 indicates the last week of the month. Range: [1..5]

Note : Either <dweek> and <wmonth> should to be set, or <dmonth> should be set

MSG
	exit 1;
}

#=========================== POD ============================#

=head1 NAME

  dfm_schedule.pl - Manages dfm-schedule on a dfm server


=head1 SYNOPSIS

  dfm_schedule.pl <dfmserver> <user> <password> list [ <schedule> ]

  dfm_schedule.pl <dfmserver> <user> <password> delete <schedule>

  dfm_schedule.pl <dfmserver> <user> <password> create <schedule> daily
  [ -h <shour> ] [ -m <sminute> ]

  dfm_schedule.pl <dfmserver> <user> <password> create <schedule> weekly
  [ -d <dweek>] [ -h <shour> ] [ -m <sminute> ]

  dfm_schedule.pl <dfmserver> <user> <password> create <schedule> monthly
  { [ -D <dmonth> ] | [ -d <dweek> -w <wmonth> ] } [ -h <shour> ]
  [ -m <sminute> ]


=head1 ARGUMENTS

  <dfmserver>
   DFM server name.

  <user>
  DFM server username.

  <password>
  DFM server user password.

  {create | list | delete}
  Operation

  [ <Schedule name>]
  Name of the schedule

  [ daily | weekly | monthly ]
  Type of the schedule

  [ <day of month> ]
  Day of the month Range [0..31]

  [ <day of week> ]
  Day of week for the schedule. Range: [0..6] (0 = "Sun")

  [ <start hour> ]
  Start hour of schedule. Range: [0..23]

  [ <start minute> ]
  Start minute of schedule. Range: [0..59]

  [ <week of month> ]
  A value of 5 indicates the last week of the month. Range: [1..5]

=head1 SEE ALSO

  NaElement.pm, NaServer.pm

=head1 COPYRIGHT

 Copyright (c) 2009 NetApp, Inc. All rights reserved.
 Specifications subject to change without notice.

=cut

