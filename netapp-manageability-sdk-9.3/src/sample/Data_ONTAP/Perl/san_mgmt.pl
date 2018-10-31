#============================================================#
#                                                            #
# $ID$                                                       #
#                                                            #
# san_mgmt.pl                                                #
#                                                            #
# Application which uses ONTAPI APIs to perform SAN          #
# management operations for lun/igroup/fcp/iscsi             #
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
my $args = $#ARGV + 1;
my $filer = shift;
my $user = shift;
my $pw = shift;
my $command  = shift;

main();

sub main()
{
	# check for valid number of parameters
	if ($args < 3) {
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


	#process the given command
	if($command eq "lun") {
			process_LUN($s);
	}	
	elsif($command eq "igroup") {
			process_igroup($s);
	}
	elsif ($command eq "fcp") {
		process_fcp($s);
	}
	elsif ($command eq "iscsi") {
		process_iscsi($s);
	}
	else {
		print_usage();
	}
 }

 #process LUN operations
sub process_LUN {
	my $s = $_[0];
	my $index = 0;
	my $args = $#ARGV + 1;
	my $path = "";
	my $sre = "";
	my $type = "";
 
	if($ARGV[$index] eq "create") {
		if($args < 4) {
			print_LUN_create_usage();
			exit -1;
		}
		my $in = NaElement->new("lun-create-by-size");
		++$index;
		$in->child_add_string("path",$ARGV[$index++]);
		$in->child_add_string("size",$ARGV[$index++]);
		$in->child_add_string("type",$ARGV[$index++]);
		
		if($ARGV[$index] eq "-sre") {
			$in->child_add_string("space-reservation-enabled",$ARGV[++$index]);
			++$index;
		}
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
			print($out->results_reason() ."\n");
			exit(-2);
		}
		else {
			print "Operation successful!\n";
		}
	} #if($ARGV[$index] eq "create") {
	elsif($ARGV[$index] eq "destroy") {
		if(($args < 2) || ($args == 2 && $ARGV[$index+1] eq "-f")) {
			print "Usage: sanmgmt.pl <filer> <user> <passwd> lun destroy [-f] <lun-path> \n\n";
			print "If -f is used, the LUN specified would be deleted even in ";
			print "online and/or mapped state.\n";
			exit -1;
		}
		my $in = NaElement->new("lun-destroy");
		++$index;
		if($ARGV[$index] eq "-f") {
			$in->child_add_string("force","true");
			++$index;
		}
		$in->child_add_string("path",$ARGV[$index++]);
		
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
		   print($out->results_reason() ."\n");
		   exit(-2);
		}
		else {
			print "Operation successful!\n";
		}
	} #elsif($ARGV[$index] eq "destroy") {
	elsif($ARGV[$index] eq "show") {
		my $in = NaElement->new("lun-list-info");
		if($args > 1) {
			if($ARGV[$index+1] eq "help") {
				print "Usage: sanmgmt.pl <filer> <user> <passwd> lun show [<lun-path>] \n";
				exit -1;
			}
			$in->child_add_string("path",$ARGV[++$index]);
		}
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
		   print($out->results_reason() ."\n");
		   exit(-2);
		}
		my $lun_info = $out->child_get("luns");
		my @result = $lun_info->children_get();
		print "\n";
		foreach $lun (@result){
			my $path = $lun->child_get_string("path");
			print  "path: $path \n";
			my $size = $lun->child_get_string("size");
			print  "size: $size\n";
			my $online = $lun->child_get_string("online");
			print  "online: $online \n";
			my $mapped = $lun->child_get_string("mapped");
			print  "mapped: $mapped \n";
			my $uuid = $lun->child_get_string("uuid");
			print  "uuid: $uuid \n";
				my $ser_num = $lun->child_get_string("serial-number");
			print  "serial-number: $ser_num \n";
				my $blk_size = $lun->child_get_string("block-size");
			print  "block-size: $blk_size \n";
			my $is_sre = $lun->child_get_string("is-space-reservation-enabled");
			print  "is-space-reservation-enabled: $is_sre \n";

			my $type = $lun->child_get_string(" multiprotocol-type");
			print  "multiprotocol-type: $type \n";
			print "--------------------------------------\n";
		}
	} #elsif($ARGV[$index] eq "list") {
	elsif($ARGV[$index] eq "clone") {
		if($args < 2) {
			print_clone_usage();
			exit -1;
		}
		++$index;
		if($ARGV[$index] eq "create") {
			if($args < 5) {
				print "Usage: sanmgmt.pl <filer> <user> <password> lun clone ";
				print "create <parent-lun-path> <parent-snapshot> <path> ";
				print "[-sre <space-res-enabled>] \n";
				exit -1;
			}
			my $in = NaElement->new("lun-create-clone");
			$in->child_add_string("parent-lun-path",$ARGV[++$index]);
			$in->child_add_string("parent-snap",$ARGV[++$index]);
			$in->child_add_string("path",$ARGV[++$index]);
			if($ARGV[++$index] eq "-sre") {
				$in->child_add_string("space-reservation-enabled",$ARGV[++$index]);
			}
			my $out = $s->invoke_elem($in);
			if($out->results_status() eq "failed") {
			   print($out->results_reason() ."\n");
				exit(-2);
			}
			else {
				print "Operation successful!\n";
			}
		}
		elsif($ARGV[$index] eq "status") {

			my $in = NaElement->new("lun-clone-status-list-info");
			if($args > 2) {
				if($ARGV[$index+1] eq "help") {
					print "Usage: sanmgmt.pl <filer> <user> <password> lun ";
					print "clone status [<lun-path>] \n";
					exit -1;
				}
				$in->child_add_string("path",$ARGV[++$index]);
			}
			my $out = $s->invoke_elem($in);
			if($out->results_status() eq "failed") {
			   print($out->results_reason() ."\n");
				exit(-2);
			}
			my $clone_info = $out->child_get("clone-status");
			my @result = $clone_info->children_get();
			print "\n";
			foreach $clone (@result){
				my $path = $clone->child_get_string("path");
				print  "path: $path \n";
				my $blks_cmp = $clone->child_get_string("blocks-completed");
				print  "blocks-completed: $blks_cmp \n";
				my $blks_total = $clone->child_get_string("blocks-total");
				print  "blocks-total: $blks_total \n";
				print "--------------------------------------\n";
			}
		}
		elsif($ARGV[$index] eq "start") {
			my $in = NaElement->new("lun-clone-start");
			
			if(($args <3) || ($ARGV[$index+1] eq "help")) {
				print "Usage: sanmgmt.pl <filer> <user> <password> lun ";
				print "clone start <lun-path> \n";
				exit -1;
			}
			if($args > 2) {
				$in->child_add_string("path",$ARGV[++$index]);
			}
			my $out = $s->invoke_elem($in);
			if($out->results_status() eq "failed") {
			   print($out->results_reason() ."\n");
				exit(-2);
			}
			else {
				print "Operation successful!\n";
			}
		}
		elsif($ARGV[$index] eq "stop") {
			my $in = NaElement->new("lun-clone-stop");
			if(($args <3) || ($ARGV[$index+1] eq "help")) {
				print "Usage: sanmgmt.pl <filer> <user> <password> lun ";
				print "clone stop <lun-path> \n";
				exit -1;
			}
			if($args > 2) {
				$in->child_add_string("path",$ARGV[++$index]);
			}
			my $out = $s->invoke_elem($in);
			if($out->results_status() eq "failed") {
			   print($out->results_reason() ."\n");
				exit(-2);
			}
			else {
				print "Operation successful!\n";
			}
		}
		else {
		print_clone_usage();
		}
	} #if($ARGV[$index] eq "clone") {
	elsif($ARGV[$index] eq "map") {
		if($args < 3) {
			print "Usage: sanmgmt.pl <filer> <user> <password> lun map ";
			print "<initiator-group> <lun-path> [-f <force>] [-id <lun-id>]\n";
			exit -1;
		}
		my $in = NaElement->new("lun-map");
		$in->child_add_string("initiator-group",$ARGV[++$index]);
		$in->child_add_string("path",$ARGV[++$index]);
		
		if($ARGV[$index] eq "-f") {
		  $in->child_add_string("force",$ARGV[++$index]);
		  ++$index;
		}
		if($ARGV[$index] eq "-id") {
		  $in->child_add_string("lun-id",$ARGV[++$index]);
		  ++$index;
		}
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
			print($out->results_reason() ."\n");
			exit(-2);
		}
		else {
			print "Operation successful!\n";
		}	
	} #elsif($ARGV[$index] eq "map") {
	elsif($ARGV[$index] eq "unmap") {
		if($args < 3) {
			print "Usage: sanmgmt.pl <filer> <user> <password> lun unmap ";
			print "<initiator-group> <lun-path> \n";
			exit -1;
		}
		my $in = NaElement->new("lun-map");
		$in->child_add_string("initiator-group",$ARGV[++$index]);
		$in->child_add_string("path",$ARGV[++$index]);
		
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
			print($out->results_reason() ."\n");
			exit(-2);
		}
		else {
			print "Operation successful!\n";
		}
	} #elsif($ARGV[$index] eq "unmap")  {
	elsif($ARGV[$index] eq "show-map") {
		my $in = NaElement->new("lun-map-list-info");
		if($args < 2) {
			print "Usage: sanmgmt.pl <filer> <user> <password> lun show-map <lun-path> \n";
			exit -1;
		}
		$in->child_add_string("path",$ARGV[++$index]);
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
		   print($out->results_reason() ."\n");
		   exit(-2);
		}
		my $inititorgr_info = $out->child_get("initiator-groups");
		my @result = $inititorgr_info->children_get();
		print "\n";
		foreach $initiatorgr (@result){
			my $gname = $initiatorgr->child_get_string("initiator-group-name");
			print  "initiator-group-name: $gname \n";
			my $ostype = $initiatorgr->child_get_string("initiator-group-os-type");
			print  "initiator-group-os-type: $ostype\n";
			my $gtype = $initiatorgr->child_get_string("initiator-group-type");
			print  "initiator-group-type: $gtype \n";
			my $alua = $initiatorgr->child_get_string("initiator-group-alua-enabled");
			print  "initiator-group-alua-enabled: $alua \n";
			my $lunid = $initiatorgr->child_get_string("lun-id");
			if($lunid ne "") {
				print  "lun-id: $lunid \n";
			}
			my $initiators = $initiatorgr->child_get("initiators");
			if($initiators ne undef) {
				my @iresult = $initiators->children_get();
				print  "initiator-name(s):\n";
				foreach $initiator(@iresult){
					my $iname = $initiator->child_get_string("initiator-name");
					print  "  $iname\n";	
				}
			}
			print "--------------------------------------\n";
		}
	} #elsif($ARGV[$index] eq "show-map") {
	else {
		print_LUN_usage();
		exit -1;
	  }
}

