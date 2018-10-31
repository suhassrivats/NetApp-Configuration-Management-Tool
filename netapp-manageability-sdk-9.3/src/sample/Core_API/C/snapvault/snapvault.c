//================================================================//
//								  //
// $Id: $						          //
// snapvault.c							  //
//								  //
// ONTAPI API Category: snapvault				  //
// Sample code for the following APIs:			  	  //
//	snapvault-primary-snapshot-schedule-list-info	  	  //
//	snapvault-primary-initiate-snapshot-create		  //
//	snapvault-secondary-relationship-status-list-iter-start	  //
//	snapvault-secondary-relationship-status-list-iter-next	  //
//	snapvault-secondary-relationship-status-list-iter-end	  //
//								  //	
//								  //
// This program demonstrates how to handle arrays		  //
//								  //
//								  //
// Copyright 2007 Network Appliance, Inc. All rights		  //
// reserved. Specifications subject to change without notice.	  //
//								  //
// This SDK sample code is provided AS IS, with no support or	  //
// warranties of any kind, including but not limited to 	  //
// warranties of merchantability or fitness of any kind,	  //
// expressed or implied.  This code is subject to the license	  //
// agreement that accompanies the SDK.				  //
//								  //
//								  //
// Usage:							  //
// snapvault <filer> <user> <password> <operation> [<value1>] [<value2>]//
// <filer>	-- Name/IP address of the filer			  //
// <user>	-- User name					  //
// <password>	-- Password					  //
// <operation>	-- scheduleList/snapshotCreate/relationshipStatus//
// <value1>	-- This depends on the operation		  //
// <value2> 	-- This depends on the operation		  //
//================================================================//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "netapp_api.h"

