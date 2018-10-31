//==================================================================//
//								//
// $Id: $							//
// snapmirror.c							//
//								//
// ONTAPI API Category: Snapmirror				//
// Sample code for the following API:				//
//		snapmirror-get-status				//
//		snapmirror-get-volume-status			//
//		snapmirror-initialize				//
//		snapmirror-release				//
//		snapmirror-on					//
//		snapmirror-off					//
//								//
//								//
// This program demonstrates how to handle arrays		//
//								//
//								//
// Copyright 2007 Network Appliance, Inc. All rights		//
// reserved. Specifications subject to change without notice.	//
//								//
// This SDK sample code is provided AS IS, with no support or	//
// warranties of any kind, including but not limited to		//
// warranties of merchantability or fitness of any kind,	//
// expressed or implied.  This code is subject to the license	//
// agreement that accompanies the SDK.				//
//								//
//								//
// Usage:							//
// snapmirror <filer> <user> <password> <operation> [<value1>] [<value2>]  //
//		[<value3>] [<value4>] [<value5>]		//
// <filer>	-- Name/IP address of the filer			//
// <user>	-- User name					//
// <password>	-- Password					//
// <operation>	-- getStatus/getVolStatus/initialize/release/off/on	//
// <value1>	-- This depends on the operation		//
// <value2> 	-- This depends on the operation		//
// <value3> 	-- This depends on the operation		//
// <value4> 	-- This depends on the operation		//
// <value5> 	-- This depends on the operation		//
//================================================================//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "netapp_api.h"

