#============================================================#
#                                                            #
#                                                            #
# vserverlist.pl                                             #
#                                                            #
# Sample code to list the vservers available in the cluster. #
# This sample code demonstrates the usage of new iterative   #
# vserver-get-iter API.                                      #
# This sample code is supported from Cluster-Mode            #
# Data ONTAP 8.1 onwards.                                    #
#                                                            #
# Copyright 2011 NetApp, Inc. All rights reserved.           #
# Specifications subject to change without notice.           #
#                                                            #
#============================================================#

use lib "../../../../../lib/perl/NetApp"; 
use NaServer;
use NaElement;
use strict;

my $args = $#ARGV + 1;
my ($server, $ipaddr, $user, $passwd);


sub print_usage_and_exit() {
    print("\nUsage: \n");
    print("vserverlist <cluster/vserver> <user> <passwd> [-v <vserver-name>] \n");
    print("<cluster>             -- IP address of the cluster \n");
    print("<vserver>             -- IP address of the vserver \n");
    print("<user>                -- User name \n");
    print("<passwd>              -- Password \n");
    print("<vserver-name>        -- Name of the vserver \n\n");
    print("Note: \n");
    print(" -v switch is required when you want to tunnel the command to a vserver using cluster interface \n\n");
    exit (-1);
}

sub list_vservers {
   my ($in, $out);
    my ($rootVol, $rootVolAggr, $secStyle, $state);
    my $tag = "";

   if ($args > 3) {
        if ($args < 5 || $ARGV[3] ne ("-v")) {
            print_usage_and_exit();
        }
        $server->set_vserver($ARGV[4]);
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
            my $allowedProtocols;
            print("Allowed protocols       : ");
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

sub main() {

    if ($args < 3) {
        print_usage_and_exit();
    }
    $ipaddr = $ARGV[0];
    $user = $ARGV[1];
    $passwd = $ARGV[2];

    $server = NaServer->new($ipaddr, 1, 15);
    $server->set_style("LOGIN");
    $server->set_admin_user($user, $passwd);
    $server->set_transport_type("HTTP");
    list_vservers();
}

main();
