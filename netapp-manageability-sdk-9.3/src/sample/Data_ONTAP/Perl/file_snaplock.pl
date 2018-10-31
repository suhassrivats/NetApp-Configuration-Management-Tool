#===============================================================#
#						    	                                #
# $ID$						       		                        #
#							    	                            #
# file_snaplock.pl			       	     	                    #
#							    	                            #
# Sample code for the usage of following APIs: 		     	    #
#		file-get-snaplock-retention-time   		                #
#		file-snaplock-retention-time-list-info		            #
#		file-set-snaplock-retention-time		                #
#		file-get-snaplock-retention-time-list-info-max	        #
#							    	                            #
# Copyright 2005 Network Appliance, Inc. All rights	  	        #
# reserved. Specifications subject to change without notice.    #
#							    	                            #
# This SDK sample code is provided AS IS, with no support or    #
# warranties of any kind, including but not limited to          #
# warranties of merchantability or fitness of any kind,         #
# expressed or implied.  This code is subject to the license    #
# agreement that accompanies the SDK.				            #
#							    	                            #
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


#Invoke routine
main();

sub main() 
{
	# check for valid number of parameters
	if ($args < 4)
	{
		print_usage();
	}

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

	if($command eq "file-get-snaplock-retention-time")
	{
		file_get_retention($s);
	}
	elsif($command eq "file-set-snaplock-retention-time")
	{
		file_set_retention($s);
	}
	elsif($command eq "file-snaplock-retention-time-list-info")
	{
		file_get_retention_list($s);
	}
	elsif($command eq "file-get-snaplock-retention-time-list-info-max")
	{
		file_get_retention_list_info_max($s);
	}
	else
	{
		print "Invalid operation\n";
		print_usage();
	}
	exit 0;	
}


# file-snaplock-retention-time-list-info operation
# Usage: file_snaplock.pl <filer> <user> <password> file-snaplock-retention-time-list-info <filepath>
# <volumes>   
sub file_get_retention_list
{
	my $s = $_[0];
	my $i;
	
	
	if ($args < 5) 
	{
		print "Usage: file_snaplock.pl <filer> <user> <password> file-snaplock-retention-time-list-info";
		print " <filepathnames> \n";
		exit -1;
	}
	my $in = NaElement->new("file-snaplock-retention-time-list-info");
	
	my $pathnames = NaElement->new("pathnames");
	my $pathname_info = NaElement->new("pathname-info");

	#Now store rest of the volumes as a child element of pathnames
	# 
	#Here $no_of_vols stores the total  no of volumes 
	#Note:First volume is specified at 5th position from cmd prompt input
	
	foreach (@ARGV) { 
		$pathname_info->child_add_string("pathname",$_);
	}

	$pathnames->child_add($pathname_info);
	$in->child_add($pathnames);

	# 
	# Invoke API
	# 
	my $out = $s->invoke_elem($in);
	
	if($out->results_status() eq "failed")
	{
		print($out->results_reason() ."\n");
		exit(-2);
	}

	my $retention_info = $out->child_get("file-retention-details");
	my @result = $retention_info->children_get();
	
	foreach $path (@result){
		my $formatted_date = $path->child_get_string("formatted-retention-time");
		my $filepath = $path->child_get_string("pathname");
		print("Retention date for the file $filepath is $formatted_date\n");
	}
	print "\n";
}

# file-get-snaplock-retention-time operation
# Usage: file_snaplock.pl <filer> <user> <password> file-get-snaplock-retention-time <filepathnames>
 
sub file_get_retention
{
	my $s = $_[0];
	my $i;
	my $no_of_var_arguments;
		
	if ($args < 5) 
	{
		print "Usage: file_snaplock.pl <filer> <user> <password> file-get-snaplock-retention-time";
		print " <filepathnames> \n";
		exit -1;
	}
	my $in = NaElement->new("file-get-snaplock-retention-time");
	$path = @ARGV[0];
	
	$in->child_add_string("path",$path);

	# 
	# Invoke API
	# 
	my $out = $s->invoke_elem($in);
		
	if($out->results_status() eq "failed")
	{
		print($out->results_reason() ."\n");
		exit(-2);
	}

	my $retention_time = $out->child_get_int("retention-time");
	print "retention time: $retention_time\n";
	print "\n";
}

# file-set-snaplock-retention-time operation
# Usage: file_snaplock.pl <filer> <user> <password> file-set-snaplock-retention-time <filepathnames>
sub file_set_retention
{
	my $s = $_[0];
	my $i;
	my $retention_time;
	my $path;

	if ($args < 6) 
	{
		print "Usage: file_snaplock.pl <filer> <user> <password> file-set-snaplock-retention-time";
		print " <filepathnames> <retention-time>\n";
		exit -1;
	}
	$path = @ARGV[0];
	$retention_time = @ARGV[1];
	my $in = NaElement->new("file-set-snaplock-retention-time");
		
	$in->child_add_string("path",$path);
	$in->child_add_string("retention-time",$retention_time);

	

	# 
	# Invoke API
	# 
	my $out = $s->invoke_elem($in);
		
	if($out->results_status() eq "failed")
	{
		print($out->results_reason() ."\n");
		exit(-2);
	}
	print "\n";
}

# file-get-snaplock-retention-time-list-info-max operation
# Usage: file_snaplock.pl <filer> <user> <password> file-get-snaplock-retention-time <filepathnames>
 
sub file_get_retention_list_info_max
{
	my $s = $_[0];
	my $i;
		
	if ($args < 4) 
	{
		print "Usage: file_snaplock.pl <filer> <user> <password> file-get-snaplock-retention-time-list-info-max";
		exit -1;
	}
	my $in = NaElement->new("file-get-snaplock-retention-time-list-info-max");
		
	
	# 
	# Invoke API
	# 
	my $out = $s->invoke_elem($in);
	
	
	if($out->results_status() eq "failed")
	{
		print($out->results_reason() ."\n");
		exit(-2);
	}
	my $max_entries = $out->child_get_int("max-list-entries");
	print "Max number of records = $max_entries \n";
}



sub print_usage() 
{

	print "file_snaplock.pl <filer> <user> <password> <operation> <value1>";
	print "[<value2>]\n";
	print "<filer>     -- Filer name\n";
	print "<user>      -- User name\n";
	print "<password>  -- Password\n";
	print "<operation> -- Operation to be performed: \n";
	print "\tfile-get-snaplock-retention-time\n";
	print "\tfile-set-snaplock-retention-time\n";
	print "\tfile-snaplock-retention-time-list-info\n";
	print "\tfile-get-snaplock-retention-time-list-info-max\n";
	print "<value1>    -- Depends on the operation \n";
	print "[<value2>]  -- Depends on the operation \n";
	exit -1;
}

#=========================== POD ============================#

=head1 NAME

  file_snaplock.pl - Displays the usage of file_snaplock group APIs 

=head1 SYNOPSIS

  file_snaplock.pl <filer> <user> <password> <operation> <value1> [<value2>]

=head1 ARGUMENTS

  <filer>
   Filer name.

  <user>
  username.

  <password>
  password.

  <operation>
  Operation to be performed: file-get-snaplock-retention-time/file-set-snaplock-retention-time/file-snaplock-retention-time-list-info/file-get-snaplock-retention-time-list-info-max

  <value1>
  Depends on the operation

  [<value2>]
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

