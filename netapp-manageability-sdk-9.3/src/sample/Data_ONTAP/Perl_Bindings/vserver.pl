#===============================================================#
# $Id: //depot/prod/zephyr/Rlufthansaair/src/perl/bin/perl_bindings/sample/Data_ONTAP/vserver.pl#1 $								#
#						  		#
# vserver.pl						   	#
#							  	#
# Copyright (c) 2013 NetApp, Inc. All rights reserved.	 	#
# Specifications subject to change without notice.	 	#
#							  	#
#							  	#
# This advanced sample code is used for vserver management in	#
# Cluster ONTAP. You can create or list vservers, add	  	#
# aggregates, create new volumes, configure LIFs, NFS service,	#
# nis domain and export rule for a vserver that are all		#
# required to export a vserver volume on a host for data   	#
# access.						  	#
# You can even create new roles and users, and assign	  	#
# the roles to the new users for privileged access on vserver  	#
# operations.						  	#
#							  	#
# This Sample code is supported from Cluster-Mode	  	#
# Data ONTAP 8.1 onwards.				  	#
#							  	#
#===============================================================#

use lib "../../../../lib/perl/NetApp";
use NaServer;
use strict;

# Variable declaration
my $args = $#ARGV + 1;
my ($server, $ipaddr, $user, $passwd, $command);

# Print the usage and exit the sample code.
sub print_usage_and_exit() {
	print("\nUsage: \n");
	print("vserver <cluster/vserver> <user> <passwd> show [-v <vserver-name>] \n");
	print("vserver <cluster> <user> <passwd> create <vserver-name> <root-vol-aggr> <root-vol> [<ns-switch1> <ns-switch2> ..] \n");
	print("vserver <cluster> <user> <passwd> start <vserver-name> \n");
	print("vserver <cluster> <user> <passwd> stop <vserver-name> \n\n");

	print("vserver <cluster> <user> <passwd> aggr-show \n");
	print("vserver <cluster> <user> <passwd> aggr-add <vserver-name> <aggr-name1> [<aggr-name2> ..] \n\n");

	print("vserver <cluster/vserver> <user> <passwd> vol-create [-v <vserver-name>] <aggr-name> <vol-name> <size> \n");
	print("vserver <cluster/vserver> <user> <passwd> vol-show [-v <vserver-name>] \n\n");

	print("vserver <cluster> <user> <passwd> node-show \n\n");

	print("vserver <cluster> <user> <passwd> lif-create <vserver-name> <lif-name> <ip-addr> <netmask> <gateway> <home-node> <home-port> \n");
	print("vserver <cluster/vserver> <user> <passwd> lif-show [-v <vserver-name>] \n\n");

	print("vserver <cluster/vserver> <user> <passwd> nfs-configure [-v <vserver-name>] \n");
	print("vserver <cluster/vserver> <user> <passwd> nfs-enable [-v <vserver-name>] \n");
	print("vserver <cluster/vserver> <user> <passwd> nfs-disable [-v <vserver-name>] \n");
	print("vserver <cluster/vserver> <user> <passwd> nfs-show [-v <vserver-name>] \n\n");

	print("vserver <cluster/vserver> <user> <passwd> nis-create [-v <vserver-name>] <nis-domain> <is-active-domain> <nis-server-ip> \n");
	print("vserver <cluster/vserver> <user> <passwd> nis-show [-v <vserver-name>] \n\n");

	print("vserver <cluster/vserver> <user> <passwd> export-rule-create [-v <vserver-name>] \n");
	print("vserver <cluster/vserver> <user> <passwd> export-rule-show [-v <vserver-name>] \n\n");

	print("vserver <cluster> <user> <passwd> role-create <role-name> [<cmd-dir-name1> <cmd-dir-name2> ..] \n");
	print("vserver <cluster> <user> <passwd> role-show [<vserver-name>] \n");
	print("vserver <cluster> <user> <passwd> user-create <user-name> <password> <role-name> \n");
	print("vserver <cluster> <user> <passwd> user-show [<vserver-name>] \n");

	print("<cluster> 		-- IP address of the cluster \n");
	print("<vserver> 		-- IP address of the vserver \n");
	print("<user>			-- User name \n");
	print("<passwd>		-- Password \n");
	print("<vserver-name>		-- Name of the vserver \n");
	print("<root-vol-aggr>		-- Aggregate on which the root volume will be created \n");
	print("<root-vol>		-- New root volume of the Vserver \n");
	print("<vol-name>		-- Name of the volume to create \n");
	print("<aggr-name>		-- Name of the aggregate to add \n");
	print("<ns-switch>   		-- Name Server switch configuration details for the Vserver. Possible values: 'nis', 'file', 'ldap' \n");
	print("<size>			-- The initial size (in bytes) of the new flexible volume \n");
	print("<is-active-domain>	-- Specifies whether the NIS domain configuration is active or inactive \n");
	print("<cmd-dir-name>		-- The command or command directory to which the role has an access \n");
	print("Note: \n");
	print(" -v switch is required when you want to tunnel the command to a vserver using cluster interface. \n");
	print(" You need not specify <vserver-name> when you target the command to a vserver interface. \n");
	print(" 'role-create' option creates a new role with default access for vserver get, start, stop and volume show operations. \n");
	print(" 'create' option creates a new vserver with default ns-switch value as 'file' and security-style as 'unix'. \n\n");
	exit (-1);
}

