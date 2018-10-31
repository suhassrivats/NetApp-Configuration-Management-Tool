#==============================================================#
#                                                              #
#                                                              #
# vserver.pl                                                   #
#                                                              #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.         #
# Specifications subject to change without notice.             #
#                                                              #
#                                                              #
# This advanced sample code is used for vserver management in  #
# Cluster ONTAP. You can create or list vservers, add          #
# aggregates, create new volumes, configure LIFs, NFS service, #
# nis domain and export rule for a vserver that are all        #
# required to export a vserver volume on a host for data       #
# access.                                                      #
# You can even create new roles and users, and assign          #
# the roles to the new users for privileged access on vserver  #
# operations.                                                  #
#                                                              #
# This Sample code is supported from Cluster-Mode              #
# Data ONTAP 8.1 onwards.                                      #
#                                                              #
#==============================================================#

use lib "../../../../../lib/perl/NetApp";
use NaServer;
use NaElement;
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

    print("<cluster>             -- IP address of the cluster \n");
    print("<vserver>             -- IP address of the vserver \n");
    print("<user>                -- User name \n");
    print("<passwd>              -- Password \n");
    print("<vserver-name>        -- Name of the vserver \n");
    print("<root-vol-aggr>       -- Aggregate on which the root volume will be created \n");
    print("<root-vol>            -- New root volume of the Vserver \n");
    print("<vol-name>            -- Name of the volume to create \n");
    print("<aggr-name>            -- Name of the aggregate to add \n");
    print("<ns-switch>           -- Name Server switch configuration details for the Vserver. Possible values: 'nis', 'file', 'ldap' \n");
    print("<size>                -- The initial size (in bytes) of the new flexible volume \n");
    print("<is-active-domain>    -- Specifies whether the NIS domain configuration is active or inactive \n");
    print("<cmd-dir-name>        -- The command or command directory to which the role has an access \n");
    print("Note: \n");
    print(" -v switch is required when you want to tunnel the command to a vserver using cluster interface. \n");
    print(" You need not specify <vserver-name> when you target the command to a vserver interface. \n");
    print(" 'role-create' option creates a new role with default access for vserver get, start, stop and volume show operations. \n");
    print(" 'create' option creates a new vserver with default ns-switch value as 'file' and security-style as 'unix'. \n\n");
    exit (-1);
}

