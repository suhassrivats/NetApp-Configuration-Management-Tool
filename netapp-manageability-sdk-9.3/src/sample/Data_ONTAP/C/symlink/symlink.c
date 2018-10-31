//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// symlink.c                                                  //
//                                                            //
// Set (and get) symlinks from Windows                        //
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
#include <netapp_api.h>
#include "ontapiver.h"

int main(int argc, char* argv[])
{
    na_server_t*    s;
    na_elem_t*      out;
    char            err[256];
	int				major = 1, minor = 1, mj, mn;
	const char*		filer = argv[1];
	const char*		user = argv[2];
	const char*		passwd = argv[3];
	const char*		linkname = argv[4];
	const char*		target = argv[5];

	if (argc < 5) {
		fprintf(stderr, "Usage: symlink <filer> <user> <passwd> <linkname> [ <target> ]\n");
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
	// check the ONTAPI version
	//
	if (na_has_ontapi_version(filer, user, passwd, major, minor) == 0) {
		na_get_ontapi_version(filer, user, passwd, &mj, &mn);
		fprintf(stderr, "ONTAPI version mismatch, %d.%d instead of %d.%d\n",
							mj, mn, major, minor);
		return -4; 
	}

	//
	// sanity-check arguments
	//
	if (strstr(linkname, "/vol/") == NULL) {
		fprintf(stderr, "link target path must be a full path beginning with '/vol'\n");
		return -5;
	}
	if (target != NULL && strstr(target, "/vol/") == NULL) {
		fprintf(stderr, "link name must be a full path beginning with '/vol'\n");
		return -6;
	}
 
	//
	// Initialize connection to server
	//
    s = na_server_open(filer, major, minor); 

	//
	// Set connection style (Windows RPC or HTTP)
	//
    na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
    na_server_adminuser(s, user, passwd);


	//
	// get link target
	//
	if (target == NULL) { 
		out = na_server_invoke(s, "file-read-symlink",
								"path", linkname,
								NULL);
        if (na_results_status(out) != NA_OK) {
            fprintf(stderr, "Error %d: %s\n", na_results_errno(out), 
				na_results_reason(out));
            return -7;
		}
		else {
			printf("link '%s' points to '%s'\n", linkname,
					na_child_get_string(out, "symlink"));
			return 0;
		}
	}
	else {
		out = na_server_invoke(s, "file-create-symlink",
								"path", linkname,
								"symlink", target,
								NULL);
        if (na_results_status(out) != NA_OK) {
            fprintf(stderr, "Error %d: %s\n", na_results_errno(out), 
				na_results_reason(out));
            return -8;
		}
		else {
			return 0;
		}
	}

	//
	// free the resources used by the result of the call
	//
    na_elem_free(out);
	
	//
	// clean up
	//
	na_server_close(s);
	na_shutdown();
        
	return 0;
}