# List the vservers available in Cluster ONTAP
sub show_vservers() {
	my $out;
	my ($rootVol, $rootVolAggr, $secStyle, $state);
	my $tag = "";

   if ($args > 4) {
		if ($args < 6 || $ARGV[4] ne ("-v")) {
			print_usage_and_exit();
		}
		$server->set_vserver($ARGV[5]);
	}
	while (defined($tag)) {
		eval {
			if ($tag ne "") {
	   			$out = $server->vserver_get_iter('tag' => $tag);
			} else {
				$out = $server->vserver_get_iter();
			}
		};
		if($@) {
			my ($error_reason, $error_code) = $@ =~ /(.+)\s\((\d+)\)/;
			print($@);
			exit(-1);
		}
		if ($out->{'num-records'} == 0) {
			print("No vserver(s) information available \n");
			return;
		}
		$tag = $out->{'next-tag'};
		my $vserverList = $out->{'attributes-list'}->{'vserver-info'};
		print("----------------------------------------------------\n");
		my $vserverInfo;
		# Iterate through each vserver info
		foreach $vserverInfo (@{$vserverList}) {
			print("Name			: " . $vserverInfo->{'vserver-name'} . "\n");
			print("Type			: " . $vserverInfo->{'vserver-type'} . "\n");
			$rootVolAggr = $vserverInfo->{'root-volume-aggregate'};
			$rootVol = $vserverInfo->{'root-volume'};
			$secStyle = $vserverInfo->{'root-volume-security-style'};
			$state = $vserverInfo->{'state'};
			print("Root volume aggr	: " . ($rootVolAggr ? $rootVolAggr : "") . "\n");
			print("Root volume		: " . ($rootVol ? $rootVol : "") . "\n");
			print("Root volume sec style	: " . ($secStyle ? $secStyle : "") . "\n");
			print("UUID			: " . $vserverInfo->{'uuid'} . "\n");
			print("State			: " . ($state ? $state : "") . "\n");
			my $aggregates;
			print("Aggregates		: ");
			if (($aggregates = $vserverInfo->{'aggr-list'})) {
				my $aggrList = $aggregates->{'aggr-name'};
				foreach my $aggr (@{$aggrList}) {
				   print($aggr . " ");
				}
			}
			my $allowedProtocols;
			print("\nAllowed protocols	: ");
			if (($allowedProtocols = $vserverInfo->{'allowed-protocols'})) {
				my $allowedProtocolsList = $allowedProtocols->{'protocol'};
				foreach my $protocol (@{$allowedProtocolsList}) {
				   print($protocol . " ");
				}
			}
			print("\nName server switch	: ");
			my $nameServerSwitch;
			if (($nameServerSwitch = $vserverInfo->{'name-server-switch'})) {
				my $nsSwitchList = $nameServerSwitch->{'nsswitch'};
				foreach my $nsSwitch (@{$nsSwitchList}) {
					print($nsSwitch . " ");
				}
			}
			print("\n----------------------------------------------------\n");
		}
	}
}

# Creates a vserver with specified root aggregate and volume name
sub create_vserver() {
	my ($in, $out, $index, $nameSrvSwitch);
	$index = 4;

	$in->{'vserver-name'} = $ARGV[$index++];
	$in->{'root-volume-aggregate'} = $ARGV[$index++];
	$in->{'root-volume'} =  $ARGV[$index++];

	if ($args == 7) {
		$nameSrvSwitch = {'nsswitch' => ['file']};
	} else {
		my @nsswitchArray = ();
		while ($index < $args) {
			push(@nsswitchArray, $ARGV[$index++]);
		}
		$nameSrvSwitch = {'nsswitch' => \@nsswitchArray};
	}
	$in->{'name-server-switch'} = $nameSrvSwitch;
	$in->{'root-volume-security-style'} = "unix";
	eval {
		$out = $server->vserver_create(%{$in});
	};
	if ($@) {
		print($@ ."\n");
		exit(-1);
	}
	print("Vserver created successfully! \n");
}

