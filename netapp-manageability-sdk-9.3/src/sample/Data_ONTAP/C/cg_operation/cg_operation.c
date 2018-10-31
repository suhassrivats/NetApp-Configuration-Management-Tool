/*----------------------------------------------------------------
 *  $Id:$							  
 *  cg_operation.c					       	  
 *								  
 *  Displays usage of following APIs:				  
 *		cg-start					  
 *		cg-commit					  		 
 *								  
 * Copyright 2007 Network Appliance, Inc. All rights		  
 * reserved. Specifications subject to change without notice.      
 *								  
 * This SDK sample code is provided AS IS, with no support or 	  
 *  warranties of any kind, including but not limited to 	  
 * warranties of merchantability or fitness of any kind,	  
 * expressed or implied.  This code is subject to the license     
 * agreement that accompanies the SDK.				  
 *								  
 *								  
 * Usage:							 
 * cg_operation <filer> <user> <password> <operation> <value1>     
 *					[<value2>] [<volumes>]	  
 * <filer>      -- Name/IP address of the filer		   
 * <user>       -- User name				      
 * <password>   -- Password				       
 * <operation>  -- cg-start/cg-commit			  	  
 * <value1>     -- This depends on the operation		  
 * <value2>     -- This depends on the operation		  
 * <volumes>    -- This depends on the operation		  
------------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "netapp_api.h"

void usage()
{
	fprintf(stderr, "Usage: cg_operation <filer> <user> ");
        fprintf(stderr, "<password> <operation> <value1> [<value2>] ");
        fprintf(stderr, "[<volumes>]\n");
        fprintf(stderr, "<filer>      --");
        fprintf(stderr, "Name/IP address of the filer \n");
        fprintf(stderr, "<user>       -- User name\n");
        fprintf(stderr, "<password>   -- Password\n");
        fprintf(stderr, "<operation>  --");
        fprintf(stderr, " cg-start/cg-commit \n");
        fprintf(stderr, "<value1>     -- This depends on the ");
        fprintf(stderr, "operation\n");
        fprintf(stderr, "<value2>     -- This depends on the ");
        fprintf(stderr, "operation\n");
        fprintf(stderr, "<volumes>    -- List of volumes.This depends");
        fprintf(stderr, " on the operation\n");
}

int main(int argc, char* argv[])
{
	na_server_t*	s;
	na_elem_t*	out = NULL;
	na_elem_t*	in;	
	na_elem_t*	vols;
	int 		volume_counter = 0;
	char		err[256];
	char*		filername = argv[1];
	char*		user = argv[2]; 	
	char*		passwd = argv[3];
	char*  		operation = argv[4];
	char* 		value1 = argv[5];
	char*   	value2 = argv[6];
	int 		value = 0;
	char*   	buffer;

	if (argc < 5) {
		usage();	
		return -1;
	}

	/* One-time initialization of system on client */
	if (!na_startup(err, sizeof(err))) {
		fprintf(stderr, "Error in na_startup: %s\n", err);
		return -2;
	}
	
	/* Initialize connection to server, and
	 request version 1.1 of the API set.*/
	s = na_server_open(filername, 1, 1); 
	
	/* Set connection style (HTTP)*/
	na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
	na_server_adminuser(s, user, passwd);


	/* 
	* To start cg-start operation 
	* Usage:
	* cg_operation <filer> <user> <password> cg-start <snapshot> 
	* <timeout> <volumes>
	*/ 
	if(!strcmp(operation, "cg-start"))
	{
		if(argc < 8)
		{
			fprintf(stderr, "Usage: cg_operation <filer> <user>"); 
	       		fprintf(stderr, " <password> cg-start <snapshot> ");
			fprintf(stderr, "<timeout> <volumes> \n"); 
	       		return -1;
		}
		
		in = na_elem_new(operation);
       		if (in==NULL) {
			printf("Error %d: %s\n", na_results_errno(in),
      			na_results_reason(in));
			return -3;
		}
   		na_child_add_string(in, "snapshot",value1 );
    		na_child_add_string(in, "timeout",value2 );

		vols = na_elem_new("volumes");
		if (vols==NULL) {
			printf("Error %d: %s\n", na_results_errno(vols),
			na_results_reason(vols));
			return -3;
		}

		/*
		* Now store rest of the volumes as a child element of vols.
		* Here it has been hard coded as 7 because first volume is
		* specified at 7th position from cmd prompt 
		*/
		volume_counter=7;
		while(volume_counter!=argc)
		{
			na_child_add_string(vols, "volume-name",
						argv[volume_counter] );
			volume_counter++;
		}
		na_child_add(in, vols);

		
		/*Printing the input XML built*/
		buffer=na_elem_sprintf(in);
		printf("Input XML:\n%s\n",buffer);
		na_free(buffer);

		
   		 /* Invoke cg-start API*/
    		out = na_server_invoke_elem(s, in);
	
		/*Printing the output XML*/ 
		buffer=na_elem_sprintf(out);
		printf("Output XML:\n%s\n",buffer);
		na_free(buffer);

	 	if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
					na_results_reason(out));
			return -3;
       		}
	 	else {
	       		printf("Consistency group operation started "); 
			printf("successfuly\n");
		}
		na_elem_free(in);
	}
	/* To start cg-commit operation
	*  Usage:
	*  cg_operation <filer> <user> <password> cg-commit <cg-id>
	*/
	else if(!strcmp(operation, "cg-commit"))
	{
		if(argc < 6)
		{
			fprintf(stderr, "Usage: cg_operation <filer> <user>");
			fprintf(stderr, " <password> cg-commit <cg-id>\n");
			return -1;
		}

		/* Invoke cg-commit API */
      		in = na_elem_new(operation);
		value = atoi(argv[5]);
    		na_child_add_int(in, "cg-id", value);
 		out = na_server_invoke_elem(s, in);
	   	if (na_results_status(out) != NA_OK) {
		  	printf("Error %d: %s\n", na_results_errno(out),
					na_results_reason(out));
		   	return -3;
	     	}
	    	else {
			printf("Consistency group operation commited "); 
			printf("successfuly\n");
	    	}
		na_elem_free(in);
    	}
	else
	{
		fprintf(stderr, "Not a valid operation\n\n");
		usage();
	}

	na_elem_free(out);
	na_server_close(s);
	na_shutdown();
	return 0;
}
