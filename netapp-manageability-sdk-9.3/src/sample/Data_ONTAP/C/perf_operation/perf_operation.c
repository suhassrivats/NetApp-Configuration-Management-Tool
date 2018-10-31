//=======================================================================//
//                                                                       //
// $ID$                                                                  //
//                                                                       //
// perf_operation.c                                                      //
//                                                                       //
// Brief information of the contents                                     //
//                                                                       //
// Copyright 2002-2003 Network Appliance, Inc. All rights                //
// reserved. Specifications subject to change without notice.            //
//                                                                       //
// This SDK sample code is provided AS IS, with no support or            //
// warranties of any kind, including but not limited to                  //
// warranties of merchantability or fitness of any kind,                 //
// expressed or implied.  This code is subject to the license            //
// agreement that accompanies the SDK.                                   //
//                                                                       //
//  Sample for usage of following perf group API:                        //
//          perf-object-list-info                                        //
//          perf-object-counter-list-info                                //
//          perf-object-instance-list-info                               //
//          perf-object-get-instances-iter-*                             //
//                                                                       //
// Usage:                                                                //
// perf_operation <filer> <user> <password> <operation>                  //
//                                                                       //
// <filer>      -- Name/IP address of the filer                          //
// <user>       -- User name                                             //
// <password>   -- Password                                              //
// <operation>  --                                                       //
//      object-list - Get the list of perforance objects                 //
//                in the system                                          //
//      instance-list - Get the list of instances for a given            //
//                  performance object                                   //
//      counter-list - Get the list of counters available for a          //
//                 given performance object                              //
//      get-counter-values - get the values of the counters for          //
//                   all instance of a performance object                //
//=======================================================================//


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netapp_api.h>


void print_usage() {
	printf("\nUsage : perf_operation <filer> <user> <passwd> <operation> [<objectname> <counter1> <counter2> ..]\n");
	printf("<filer>	-- ");
	printf("Name/IP address of the filer\n");
	printf("<user>	-- User Name\n");
	printf("<passwd>	-- Password\n");
	printf("<operation>	--\n");
	printf("  object-list - Get the list of perforance objects in the system\n");
	printf("  instance-list - Get the list of instances for a given performance object\n");
	printf("  counter-list - Get the list of counters available for a given performance object\n");
	printf("  get-counter-values - Get the values of the counters for all the instances of a performance object\n");
	exit(-1);
}


/****************************************************************************
 Name: Main

 Description: Initializes the server context object and calls the
	      appropriate perf API commands based on the input arguments

 Parameters:
      IN:
	argc 	- number of command line arguments
	argv	- Array of command line arguments

 Return value: None
******************************************************************************/