# Starts a specified vserver
sub start_vserver() {
	eval {
		my $out = $server->vserver_start('vserver-name' => $ARGV[4]);
	};
	if ($@) {
		print($@ ."\n");
		exit(-1);
	}
	print("Vserver started successfully! \n");
}

# Stops a specified vserver
sub stop_vserver() {
	eval {
		my $out = $server->vserver_stop('vserver-name' => $ARGV[4]);
	};
	if ($@) {
		print($@ ."\n");
		exit(-1);
	}
	print("Vserver stopped successfully! \n");
}

# Creates a volume on a vserver with the specified size
sub create_volume() {
	my ($out, $volume, $index);
	$index = 4;

	if ($args == 9) {
			if ($ARGV[$index] ne ("-v")) {
				print_usage_andexit();
			}
			$index++;
			$server->set_vserver($ARGV[$index++]);
		}
		my %in = ();
		$in{'containing-aggr-name'} = $ARGV[$index++];
		$volume = $ARGV[$index++];
		$in{'volume'}  = $volume;
		$in{'size'}  = $ARGV[$index++];
		$in{'junction-path'} = "/" . $volume;
		eval {
			$out = $server->volume_create(%in);
		};
		if ($@) {
			print($@ ."\n");
			exit(-1);
		}
		print("Volume created successfully! \n");
}

# Lists the volumes available in cluster or vserver
sub show_volumes {
	my ($out, $tag, $old_tag);
	$tag = "";

	if ($args > 4) {
		if ($args < 6 || $ARGV[4] ne ("-v")) {
			print_usage_and_exit();
		}
		$server->set_vserver($ARGV[5]);
	}
	my %in = ();
	while (defined($tag)) {
		if ($tag ne "") {
			$in{'tag'} = $tag;
			$old_tag = $tag;
		}
		eval {
			# Disabling bindings validation for this invocation.
			$server->set_bindings_validation(0);

			$out = $server->volume_get_iter();

			# Enabling bindings validation again after the invocation.
			$server->set_bindings_validation(1);
		};
		if ($@) {
			print($@ ."\n");
			exit(-1);
		}

		if ($out->{'num-records'} == 0) {
			print("No vserver(s) information available\n");
			return;
		}

		$tag = $out->{'next-tag'};
		my $volList = $out->{'attributes-list'}->{'volume-attributes'};

		if(ref($volList) eq 'HASH') {
			my @temp_array = $out->{'attributes-list'}->{'volume-attributes'};
			$volList = \@temp_array;
		}

		my $volInfo;
		my ($vserverName, $volName, $aggrName, $volType, $volState, $size, $availSize);
		print("----------------------------------------------------\n");
		foreach $volInfo (@{$volList}) {
			$vserverName = $volName = $aggrName = $volType = $volState = $size = $availSize = "";
			my $volIdAttrs = $volInfo->{'volume-id-attributes'};
			if ($volIdAttrs) {
				$vserverName = $volIdAttrs->{'owning-vserver-name'};
				$volName = $volIdAttrs->{'name'};
				$aggrName = $volIdAttrs->{'containing-aggregate-name'};
				$volType = $volIdAttrs->{'type'};
			}
			print("Vserver Name		: $vserverName \n");
			print("Volume Name		: $volName \n");
			print("Aggregate Name		: $aggrName \n");
			print("Volume type		: $volType \n");

			my $volStateAttrs = $volInfo->{'volume-state-attributes'};
			if ($volStateAttrs) {
				$volState = $volStateAttrs->{'state'};
			}	
			print("Volume state		: $volState \n");
			my $volSizeAttrs = $volInfo->{'volume-space-attributes'};
			if ($volSizeAttrs) {
				$size = $volSizeAttrs->{'size'};
				$availSize = $volSizeAttrs->{'size-available'};
			}
			print("Size (bytes)		: $size \n");
			print("Available Size (bytes)	: $availSize \n");
			print("----------------------------------------------------\n");
		}

		if($tag eq $old_tag) {
			return;
		}
	}
}

