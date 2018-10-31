//=============================================================//
//                                                             //
// $ID$                                                        //
//                                                             //
// dfm_proxy.c                                                 //
//                                                             //
// Copyright (c) 2009 NetApp, Inc. All rights reserved.        //
// Specifications subject to change without notice.            //
//                                                             //
// This sample code demonstrates how to use DFM server as a    //
// proxy in sending ONTAPI commands to NetApp storage systems  //
//                                                             //
// Usage: dfm_proxy <dfmserver> <dfmuser>                      //
//        <dfmpassword> <filerip>                              //
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


/****************************************************************************
	Name: get_filer_version

	Description: Gets the version of the filer by sending the 'system-get-version'
		to the DFM server
	Parameters:
		IN:
		s - na element containing the proxy server context
		filerip - IP address of the filer for which the version is requested

	Return value:
		0 - On Success
		Error Code - On Failure
******************************************************************************/

int get_filer_version(na_server_t* s, char* filerip) {

	na_elem_t*		out;
	na_elem_t*		proxyElem   = 0;
	na_elem_t*		requestElem = 0;
	na_elem_t*		response = NULL;
	na_elem_t*		apiResponse = NULL;
	const char*		ver;

	requestElem = na_elem_new("request");
	na_child_add_string(requestElem, "name", "system-get-version");

	proxyElem = na_elem_new("api-proxy");
	na_child_add_string(proxyElem, "target", filerip );
	na_child_add(proxyElem, requestElem);

	out = na_server_invoke_elem(s,proxyElem);

	if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n", na_results_errno(out),
				na_results_reason(out));
		na_elem_free(proxyElem);
		na_elem_free(out);
		return -3;
	}

	response = na_elem_child(out, "response");
	if( strcmp(na_child_get_string(response,"status"),"passed") != 0 ) {
		printf("Error %d: %s\n", na_child_get_int(response,"errno",-1),na_child_get_string(response,"reason"));
		na_elem_free(proxyElem);
		na_elem_free(out);
		return -3;
	}

	apiResponse = na_elem_child(response, "results");

	if (na_results_status(apiResponse) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(apiResponse),
							na_results_reason(apiResponse));
			na_elem_free(proxyElem);
			na_elem_free(out);
			return -3;
	}
	//
	// get the version string from the result of the call
	//
	ver = na_child_get_string(apiResponse, "version");

	//
	// print the versions string
	//
	printf("Hello world!  DOT version of %s got from DFM-Proxy is %s\n", filerip, ver);

	//
	// free the resources used by the result of the call
	//
	na_elem_free(proxyElem);
	na_elem_free(out);

	return 0;

}

/****************************************************************************
	Name: Main

	Description: Initializes the server context object and calls the
		get_filer_version() function

	Parameters:
		IN:
		argc 	- number of command line arguments
		argv	- Array of command line arguments

	Return value: None
******************************************************************************/

int main(int argc, char* argv[])
{
	na_server_t*	s;
	char*			dfmserver = argv[1];
	char*			dfmuser = argv[2];
	char*			dfmpasswd = argv[3];
	char*			filerip = argv[4];
	char			err[256];

	if (argc < 5) {
		fprintf(stderr, "Usage: dfm_proxy <dfmserver> <dfmuser> <dfmpassword> <filer>\n");
		fprintf(stderr, "<dfmserver> -- Name/IP Address of the DFM server\n");
		fprintf(stderr, "<dfmuser> -- DFM server User name\n");
		fprintf(stderr, "<dfmpassword> -- DFM server Password\n");
		fprintf(stderr, "<filer> -- Name/IP Address of the Filer\n");
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
	// Set connection style (HTTP)
	//
	na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
	na_server_set_server_type(s,NA_SERVER_TYPE_DFM);
	na_server_set_transport_type(s,NA_SERVER_TRANSPORT_HTTP, NULL);
	na_server_set_port(s,8088);
	na_server_adminuser(s, dfmuser, dfmpasswd);

	get_filer_version(s,filerip);

	na_server_close(s);
	na_shutdown();

	return 0;

}