int main(int argc, char* argv[])
{
	na_server_t*    s;
	na_elem_t       *out,*in;
	na_elem_t*	nextElem = NULL;
	na_elem_t*	iterList = NULL;
	na_elem_t*	counterList = NULL;
	na_elem_iter_t	iter, counterIter;
	char*           filerip    = argv[1];
	char*           user   	   = argv[2];
	char*           passwd 	   = argv[3];
	char*           operation  = argv[4];
	char            err[256];

	if (argc < 5) {
		print_usage();
	}

	// One-time initialization of system on client
	if (!na_startup(err, sizeof(err))) {
		fprintf(stderr, "Error in na_startup: %s\n", err);
		return -2;
	}

	//
	// Initialize connection to server, and request version 1.0 of the API set.
	//
	s = na_server_open(filerip, 1, 0);

	//
	// Set connection style (HTTP)
	//
	na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
	na_server_set_transport_type(s,NA_SERVER_TRANSPORT_HTTP, NULL);
	na_server_adminuser(s,user,passwd);

	if(!strcmp(operation, "object-list")) {
		in = na_elem_new("perf-object-list-info");
		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			na_elem_free(in);
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return -3;
		}
		iterList = na_elem_child(out, "objects");
		if(iterList == NULL) {
			// no data to list
			na_elem_free(in);
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return -3;
		}
		printf("\n-------------------------------------------------------\n");
		printf(" Object Name                           Privilege Level");
		printf("\n-------------------------------------------------------\n");
		for (iter=na_child_iterator(iterList); (nextElem =na_iterator_next(&iter)) != NULL;  ) {
			printf(" %-35s    %s\n",
			na_child_get_string(nextElem, "name"),
			na_child_get_string(nextElem, "privilege-level"));
		}
		printf("\n--------------------------------------------------------\n");

	}
	else if(!strcmp(operation, "instance-list")) {

		if( argc < 6) {
			printf("Usage:\n");
			printf("perf_operation <filer> <user> <password> <instance-list> <objectname>\n");
			return -1;
		}

		in = na_elem_new("perf-object-instance-list-info");
		na_child_add_string(in,"objectname",argv[5]);
		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
        	printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			na_elem_free(in);
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return -3;
		}
		iterList = na_elem_child(out, "instances");
		if(iterList == NULL) {
			// no data to list
			na_elem_free(in);
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return -3;
		}
		for (iter=na_child_iterator(iterList); (nextElem =na_iterator_next(&iter)) != NULL;  ) {
			printf("Instance Name = %s\n", na_child_get_string(nextElem, "name"));
		}

	}
	else if(!strcmp(operation, "counter-list")) {

		if( argc < 6) {
			printf("Usage:\n");
			printf("perf_operation <filer> <user> <password> <counter-list> <objectname>\n");
			return -1;
		}

		in = na_elem_new("perf-object-counter-list-info");
		na_child_add_string(in,"objectname",argv[5]);

		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
        	printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			na_elem_free(in);
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return -3;
		}
		iterList = na_elem_child(out, "counters");
		if(iterList == NULL) {
			// no data to list
			na_elem_free(in);
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return -3;
		}
		for (iter=na_child_iterator(iterList); (nextElem =na_iterator_next(&iter)) != NULL;  ) {

			printf("counter name: %s\n",na_child_get_string(nextElem, "name"));

			if(na_child_get_string(nextElem,"base-counter") != NULL) {
				printf("Base counter: %s\n",na_child_get_string(nextElem,"base-counter"));
			}
			else {
				printf("base counter: none\n");
			}
			printf("privilege-level: %s\n",na_child_get_string(nextElem,"privilege-level"));

			if(na_child_get_string(nextElem,"unit") != NULL) {
				printf("unit: %s\n",na_child_get_string(nextElem,"unit"));
			}
			else {
				printf("Unit: none\n");
			}
			printf("\n");
		}

	}
	else if(!strcmp(operation, "get-counter-values")) {

		int total_records = 0;
		int max_records = 10;
		int num_records = 0;
		char* iter_tag = NULL;
		na_elem_t *counters = NULL;
		int num_counter = 6;

		/* Here num_counter has been hard coded as 6 because first counter
			is specified at 7th position from cmd prompt */

		if( argc < 6) {
			printf("Usage:\n");
			printf("perf_operation <filer> <user> <password> ");
			printf("<get-counter-values> <objectname> [<counter1> <counter2> ..]\n");
			return -1;
		}

		in = na_elem_new("perf-object-get-instances-iter-start");
		na_child_add_string(in,"objectname",argv[5]);

		counters = na_elem_new("counters");

		/*Now store rest of the counter names as child element of counters */
		while(num_counter < argc) {
			na_child_add_string(counters, "counter",argv[num_counter]);
			num_counter++;
		}

		/* If no counters are specified then all the counters are fetched */
		if(num_counter > 6) {
			na_child_add(in,counters);
		}

		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
        	printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			na_elem_free(in);
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return -3;
		}
		total_records = na_child_get_int(out,"records",-1);
		iter_tag = (char *)na_child_get_string(out,"tag");

		do {
			in = na_elem_new("perf-object-get-instances-iter-next");
			na_child_add_string(in,"tag",iter_tag);
			na_child_add_int(in,"maximum", max_records);

			out = na_server_invoke_elem(s,in);
			if (na_results_status(out) != NA_OK) {
        		printf("Error %d: %s\n", na_results_errno(out),
				na_results_reason(out));
				na_elem_free(in);
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
        		return -3;
			}
			num_records = na_child_get_int(out,"records",0);

			if(num_records != 0) {
				iterList = na_elem_child(out, "instances");
				if(iterList == NULL) {
					// no data to list
					na_elem_free(in);
					na_elem_free(out);
					na_server_close(s);
					na_shutdown();
					return -3;
				}
				for (iter=na_child_iterator(iterList); (nextElem =na_iterator_next(&iter)) != NULL;  ) {
					printf("Instance = %s\n", na_child_get_string(nextElem,"name"));
					counterList = na_elem_child(nextElem,"counters");
					if(counterList == NULL) {
						// no data to list
						na_elem_free(in);
						na_elem_free(out);
						na_server_close(s);
						na_shutdown();
						return -3;
					}
					for (counterIter=na_child_iterator(counterList); (nextElem =na_iterator_next(&counterIter)) != NULL;  ) {
						printf("\ncounter name: %s\n",na_child_get_string(nextElem,"name"));
						printf("counter value: %s\n", na_child_get_string(nextElem,"value"));
					}
					printf("\n");
				}
			}
		} while (num_records != 0);

		in = na_elem_new("perf-object-get-instances-iter-end");
		na_child_add_string(in,"tag",iter_tag);
		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out), na_results_reason(out));
			na_elem_free(in);
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return -3;
		}
	}
	else {
		printf("Invalid Operation \n");
		print_usage();
	}
	na_elem_free(in);
	na_elem_free(out);
	na_server_close(s);
	na_shutdown();
	return 0;
}