# Gets the admin vserver
sub get_admin_vserver()  {
	my ($in, $out, $query, $qinfo, $desiredAttrs, $dinfo, $attr, $vserverInfo, $vserver);

	$qinfo->{'vserver-type'} = "admin";
	$query->{'vserver-info'} = $qinfo;
	$in->{'query'} = $query;

	$dinfo->{'vserver-name'}  = "";
	$desiredAttrs->{'vserver-info'} = $dinfo;
	$in->{'desired-attributes'} = $desiredAttrs;

	eval {
		$out = $server->vserver_get_iter(%{$in});
	};
	if ($@) {
		print($@ ."\n");
		exit(-1);
	}

	$attr = $out->{'attributes-list'};
	$vserverInfo = $attr->{'vserver-info'};
	$vserver = $vserverInfo->[0]->{'vserver-name'};
	return $vserver;
}

# Creates a role with default access to vserver start, vserver stop, volume list and vserver list operations
sub create_role() {
	my ($out, $vserver, $roleName, $cmddir, $accessLevel, $index);
	my %in = ();

	$vserver = get_admin_vserver();
	$roleName = $ARGV[4];
	$accessLevel = "all";
	# create a role by default for vserver start and stop access
	if ($args < 6) {
		$index = 0;
		while ($index++ < 4) {
			$accessLevel = "all";
			$in{'vserver'} = $vserver;
			$in{'role-name'}  = $roleName;

			if ($index == 1) {
				$cmddir = "vserver show";
				$accessLevel = "readonly";
			} elsif ($index == 2) {
				$cmddir = "vserver start";
			} elsif ($index == 3) {
				$cmddir = "vserver stop";
			} elsif ($index == 4) {
				$cmddir = "volume show";
				$accessLevel = "readonly";
		   }

		   $in{'command-directory-name'} = $cmddir;
		   $in{'access-level'} = $accessLevel;

		   eval {
		   	$out = $server->security_login_role_create(%in);
		
		   };
		   if ($@) {
				print($@ ."\n");
				exit(-1);
			}
		}
	} else {
		$index = 5;
		%in = ();
		while ($index < $args) {
			$in{'vserver'} = $vserver;
			$in{'role-name'} = $roleName;
			$in{'command-directory-name'} = $ARGV[$index++];
			$in{'access-level'} = "all";
			$in{'return-record'} = "true";

			eval {
				$out = $server->security_login_role_create(%in);
			};
			if ($@) {
				print($@ ."\n");
				exit(-1);
			}
		 }
	}
	print("Role created successfully! \n");
}

sub show_roles() {
	my ($in, $out, $tag, $info, $query);
	$tag = "";

	while (defined($tag)) {
		if ($args > 4) {
			$info->{'vserver'} = $ARGV[4];
			$query->{'security-login-role-info'} = $info;
			$in->{'query'} = $query;
		}
		if ($tag ne "") {
			$in->{'tag'} = $tag;
		}

		eval {
			$out = $server->security_login_role_get_iter(%{$in});
		};
		if ($@) {
			print($@ ."\n");
			exit(-1);
		}

		$tag = $out->{'next-tag'};
		if ($out->{'num-records'} == 0) {
			print("No more role(s) information available \n");
			return;
		}
		my $roleList = $out->{'attributes-list'}->{'security-login-role-info'};
		my $roleInfo;
		print("----------------------------------------------------\n");
		foreach $roleInfo (@{$roleList}) {
			print("Role Name	: " . $roleInfo->{'role-name'} . "\n");
			print("Vserver		: " . $roleInfo->{'vserver'} . "\n");
			print("Command		: " . $roleInfo->{'command-directory-name'} . "\n");
			print("Query		: " . $roleInfo->{'role-query'} . "\n");
			print("Access Level	: " . $roleInfo->{'access-level'} . "\n");
			print("----------------------------------------------------\n");
		}
	}
}

sub create_user() {
	my ($out, $vserver, $index);

	$index = 4;
	$vserver = get_admin_vserver();

	my %in = ();
	$in{'application'} = "ontapi";
	$in{'authentication-method'} = "password";
	$in{'vserver'} = $vserver;
	$in{'user-name'} = $ARGV[$index++];
	$in{'password'} = $ARGV[$index++];
	$in{'role-name'} = $ARGV[$index++];

	eval {
		$out = $server->security_login_create(%in);
	};
	if ($@) {
		print($@ ."\n");
		exit(-1);
	}
	print("User created successfully! \n");
}

