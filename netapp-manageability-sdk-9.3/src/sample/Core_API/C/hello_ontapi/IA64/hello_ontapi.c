//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// hello_ontapi.c                                             //
//                                                            //
// Hello World for the ONTAPI APIs                            //
//                                                            //
// Copyright 2002-2003 Network Appliance, Inc. All rights     //
// reserved. Specifications subject to change without notice. // 
//                                                            //
// This SDK sample code is provided AS IS, with no support or //
// warranties of any kind, including but not limited to       //
// warranties of merchantability or fitness of any kind,      //
// expressed or implied.  This code is subject to the license //
// agreement that accompanies the SDK.                        //
//                                                            //
// tab size = 4                                               //
//                                                            //
// Usage: hello_ontapi <filer> <user> <password>              //
//                                                            //
//============================================================//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netapp_api.h>

int main(int argc, char* argv[])
{
    na_server_t*    s;
    na_elem_t*      out;
    char            err[256];
    char*           filername = argv[1];
    char*           user = argv[2];     
    char*           passwd = argv[3];
	const char*		ver;
	char*			verbuf = NULL;

	if (argc < 4) {
		fprintf(stderr, "Usage: hello_ontapi <filer> <user> <password>\n");
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
	// Test the connection.  This should be done as
	// a sanity check on all new server connections.
	//
	out = na_server_invoke(s, "system-get-version", NULL);
    if (na_results_status(out) != NA_OK) {
        printf("Error %d: %s\n", na_results_errno(out), 
				na_results_reason(out));
        return -3;        
    }
    else {
	//
	// get the version string from the result of the call
	// (na_child_get_string() returns a pointer to a static
	// buffer which gets freed when we call na_elem_free(), 
	// so we copy the data to newly allocated storage)
	//
	ver = na_child_get_string(out, "version");
	verbuf = (char*) malloc(strlen(ver)+1);
	if (verbuf) 
		strcpy(verbuf, ver);
    }

	//
	// free the resources used by the result of the call
	//
    na_elem_free(out);
	
	//
	// print the versions string, etc.
	//
	printf("Hello world!  DOT version of %s is %s\n", filername, verbuf);

	//
	// clean up
	//
	if (verbuf)
		free(verbuf);
	na_server_close(s);
	na_shutdown();
        
	return 0;
}
