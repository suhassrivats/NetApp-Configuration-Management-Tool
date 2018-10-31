#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# monitor_volume.pl                                          #
#                                                            #
# Monitors volume on a filer and sends e-mail on space usage #
# crossing threshold.        				     #
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
use Net::SMTP;
use Math::Round;
use NaServer;
use NaElement;

# Variable declaration

my $args = $#ARGV + 1;
my $user=shift;
my $pw  =shift;
my $filer;
my $poll_frequency ;
my $threshold ;
my @volumes ;
my $volume_name;
my $total_volume_size;
my $used_volume_size;
my $percent_space_avail;
my $mailserver;
my $to_addr;
my $from_addr;


if ($args < 2)
{
  print_usage() 
}


while(1){
monitor_volume();
sleep($poll_frequency);
}

# Monitors volume and invokes send_mail() on space usage 
# crossing threshold.

sub monitor_volume(){
	read_config_file();
	get_volume_info();
}


# Get volume information
# Math/Round.pm needs to be present in the perl library for this to work.

sub get_volume_info(){

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
	
	foreach $volume (@volumes) {
		my $out = $s->invoke( "volume-list-info",
					"volume", $volume );

	if ($out->results_status() eq "failed"){
		print($out->results_reason() ."\n");
		exit (-2);
	}

	my $volume_info = $out->child_get("volumes");
	my @result = $volume_info->children_get();

	foreach $vol (@result){
		my $size_total = $vol->child_get_int("size-total");
		#$total_volume_size = round((size_total)/(1024*1024));
		$total_volume_size = $size_total;
		my $size_used = $vol->child_get_int("size-used");
		$used_volume_size = round((size_used)/(1024*1024));
		$used_volume_size = $size_used;
		my $space_avail = ($total_volume_size - $used_volume_size);
		$percent_space_avail = round(($space_avail/$total_volume_size)*100);

		if ($percent_space_avail < $threshold){
		send_mail($volume);
		}
	}
	}
}

#Read configuration details from volume_config

sub read_config_file(){

	open (FILE,"volume_config");
	while(<FILE>){
	chomp($_);
	if($_ !~ /#/ && $_ ne ""){
	if($_ =~ /filers/) {
		@tmp = split("=", $_);
		$filer =$tmp[1];
	} elsif($_ =~ /frequency/){
		@tmp = split("=", $_);
		$poll_frequency = $tmp[1];
	} elsif($_ =~ /volume/) {
		@tmp = split("=", $_);
		@volumes = split(/,/,$tmp[1]);
	} elsif($_ =~ /threshold/){
		@tmp = split("=", $_);
		$threshold = $tmp[1];
	}elsif($_ =~ /mailserver/){
		@tmp = split("=", $_);
		$mailserver = $tmp[1];
	}elsif($_ =~ /to/){
		@tmp = split("=", $_);
		$to_addr= $tmp[1];
	}elsif($_ =~ /from/){
		@tmp = split("=", $_);
		$from_addr= $tmp[1];
		}
		}
	}
	close FILE;
}

# Send e-mail

sub send_mail(){
	my $vol= $_[0];
	my $subject = "Volume usage on filer : $filer";
	my $smtp = Net::SMTP->new($mailserver) or die $!;
	my $total_size_mb = round(($total_volume_size)/(1024 * 1024));
	my $used_size_mb = round(($used_volume_size)/(1024 * 1024)); 
	$smtp->mail( $from_addr );
	$smtp->to( $to_addr );
	$smtp->data();
	$smtp->datasend("To: $to_addr\n");
	$smtp->datasend("From: $from_addr\n");
	$smtp->datasend("Subject: $subject\n");
	$smtp->datasend("\n"); # done with header
	$smtp->datasend("Volume statistics for $vol" ."\n");
	$smtp->datasend("Total size 	   : $total_size_mb MB" ."\n");
	$smtp->datasend("Used size       : $used_size_mb MB" ."\n");
	$smtp->datasend("% space available: $percent_space_avail" ."\n");
	$smtp->dataend();
	$smtp->quit();
}

sub print_usage() 
{
	print "monitor_volume.pl  <user> <password> \n";
	print "<user> -- User name\n";
	print "<password> -- Password\n";
	exit 1;
}

#=========================== POD ============================#

=head1 NAME

  monitor_volume.pl -  Polls volume usage at regular intervals
  and sends e-mail on volume usage crossing threshold value.

=head1 SYNOPSIS

  monitor_volume.pl  <user> <password>

=head1 ARGUMENTS

  <user>
  username.

  <password>
  password.

  volume_config
  Config file specifying :
   Filer Name 
   Polling frequency
   Volume name to be monitored
   Threshold
   Mail Server 	
   E-Mail Address

=head1 EXAMPLE
 
  E-mail sent by monitor_volume.pl when volume 
  usage crosses 50% (threshold value). 

  From : monitor-volume@abc.com
  To   : admin@abc.com
  Subject: Volume usage on filer : test-filer.abc.com
  Volume statistics for vol0
  Total size 	   : 24465 MB
  Used size       :  12232 MB
  % space available: 50 % 

	
=head1 SEE ALSO

  NaElement.pm, NaServer.pm, Net::SMTP, Math::Round

=head1 COPYRIGHT

  Copyright 2005 Network Appliance, Inc. All rights
  reserved. Specifications subject to change without notice.

  This SDK sample code is provided AS IS, with no support or 
  warranties of any kind, including but not limited to 
  warranties of merchantability or fitness of any kind, 
  expressed or implied.  This code is subject to the license 
  agreement that accompanies the SDK.

=cut