# List the vservers available in Cluster ONTAP
sub show_vservers() {
    my ($in, $out);
    my ($rootVol, $rootVolAggr, $secStyle, $state);
    my $tag = "";

   if ($args > 4) {
        if ($args < 6 || $ARGV[4] ne ("-v")) {
            print_usage_and_exit();
        }
        $server->set_vserver($ARGV[5]);
    }
    while (defined($tag)) {
        $in = NaElement->new("vserver-get-iter");
        if ($tag ne "") {
            $in->child_add_string("tag", $tag);
        }
        $out = $server->invoke_elem($in);
        if($out->results_status() eq "failed") {
            print($out->results_reason() ."\n");
            exit(-1);
        }
        if ($out->child_get_int("num-records") == 0) {
            print("No vserver(s) information available \n");
            return;
        }
        $tag = $out->child_get_string("next-tag");
        my @vserverList = $out->child_get("attributes-list")->children_get();
        print("----------------------------------------------------\n");
        my $vserverInfo;
        # Iterate through each vserver info
        foreach $vserverInfo (@vserverList) {
            print("Name                    : " . $vserverInfo->child_get_string("vserver-name") . "\n");
            print("Type                    : " . $vserverInfo->child_get_string("vserver-type") . "\n");
            $rootVolAggr = $vserverInfo->child_get_string("root-volume-aggregate");
            $rootVol = $vserverInfo->child_get_string("root-volume");
            $secStyle = $vserverInfo->child_get_string("root-volume-security-style");
            $state = $vserverInfo->child_get_string("state");
            print("Root volume aggr        : " . ($rootVolAggr ? $rootVolAggr : "") . "\n");
            print("Root volume             : " . ($rootVol ? $rootVol : "") . "\n");
            print("Root volume sec style   : " . ($secStyle ? $secStyle : "") . "\n");
            print("UUID                    : " . $vserverInfo->child_get_string("uuid") . "\n");
            print("State                   : " . ($state ? $state : "") . "\n");
            my $aggregates;
            print("Aggregates              : ");
            if (($aggregates = $vserverInfo->child_get("aggr-list"))) {
                my @aggrList = $aggregates->children_get();
                foreach my $aggr (@aggrList) {
                   print($aggr->get_content() . " ");
                }
            }
            my $allowedProtocols;
            print("\nAllowed protocols       : ");
            if (($allowedProtocols = $vserverInfo->child_get("allowed-protocols"))) {
                my @allowedProtocolsList = $allowedProtocols->children_get();
                foreach my $protocol (@allowedProtocolsList) {
                   print($protocol->get_content() . " ");
                }
            }
            print("\nName server switch      : ");
            my $nameServerSwitch;
            if (($nameServerSwitch = $vserverInfo->child_get("name-server-switch"))) {
                my @nsSwitchList = $nameServerSwitch->children_get();
                foreach my $nsSwitch (@nsSwitchList) {
                    print($nsSwitch->get_content() . " ");
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

    $in = NaElement->new("vserver-create");
    $nameSrvSwitch = NaElement->new("name-server-switch");
    $in->child_add_string("vserver-name", $ARGV[$index++]);
    $in->child_add_string("root-volume-aggregate", $ARGV[$index++]);
    $in->child_add_string("root-volume", $ARGV[$index++]);

    if ($args == 7) {
        $nameSrvSwitch->child_add_string("nsswitch", "file");
    } else {
        while ($index < $args) {
            $nameSrvSwitch->child_add_string("nsswitch", $ARGV[$index++]);
        }
    }
    $in->child_add($nameSrvSwitch);
    $in->child_add_string("root-volume-security-style", "unix");
    $out = $server->invoke_elem($in);
    if ($out->results_status() eq "failed") {
        print($out->results_reason() ."\n");
        exit(-1);
    }
    print("Vserver created successfully! \n");
}

# Starts a specified vserver
sub start_vserver() {
    my $out = $server->invoke("vserver-start", "vserver-name", $ARGV[4]);
    if ($out->results_status() eq "failed") {
        print($out->results_reason() ."\n");
        exit(-1);
    }
    print("Vserver started successfully! \n");
}

# Stops a specified vserver
sub stop_vserver() {
    my $out = $server->invoke("vserver-stop", "vserver-name", $ARGV[4]);
    if ($out->results_status() eq "failed") {
        print($out->results_reason() ."\n");
        exit(-1);
    }
    print("Vserver stopped successfully! \n");
}

# Creates a volume on a vserver with the specified size
sub create_volume() {
    my ($in, $out, $volume, $index);
    $index = 4;

    if ($args == 9) {
            if ($ARGV[$index] ne ("-v")) {
                print_usage_andexit();
            }
            $index++;
            $server->set_vserver($ARGV[$index++]);
        }
        $in = NaElement->new("volume-create");
        $in->child_add_string("containing-aggr-name", $ARGV[$index++]);
        $volume = $ARGV[$index++];
        $in->child_add_string("volume", $volume);
        $in->child_add_string("size", $ARGV[$index++]);
        $in->child_add_string("junction-path", "/" . $volume);
        $out = $server->invoke_elem($in);
        if ($out->results_status() eq "failed") {
            print($out->results_reason() ."\n");
            exit(-1);
        }
        print("Volume created successfully! \n");
}

# Lists the volumes available in cluster or vserver
sub show_volumes {
    my ($in, $out, $tag);
    $tag = "";

   if ($args > 4) {
        if ($args < 6 || $ARGV[4] ne ("-v")) {
            print_usage_and_exit();
        }
        $server->set_vserver($ARGV[5]);
    }
    while (defined($tag)) {
        $in = NaElement->new("volume-get-iter");
        if ($tag ne "") {
            $in->child_add_string("tag", $tag);
        }
        my $out = $server->invoke_elem($in);
        if ($out->results_status() eq "failed") {
            print($out->results_reason() ."\n");
            exit(-1);
        }
        if ($out->child_get_int("num-records") == 0) {
            print("No vserver(s) information available\n");
            return;
        }
        $tag = $out->child_get_string("next-tag");
        my @volList = $out->child_get("attributes-list")->children_get();
        my $volInfo;
        my ($vserverName, $volName, $aggrName, $volType, $volState, $size, $availSize);
        print("----------------------------------------------------\n");
        foreach $volInfo (@volList) {
            $vserverName = $volName = $aggrName = $volType = $volState = $size = $availSize = "";
            my $volIdAttrs = $volInfo->child_get("volume-id-attributes");
            if ($volIdAttrs) {
                $vserverName = $volIdAttrs->child_get_string("owning-vserver-name");
                $volName = $volIdAttrs->child_get_string("name");
                $aggrName = $volIdAttrs->child_get_string("containing-aggregate-name");
                $volType = $volIdAttrs->child_get_string("type");
            }
            print("Vserver Name            : $vserverName \n");
            print("Volume Name             : $volName \n");
            print("Aggregate Name          : $aggrName \n");
            print("Volume type             : $volType \n");
            my $volStateAttrs = $volInfo->child_get("volume-state-attributes");
            if ($volStateAttrs) {
                $volState = $volStateAttrs->child_get_string("state");
            }    
            print("Volume state            : $volState \n");
            my $volSizeAttrs = $volInfo->child_get("volume-space-attributes");
            if ($volSizeAttrs) {
                $size = $volSizeAttrs->child_get_string("size");
                $availSize = $volSizeAttrs->child_get_string("size-available");
            }
            print("Size (bytes)            : $size \n");
            print("Available Size (bytes)  : $availSize \n");
            print("----------------------------------------------------\n");
        }
    }
}

# Gets the admin vserver
sub get_admin_vserver()  {
    my ($in, $out, $query, $qinfo, $desiredAttrs, $dinfo, $attr, $vserverInfo, $vserver);

    $in = NaElement->new("vserver-get-iter");
    $query = NaElement->new("query");
    $qinfo = NaElement->new("vserver-info");
    $qinfo->child_add_string("vserver-type", "admin");
    $query->child_add($qinfo);
    $desiredAttrs = NaElement->new("desired-attributes");
    $dinfo = NaElement->new("vserver-info");
    $dinfo->child_add_string("vserver-name", "");
    $desiredAttrs->child_add($dinfo);
    $in->child_add($query);
    $in->child_add($desiredAttrs);

    $out = $server->invoke_elem($in);
    if ($out->results_status() eq "failed") {
        print($out->results_reason() ."\n");
        exit(-1);
    }
    $attr = $out->child_get("attributes-list");
    $vserverInfo = $attr->child_get("vserver-info");
    $vserver = $vserverInfo->child_get_string("vserver-name");
    return $vserver;
}

# Creates a role with default access to vserver start, vserver stop, volume list and vserver list operations
sub create_role() {
    my ($in, $out, $vserver, $roleName, $cmddir, $accessLevel, $index);

    $vserver = get_admin_vserver();
    $roleName = $ARGV[4];
    $accessLevel = "all";
    # create a role by default for vserver start and stop access
    if ($args < 6) {
        $index = 0;
        while ($index++ < 4) {
            $accessLevel = "all";
            $in = NaElement->new("security-login-role-create");
            $in->child_add_string("vserver", $vserver);
            $in->child_add_string("role-name", $roleName);
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
           $in->child_add_string("command-directory-name", $cmddir);
           $in->child_add_string("access-level", $accessLevel);
           $out = $server->invoke_elem($in);
           if ($out->results_status() eq "failed") {
                print($out->results_reason() ."\n");
                exit(-1);
            }
        }
    } else {
        $index = 5;
        while ($index < $args) {
            $in = NaElement->new("security-login-role-create");
            $in->child_add_string("vserver", $vserver);
            $in->child_add_string("role-name", $roleName);
            $in->child_add_string("command-directory-name", $ARGV[$index++]);
            $in->child_add_string("access-level", "all");
            $in->child_add_string("return-record", "true");
            $out = $server->invoke_elem($in);
            if ($out->results_status() eq "failed") {
                print($out->results_reason() ."\n");
                exit(-1);
            }
         }
    }
    print("Role created successfully! \n");
}

sub show_roles() {
    my ($in, $out, $tag);
    $tag = "";

    while (defined($tag)) {
        $in = NaElement->new("security-login-role-get-iter");
        if ($args > 4) {
            my $query = NaElement->new("query");
            my $info = NaElement->new("security-login-role-info");
            $info->child_add_string("vserver", $ARGV[4]);
            $query->child_add($info);
            $in->child_add($query);
        }
        if ($tag ne "") {
            $in->child_add_string("tag", $tag);
        }
        $out = $server->invoke_elem($in);
        if ($out->results_status() eq "failed") {
            print($out->results_reason() ."\n");
            exit(-1);
        }
        $tag = $out->child_get_string("next-tag");
        if ($out->child_get_int("num-records") == 0) {
            print("No more role(s) information available \n");
            return;
        }
        my @roleList = $out->child_get("attributes-list")->children_get();
        my $roleInfo;
        print("----------------------------------------------------\n");
        foreach $roleInfo (@roleList) {
            print("Role Name               : " . $roleInfo->child_get_string("role-name") . "\n");
            print("Vserver                 : " . $roleInfo->child_get_string("vserver") . "\n");
            print("Command                 : " . $roleInfo->child_get_string("command-directory-name") . "\n");
            print("Query                   : " . $roleInfo->child_get_string("role-query") . "\n");
            print("Access Level            : " . $roleInfo->child_get_string("access-level") . "\n");
            print("----------------------------------------------------\n");
        }
    }
}

sub create_user() {
    my ($in, $out, $vserver, $index);

    $index = 4;
    $vserver = get_admin_vserver();
    $in = NaElement->new("security-login-create");
    $in->child_add_string("application", "ontapi");
    $in->child_add_string("authentication-method", "password");
    $in->child_add_string("vserver", $vserver);
    $in->child_add_string("user-name", $ARGV[$index++]);
    $in->child_add_string("password", $ARGV[$index++]);
    $in->child_add_string("role-name", $ARGV[$index++]);
    $out = $server->invoke_elem($in);
    if ($out->results_status() eq "failed") {
        print($out->results_reason() ."\n");
        exit(-1);
    }
    print("User created successfully! \n");
}

sub show_users() {
    my ($in, $out, $tag);
    $tag = "";

   while (defined($tag)) {
        $in = NaElement->new("security-login-get-iter");
        if ($args > 4) {
            my $query = NaElement->new("query");
            my $info = NaElement->new("security-login-account-info");
            $info->child_add_string("vserver", $ARGV[4]);
            $query->child_add($info);
            $in->child_add($query);
        }
        if ($tag ne "") {
            $in->child_add_string("tag", $tag);
        }
        $out = $server->invoke_elem($in);
        if ($out->results_status() eq "failed") {
            print($out->results_reason() ."\n");
            exit(-1);
        }
        $tag = $out->child_get_string("next-tag");
        if ($out->child_get_int("num-records") == 0) {
            print("No user(s) information available \n");
            return;
        }
        my @userList = $out->child_get("attributes-list")->children_get();
        my $accountInfo;
        print("----------------------------------------------------\n");
        foreach $accountInfo (@userList) {
            print("User Name               : " . $accountInfo->child_get_string("user-name") . "\n");
            print("Role Name               : " . $accountInfo->child_get_string("role-name") . "\n");
            print("Vserver                 : " . $accountInfo->child_get_string("vserver") . "\n");
            print("Account Locked          : " . $accountInfo->child_get_string("is-locked") . "\n");
            print("Application             : " . $accountInfo->child_get_string("application") . "\n");
            print("Authentication          : " . $accountInfo->child_get_string("authentication-method") . "\n");
            print("----------------------------------------------------\n");
        }
    }
}

sub configure_NFS() {
    my ($in, $out);

    if ($args > 4) {
        if ($args < 6 || $ARGV[4] ne ("-v")) {
            print_usage_and_exit();
        }
        $server->set_vserver($ARGV[5]);
    }
    $in = NaElement->new("nfs-service-create");
    $out = $server->invoke_elem($in);
    if ($out->results_status() eq "failed") {
        print($out->results_reason() ."\n");
        exit(-1);
    }
    print("NFS service created successfully! \n");
}

sub enable_NFS() {
   my ($in, $out);

   if ($args > 4) {
        if ($args < 6 || $ARGV[4] ne ("-v")) {
            print_usage_and_exit();
        }
        $server->set_vserver($ARGV[5]);
    }
    $in = NaElement->new("nfs-enable");
    $out = $server->invoke_elem($in);
    if ($out->results_status() eq "failed") {
        print($out->results_reason() ."\n");
        exit(-1);
    }
    print("NFS service enabled successfully! \n");
}

sub disable_NFS() {
    my ($in, $out);

    if ($args > 4) {
        if ($args < 6 || $ARGV[4] ne ("-v")) {
            print_usage_and_exit();
        }
        $server->set_vserver($ARGV[5]);
    }
    $in = NaElement->new("nfs-disable");
    $out = $server->invoke_elem($in);
    if ($out->results_status() eq "failed") {
        print($out->results_reason() ."\n");
        exit(-1);
    }
    print("NFS service disabled successfully! \n");
}

sub show_NFS() {
    my ($in, $out);

    if ($args > 4) {
        if ($args < 6 || $ARGV[4] ne ("-v")) {
            print_usage_and_exit();
        }
        $server->set_vserver($ARGV[5]);
    }
    $in = NaElement->new("nfs-service-get");
    $out = $server->invoke_elem($in);
    if ($out->results_status() eq "failed") {
        print($out->results_reason() ."\n");
        exit(-1);
    }
    my $attrs = $out->child_get("attributes");
    if (!defined($attrs)) {
        print("NFS information in not available\n");
    }
    my $nfsInfo = $attrs->child_get("nfs-info");
    my $nfsAccess = "enabled";
    if ($nfsInfo->child_get_string("is-nfs-access-enabled") eq "false") {
        $nfsAccess = "disabled";
    }
    my $nfsv3 = "enabled";
    if ($nfsInfo->child_get_string("is-nfsv3-enabled") eq "false") {
        $nfsv3 = "disabled";
    }
    my $nfsv4 = "enabled";
    if ($nfsInfo->child_get_string("is-nfsv40-enabled") eq "false") {
        $nfsv4 = "disabled";
    }
    print("----------------------------------------------------\n");
    print("Vserver Name            : " . $nfsInfo->child_get_string("vserver") . "\n");
    print("General NFS access      : " . $nfsAccess . "\n");
    print("NFS v3                  : " . $nfsv3 . "\n");
    print("NFS v4.0                : " . $nfsv4 . "\n");
    print("----------------------------------------------------\n");
}

sub create_Lif () {
    my ($in, $out, $index, $vserver, $ipAddr, $gateway);

    $index = 4;
    $in = NaElement->new("net-interface-create");
    $vserver = $ARGV[$index++];
    $in->child_add_string("vserver", $vserver);
    $in->child_add_string("interface-name", $ARGV[$index++]);
    $ipAddr = $ARGV[$index++];
    $in->child_add_string("address", $ipAddr);
    $in->child_add_string("netmask", $ARGV[$index++]);
    $gateway = $ARGV[$index++];
    $in->child_add_string("home-node", $ARGV[$index++]);
    $in->child_add_string("home-port", $ARGV[$index++]);
    $in->child_add_string( "firewall-policy", "mgmt");
    $in->child_add_string("role", "data");
    $in->child_add_string("return-record", "true");
    $out = $server->invoke_elem($in);
    if ($out->results_status() eq "failed") {
        print($out->results_reason() ."\n");
        exit(-1);
    }
    my $netLifInfo = $out->child_get("result")->child_get("net-interface-info");
    my $routingGroup = $netLifInfo->child_get_string("routing-group-name");
    $in = NaElement->new("net-routing-group-route-get-iter");
    my $query = NaElement->new("query");
    my $info = NaElement->new("routing-group-route-info");
    $info->child_add_string("routing-group", $routingGroup);
    $info->child_add_string("vserver", $vserver);
    $query->child_add($info);
    $in->child_add($query);
    $out = $server->invoke_elem($in);
    if ($out->child_get_string("num-records") ne "0") {
        print("LIF created successfully! \n");
        return;
    }
    $in = NaElement->new("net-routing-group-route-create");
    $in->child_add_string("vserver", $vserver);
    my $destAddr = "0.0.0.0" . "/" . "0";
    $in->child_add_string("destination-address", $destAddr);
    $in->child_add_string( "gateway-address", $gateway);
    $in->child_add_string("routing-group", $routingGroup);
    $out = $server->invoke_elem($in);
    if ($out->results_status() eq "failed") {
        print($out->results_reason() ."\n");
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
        $in = NaElement->new("net-interface-get-iter");
        if ($tag ne "") {
            $in->child_add_string("tag", $tag);
        }
        $out = $server->invoke_elem($in);
        if ($out->results_status() eq "failed") {
            print($out->results_reason() ."\n");
            exit(-1);
        }
        if ($out->child_get_int("num-records") == 0) {
            print("No interface information available \n");
            return;
        }
        $tag = $out->child_get_string("next-tag");
        my @lifList = $out->child_get("attributes-list")->children_get();
        my $lifInfo;
        print("----------------------------------------------------\n");
        foreach $lifInfo (@lifList) {
            print("Vserver Name            : " . $lifInfo->child_get_string("vserver") . "\n");
            print("Address                 : " . $lifInfo->child_get_string("address") . "\n");
            print("Logical Interface Name  : " . $lifInfo->child_get_string("interface-name") . "\n");
            print("Netmask                 : " . $lifInfo->child_get_string("netmask") . "\n");
            print("Routing Group Name      : " . $lifInfo->child_get_string("routing-group-name") . "\n");
            print("Firewall Policy         : " . $lifInfo->child_get_string("firewall-policy") . "\n");
            print("Administrative Status   : " . $lifInfo->child_get_string("administrative-status") . "\n");
            print("Operational Status      : " . $lifInfo->child_get_string("operational-status") . "\n");
            print("Current Node            : " . $lifInfo->child_get_string("current-node") . "\n");
            print("Current Port            : " . $lifInfo->child_get_string("current-port") . "\n");
            print("Is Home                 : " . $lifInfo->child_get_string("is-home") . "\n");
            print("----------------------------------------------------\n");
        }
    }
}

sub show_aggregates() {
    my ($in, $out, $tag);
    $tag = "";

    while (defined($tag)) {
        $in = NaElement->new("aggr-get-iter");
        if ($tag ne "") {
            $in->child_add_string("tag", $tag);
        }
        $out = $server->invoke_elem($in);
        if ($out->child_get_int("num-records") == 0) {
            print("No aggregate(s) information available\n");
            return;
        }
        $tag = $out->child_get_string("next-tag");
        my @aggrList = $out->child_get("attributes-list")->children_get();
        my $aggrInfo;
        print("----------------------------------------------------\n");
        foreach $aggrInfo (@aggrList) {
            print("Aggregate Name          : " . $aggrInfo->child_get_string("aggregate-name") . "\n");
            my $aggrSizeAttrs = $aggrInfo->child_get("aggr-space-attributes");
            print("Size (bytes)            : " . $aggrSizeAttrs->child_get_string("size-total") . "\n");
            print("Available Size (bytes)  : " . $aggrSizeAttrs->child_get_string("size-available") . "\n");
            print("Used Percentage         : " . $aggrSizeAttrs->child_get_string("percent-used-capacity") . "\n");
            my $aggrRaidAttrs = $aggrInfo->child_get("aggr-raid-attributes");
            print("Aggregate State         : " . $aggrRaidAttrs->child_get_string("state") . "\n");
            print("----------------------------------------------------\n");
        }
    }
}

sub add_aggregates() {
    my ($in, $out, $index, $aggr_list);

    $index = 4;
    $in = NaElement->new("vserver-modify");
    $in->child_add_string("vserver-name", $ARGV[$index++]);
    $aggr_list = NaElement->new("aggr-list");
    while ($index < $args) {
        $aggr_list->child_add_string("aggr-name", $ARGV[$index++]);
    }
    $in->child_add($aggr_list);
    $out = $server->invoke_elem($in);
    if ($out->results_status() eq "failed") {
        print($out->results_reason() ."\n");
        exit(-1);
    }
    print("Aggregate(s) added successfully! \n");
}

sub show_nodes() {
    my ($in, $out, $tag);
    $tag = "";

    while (defined($tag)) {
        $in = NaElement->new("system-node-get-iter");
        if ($tag ne "") {
            $in->child_add_string("tag", $tag);
        }
        $out = $server->invoke_elem($in);
        if ($out->child_get_int("num-records") == 0) {
            print("No node(s) information available\n");
            return;
        }
        $tag = $out->child_get_string("next-tag");
        my @nodeInfoList = $out->child_get("attributes-list")->children_get();
        my $nodeInfo;
        print("----------------------------------------------------\n");
        foreach $nodeInfo (@nodeInfoList) {
            print("Node Name               : " . $nodeInfo->child_get_string("node") . "\n");
            print("UUID                    : " . $nodeInfo->child_get_string("node-uuid") . "\n");
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
    $in = NaElement->new("export-rule-create");
    $in->child_add_string("policy-name", "default");
    $in->child_add_string("client-match", "0.0.0/0");
    $in->child_add_string("rule-index", "1");
    $roRule = NaElement->new("ro-rule");
    $roRule->child_add_string("security-flavor", "any");
    $rwRule = NaElement->new("rw-rule");
    $rwRule->child_add_string("security-flavor", "any");
    $in->child_add($roRule);
    $in->child_add($rwRule);
    $out = $server->invoke_elem($in);
    if ($out->results_status() eq "failed") {
        print($out->results_reason() ."\n");
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
        $in = NaElement->new("export-rule-get-iter");
        if ($tag ne "") {
            $in->child_add_string("tag", $tag);
        }
        $out = $server->invoke_elem($in);
        if ($out->child_get_int("num-records") == 0) {
            print("No export rule(s) information available\n");
            return;
        }
        $tag = $out->child_get_string("next-tag");
        my @exportRuleList = $out->child_get("attributes-list")->children_get();
        my $exportRuleInfo;
        print("----------------------------------------------------\n");
        foreach $exportRuleInfo (@exportRuleList) {
            print("Vserver                 : " . $exportRuleInfo->child_get_string("vserver-name") . "\n");
            print("Policy Name             : " . $exportRuleInfo->child_get_string("policy-name") . "\n");
            print("Rule Index              : " . $exportRuleInfo->child_get_string("rule-index") . "\n");
            print("Access Protocols        : ");
            my @protocolList = $exportRuleInfo->child_get("protocol")->children_get();
            my $protocol;
            foreach $protocol (@protocolList) {
               print($protocol->get_content() . " ");
            }
            print("\nClient Match Spec       : " . $exportRuleInfo->child_get_string("client-match") . "\n");
            print("RO Access Rule          : ");
            my @roRuleList = $exportRuleInfo->child_get("ro-rule")->children_get();
            my $roRule;
            foreach $roRule (@roRuleList) {
                print($roRule->get_content() . " ");
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
        $in = NaElement->new("nis-get-iter");
        if ($tag ne "") {
            $in->child_add_string("tag", $tag);
        }
        $out = $server->invoke_elem($in);
        if ($out->child_get_int("num-records") == 0) {
            print("No nis domain information available \n");
            return;
        }
        $tag = $out->child_get_string("next-tag");
        my @nisDomainList = $out->child_get("attributes-list")->children_get();
        my $nisDomainInfo;
        my $nisServers;
        print("----------------------------------------------------\n");
        foreach $nisDomainInfo (@nisDomainList) {
            print("NIS Domain              : " . $nisDomainInfo->child_get_string("nis-domain") . "\n");
            print("Is Active               : " . $nisDomainInfo->child_get_string("is-active") . "\n");
            print("Vserver                 : " . $nisDomainInfo->child_get_string("vserver") . "\n");
            print("NIS Server(s)           : ");
            if (($nisServers = $nisDomainInfo->child_get("nis-servers"))) {
                my @ipaddrList = $nisServers->children_get();
                my $ipaddr;
                foreach $ipaddr (@ipaddrList) {
                   print($ipaddr->get_content() . " ");
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
    $in = NaElement->new("nis-create");
    $in->child_add_string("nis-domain", $ARGV[$index++]);
    $in->child_add_string("is-active", $ARGV[$index++]);
    $nisServers = NaElement->new("nis-servers");
    $nisServers->child_add_string("ip-address", $ARGV[$index++]);
    $in->child_add($nisServers);
    $out = $server->invoke_elem($in);
    if ($out->results_status() eq "failed") {
        print($out->results_reason() ."\n");
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