sub show_users() {
	my ($in, $out, $tag, $info, $query);
	$tag = "";

	while (defined($tag)) {
		if ($args > 4) {
			$info->{'vserver'} = $ARGV[4];
			$query->{'security-login-account-info'} = $info;
			$in->{'query'} = $query;
		}
		if ($tag ne "") {
			$in->{'tag'} = $tag;
		}

		eval {
			$out = $server->security_login_get_iter(%{$in});;
		};
		if ($@) {
			print($@ ."\n");
			exit(-1);
		}

		$tag = $out->{'next-tag'};
		if ($out->{'num-records'} == 0) {
			print("No user(s) information available \n");
			return;
		}

		my $userList = $out->{'attributes-list'}->{'security-login-account-info'};
		my $accountInfo;
		print("----------------------------------------------------\n");
		foreach $accountInfo (@{$userList}) {
			print("User Name	: " . $accountInfo->{'user-name'} . "\n");
			print("Role Name	: " . $accountInfo->{'role-name'} . "\n");
			print("Vserver		: " . $accountInfo->{'vserver'} . "\n");
			print("Account Locked	: " . $accountInfo->{'is-locked'} . "\n");
			print("Application	: " . $accountInfo->{'application'} . "\n");
			print("Authentication	: " . $accountInfo->{'authentication-method'} . "\n");
			print("----------------------------------------------------\n");
		}
	}
}

sub configure_NFS() {
	my $out;

	if ($args > 4) {
		if ($args < 6 || $ARGV[4] ne ("-v")) {
			print_usage_and_exit();
		}
		$server->set_vserver($ARGV[5]);
	}

	eval {
		$out = $server->nfs_service_create();
	};
	if ($@) {
		print($@ ."\n");
		exit(-1);
	}
	print("NFS service created successfully! \n");
}

sub enable_NFS() {
	my $out;

	if ($args > 4) {
		if ($args < 6 || $ARGV[4] ne ("-v")) {
			print_usage_and_exit();
		}
		$server->set_vserver($ARGV[5]);
	}

	eval {
		$out = $server->nfs_enable();
	};
	if ($@) {
		print($@ ."\n");
		exit(-1);
	}

	print("NFS service enabled successfully! \n");
}

sub disable_NFS() {
	my $out;

	if ($args > 4) {
		if ($args < 6 || $ARGV[4] ne ("-v")) {
			print_usage_and_exit();
		}
		$server->set_vserver($ARGV[5]);
	}

	eval {
		$out = $server->nfs_disable();
	};
	if ($@) {
		print($@ ."\n");
		exit(-1);
	}

	print("NFS service disabled successfully! \n");
}

sub show_NFS() {
	my $out;

	if ($args > 4) {
		if ($args < 6 || $ARGV[4] ne ("-v")) {
			print_usage_and_exit();
		}
		$server->set_vserver($ARGV[5]);
	}

	eval {
		# Disabling bindings validation
		$server->set_bindings_validation(0);

		$out = $server->nfs_service_get();

		# Re-enabling bindings validation
		$server->set_bindings_validation(1);
	};
	if ($@) {
		print($@ ."\n");
		exit(-1);
	}

	my $attrs = $out->{'attributes'};
	if (!defined($attrs)) {
		print("NFS information in not available\n");
	}
	my $nfsInfo = $attrs->{'nfs-info'};

	my $nfsAccess = "enabled";
	if ($nfsInfo->{'is-nfs-access-enabled'} eq "false") {
		$nfsAccess = "disabled";
	}

	my $nfsv3 = "enabled";
	if ($nfsInfo->{'is-nfsv3-enabled'} eq "false") {
		$nfsv3 = "disabled";
	}

	my $nfsv4 = "enabled";
	if ($nfsInfo->{'is-nfsv40-enabled'} eq "false") {
		$nfsv4 = "disabled";
	}

	print("----------------------------------------------------\n");
	print("Vserver Name		: " . $nfsInfo->{'vserver'} . "\n");
	print("General NFS access	: " . $nfsAccess . "\n");
	print("NFS v3			: " . $nfsv3 . "\n");
	print("NFS v4.0		: " . $nfsv4 . "\n");
	print("----------------------------------------------------\n");
}

