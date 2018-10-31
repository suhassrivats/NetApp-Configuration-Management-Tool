//=============================================================//
//                                                     	       //
// $ID$                                                        //
//                                                             //
// hello_dfm.c                                                 //
//                                                             //
// Copyright (c) 2009 NetApp, Inc. All rights reserved.        //
// Specifications subject to change without notice.            //
//                                                             //
// This program will print the version number of               //
// the DFM Server                                              //
//                                                             //
// Usage: hello_dfm <dfmserver> <dfmuser> <dfmpassword>        //
//                                                             //
// This Sample code is supported from DataFabric Manager 3.6R2 //
// onwards.                                                    //
// However few of the functionalities of the sample code may   //
// work on older versions of DataFabric Manager.               //
//=============================================================//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netapp_api.h>


int main(int argc, char* argv[])
{
	na_server_t*    s = NULL;
	na_elem_t *     requestElem = NULL;
	na_elem_t *     responseElem = NULL;
	char*           dfmserver = argv[1];
	char*           dfmuser   = argv[2];
	char*           dfmpasswd = argv[3];
	char*			version = NULL;
	char*			verBuff = NULL;
	char            err[256];

	if (argc < 4) {
		fprintf(stderr, "Usage: hello_dfm <dfmserver> <dfmuser> <dfmpassword> \n");
		fprintf(stderr, "<dfmserver> -- Name/IP Address of the DFM server\n");
		fprintf(stderr, "<dfmuser> -- DFM server User name\n");
		fprintf(stderr, "<dfmpassword> -- DFM server Password\n");
		return -1;
	}

	// One-time initialization of system on client
	if (!na_startup(err, sizeof(err))) {
		fprintf(stderr, "Error in na_startup: %s\n", err);
		return -2;
	}

	//
	// Initialize connection to server, and
	// request version 1.0 of the API set.
	//
	s = na_server_open(dfmserver, 1, 0);

	//
	// default settings for dfm transoprt
	//
	na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
	na_server_set_server_type(s,NA_SERVER_TYPE_DFM);
	na_server_set_transport_type(s,NA_SERVER_TRANSPORT_HTTP, NULL);
	na_server_set_port(s,8088);
	
	na_server_adminuser(s, dfmuser, dfmpasswd);

	requestElem = na_elem_new("dfm-about");
		
	responseElem = na_server_invoke_elem(s,requestElem);

	if (na_results_status(responseElem) != NA_OK) {
       	printf("Error %d: %s\n", na_results_errno(responseElem),
		na_results_reason(responseElem));
       	return -3;
	}

	// get the version string from the result of the call
	// (na_child_get_string() returns a pointer to a static
	// buffer which gets freed when we call na_elem_free(), 
	// so we copy the data to newly allocated storage)
	//
	version = (char *) na_child_get_string(responseElem, "version");
	verBuff = (char*) malloc(strlen(version)+1);

	if (verBuff) {
		strcpy(verBuff, version);
	}

	//
	// free the resources used by the result of the call
	//
	na_elem_free(responseElem);
		
	//
	// print the versions string.
	printf("Hello world!  DFM Server version is: %s\n",verBuff);

	// clean up
	if (verBuff) {
		free(verBuff);
	}
	na_server_close(s);
	na_shutdown();
        
	return 0;		
}