sub process_igroup {
	my $s = $_[0];
	my $index = 0;
	my $args = $#ARGV + 1;
	my $path = "";
	my $sre = "";
	my $type = "";
 
	if($ARGV[$index] eq "create") {
		if($args < 3) {
			print "Usage: sanmgmt.pl <filer> <user> <passwd> igroup create ";
			print "<igroup-name> <igroup-type> [-bp <bind-portset>] ";
			print "[-os <os-type>] \n\n";
			print "igroup-type: fcp/iscsi \n";
			print "os-type: solaris/windows/hpux/aix/linux. ";
			print "If not specified, \"default\" is used. \n";
			exit -1;
		}
		my $in = NaElement->new("igroup-create");
		$in->child_add_string("initiator-group-name",$ARGV[++$index]);
		$in->child_add_string("initiator-group-type",$ARGV[++$index]);
		++$index;
		if($ARGV[$index] eq "-bp") {
			$in->child_add_string("bind-portset",$ARGV[++$index]);
		}
		if($ARGV[++$index] eq "-os") {
			$in->child_add_string("os-type",$ARGV[++$index]);
			++$index;
		}
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
			print($out->results_reason() ."\n");
			exit(-2);
		}
		else {
			print "Operation successful!\n";
		}
	} #iif($ARGV[$index] eq "create") {
	elsif($ARGV[$index] eq "destroy") {
		if($args < 2) {
			print "Usage: sanmgmt.pl <filer> <user> <passwd> igroup destroy ";
			print "<igroup-name> [-f <force>] \n";
			exit -1;
		}
		my $in = NaElement->new("igroup-destroy");
		$in->child_add_string("initiator-group-name",$ARGV[++$index]);
		if($ARGV[++$index] eq "-f") {
			$in->child_add_string("force",$ARGV[++$index]);
		}
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
			print($out->results_reason() ."\n");
			exit(-2);
		}
		else {
			print "Operation successful!\n";
		}
	} #iif($ARGV[$index] eq "destroy") {
	elsif($ARGV[$index] eq "show") {
		if($ARGV[$index+1] eq "help") {
			print "Usage: sanmgmt.pl <filer> <user> <password> ";
			print "lun show [<lun-path>] \n";
			exit -1;
		}
		my $in = NaElement->new("igroup-list-info");
		if($args > 1) {
			$in->child_add_string("initiator-group-name",$ARGV[++$index]);
		}
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
		   print($out->results_reason() ."\n");
		   exit(-2);
		}
		my $igroup_info = $out->child_get("initiator-groups");
		my @result = $igroup_info->children_get();
		print "\n";
		foreach $igroup (@result){
			my $name = $igroup->child_get_string("initiator-group-name");
			print  "initiator-group-name: $name \n";
			my $ostype = $igroup->child_get_string("initiator-group-os-type");
			print  "initiator-group-os-type: $ostype\n";
			my $type = $igroup->child_get_string("initiator-group-type");
			print  "initiator-group-type: $type \n";
			my $lunid = $igroup->child_get_string("lun-id");
			if($lunid ne "") {
				print  "lun-id: $lunid \n";
			}
			my $initiators = $igroup->child_get_string("initiators");
			if($initiators ne undef) {
				my @iresult = $initiators->children_get();
				print  "initiator-name(s):\n";
				foreach $initiator(@iresult){
					my $iname = $initiator->child_get_string("initiator-name");
					print  "  $iname\n";	
				}
			}
			print "--------------------------------------\n";
		}
	} #elsif($ARGV[$index] eq "add") {
	elsif($ARGV[$index] eq "add") {
		if(($args < 3) || ($args == 3 && $ARGV[$index+1] eq "-f")) {
			print "Usage: sanmgmt.pl <filer> <user> <passwd> igroup add ";
			print "[-f] <igroup-name> <initiator> \n\n";
			print "-f: forcibly add the initiator, disabling mapping ";
			print "and type conflict checks with the cluster partner.\n";
			exit -1;
		}
		my $in = NaElement->new("igroup-add");
		++$index;
		if($ARGV[$index] eq "-f") {
			$in->child_add_string("force","true");
			++$index;
		}
		$in->child_add_string("initiator-group-name",$ARGV[$index++]);
		$in->child_add_string("initiator",$ARGV[$index++]);
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
		   print($out->results_reason() ."\n");
		   exit(-2);
		}
		else {
			print "Operation successful!\n";
		}
	} #elsif($ARGV[$index] eq "add") {
	else {
		print_igroup_usage();
	}
}
	
