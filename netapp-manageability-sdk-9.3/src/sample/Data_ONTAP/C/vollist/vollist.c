//================================================================//
//						                  //
// $Id: //depot/prod/zephyr/belair/src/sample/C/vollist/vollist.c#1 $ 						          //
// vollist.c					        	  //
//								  //
// ONTAPI API lists volume information				  //
//								  //
// This program demonstrates how to handle arrays		  //
//								  //
//								  //
// Copyright 2005 Network Appliance, Inc. All rights		  //
// reserved. Specifications subject to change without notice.     // 
//								  //
// This SDK sample code is provided AS IS, with no support or 	  //
// warranties of any kind, including but not limited to 	  //
// warranties of merchantability or fitness of any kind,	  //
// expressed or implied.  This code is subject to the license     //
// agreement that accompanies the SDK.				  //
//								  //
//								  //
// Usage: vollist  <filer> <user> <password> [volume]		  //
//================================================================//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "netapp_api.h"
#include "vollist.h"

int main(int argc, char* argv[])
{
	int 		r = 1;
	na_server_t*	s;
	na_elem_t*		out;
	na_elem_t*		volumes;
	na_elem_t*		ss;
	na_elem_iter_t	iter;
	int 		neltsread = 0;
	char			err[256];
	char*			filername = argv[1];
	char*			user = argv[2]; 	
	char*			passwd = argv[3];
	char*			volume = argv[4];
	VolumeInfoPtr  info;
	VolumeInfoPtr  infoptr;
	
	if (argc < 4) {
		fprintf(stderr, "Usage: vollist <filer> <user> <password> [<volume>]\n");
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
	// Invoke Volume list info API 
	//
	if (volume != NULL) {
		out = na_server_invoke(s, "volume-list-info", "volume", volume, NULL);
	} else {
		out = na_server_invoke(s, "volume-list-info", NULL);
	}
	
	
	if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n", na_results_errno(out), 
			na_results_reason(out));
		return -3;		  
	}
	else {
		//
		// list the volumes from the result of the call
		//
		
		volumes = na_elem_child(out, "volumes");
		if (volumes == NULL) {
			// no volumes to list
			
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return 1;
		}
		
		//
		// Allocate memory for first volumes 
		//
		info = (VolumeInfoPtr) malloc (sizeof(VolumeInfo));
		if (info == NULL) {
			fprintf(stderr, "Memory allocation err at line %d\n", __LINE__);
			
			r = 0;
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return 0;
			
		}
		
		//
		// Iterate through volume list
		//
		
		for (iter=na_child_iterator(volumes);
		(ss=na_iterator_next(&iter)) != NULL;  ) {
			
			//
			// for each volume, increase the size of the
			// array and use pointer arithmetic to get a pointer
			// to the last new and empty record
			//
			info = (VolumeInfoPtr) realloc (info,													   (neltsread+1)*sizeof(VolumeInfo));
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
				printf("Volume Name : %s\n", infoptr->name);
			}
			
			if ((na_child_get_string(ss, "state")) != NULL)
			{
				strcpy(infoptr->state, na_child_get_string(ss, "state"));
				printf("Volume State : %s\n", infoptr->state);
			}
			
			infoptr->disk_count = na_child_get_int(ss,"disk-count", 0);
			infoptr->files_total = na_child_get_int(ss,"files-total", 0);
			infoptr->files_used = na_child_get_int(ss,"files-used", 0);
			
			printf("Disk Count  : %d\n", infoptr->disk_count);
			printf("Files Total : %d\n", infoptr->files_total);
			printf("Files Used  : %d\n", infoptr->files_used);
			printf("------------------------------------------------\n");
			
			neltsread++;
		}
		
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 0;
		
	}
}
