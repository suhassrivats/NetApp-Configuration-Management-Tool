#============================================================#
#                                                            #
#                                                            #
# vollist.pl                                                 #
#                                                            #
# Sample code to list the volumes available in the cluster.  #
#                                                            #
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
    print("vollist.pl <cluster/vserver> <user> <passwd> [-v <vserver-name>] \n");
    print("<cluster>             -- IP address of the cluster \n");
    print("<vserver>             -- IP address of the vserver \n");
    print("<user>                -- User name \n");
    print("<passwd>              -- Password \n");
    print("<vserver-name>        -- Name of the vserver \n\n");
    print("Note: \n");
    print(" -v switch is required when you want to tunnel the command to a vserver using cluster interface \n\n");
    exit (-1);
}

sub list_volumes {
    my ($in, $out, $tag);

    $tag = "";
   if ($args > 3) {
        if ($args < 5 || $ARGV[3] ne ("-v")) {
            print_usage_and_exit();
        }
        $server->set_vserver($ARGV[4]);
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
    list_volumes();
}

main();
