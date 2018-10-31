//============================================================//
//                                                            //
//                                                            //
// vollist.c                                                  //
//                                                            //
// Sample code to list the volumes available in the cluster.  //
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
	fprintf(stderr, "vollist <cluster/vserver> <user> <passwd> [-v <vserver-name>] \n");
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
	na_elem_t *out, *attrs, *volume;
	na_elem_t *vol_id_attr, *vol_state_attr, *vol_size_attr;
	char err[256];
	char *ipaddr = argv[1];
	char *user = argv[2];
	char *passwd = argv[3];
	char *vserver_name = argv[5];
	na_elem_iter_t iter;
	char *tag = "";
	char *vserver, *vol_name, *aggr_name, *vol_type, *vol_state, *size, *avail_size;

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
			out = na_server_invoke(server, "volume-get-iter", NULL);
		} else {
			out = na_server_invoke(server, "volume-get-iter", "tag", tag, NULL);
		}
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -1; 
		}
		if (na_child_get_int(out, "num-records", 0) == 0) {
			fprintf(stderr, "No volume(s) information available \n");
			return -1;
		}
		tag = (char *) na_child_get_string(out, "next-tag");
		attrs = na_elem_child(out, "attributes-list");
		printf("----------------------------------------------------\n");
		for (iter = na_child_iterator(attrs); (volume = na_iterator_next(&iter)) != NULL;  ) {
			vserver = vol_name = aggr_name = vol_type = vol_state = size = avail_size = "";
			vol_id_attr = na_elem_child(volume, "volume-id-attributes");
			vol_state_attr = na_elem_child(volume, "volume-state-attributes");
			vol_size_attr = na_elem_child(volume, "volume-space-attributes");
			if (vol_id_attr != NULL) {
				vserver = (char *) na_child_get_string(vol_id_attr, "owning-vserver-name");
				vol_name = (char *) na_child_get_string(vol_id_attr, "name");
				aggr_name = (char *) na_child_get_string(vol_id_attr, "containing-aggregate-name");
				vol_type = (char *) na_child_get_string(vol_id_attr, "type");
			}
			if (vol_state_attr != NULL) {
				vol_state = (char *) na_child_get_string(vol_state_attr, "state");
			}
			if (vol_size_attr != NULL) {
				size = (char *) na_child_get_string(vol_size_attr, "size");
				avail_size = (char *) na_child_get_string(vol_size_attr, "size-available");
			}
			printf("Vserver Name            : %s \n", (vserver != NULL ? vserver : ""));
			printf("Volume Name             : %s \n", (vol_name != NULL ? vol_name : ""));
			printf("Aggregate Name          : %s \n", (aggr_name != NULL ? aggr_name : ""));
			printf("Volume type             : %s \n", (vol_type != NULL ? vol_type : ""));
			printf("Volume state            : %s \n", (vol_state != NULL ? vol_state : ""));
			printf("Size (bytes)            : %s \n", (size != NULL ? size : ""));
			printf("Available Size (bytes)  : %s \n", (avail_size != NULL ? avail_size : ""));
			printf("----------------------------------------------------\n");
		}
	}
	na_elem_free(out);
	na_server_close(server);
	na_shutdown();
	return 0;
}
