//============================================================//
//                                                            //
//                                                            //
// vserverlist.c                                              //
//                                                            //
// Sample code to list the vservers available in the cluster. //
//                                                            //
// This sample code is supported from Cluster-Mode            //
// Data ONTAP 8.1 onwards.                                    //
//                                                            //
// Copyright 2011 NetApp, Inc. All rights reserved.           //
// Specifications subject to change without notice.           //
//                                                            //
//============================================================//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netapp_api.h>

void print_usage_and_exit() {
	fprintf(stderr, "Usage: \n");
	fprintf(stderr, "vserverlist <cluster/vserver> <user> <passwd> [-v <vserver-name>] \n");
	fprintf(stderr, "<cluster>             -- IP address of the cluster \n");
	fprintf(stderr, "<vserver>             -- IP address of the vserver \n");
	fprintf(stderr, "<user>                -- User name \n");
	fprintf(stderr, "<passwd>              -- Password \n");
	fprintf(stderr, "<vserver-name>        -- Name of the vserver \n");
	fprintf(stderr, "Note: ");
	fprintf(stderr, " -v switch is required when you want to tunnel the command to a vserver using cluster interface \n");
	exit(-1);
}

int main(int argc, char* argv[]) {
	na_server_t *server;
	na_elem_t *out, *attrs, *vserver;
	na_elem_t *protocols, *protocol, *ns_switches, *ns_switch;
	char err[256];
	char *ipaddr = argv[1];
	char *user = argv[2];
	char *passwd = argv[3];
	char *vserver_name = argv[5];
	const char *root_vol_aggr, *root_vol, *vol_sec_style, *state;
	na_elem_iter_t iter, proto_iter, ns_switch_iter;
	char *tag = "";

	if (argc < 4) {
		print_usage_and_exit();
	} 

	if (!na_startup(err, sizeof(err))) {
		fprintf(stderr, "Error in na_startup: %s\n", err);
		return -1;
	}

	// Initialize connection to server, and request version 1.15 of the API set
	server = na_server_open(ipaddr, 1, 15); 

	na_server_adminuser(server, user, passwd);

	if (argc > 4) {
		if (argc < 6 || strcmp(argv[4], "-v")) {
			print_usage_and_exit();
		}
		na_server_set_vserver(server, vserver_name);
	}

	while (tag != NULL) {
		if (!strcmp(tag, "")) {
			out = na_server_invoke(server, "vserver-get-iter", NULL);
		} else {
			out = na_server_invoke(server, "vserver-get-iter", "tag", tag, NULL);
		}
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out), 
			na_results_reason(out));
			return -1;          
		}
		if (na_child_get_int(out, "num-records", 0) == 0) {
			fprintf(stderr, "No vserver(s) information available \n");
			return -1;
		}
		tag = (char *) na_child_get_string(out, "next-tag");
		attrs = na_elem_child(out, "attributes-list");
		printf("----------------------------------------------------\n");
		for (iter = na_child_iterator(attrs); (vserver = na_iterator_next(&iter)) != NULL;  ) {
			root_vol_aggr = na_child_get_string(vserver, "root-volume-aggregate");
			root_vol = na_child_get_string(vserver, "root-volume");
			vol_sec_style = na_child_get_string(vserver, "root-volume-security-style");
			state = na_child_get_string(vserver, "state");
			printf("Name                    : %s \n", na_child_get_string(vserver, "vserver-name"));
			printf("Type                    : %s \n", na_child_get_string(vserver, "vserver-type"));
			printf("Root volume aggr        : %s \n", (root_vol_aggr != NULL ? root_vol_aggr : ""));
			printf("Root volume             : %s \n", (root_vol != NULL ? root_vol : ""));
			printf("Root volume sec style   : %s \n", (vol_sec_style != NULL ? vol_sec_style : ""));
			printf("UUID                    : %s \n", na_child_get_string(vserver, "uuid"));
			printf("State                   : %s \n", (state != NULL ? state : ""));
			printf("Allowed protocols       : ");
			protocols = na_elem_child(vserver, "allowed-protocols");
			for (proto_iter = na_child_iterator(protocols); (protocol = na_iterator_next(&proto_iter)) != NULL;  ) {
				printf("%s ", na_elem_get_content(protocol));
			}
			printf("\nName server switch      : ");
			ns_switches = na_elem_child(vserver, "name-server-switch");
			for (ns_switch_iter = na_child_iterator(ns_switches); (ns_switch = na_iterator_next(&ns_switch_iter)) != NULL;  ) {
				printf("%s ", na_elem_get_content(ns_switch));
			}
			printf("\n----------------------------------------------------\n");
		}
	}
	na_elem_free(out);
	na_server_close(server);
	na_shutdown();
	return 0;
}
