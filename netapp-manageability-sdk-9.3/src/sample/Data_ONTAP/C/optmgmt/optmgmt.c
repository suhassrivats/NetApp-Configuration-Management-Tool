//================================================================//
//						                  //
// $Id: $ 						          //
// optmgmt.c					        	  //
//								  //
// ONTAPI API lists option information, get value of a specific   // 
// option, and set value for a specific option.			  //
//								  //
// This program demonstrates how to handle arrays		  //
//								  //
//								  //
// Copyright 2007 Network Appliance, Inc. All rights		  //
// reserved. Specifications subject to change without notice.     // 
//								  //
// This SDK sample code is provided AS IS, with no support or 	  //
// warranties of any kind, including but not limited to 	  //
// warranties of merchantability or fitness of any kind,	  //
// expressed or implied.  This code is subject to the license     //
// agreement that accompanies the SDK.				  //
//								  //
//								  //
// Usage:							  // 
// optmgmt <filer> <user> <password> [<operation>] [<optionName>] [<value>]//
// <filer> 	-- Name/IP address of the filer			  //
// <user>  	-- User name					  //
// <password> 	-- Password					  //	
// <operation> 	-- get/set					  //
// <optionName>	-- Name of the option on which get/set operation  // 
//		   needs to be performed			  //
// <value> 	-- This is required only for set operation. 	  //
//		   Provide the value that needs to be assigned for//
//		   the option					  //     
//================================================================//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "netapp_api.h"
#include "optmgmt.h"