sub create_Lif () {
	my ($in, $out, $index, $vserver, $ipAddr, $gateway);

	$index = 4;

	$vserver = $ARGV[$index++];
	$in->{'vserver'} = $vserver;
	$in->{'interface-name'} = $ARGV[$index++];
	$ipAddr = $ARGV[$index++];
	$in->{'address'} =  $ipAddr;
	$in->{'netmask'} = $ARGV[$index++];
	$gateway = $ARGV[$index++];
	$in->{'home-node'} = $ARGV[$index++];
	$in->{'home-port'} = $ARGV[$index++];
	$in->{'firewall-policy'} = "mgmt";
	$in->{'role'} = "data";
	$in->{'return-record'} = "true";

	eval {
		$out = $server->net_interface_create(%{$in});
	};
	if ($@) {
		print($@ ."\n");
		exit(-1);
	}

	my $netLifInfo = $out->{'result'}->{'net-interface-info'};
	my $routingGroup = $netLifInfo->{'routing-group-name'};

	my $info = {};
	$info->{'routing-group'} = $routingGroup;
	$info->{'vserver'} = $vserver;
	my $query = {};
	$query->{'routing-group-route-info'} = $info;
	$in = {};
	$in->{'query'} = $query;

	eval {
		$out = $server->net_routing_group_route_get_iter(%{$in});
	};
	if($@) {
		print($@ ."\n");
		exit(-1);
	}

	if ($out->{'num-records'} ne "0") {
		print("LIF created successfully! \n");
		return;
	}

	$in = {};
	$in->{'vserver'} = $vserver;
	my $destAddr = "0.0.0.0" . "/" . "0";
	$in->{'destination-address'} =  $destAddr;
	$in->{'gateway-address'} = $gateway;
	$in->{'routing-group'} = $routingGroup;

	eval {
		$out = $server->net_routing_group_route_create(%{$in});
	};
	if ($@) {
		print($@ ."\n");
		exit(-1);
	}
	print("LIF created successfully! \n");
}

sub show_LIFs() {
	my ($in, $out, $tag);
	$tag = "";

	while (defined($tag)) {
		if ($args > 4) {
			if ($args < 6 || $ARGV[4] ne ("-v")) {
				print_usage_and_exit();
			}
			$server->set_vserver($ARGV[5]);
		}

		if ($tag ne "") {
			$in->{'tag'} =  $tag;
		}

		eval {
			$out = $server->net_interface_get_iter(%{$in});
		};
		if ($@) {
			print($@ ."\n");
			exit(-1);
		}

		if ($out->{'num-records'} == 0) {
			print("No interface information available \n");
			return;
		}

		$tag = $out->{'next-tag'};
		my $lifList = $out->{'attributes-list'}->{'net-interface-info'};
		my $lifInfo;
		print("----------------------------------------------------\n");
		foreach $lifInfo (@{$lifList}) {
			print("Vserver Name		: " . $lifInfo->{'vserver'} . "\n");
			print("Address			: " . $lifInfo->{'address'} . "\n");
			print("Logical Interface Name	: " . $lifInfo->{'interface-name'} . "\n");
			print("Netmask			: " . $lifInfo->{'netmask'} . "\n");
			print("Routing Group Name	: " . $lifInfo->{'routing-group-name'} . "\n");
			print("Firewall Policy		: " . $lifInfo->{'firewall-policy'} . "\n");
			print("Administrative Status	: " . $lifInfo->{'administrative-status'} . "\n");
			print("Operational Status	: " . $lifInfo->{'operational-status'} . "\n");
			print("Current Node		: " . $lifInfo->{'current-node'} . "\n");
			print("Current Port		: " . $lifInfo->{'current-port'} . "\n");
			print("Is Home			: " . $lifInfo->{'is-home'} . "\n");
			print("----------------------------------------------------\n");
		}
	}
}

sub show_aggregates() {
	my ($in, $out, $tag);
	$tag = "";

	while (defined($tag)) {
		if ($tag ne "") {
			$in->child_add_string("tag", $tag);
		}

		eval {
			$out = $server->aggr_get_iter(%{$in});
		};
		if($@) {
			print($@ ."\n");
			exit(-1);
		}

		if ($out->{'num-records'} == 0) {
			print("No aggregate(s) information available\n");
			return;
		}

		$tag = $out->{'next-tag'};
		my $aggrList = $out->{'attributes-list'}->{'aggr-attributes'};
		my $aggrInfo;
		print("----------------------------------------------------\n");
		foreach $aggrInfo (@{$aggrList}) {
			print("Aggregate Name		: " . $aggrInfo->{'aggregate-name'} . "\n");
			my $aggrSizeAttrs = $aggrInfo->{'aggr-space-attributes'};
			print("Size (bytes)		: " . $aggrSizeAttrs->{'size-total'} . "\n");
			print("Available Size (bytes)	: " . $aggrSizeAttrs->{'size-available'} . "\n");
			print("Used Percentage		: " . $aggrSizeAttrs->{'percent-used-capacity'} . "\n");
			my $aggrRaidAttrs = $aggrInfo->{'aggr-raid-attributes'};
			print("Aggregate State		: " . $aggrRaidAttrs->{'state'} . "\n");
			print("----------------------------------------------------\n");
		}
	}
}

