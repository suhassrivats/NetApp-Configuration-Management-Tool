//============================================================//
//                                                            //
//                                                            //
// vfiler_tunnel.c                                            //
//                                                            //
// This sample code demonstrates how to execute ONTAPI APIs   //
// on a vfiler through the physical filer                     //
//                                                            //
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
//============================================================//


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

#if defined(__LP64__)
#define INT_TO_PTR_CAST	(intptr_t)(int)
#else
#define INT_TO_PTR_CAST	(intptr_t)
#endif

#ifdef	WIN32
#ifdef _WIN64
typedef		unsigned __int64	uintptr_t;
typedef		__int64			intptr_t;
#else
typedef		unsigned int		uintptr_t;
typedef		int			intptr_t;
#endif
#endif /* WIN32 */

void printUsage()
{
	fprintf(stderr, "Usage: vfiler_tunnel {options} <vfiler-name> <filer> ");
    fprintf(stderr, "<user> <password> <API> [ <param-name> <arg> ...]\n");
	fprintf(stderr, "\nOptions:\n");
	fprintf(stderr, "  -r          Use RPC transport (Windows)\n");
	fprintf(stderr, "  -s          Use SSL\n");
}

int main(int argc, char* argv[])
{


	int				index = 1;
	int             option_flag = 0;
    int				transport = NA_SERVER_TRANSPORT_HTTP;
	int				apistyle  =  NA_STYLE_LOGIN_PASSWORD;
	int				retval = 0;
	int				port = 80;
	char*           user = NULL;
    char*           passwd = NULL;
	char*			vfiler = NULL;
	char*			filer = NULL;
	char*			api = NULL;
	char*			key = NULL;
	char*			value = NULL;
	char*			xmlout = NULL;
	char			err[256];

	na_server_t*    s = NULL;
    na_elem_t*		in = NULL;
	na_elem_t*      out = NULL;


	if(argc < 6) {
		printUsage();
		return -1;
	}



	if(!strcmp(argv[index],"-s"))	{
		transport = NA_SERVER_TRANSPORT_HTTPS;
		port = 443;
		index++;
        option_flag = 1;
	}
	else if(!strcmp(argv[index],"-r"))	{
		apistyle = NA_STYLE_RPC;
		index++;
        option_flag = 1;
	}

    if((option_flag == 1) && (argc < 7)) {
        printUsage();
		return -1;
    }

	vfiler = argv[index++];
	filer = argv[index++];
	user = argv[index++];
	passwd = argv[index++];
	api = argv[index];

    //check for even no. of arguments for <param-name> and <arg> value pair
	if((argc - index) %2 != 1)
	{
		printUsage();
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
	// Initialize connection to server, and request version 1.7
	// of the API set for vfiler tunneling.
	//
   	s = na_server_open(filer, 1, 7);

	//
	// Set connection style (default HTTP)
	//
	na_server_style(s, apistyle);
    na_server_adminuser(s, user, passwd);

	retval = na_server_set_vfiler(s,vfiler);

	if (!retval)
	{
		return -2;
	}

	na_server_set_transport_type(s, transport, 0);
	na_server_set_port(s, port);


	in = na_elem_new(api);

	while(++index < argc)
	{
		key = argv[index++];
		value = argv[index];
		na_child_add_string(in,key,value);
	}

	out = na_server_invoke_elem(s, in);
    if (na_results_status(out) != NA_OK) {
        printf("Error %d: %s\n", na_results_errno(out),
		na_results_reason(out));
        return -2;
    }
    else {
		xmlout = na_elem_sprintf(out);
		printf("%s\n",xmlout);
	}

	na_elem_free(in);
	na_elem_free(out);
	na_free(xmlout);
	na_server_close(s);
	na_shutdown();

	return 1;
}

