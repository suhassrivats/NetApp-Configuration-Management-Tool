//============================================================//
//                                                            //
// $Id: //depot/prod/zephyr/corsair/src/sample/C/systemcli/systemcli.c#1 $ //
//                                                            //
// systemcli.c                                                //
//                                                            //
// Sample code for systemcli                                  //
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
// Usage: systemcli [<filer-ip> -l username:password] arguments  //
//                                                            //
//                                                            //
//============================================================//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netapp_api.h>

static int system_cli(na_server_t * s, int argc, char * argv[]);


int main(int argc, char* argv[])
{
	na_server_t*	s;
	char			err[256];
	char*			filername = argv[1];
	char			user[32];
	char			passwd[32];
	char**			arguments;
	int				numarguments;

	if (argc < 3)
		goto print_usage_and_return;
 
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


	if (strcmp(argv[2], "-l") == 0) {
		char * ch_colon;
		if (argc < 5)
			goto print_usage_and_return;
		
		// 
		// Set connection style (HTTP)
		//
		strcpy(user, argv[3]);
		ch_colon = strchr(user, ':');
		if (ch_colon == NULL)
			goto print_usage_and_return;
				
		ch_colon[0] = '\0';
		strcpy(passwd, &ch_colon[1]);

		na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
		na_server_adminuser(s, user, passwd);
		arguments = &argv[4];
		numarguments = argc - 4;
	} else {
		na_server_style(s, NA_STYLE_RPC);
		arguments = &argv[2];
		numarguments = argc - 2;
	}

	system_cli(s, numarguments, arguments);

	//
	// clean up
	//
	na_server_close(s);
	na_shutdown();

	return 0;

print_usage_and_return:
	fprintf(stderr, "Usage: systemcli <filer-ip> [-l username:password] arguments\n");
	return -1;

}

int system_cli(na_server_t * s, int argc, char * argv[])
{
	na_elem_t*		in;
	na_elem_t*		in_arg;
	na_elem_t*		out;
	const char*		output;
	int i;

	in  = na_elem_new("system-cli");
	in_arg = na_elem_new("args");

	for (i = 0; i < argc; i ++) {
		na_child_add_string(in_arg, "arg", argv[i]);
	}

	na_child_add(in, in_arg);

	//
	// Test the connection.  This should be done as
	// a sanity check on all new server connections.
	//
	out = na_server_invoke_elem(s, in);
	if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n", na_results_errno(out), 
			na_results_reason(out));
		na_elem_free(in);
		na_elem_free(out);
		return -3;
	} 
	//
	// get the version string from the result of the call
	// (na_child_get_string() returns a pointer to a static
	// buffer which gets freed when we call na_elem_free(), 
	// so we copy the data to newly allocated storage)
	//
	output = na_child_get_string(out, "cli-output");

	//
	// print the versions string, etc.
	//
	printf("%s\n", output);

	//
	// free the resources used by the result of the call
	//
	na_elem_free(in);
	na_elem_free(out);
	return 0;
}
