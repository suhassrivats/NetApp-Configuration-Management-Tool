//================================================================//
//						                  //
// $Id:$                                                         //
// Quotalist.c					        	  //
//								  //
// ONTAPI API lists Quota information				  //
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
// Usage: quotalist  <filer> <user> <password> 		  	  //
//================================================================//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "netapp_api.h"
#include "quotalist.h"

int main(int argc, char* argv[])
{
	int 		r = 1;
	na_server_t*	s;
	na_elem_t*	out;
	na_elem_t*	quotas;
	na_elem_t*	ss;
	na_elem_iter_t	iter;
	int 		neltsread = 0;
	char		err[256];
	char*		filername = argv[1];
	char*		user = argv[2]; 	
	char*		passwd = argv[3];
	QuotaInfoPtr  	info;
	QuotaInfoPtr  	infoptr;
	
	if (argc < 4) {
		fprintf(stderr, "Usage: quotalist <filer> <user> <password> \n");
		return -1;
	}
	
	// One-time initialization of system on client
	if (!na_startup(err, sizeof(err))) {
		fprintf(stderr, "Error in na_startup: %s\n", err);
		return -2;
	}
	
	// Initialize connection to server, and
	// request version 1.1 of the API set.
	s = na_server_open(filername, 1, 5); 
	
	// Set connection style (HTTP)
	na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
	na_server_adminuser(s, user, passwd);

	printf("\nQuota Entries");
	printf("\n------------------------------------------------\n");
	
	// Invoke Quota  list info API 
		out = na_server_invoke(s, "quota-list-entries", NULL);
	
	if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n", na_results_errno(out), 
			na_results_reason(out));
		return -3;		  
	}
	else {
		// list the quotas from the result 
		
		quotas = na_elem_child(out, "quota-entries");
		if (quotas == NULL) {
			// no quotas to list
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return 1;
		}
		
		// Allocate memory  
		info = (QuotaInfoPtr) malloc (sizeof(QuotaInfo));
		if (info == NULL) {
			fprintf(stderr, "Memory allocation err at line %d\n", __LINE__);
			r = 0;
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return 0;
		}
		
		// Iterate through quota  list
		for (iter=na_child_iterator(quotas);
		(ss=na_iterator_next(&iter)) != NULL;  ) {
			
			info = (QuotaInfoPtr) realloc (info,(neltsread+1)*sizeof(QuotaInfo));
			if (info == NULL) {
				fprintf(stderr, "Memory allocation error at line %d\n",__LINE__);
				r = 0;
			}
			infoptr = info + neltsread;
			
			// read information
			if ((na_child_get_string(ss, "quota-target")) != NULL) {
				strcpy(infoptr->quota_target, na_child_get_string(ss, "quota-target"));
				printf("Quota Target : %s\n", infoptr->quota_target);
			}
			if ((na_child_get_string(ss, "volume")) != NULL) {
				strcpy(infoptr->volume, na_child_get_string(ss, "volume"));
				printf("Volume  : %s\n", infoptr->volume);
			}
			if ((na_child_get_string(ss, "quota-type")) != NULL) {
				strcpy(infoptr->quota_type, na_child_get_string(ss, "quota-type"));
				printf("Quota Type  : %s\n", infoptr->quota_type);

			}
			printf("------------------------------------------------\n");
			neltsread++;
		}
	}
	free(info);
	na_elem_free(out);
	na_server_close(s);
	na_shutdown();
	return 0;
}