sub process_fcp
 {
	my $s = $_[0];
	my $index = 0;
	my $args = $#ARGV + 1;
	my $path = "";
	my $sre = "";
	my $type = "";
 
	if($ARGV[$index] eq "start") {
		my $in = NaElement->new("fcp-service-start");
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
			print($out->results_reason() ."\n");
			exit(-2);
		}
		else {
			print "Operation successful!\n";
		}
	} #iif($ARGV[$index] eq "start") {
	elsif($ARGV[$index] eq "stop") {
		my $in = NaElement->new("fcp-service-stop");
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
			print($out->results_reason() ."\n");
			exit(-2);
		}
		else {
			print "Operation successful!\n";
		}
	} #iif($ARGV[$index] eq "stop") {
	elsif($ARGV[$index] eq "status") {
		my $in = NaElement->new("fcp-service-status");
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
		   print($out->results_reason() ."\n");
		   exit(-2);
		}
		if($out->child_get_string("is-available") eq "true") {
			print "FCP service is running.\n";
		}
		else {
			printf("FCP service is not running.\n");
		}
		
	} #elsif($ARGV[$index] eq "status") {
	elsif($ARGV[$index] eq "config") {
		if(($args < 3) || ($ARGV[$index+1] eq "help")) {
			print_fcp_config_usage();
		}
		my $in;
		$index+=2;
		if($ARGV[$index] eq "up") {
			$in = NaElement->new("fcp-adapter-config-up");
			$in->child_add_string("fcp-adapter",$ARGV[$index-1]);
		}
		elsif($ARGV[$index] eq "down") {
			$in = NaElement->new("fcp-adapter-config-down");
			$in->child_add_string("fcp-adapter",$ARGV[$index-1]);
		}
		elsif($ARGV[$index] eq "mediatype") {
			$in = NaElement->new("fcp-adapter-config-media-type");
			$in->child_add_string("fcp-adapter",$ARGV[$index-1]);
			$in->child_add_string("media-type",$ARGV[++$index]);
		}
		elsif($ARGV[$index] eq "speed") {
			$in = NaElement->new("fcp-adapter-set-speed");
			$in->child_add_string("fcp-adapter",$ARGV[$index-1]);
			$in->child_add_string("speed",$ARGV[++$index]);
		}
		else {
			print_fcp_config_usage();
		}
		 my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
		   print($out->results_reason() ."\n");
		   exit(-2);
		}
		else {
			print "Operation successful!\n";
		}
		
	} #elsif($ARGV[$index] eq "config") {
	elsif($ARGV[$index] eq "show") {
		if($ARGV[$index+1] eq "help") {
			print "Usage: sanmgmt.pl <filer> <user> <password> ";
			print "fcp show [<fcp-adapter>] \n";
			exit -1;
		}
		my $in = NaElement->new("fcp-adapter-list-info");
		if($args > 1) {
			$in->child_add_string("fcp-adapter",$ARGV[++$index]);
		}
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
		   print($out->results_reason() ."\n");
		   exit(-2);
		}
		my $adapter_info = $out->child_get("fcp-config-adapters");
		my @result = $adapter_info->children_get();
		print "\n";
		foreach $adapter (@result){
			my $adapter_name = $adapter->child_get_string("adapter");
			print  "adapter: $adapter_name \n";
			my $nodename = $adapter->child_get_string("node-name");
			print  "node-name: $nodename\n";
			my $port = $adapter->child_get_string("port-name");
			print  "port-name: $port \n";
			my $addr = $adapter->child_get_string("port-address");
			print  "port-address: $addr \n";
			my $adapter_type = $adapter->child_get_string("adapter-type");
			print  "adapter-type: $adapter_type \n";
			my $media_type = $adapter->child_get_string("media-type");
			print  "media-type: $media_type \n";	
			my $speed = $adapter->child_get_string("speed");
			print  "speed: $speed \n";		
			my $partner = $adapter->child_get_string("partner-adapter");
			print  "partner-adapter: $partner \n";	
			my $standby = $adapter->child_get_string("standby");
			print  "standby: $standby \n";			
			print "--------------------------------------\n";
		}
	} #elsif($ARGV[$index] eq "show") {
	else {
		print_fcp_usage();
	}
}

