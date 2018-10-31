//depot/prod/zephyr/Rhimsagar/src/sample/C/vfiler/vfiler.c#2 - edit change 765420 (ktext)
//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// vfiler.c                                                   //
//                                                            //
// This sample code demonstrates how to create, destroy or    //
// list vfiler(s) using ONTAPI APIs                           //
//                                                            //
// Copyright 2003 Network Appliance, Inc. All rights          //
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
// See printUsage() for command-line syntax                   //
//                                                            //
//============================================================//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "netapp_api.h"

//============================================================//

void printUsage()
{
    fprintf(stderr, "Usage: vfiler <filer> <user> <password> ");
	fprintf(stderr,	"<operation> [<value1>] [<value2>] ..\n\n");
	fprintf(stderr, "<filer>      -- Name/IP address of the filer \n");
	fprintf(stderr, "<user>       -- User name\n");
	fprintf(stderr, "<password>   -- Password\n");
	fprintf(stderr, "<operation>  -- ");
	fprintf(stderr, "create/destroy/list/status/start/stop\n");
    fprintf(stderr, "<value1>     -- This depends on the operation\n");
	fprintf(stderr, "<value2>     -- This depends on the operation\n");
}

int main(int argc, char* argv[])
{

	na_server_t*	s;
	na_elem_t*		out;

	char			err[256];
	char*			filername = NULL;
	char*			user = NULL;
	char*			passwd = NULL;
	char*			operation = NULL;
	char*			value1 = NULL;
    int             index = 1;

	if (argc < 5) {
		printUsage();
		return -1;
	}

	filername = argv[index++];
    user = argv[index++];
    passwd = argv[index++];
    operation = argv[index++];

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

    //Usage: vfiler <filer> <user> <password> list [<vfiler-name>]\n");
	if(!strcmp(operation, "list"))
	{
        na_elem_t*		vfilers = NULL;
        na_elem_t*		vfiler = NULL;
	    na_elem_t*      next_elem = NULL;
	    na_elem_iter_t	iter;

        na_elem_t*		vfnets = NULL;
	    na_elem_iter_t	vfnetIter;
	    na_elem_t*		vfnet;

        na_elem_t*		stunits = NULL;
	    na_elem_iter_t	stunitIter;
	    na_elem_t*		stunit = NULL;


        if(argc > 5) {
            value1 = argv[5];
	    	out = na_server_invoke(s,"vfiler-list-info","vfiler", value1, NULL);
        }
		else {
			out = na_server_invoke(s,"vfiler-list-info",NULL);
		}
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			vfilers = na_elem_child(out, "vfilers");
			if (vfilers == NULL) {
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}

			// dig out the info
			printf("--------------------------------------------\n");

			for (iter = na_child_iterator(vfilers);
			(vfiler = na_iterator_next(&iter)) != NULL;  ) {

				if ((na_child_get_string(vfiler, "name"))!= NULL) {
					printf("name: %s\n",na_child_get_string(vfiler, "name"));
				}
				if ((na_child_get_string(vfiler, "ipspace"))!= NULL) {
					printf("ipspace: %s\n",na_child_get_string(vfiler, "ipspace"));
				}
				if ((na_child_get_string(vfiler, "uuid"))!= NULL) {
					printf("uuid: %s\n",na_child_get_string(vfiler, "uuid"));
				}

                vfnets = na_elem_child(vfiler, "vfnets");

				if(vfnets != NULL) {
					printf("network resources:");
					for (vfnetIter = na_child_iterator(vfnets); (vfnet = na_iterator_next(&vfnetIter)) != NULL; ) {
						if ((na_child_get_string(vfnet, "ipaddress"))!= NULL) {
							printf("\n\tipaddress: %s\n",na_child_get_string(vfnet, "ipaddress"));
						}
						if ((na_child_get_string(vfnet, "interface"))!= NULL) {
							printf("\tinterface: %s\n",na_child_get_string(vfnet, "interface"));
						}
					}
				}

				stunits = na_elem_child(vfiler, "vfstores");

				if(stunits != NULL) {
					printf("storage resources:");
					for (stunitIter = na_child_iterator(stunits); (stunit = na_iterator_next(&stunitIter)) != NULL; ) {
						if ((na_child_get_string(stunit, "path"))!= NULL) {
							printf("\n\tpath: %s\n",na_child_get_string(stunit, "path"));
						}
						if ((na_child_get_string(stunit, "status"))!= NULL) {
							printf("\tstatus: %s\n",na_child_get_string(stunit, "status"));
						}
						if ((na_child_get_string(stunit, "is-etc"))!= NULL) {
							printf("\tis-etc: %s\n",na_child_get_string(stunit, "is-etc"));
						}
					}
				}
				printf("------------------------------------------\n");
			}
		}
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 1;
    }

	// vfiler status/start/stop/destroy
	else if(!strcmp(operation, "status") || !strcmp(operation, "start") ||
           !strcmp(operation, "stop")  || !strcmp(operation, "destroy"))
	{
        char cmd[25];
        char usage[100];

		if(argc != 6) {
            sprintf(usage,"Usage: vfiler <filer> <user> <password> %s <vfiler-name>\n",operation);
			fprintf(stderr, usage);
			na_server_close(s);
			na_shutdown();
			return -1;
		}
		else {
            value1 = argv[5];

            if(!strcmp(operation,"status")) {
                strcpy(cmd,"vfiler-get-status");
            }
            else if(!strcmp(operation,"start")) {
                strcpy(cmd,"vfiler-start");
            }
            else if (!strcmp(operation,"stop")) {
                strcpy(cmd,"vfiler-stop");
            }
            else if (!strcmp(operation,"destroy")) {
                strcpy(cmd,"vfiler-destroy");
            }
            out = na_server_invoke(s, cmd,"vfiler", value1, NULL);
        }

        if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}

        if(!strcmp(operation,"status")) {
            printf("status:%s\n",na_child_get_string(out,"status"));
        }
		else {
			printf("Operation successful\n");
		}

		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 1;
	}
    else if (!strcmp(operation, "create"))
	{

        char *vfiler = NULL;
        na_elem_t *in = NULL;
        na_elem_t *stg_units = NULL;
        na_elem_t *ip_addrs = NULL;
        int index = 7;
        int parseIP = 1;

        if(argc < 10 || strcmp("-ip",argv[6]) !=0) {
            fprintf(stderr,"Usage: vfiler <filer> <user> <password> create <vfiler-name> -ip <ip-address1> [<ip-address2>..] -su <storage-unit1> [<storage-unit2]..]\n");
			na_server_close(s);
			na_shutdown();
			return 1;
		}

        in = na_elem_new("vfiler-create");
        na_child_add_string(in, "vfiler",argv[5]);

        ip_addrs  = na_elem_new("ip-addresses");
        stg_units = na_elem_new("storage-units");
        na_child_add_string(ip_addrs,"ip-address",argv[index]);

        while(++index < argc)
        {
            //read the ip-addresses until we parse -su option
            if(!strcmp(argv[index],"-su")) {
            parseIP = 0;
            continue;
        }
        if(parseIP) {
            na_child_add_string(ip_addrs,"ip-address",argv[index]);
        }
        else {
            na_child_add_string(stg_units, "storage-unit",argv[index]);
        }
        }

        na_child_add(in,ip_addrs);
        na_child_add(in,stg_units);

        out = na_server_invoke_elem(s, in);

		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Operation successful\n");
		}
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 0;
	}
    else
    {
        printUsage();
        return -1;
    }
}

//============================================================//