sub add_aggregates() {
	my ($in, $out, $index, $aggr_list, @aggrs);

	$index = 4;
	$in->{'vserver-name'} = $ARGV[$index++];
	while ($index < $args) {
		push (@aggrs, $ARGV[$index++]);
	}
	$aggr_list->{'aggr-name'} = \@aggrs;
	$in->{'aggr-list'} = $aggr_list;

	eval {
		$out = $server->vserver_modify(%{$in});
	};
	if ($@) {
		print($@ ."\n");
		exit(-1);
	}

	print("Aggregate(s) added successfully! \n");
}

sub show_nodes() {
	my ($in, $out, $tag);
	$tag = "";

	while (defined($tag)) {
		if ($tag ne "") {
			$in->child_add_string("tag", $tag);
		}

		eval {
			# Disabling bindings validation
			$server->set_bindings_validation(0);

			$out = $server->system_node_get_iter(%{$in});

			# Enabling bindings validation again
			$server->set_bindings_validation(1);
		};
		if($@) {
			print($@ ."\n");
			exit(-1);
		}

		if ($out->{'num-records'} == 0) {
			print("No node(s) information available\n");
			return;
		}

		$tag = $out->{'next-tag'};
		my $nodeInfoList = $out->{'attributes-list'}->{'node-details-info'};

		if(ref($nodeInfoList) eq 'HASH') {
			my @temp_array = $out->{'attributes-list'}->{'node-details-info'};
			$nodeInfoList = \@temp_array;
		}

		my $nodeInfo;
		print("----------------------------------------------------\n");
		foreach $nodeInfo (@{$nodeInfoList}) {
			print("Node Name	: " . $nodeInfo->{'node'} . "\n");
			print("UUID		: " . $nodeInfo->{'node-uuid'} . "\n");
			print("----------------------------------------------------\n");
		}
	}
}

sub create_export_rule() {
	my ($in, $out, $index, $roRule, $rwRule);

	$index = 4;
	if ($args > 4) {
		if ($args < 6 || $ARGV[4] ne ("-v")) {
			print_usage_and_exit();
		}
		$server->set_vserver($ARGV[5]);
	}

	$in->{'policy-name'} = "default";
	$in->{'client-match'} = "0.0.0/0";
	$in->{'rule-index'} = "1";

	$roRule->{'security-flavor'} = "any";
	$in->{'ro-rule'} = $roRule;

	$rwRule->{'security-flavor'} = "any";
	$in->{'rw-rule'} = $rwRule;

	eval {
		$out = $server->export_rule_create(%{$in});
	};
	if ($@) {
		print($@ ."\n");
		exit(-1);
	}

	print("Export rule created successfully! \n");
}

sub show_export_rules() {
	my ($in, $out, $tag);

	$tag = "";
	while (defined($tag)) {
		if ($args > 4) {
			if ($args < 6 || $ARGV[4] ne ("-v")) {
				print_usage_and_exit();
			}
			$server->set_vserver($ARGV[5]);
		}

		if ($tag ne "") {
			$in->{'tag'} = $tag;
		}

		eval {
			$out = $server->export_rule_get_iter(%{$in});
		};
		if($@) {
			print($@ ."\n");
			exit(-1);
		}

		if ($out->{'num-records'} == 0) {
			print("No export rule(s) information available\n");
			return;
		}

		$tag = $out->{'next-tag'};
		my $exportRuleList = $out->{'attributes-list'}->{'export-rule-info'};
		my $exportRuleInfo;
		print("----------------------------------------------------\n");
		foreach $exportRuleInfo (@{$exportRuleList}) {
			print("Vserver			: " . $exportRuleInfo->{'vserver-name'} . "\n");
			print("Policy Name		: " . $exportRuleInfo->{'policy-name'} . "\n");
			print("Rule Index		: " . $exportRuleInfo->{'rule-index'} . "\n");
			print("Access Protocols	: ");
			my $protocolList = $exportRuleInfo->{'protocol'}->{'access-protocol'};
			my $protocol;
			foreach $protocol (@{$protocolList}) {
			   print($protocol . " ");
			}
			print("\nClient Match Spec	: " . $exportRuleInfo->{'client-match'} . "\n");
			print("RO Access Rule		: ");
			my $roRuleList = $exportRuleInfo->{'ro-rule'}->{'security-flavor'};
			my $roRule;
			foreach $roRule (@{$roRuleList}) {
				print($roRule . " ");
			}
			print("\n----------------------------------------------------\n");
		}
	}
}