sub process_iscsi
 {
	my $s = $_[0];
	my $index = 0;
	my $args = $#ARGV + 1;
	my $path = "";
	my $sre = "";
	my $type = "";
 
	if($ARGV[$index] eq "start") {
		my $in = NaElement->new("iscsi-service-start");
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
			print($out->results_reason() ."\n");
			exit(-2);
		}
		else {
			print "Operation successful!\n";
		}
	} #  if($ARGV[$index] eq "start") {
	elsif($ARGV[$index] eq "stop") {
		my $in = NaElement->new("iscsi-service-stop");
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
			print($out->results_reason() ."\n");
			exit(-2);
		}
	} # elsif($ARGV[$index] eq "stop") {
	elsif($ARGV[$index] eq "status") {
		my $in = NaElement->new("iscsi-service-status");
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
		   print($out->results_reason() ."\n");
		   exit(-2);
		}
		if($out->child_get_string("is-available") eq "true") {
			print "iSCSI service is running.\n";
		}
		else {
			printf("iSCSI service is not running.\n");
		}
		
	} # elsif($ARGV[$index] eq "status") {
	elsif($ARGV[$index] eq "interface") {
		if(($args < 2) || ($ARGV[$index+1] eq "help")) {
			print_iscsi_interface_usage();
		}
		my $in;
		$index++;
		if($ARGV[$index] eq "enable") {
			if($args < 3) {
				print "Usage: sanmgmt.pl <filer> <user> <password> iscsi ";
				print " interface enable <interface-name>\n";
				exit -1;
			}
			$in = NaElement->new("iscsi-interface-enable");
			$in->child_add_string("interface-name",$ARGV[++$index]);
			 my $out = $s->invoke_elem($in);
			if($out->results_status() eq "failed") {
			   print($out->results_reason() ."\n");
			   exit(-2);
			}
			else {
				print "Operation successful!\n";
			}
		} #if($ARGV[$index] eq "enable") {
		elsif($ARGV[$index] eq "disable") {
			if($args < 3) {
				print "Usage: sanmgmt.pl <filer> <user> <password> iscsi ";
				print " interface disable <interface-name>\n";
				exit -1;
			}
			$in = NaElement->new("iscsi-interface-disable");
			$in->child_add_string("interface-name",$ARGV[++$index]);
			 my $out = $s->invoke_elem($in);
			if($out->results_status() eq "failed") {
				print($out->results_reason() ."\n");
				exit(-2);
			}
			else {
				print "Operation successful!\n";
			}
		} #elsif($ARGV[$index] eq "disable") {
		elsif($ARGV[$index] eq "show") {
			$index++;
			$in = NaElement->new("iscsi-interface-list-info");
			if($args > 2) {
				if($ARGV[$index] eq "help") {
					print "Usage: sanmgmt.pl <filer> <user> <password> iscsi ";
					print " interface show [<interface-name>]\n";	
					exit -1;
				}
				else {
					$in->child_add_string("interface-name",$ARGV[++$index]);
				}
			}
			my $out = $s->invoke_elem($in);
			if($out->results_status() eq "failed") {
				print($out->results_reason() ."\n");
				exit(-2);
			}
			my $iscsi_interface_info = $out->child_get("iscsi-interface-list-entries");
			my @result = $iscsi_interface_info->children_get();
			print "\n";
			print "------------------------------------------------------\n";
			foreach $interface (@result){
				my $name = $interface->child_get_string("interface-name");
				print  "interface-name: $name \n";
				my $enabled = $interface->child_get_string("is-interface-enabled");
				print  "is-interface-enabled: $enabled\n";
				my $tpgroup = $interface->child_get_string("tpgroup-name");
				print  "tpgroup-name: $tpgroup \n";
				print "------------------------------------------------------\n";
			}
		} #elsif($ARGV[$index] eq "show") {
		else {
			print_iscsi_interface_usage();
		}
		 my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
		   print($out->results_reason() ."\n");
		   exit(-2);
		}
	} #elsif($ARGV[$index] eq "interface")  {
	elsif($ARGV[$index] eq "show") {
		$index++;
		if(($args < 2) || ($ARGV[$index] ne "initiator")) {
			print "Usage: sanmgmt.pl <filer> <user> <password> iscsi ";
			print "show initiator \n";
			exit -1;
		}
		my $in = NaElement->new("iscsi-initiator-list-info");
		my $out = $s->invoke_elem($in);
		if($out->results_status() eq "failed") {
		   print($out->results_reason() ."\n");
		   exit(-2);
		}
		my $inititor_info = $out->child_get("iscsi-initiator-list-entries");
		my @result = $inititor_info->children_get();
		print "\n";
		foreach $initiator (@result){
			my $alname = $initiator->child_get_string("initiator-aliasname");
			print  "initiator-aliasname: $alname \n";
			my $nodename = $initiator->child_get_string("initiator-nodename");
			print  "initiator-nodename: $nodename\n";
			my $isid = $initiator->child_get_string("isid");
			print  "isid: $isid \n";
			my $ssid = $initiator->child_get_string("target-session-id");
			print  "target-session-id: $ssid \n";
			my $tptag = $initiator->child_get_int("tpgroup-tag");
			print  "tpgroup-tag: $tptag \n";
			print "--------------------------------------\n";
		}
	} #elsif($ARGV[$index] eq "show")  {
	else {
		print_iscsi_usage();
	}
}