int main(int argc, char* argv[])
{
	int 			r = 1;
	na_server_t*		s;
	na_elem_t*		out;
	na_elem_t*		outputElem;
	na_elem_t*		ss;
	na_elem_iter_t		iter;
	int 			neltsread = 0;
	const char* 		ptr;
	char			err[256];
	char*			filername = argv[1];
	char*			user = argv[2]; 
	char*			passwd = argv[3];
	char*			operation = argv[4];
	char*			value1 = argv[5];
	char*			value2 = argv[6];
	char*			value3 = argv[7];
	char*			value4 = argv[8];
	char*			value5 = argv[9];

	if (argc < 5) {
		fprintf(stderr, "Usage: snapmirror <filer> <user> <password>");
		fprintf(stderr,	" <operation> [<value1>] [<value2>] [<value3>]");
		fprintf(stderr, " [<value4>] [<value5>]\n");
		fprintf(stderr, "<filer>	  -- Name/IP address of the filer\n");
		fprintf(stderr, "<user> 	  -- User name\n");
		fprintf(stderr, "<password>   -- Password\n");
		fprintf(stderr, "<operation>  -- getStatus/getVolStatus/"); 
		fprintf(stderr, "initialize/release/off/on\n");
		fprintf(stderr, "<value1>\t-- This depends on the operation\n");
		fprintf(stderr, "<value2>\t-- This depends on the operation\n");
		fprintf(stderr, "<value3>\t-- This depends on the operation\n");
		fprintf(stderr, "<value4>\t-- This depends on the operation\n");
		fprintf(stderr, "<value5>\t-- This depends on the operation\n");
		return -1;
	}
	
	//
	// One-time initialization of system on client
	//
	
	if (!na_startup(err, sizeof(err))) {
		fprintf(stderr, "Error in na_startup: %s\n", err);
		return -2;
	}
	
	//
	// Initialize connection to server, and
	// request version 1.1 of the API set.
	//
	s = na_server_open(filername, 1, 1); 
	
	//
	// Set connection style (HTTP)
	//
	na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
	na_server_adminuser(s, user, passwd);

	//
	// Get snapmirror status
	// Usage: 
	// snapmirror <filer> <user> <password> getStatus [<value1(location)>] 
	//
	if(!strcmp(operation, "getStatus"))
	{
		if(value1 != NULL) {
			out = na_server_invoke(s, "snapmirror-get-status",
					"location", value1, NULL);
		}
		else {
			out = na_server_invoke(s, "snapmirror-get-status",
					NULL);
		}

		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else 
		{
			outputElem = na_elem_child(out, "is-available");
			if (outputElem == NULL) {
				// Did not return any value
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 1;
			}

			//
			// dig out the info
			//

			printf("--------------------------------------------\n");

			if ((na_child_get_string(out, "is-available")) != NULL)
			{
				printf("Is snapmirror available: %s\n", 
						na_child_get_string(out, "is-available"));
			}

			outputElem = na_elem_child(out, "snapmirror-status");
			if (outputElem == NULL) {
				// Did not return any value
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}

			for (iter = na_child_iterator(outputElem);
			(ss = na_iterator_next(&iter)) != NULL;  ) {
				if ((na_child_get_string(ss, "base-snapshot")) != NULL)
				{
					printf("Base snapshot: %s\n", 
						na_child_get_string(ss, "base-snapshot"));
				}

				if ((na_child_get_string(ss, "contents")) != NULL)
				{
					printf("Contents: %s\n", 
						na_child_get_string(ss, "contents"));
				}

				if ((na_child_get_string(ss, "current-transfer-error"))!= NULL)
				{
					printf("Current transfer error: %s\n", 
						na_child_get_string(ss, "current-transfer-error"));
				}

				if ((na_child_get_string(ss, "current-transfer-type")) != NULL)
				{
					printf("Current transfer type: %s\n", 
						na_child_get_string(ss, "current-transfer-type"));
				}

				if ((na_child_get_string(ss, "destination-location")) != NULL)
				{
					printf("Destination location: %s\n",
						na_child_get_string(ss, "destination-location"));
				}

				if ((na_child_get_string(ss, "lag-time")) != NULL)
				{
					printf("Lag time: %d\n", 
						atoi(na_child_get_string(ss,"lag-time")));
				}

				if ((na_child_get_string(ss, "last-transfer-duration")) 
						!= NULL)
				{
					printf("Last transfer duration: %d\n", 
						atoi(na_child_get_string(ss,"last-transfer-duration")));
				}

				if ((na_child_get_string(ss, "last-transfer-from")) != NULL)
				{
					printf("Last transfer from: %s\n", 
						na_child_get_string(ss, "last-transfer-from"));
				}

				if ((na_child_get_string(ss, "last-transfer-size")) != NULL)
				{
					printf("Last transfer size: %d\n", 
						atoi(na_child_get_string(ss, "last-transfer-size")));
				}

				if ((na_child_get_string(ss, "last-transfer-type")) != NULL)
				{
					printf("Last transfer type: %s\n", 
						na_child_get_string(ss, "last-transfer-type"));
				}

				if ((na_child_get_string(ss, "mirror-timestamp")) != NULL)
				{
					printf("Mirror timestamp: %d\n", 
						atoi(na_child_get_string(ss, "mirror-timestamp")));
				}

				if ((na_child_get_string(ss, "source-location")) != NULL)
				{
					printf("Source location: %s\n", 
						na_child_get_string(ss, "source-location"));
				}

				if ((na_child_get_string(ss, "state")) != NULL)
				{
					printf("State: %s\n", na_child_get_string(ss, "state"));
				}

				if ((na_child_get_string(ss, "status")) != NULL)
				{
					printf("Status: %s\n", na_child_get_string(ss, "status"));
				}

				if ((na_child_get_string(ss, "transfer-progress")) != NULL)
				{
					printf("Transfer progress: %d\n", 
						atoi(na_child_get_string(ss, "transfer-progress")));
				}

				printf("------------------------------------\n");

				neltsread++;
			}
		}
		
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 0;
	}

	//
	// Get snapmirror volume status information
	// Usage: snapmirror <filer> <user> <password> getVolStatus <value1>
	//
	else if(!strcmp(operation, "getVolStatus"))
	{
		if(value1 != NULL)
		{
			out = na_server_invoke(s, "snapmirror-get-volume-status", 
				"volume", value1, NULL);
		}
		else
		{
			printf("Volume not provided\n");
			na_server_close(s);
			na_shutdown();
			return 1;
		}

		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else
		{
			outputElem = na_elem_child(out, "is-destination");
			if (outputElem == NULL) {
				// Did not return any value
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 1;
			}

			//
			// dig out the info
			//

			printf("--------------------------------------------\n");

			if ((na_child_get_string(out, "is-destination")) != NULL)
			{
				printf("Is destination: %s\n",
					na_child_get_string(out, "is-destination")); 
			}

			if ((na_child_get_string(out, "is-source")) != NULL)
			{
				printf("Is source: %s\n", na_child_get_string(out, "is-source"));
			}

			if ((na_child_get_string(out, "is-transfer-broken")) != NULL)
			{
				printf("Is transfer broken: %s\n", 
					na_child_get_string(out, "is-transfer-broken"));
			}

			if ((na_child_get_string(out, "is-transfer-in-progress")) != NULL)
			{
				printf("Is transfer in progress: %s\n", 
					na_child_get_string(out, "is-transfer-in-progress"));
			}
		}
		return 0;
	}

	//
	// Snapmirror initialize
	// Usage: snapmirror <filer> <user> <password> initialize 
	//		<value1(destinationLocation)> [<value2(destionationSnapshot)>]
	//		[<value3(maxTransferRate)>] [<value4(sourceLocation)>] 
	//		[<value5(sourceSnapshot)>]
	//
	else if(!strcmp(operation, "initialize"))
	{
		if(value2 != NULL) {
			out = na_server_invoke(s, "snapmirror-initialize", 
				"destination-location", value1, "destination-snapshot", value2,
				"max-transfer-rate", value3, "source-location", value4, 
				"source-snapshot", value5, NULL);
		}
		else {
			out = na_server_invoke(s, "snapmirror-initialize",
				"destination-location", value1, NULL); 
		}

		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Snapmirror initialization successful\n");
		}
		return 0;
	}

	//
	// Snapmirror Disable
	// Usage: snapmirror <filer> <user> <password> off
	//
	else if(!strcmp(operation, "off"))
	{
		out = na_server_invoke(s, "snapmirror-off", NULL);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Snapmirror data transfers disabled and ");
			printf("Snapmirror scheduler turned off\n");
		}
		return 0;
	}

	//
	// Enable Snapmirror
	// Usage: snapmirror <filer> <user> <password> on
	//
	else if(!strcmp(operation, "on"))
	{
		out = na_server_invoke(s, "snapmirror-on", NULL);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Snapmirror data transfers enabled and ");
			printf("Snapmirror scheduler turned on\n");
		}
		return 0;
	}

	//
	// Snapmirror release 
	// Usage: snapmirror <filer> <user> <password> release 
	//			<value1(destLocation)> <value2(sourceLocation)>
	//
	else if(!strcmp(operation, "release"))
	{
		out = na_server_invoke(s, "snapmirror-release", "destination-location",
				value1, "source-location", value2, NULL); 
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else
		{
			printf("SnapMirror informed that a direct mirror is ");
			printf("no longer going to make requests\n");
		}
		return 0;
	}

	else
	{
		fprintf(stderr, "Invalid operation\n");
		fprintf(stderr, "-------------------------------------------------\n");
		fprintf(stderr, "Usage: snapmirror <filer> <user> <password>");
		fprintf(stderr,	" <operation> [<value1>] [<value2>] [<value3>]");
		fprintf(stderr, "[<value4>] [<value5>]\n");
		fprintf(stderr, "<filer>	  -- Name/IP address of the filer\n");
		fprintf(stderr, "<user> 	  -- User name\n");
		fprintf(stderr, "<password>   -- Password\n");
		fprintf(stderr, "<operation>  -- getStatus/getVolStatus/"); 
		fprintf(stderr, "initialize/release/off/on\n");
		fprintf(stderr, "<value1>\t-- This depends on the operation\n");
		fprintf(stderr, "<value2>\t-- This depends on the operation\n");
		fprintf(stderr, "<value3>\t-- This depends on the operation\n");
		fprintf(stderr, "<value4>\t-- This depends on the operation\n");
		fprintf(stderr, "<value5>\t-- This depends on the operation\n");
		return -1;
	}
	
	na_elem_free(out);
	na_server_close(s);
	na_shutdown();
	return 0;
		
}