int main(int argc, char* argv[])
{
	int 		r = 1, i = 0;
	na_server_t*	s;
	na_elem_t*		out;
	na_elem_t*		outputElem;
	na_elem_t*		records;
	na_elem_t*		ss;
	na_elem_t * 		elem = 0;
	na_elem_t* next_elem=0;
	na_elem_iter_t	iter;
	char			err[256];
	char*			filername = argv[1];
	char*			user = argv[2]; 
	char*			passwd = argv[3];
	char*			operation = argv[4];
	char*				value1 = argv[5];
	char*			value2 = argv[6];
	char tag[50] = {0}; 
	int recordsCnt = 0;

	if (argc < 5) {
		fprintf(stderr, "Usage: snapvault <filer> <user> <password> "); 
		fprintf(stderr,	"<operation> [<value1>] [<value2>]\n");
		fprintf(stderr, "<filer>	  --"); 
		fprintf(stderr, "Name/IP address of the filer \n");
		fprintf(stderr, "<user> 	  -- User name\n");
		fprintf(stderr, "<password>   -- Password\n");
		fprintf(stderr, "<operation>  -- "); 
		fprintf(stderr, "scheduleList/snapshotCreate/relationshipStatus\n");
		fprintf(stderr, "<value1>\t-- This depends on the operation\n");
		fprintf(stderr, "<value2>\t-- This depends on the operation\n");
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
	// List the configured snapshot schedules
	// Usage: snapvault <filer> <user> <password> scheduleList [<volumeName>]
	//
	if(!strcmp(operation, "scheduleList"))
	{
		if(value1 != NULL)
		{ 
			out = na_server_invoke(s, 
				"snapvault-primary-snapshot-schedule-list-info", 
				"volume-name", value1, NULL); 
		}
		else
		{
			out = na_server_invoke(s,
				"snapvault-primary-snapshot-schedule-list-info",
				NULL);
		}

		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {			
			outputElem = na_elem_child(out, "snapshot-schedules");
			if (outputElem == NULL) {
				//Did not return any value
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}

			//
			// dig out the info
			//
			printf("--------------------------------------------\n");

			for (iter = na_child_iterator(outputElem);
			(ss = na_iterator_next(&iter)) != NULL;  ) {				
				//
				// dig out the info
				//

				if ((na_child_get_string(ss, "retention-count"))!= NULL)
				{
					printf("Retention count: %s\n",
							na_child_get_string(ss, "retention-count"));
				}

				if ((na_child_get_string(ss, "schedule-name"))!= NULL)
				{					
					printf("Schedule name: %s\n",
							na_child_get_string(ss, "schedule-name"));
				}

				if ((na_child_get_string(ss, "volume-name"))!= NULL)
				{
					printf("Volume name: %s\n",
							na_child_get_string(ss, "volume-name"));
				}

				printf("------------------------------------------\n");				  
			}
		}
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 0;
	}

	//
	// Create Snapshot
	// Usage: snapvault <filer> <user> <password> snapshotCreate 
	//			<value1(ScheduleName)> <value2(volumeName)>
	//
	else if(!strcmp(operation, "snapshotCreate"))
	{
		if((value1 != NULL) && (value2 != NULL))
		{
			out = na_server_invoke(s, "snapvault-primary-initiate-snapshot-create", 
				"schedule-name", value1, "volume-name", value2, NULL);
		}
		else
		{
			printf("Schedule name and Volume name not provided\n");
			na_server_close(s);
			na_shutdown();
			return 1;
		}
		
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Snapshot created\n");
		}
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 0;
	}

	//
	// Usage: snapvault <filer> <user> <password> relationshipStatus
	//
	else if(!strcmp(operation, "relationshipStatus"))
	{
		out = na_server_invoke(s, 
			"snapvault-secondary-relationship-status-list-iter-start", NULL);
		
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			outputElem = na_elem_child(out, "records");
			if (outputElem == NULL) {
				//Did not return any value
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 1;
			}
			
			//
			// dig out the info
			//
			printf("--------------------------------------------\n");

			if ((na_child_get_string(out, "records")) != NULL)
			{
				recordsCnt=atoi(na_child_get_string(out, "records"));
				printf("Records: %d\n", recordsCnt);
			}

			if ((na_child_get_string(out, "tag")) != NULL)
			{
				strcpy(tag, na_child_get_string(out, "tag"));
				printf("Tag: %s\n", tag);  
			}

			printf("--------------------------------------------\n");

			for(i=0; i < recordsCnt; i++)
			{	
				next_elem = na_server_invoke(s, 
				"snapvault-secondary-relationship-status-list-iter-next",
				"maximum", "1", "tag", tag, NULL);	

				if (na_results_status(next_elem) != NA_OK) {
					printf("Error %d: %s\n", na_results_errno(next_elem),
					na_results_reason(next_elem));
					return -3;
				}
				else {
					outputElem = na_elem_child(next_elem, "records");
					if (outputElem == NULL) {
						//Did not return any value
						na_elem_free(next_elem);
						na_server_close(s);
						na_shutdown();
						return 1;
					}

					//
					// dig out the info
					//
					printf("--------------------------------------------\n");

					if ((na_child_get_string(next_elem, "records")) != NULL)
					{						
						printf("Records : %d\n", 
							atoi(na_child_get_string(next_elem, "records")));
					}

					records = na_elem_child(next_elem, "status-list");
					if (records == NULL) {
						//Did not return any value
						na_elem_free(next_elem);
						na_server_close(s);
						na_shutdown();
						return 0;
					}

					//
					// dig out the info
					//
					printf("--------------------------------------------\n");

					for (iter = na_child_iterator(records);
					(ss = na_iterator_next(&iter)) != NULL;  ) {

						//
						// dig out the info
						//

						if ((na_child_get_string(ss, "destination-path"))!= NULL)
						{
							printf("Destination path: %s\n",
									na_child_get_string(ss, "destination-path"));
						}

						if ((na_child_get_string(ss, "destination-system"))!= NULL)
						{
							printf("Destination system: %s\n",
									na_child_get_string(ss, "destination-system"));
						}

						if ((na_child_get_string(ss, "source-path"))!= NULL)
						{
							printf("Source path: %s\n",
									na_child_get_string(ss, "source-path"));
						}

						if ((na_child_get_string(ss, "source-system"))!= NULL)
						{
							printf("Source system: %s\n",
									na_child_get_string(ss, "source-system"));
						}

						if ((na_child_get_string(ss, "state"))!= NULL)
						{
							printf("State: %s\n",
									na_child_get_string(ss, "state"));
						}						

						if ((na_child_get_string(ss, "status"))!= NULL)
						{
							printf("Status: %s\n",
									na_child_get_string(ss, "status"));
						}

					}	
				}
			}

			ss = na_server_invoke(s,
				"snapvault-secondary-relationship-status-list-iter-end",
				"tag", tag, NULL);

		}
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	
	else
	{
		fprintf(stderr, "Invalid operation\n");
		fprintf(stderr, 
			"--------------------------------------------------\n");
		fprintf(stderr, "Usage: snapvault <filer> <user> <password> "); 
		fprintf(stderr,	"<operation> [<value1>] [<value2>]\n");
		fprintf(stderr, "<filer>	  --"); 
		fprintf(stderr, "Name/IP address of the filer \n");
		fprintf(stderr, "<user> 	  -- User name\n");
		fprintf(stderr, "<password>   -- Password\n");
		fprintf(stderr, "<operation>  -- "); 
		fprintf(stderr, "scheduleList/snapshotCreate/relationshipStatus\n");
		fprintf(stderr, "<value1>\t-- This depends on the operation\n");
		fprintf(stderr, "<value2>\t-- This depends on the operation\n");	
		return -1;
	}
	
	na_elem_free(out);
	na_server_close(s);
	na_shutdown();
	return 0;
		
}