#list of print functions

sub print_usage() {
	print "Usage: sanmgmt.pl <filer> <user> <password> <command> \n";
	print "<filer>	  -- Name/IP address of the filer \n";
	print "<user> 	  -- User name \n";
	print "<password>   -- Password \n\n";
	print "posible commands are: \n";
	print "lun    igroup    fcp    iscsi \n";
	
	exit (-1);
}

sub print_LUN_usage() {
	print "Usage: sanmgmt.pl <filer> <user> <password> lun";
	print " <command> \n\n";
	print "Possible commands are:\n";
	print "create  destroy  show  clone  map  unmap  show-map \n\n";
	exit -1;
}

sub print_LUN_create_usage() {
	print "Usage: sanmgmt.pl <filer> <user> <passwd> lun create <path> ";
	print "<size-in-bytes> <ostype> [-sre <space-res-enabled>] \n\n";
	print "space-res-enabled: true/false \n";
	print "ostype: solaris/windows/hpux/aix/linux/vmware. \n";
	exit -1;
}

sub print_clone_usage() {
	print "Usage: sanmgmt.pl <filer> <user> <password> lun clone ";
	print "<command> \n";
	print "Possible commands are: \n";
	print "create  start  stop  status \n";
	exit -1;
}

sub print_igroup_usage() {
	print "Usage: sanmgmt.pl <filer> <user> <password> igroup";
	print " <command> \n\n";
	print "Possible commands are: \n";
	print "create  destroy  add  show \n";
	exit -1;
}
sub print_fcp_usage() {
	print "Usage: sanmgmt.pl <filer> <user> <password> fcp";
	print " <command> \n\n";
	print "Possible commands are: \n";
	print "start  stop  status  config  show \n";
	exit -1;
}
sub print_fcp_config_usage() {
	print "Usage: SANMgmt <filer> <user> <password> ";
	print "fcp config <adapter> < [ up | down ] ";
	print "[ mediatype { ptp | auto | loop } ] ";
	print "[ speed { auto | 1 | 2 | 4 } ] > \n";
	exit -1;
}

sub print_iscsi_usage() {
	print "Usage: sanmgmt.pl <filer> <user> <password> iscsi";
	print " <command> \n\n";
	print "Possible commands are: \n";
	print "start  stop  status  interface  show \n";
	exit -1;
}

sub print_iscsi_interface_usage() {
	print "Usage: sanmgmt.pl <filer> <user> <password> iscsi ";
	print "interface <command> \n\n";
	print "Possible commands are: \n";
	print "enable  disable  show \n";
	exit -1;
}
#=========================== POD ============================#

