//==========================================================================//
//								   	    // 
// $Id: //depot/prod/zephyr/belair/src/sample/C/getmac/getmac.c#1 $									    //
//								   	    // 
// getmac.c	Get a list of IP addresses and corresponding MAC addresses  //
//		Use the FetchIPandMACAddrs routine in your code, main is    //
//		just a wrapper						    //
//								            // 
//Copyright 2005 Network Appliance, Inc.  All rights reserved.              //
//Specifications subject to change without notice.		            //	
//                                                                          // 
//This  SDK sample code is provided AS IS, withno support or warranties     // 
//of any kind, including but not limited to warranties of merchanbility     //
//or fitness of any kind, expressed or implied. This code is subject to     //
//the license agreement that accompanies the SDK.			    //
//								            // 
// tab size = 8							            // 
//								            // 
//========================================================================= //
#include <stdio.h> 
#include <stdlib.h>
#include <string.h>
        
#include "netapp_api.h"

                
#ifndef FALSE   
#define FALSE 0         
#endif                  
#ifndef TRUE
#define TRUE 1          
#endif
                
#define DEFAULT_SSL_PORT 443
#define DEFAULT_HTTP_PORT 80


#ifdef	WIN32
#ifdef _WIN64
typedef		unsigned __int64	uintptr_t;
typedef		__int64			intptr_t;
#else
typedef		unsigned int		uintptr_t;
typedef		int			intptr_t;
#endif
#endif /* WIN32 */


int FetchIPandMACAddrs(na_server_t* s, char* ipaddrs[256], 
	               char* macaddrs[256], int* ninterfaces);

int main(int argc, char* argv[])
{
	char*			ipaddrs[256];
	char*			macaddrs[256];
	int			ninterfaces;
	int			i;
	na_server_t*		s;

	if (argc < 4) {
		fprintf(stderr, "Usage: %s <host> <user> <pw>\n", argv[0]);  	\
		return -1;		\
	} 
	
 	s = na_server_open(argv[1], 1, 0);
	if (s == 0) {
		fprintf(stderr, "Failed to open server connection to %s\n", argv[1]);
		return -1;
	}

	na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
	na_server_adminuser(s, argv[2], argv[3]);
	na_server_set_transport_type(s,  NA_SERVER_TRANSPORT_HTTP, NULL);
	na_server_set_port(s, DEFAULT_HTTP_PORT);

	if (FetchIPandMACAddrs(s, ipaddrs, macaddrs, &ninterfaces)) {

		for(i=0; i<ninterfaces; i++) {
			printf("inet %20s    mac %s\n", ipaddrs[i], macaddrs[i]);
		}
	}
	else {
		fprintf(stderr, "Error in FetchIPandMACAddrs(), exiting...\n");
		return -1;
	}
	return 0;
}


//
// caller must free all the strings returned in the ipaddrs and macaddrs arrays
// if this routine returns non-zero
//
int FetchIPandMACAddrs(na_server_t* s,  char* ipaddrs[256], 
                       char* macaddrs[256], int* ninterfaces)
{
	na_elem_t*	eo;
	na_elem_t*	ei;
	na_elem_t*	args;
	const char*	ifout;
	char*		ifcpy;
	char*		tok;
	char*		tok2;
	int		i = 0;
	int		len;

	eo = na_elem_new("system-cli");
	if (eo == NULL) {
		fprintf(stderr, "Memory allocation error: %s\n", s); 
		return 0;
	}
	args = na_elem_new("args");
	if (args == NULL) {
		fprintf(stderr, "Memory allocation error: %s\n", s); 
		return 0;
	}
	na_child_add_string(args, "arg", "ifconfig");
	na_child_add_string(args, "arg", "-a");
	na_child_add(eo, args);

 	ei = na_server_invoke_elem(s, eo);	
	na_elem_free(eo);
	if (na_results_status(ei) != NA_OK) {
		fprintf(stderr, "ONTAPI error: %s\n", na_results_reason(ei));
		return 0;
	}
	
	ifout = na_child_get_string(ei, "cli-output");
	if (ifout == NULL) {
		fprintf(stderr, "NULL return from ONTAPI call\n");
		return 0;
	}
	
	//
	// get an overwriteable copy of the command return
	// text for use with strtok()
	//
	ifcpy = (char*) malloc(strlen(ifout)+1);
	strcpy(ifcpy, ifout);

	memset(ipaddrs, 0, 256 * sizeof(void*));
	memset(macaddrs, 0, 256 * sizeof(void*));

	//
	// Okay, do the screen scraping now that we have the
	// command return text into an overwriteable buffer
	//

	// find "inet" and get the IP address appearing after it
	//
	tok = (char*) strstr(ifcpy, "inet");
	if (tok)
		tok = (char*) strtok(tok, " ");
	if (tok) {
		len = strlen(tok) + 1;
		tok = (char*) strtok(tok+len, " ");
	}
	while (tok) {
		//
		// store the IP address
		//
		ipaddrs[i] = (char*)  strdup(tok);
		if (ipaddrs[i] == NULL)
			goto cleanup;
	
		//
		// get "ether and the mac address" after that
		//
		len = strlen(tok) + 1;
		tok = (char*) strstr(tok + len, "ether");
		tok = (char*) strtok(tok, " ");
		if (tok) {
			len = strlen(tok) + 1;
			tok2 = (char*) strtok(tok+len, " ");
		}
		if (tok2 == NULL) {
			// 
			// oops, not an ethernet port
			// 
			continue;
		}
		else
			tok = tok2;

		macaddrs[i] = (char*)  strdup(tok);
		if (macaddrs[i] == NULL)
			goto cleanup;
		i++;

		//
		// find the next "inet" and the ip address after that
		//
		len = strlen(tok) + 1;
		tok = (char*) strstr(tok + len, "inet");
		if (tok)
			tok = (char*) strtok(tok, " ");
		if (tok) {
			int len = strlen(tok) + 1;
			tok = (char*) strtok(tok+len, " ");
		}
	}
 	*ninterfaces = i;
	na_elem_free(ei);
	return 1;

cleanup:

	for(i=0; ipaddrs[i] != NULL; i++)
		free(ipaddrs[i]);
	for(i=0; macaddrs[i] != NULL; i++)
		free(macaddrs[i]);

	return 0;
}	