sub show_nis() {
	my ($in, $out, $tag);

	$tag = "";
	while (defined($tag)) {
		if ($args > 4) {
			if ($args < 6 || $ARGV[4] ne ("-v")) {
				print_usage_and_exit();
			}
			$server->set_vserver($ARGV[5]);
		}

		if ($tag ne "") {
			$in->{'tag'} = $tag;
		}

		eval {
			$out = $server->nis_get_iter(%{$in});
		};
		if($@) {
			print($@ ."\n");
			exit(-1);
		}

		if ($out->{'num-records'} == 0) {
			print("No nis domain information available \n");
			return;
		}

		$tag = $out->{'next-tag'};
		my $nisDomainList = $out->{'attributes-list'}->{'nis-domain-config-info'};
		my $nisDomainInfo;
		my $nisServers;
		print("----------------------------------------------------\n");
		foreach $nisDomainInfo (@{$nisDomainList}) {
			print("NIS Domain	: " . $nisDomainInfo->{'nis-domain'} . "\n");
			print("Is Active	: " . $nisDomainInfo->{'is-active'} . "\n");
			print("Vserver		: " . $nisDomainInfo->{'vserver'} . "\n");
			print("NIS Server(s)	: ");
			if (($nisServers = $nisDomainInfo->{'nis-servers'})) {
				my $ipaddrList = $nisServers->{'ip-address'};
				my $ipaddr;
				foreach $ipaddr (@{$ipaddrList}) {
				   print($ipaddr . " ");
				}
			}
			print("\n----------------------------------------------------\n");
		}
	}
}

sub create_nis {
	my ($in, $out, $index, $nisServers);

	$index = 4;
	if ($ARGV[4] eq "-v") {
		if ($args < 9) {
			print_usage_and_exit();
		}
		$index++;
		$server->set_vserver($ARGV[$index++]);
	}

	$in->{'nis-domain'} = $ARGV[$index++];
	$in->{'is-active'} = $ARGV[$index++];
	$nisServers->{'ip-address'} = $ARGV[$index++];
	$in->{'nis-servers'} = $nisServers;

	eval {
		$out = $server->nis_create(%{$in});
	};
	if ($@) {
		print($@ ."\n");
		exit(-1);
	}

	print("NIS domain created successfully! \n");
}

sub main() {

	if ($args < 4) {
		print_usage_and_exit();
	}
	$ipaddr = $ARGV[0];
	$user = $ARGV[1];
	$passwd = $ARGV[2];
	$command = $ARGV[3];

	$server = NaServer->new($ipaddr, 1, 15);
	$server->set_style("LOGIN");
	$server->set_admin_user($user, $passwd);
	$server->set_transport_type("HTTP");

	if ($command eq("show")) {
		show_vservers();
	} elsif ($command eq("create") && ($args >= 7)) {
		create_vserver();
	} elsif ($command eq("start") && ($args >= 5)) {
		start_vserver();
	} elsif ($command eq("stop") && ($args >= 5)) {
		stop_vserver();
	} elsif ($command eq("vol-create") && ($args == 7 || $args == 9)) {
		create_volume();
	} elsif ($command eq("role-create") && ($args >= 5)) {
		create_role();
	} elsif ($command eq("role-show")) {
		show_roles();
	} elsif ($command eq("user-create") && ($args >= 7)) {
		create_user();
	} elsif ($command eq("user-show")) {
		show_users();
	} elsif ($command eq("nfs-configure")) {
		configure_NFS();
	} elsif ($command eq("nfs-enable")) {
		enable_NFS();
	} elsif ($command eq("nfs-disable")) {
		disable_NFS();
	} elsif ($command eq("nfs-show")) {
		show_NFS();
	} elsif ($command eq("vol-show")) {
		show_volumes();
	} elsif ($command eq("lif-create") && ($args >= 11)) {
		create_Lif ();
	} elsif ($command eq("lif-show")) {
		show_LIFs();
	} elsif ($command eq("aggr-show")) {
		show_aggregates();
	}  elsif ($command eq("aggr-add") && ($args >= 6)) {
		add_aggregates();
	} elsif ($command eq("node-show")) {
		show_nodes();
	} elsif ($command eq("nis-show")) {
		show_nis();
	} elsif ($command eq("nis-create") && ($args >= 7)) {
		create_nis();
	} elsif ($command eq("export-rule-create")) {
		create_export_rule();
	} elsif ($command eq("export-rule-show")) {
		show_export_rules();
	} else {
		print_usage_and_exit();
	}
}

main();