int main(int argc, char* argv[])
{
	int 		r = 1;
	na_server_t*	s;
	na_elem_t*		out;
	na_elem_t*		options;
	na_elem_t*		ss;
	na_elem_iter_t	iter;
	int 		neltsread = 0;
	char			err[256];
	char*			filername = argv[1];
	char*			user = argv[2]; 	
	char*			passwd = argv[3];
	char* 			operation = argv[4];
	char*                   option = argv[5];
	char* 			value = argv[6];
	OptionInfoPtr info;
	OptionInfoPtr infoptr;
	
	if (argc < 4) {
		fprintf(stderr,"Usage: optmgmt <filer> <user> <password> [<operation>] [<optionName>] [<value>]\n");
		fprintf(stderr, "<filer>      -- Name/IP address of the filer \n");
		fprintf(stderr, "<user>       -- User name\n");
		fprintf(stderr, "<password>   -- Password\n");
		fprintf(stderr, "<operation>  -- get/set\n");
		fprintf(stderr, "<optionName> -- Name of the option on which get/set operation\n");
		fprintf(stderr, "                needs to be performed\n");
		fprintf(stderr, "<value>      -- This is required only for set operation. \n");
		fprintf(stderr, "                Provide the value that needs to be assigned for\n");
		fprintf(stderr, "                the option  \n"); 
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
	
	if(operation != NULL) {

		//
		// Get particular option information
		//

		if(!strcmp(operation, "get"))
		{
			out = na_server_invoke(s, "options-get", "name", option, NULL); 
			if (na_results_status(out) != NA_OK) {
				printf("Error %d: %s\n", na_results_errno(out),
				na_results_reason(out));
				return -3;
			}
			else {
				options = na_elem_child(out, "value");
				if (options == NULL) {
					// no options to list

					na_elem_free(out);
					na_server_close(s);
					na_shutdown();
					return 1;
				}

				//
				// Allocate memory for the retrieved option
				//
				info = (OptionInfoPtr) malloc (sizeof(OptionInfo));
				if (info == NULL) {
					fprintf(stderr, "Memory allocation err at line %d\n", __LINE__);
					r = 0;
					na_elem_free(out);
					na_server_close(s);
					na_shutdown();
					return 0;
				}
				infoptr = info;

				//
				// dig out the info
				//

				printf("------------------------------------------------\n");
		
				if ((na_child_get_string(out, "value")) != NULL)
				{
					strcpy(infoptr->value, na_child_get_string(out, "value"));
					printf("Value: %s\n", infoptr->value);
				}

				if ((na_child_get_string(out, "cluster_constraint")) != NULL)
				{
					strcpy(infoptr->clusterConstraint, na_child_get_string(out, "cluster_constraint"));
					printf("cluster-constraint: %s\n", infoptr->clusterConstraint);
				}
				printf("------------------------------------------------\n");
			}
			return 0;
		}

		//
		// Set value for an option
		//
		else if(!strcmp(operation, "set"))
		{
			out = na_server_invoke(s, "options-set", "name", option, "value", value, NULL); 

			if (na_results_status(out) != NA_OK) {
				printf("Error %d: %s\n", na_results_errno(out),
				na_results_reason(out));
				return -3;
			}
			else {
				options = na_elem_child(out, "message");
				if (options == NULL) {
  					// no options to list

					na_elem_free(out);
					na_server_close(s);
					na_shutdown();
					return 1;
				}

				//
				// Allocate memory for option
				//
				info = (OptionInfoPtr) malloc (sizeof(OptionInfo));
				if (info == NULL) {
					fprintf(stderr, "Memory allocation err at line %d\n", __LINE__);

					r = 0;
					na_elem_free(out);
					na_server_close(s);
					na_shutdown();
					return 0;

				}
				infoptr = info;

				//
				// dig out the info
				//
				printf("------------------------------------------------\n");

				if ((na_child_get_string(out, "message")) != NULL)
				{
					strcpy(infoptr->value, na_child_get_string(out, "message"));
					printf("Message: %s\n", infoptr->value);
				}

				if ((na_child_get_string(out, "cluster_constraint")) != NULL)
				{
					strcpy(infoptr->clusterConstraint, na_child_get_string(out, "cluster_constraint"));
					printf("cluster-constraint: %s\n", infoptr->clusterConstraint);
				}
				printf("------------------------------------------------\n");
			}
			return 0;
		}
		else
		{
			fprintf(stderr, "Invalid operation\n");
			fprintf(stderr, "-----------------------------------------------------------------------\n");
			fprintf(stderr,"Usage: optmgmt <filer> <user> <password> [<operation>] [<optionName>] [<value>]\n");
			fprintf(stderr, "<filer>      -- Name/IP address of the filer \n");
			fprintf(stderr, "<user>       -- User name\n");
			fprintf(stderr, "<password>   -- Password\n");
			fprintf(stderr, "<operation>  -- get/set\n");
			fprintf(stderr, "<optionName> -- Name of the option on which get/set operation\n");
			fprintf(stderr, "                needs to be performed\n");
			fprintf(stderr, "<value>      -- This is required only for set operation. \n");
			fprintf(stderr, "                Provide the value that needs to be assigned for\n");
			fprintf(stderr, "                the option  \n");
			return -1;
		}
	}
	//
	// List out all the options
	// 
	else {
		out = na_server_invoke(s, "options-list-info", NULL);
	}
	
	
	if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n", na_results_errno(out), 
			na_results_reason(out));
		return -3;		  
	}
	else {
		//
		// list the options from the result of the call
		//
		
		options = na_elem_child(out, "options");
		if (options == NULL) {
			// no options to list
			
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return 1;
		}
		
		//
		// Allocate memory for first options
		//
		info = (OptionInfoPtr) malloc (sizeof(OptionInfo));
		if (info == NULL) {
			fprintf(stderr, "Memory allocation err at line %d\n", __LINE__);
			
			r = 0;
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return 0;
			
		}
		//
		// Iterate through option list
		//
		
		for (iter=na_child_iterator(options);
		(ss=na_iterator_next(&iter)) != NULL;  ) { 
			//
			// for each option, increase the size of the
			// array and use pointer arithmetic to get a pointer
			// to the last new and empty record
			//
			info = (OptionInfoPtr) realloc (info,(neltsread+1)*sizeof(OptionInfo));
			if (info == NULL) {
				fprintf(stderr, "Memory allocation error at line %d\n",__LINE__);
				
				r = 0;
			}
			infoptr = info + neltsread;
			
			//
			// dig out the info
			//
			
			if ((na_child_get_string(ss, "name")) != NULL)
			{
				strcpy(infoptr->name, na_child_get_string(ss, "name"));
				printf("Option Name : %s\n", infoptr->name);
			}
			
			if ((na_child_get_string(ss, "value")) != NULL)
			{
				strcpy(infoptr->value, na_child_get_string(ss, "value"));
				printf("Value: %s\n", infoptr->value);
			}

			if ((na_child_get_string(ss, "cluster_constraint")) != NULL)
			{
				strcpy(infoptr->clusterConstraint, na_child_get_string(ss, "cluster_constraint"));
				printf("cluster-constraint: %s\n", infoptr->clusterConstraint);
			}

			printf("------------------------------------------------\n");
			
			neltsread++;
		}
		
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 0;
		
	}
}
