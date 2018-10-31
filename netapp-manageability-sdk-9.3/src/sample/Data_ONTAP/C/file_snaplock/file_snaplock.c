//==================================================================//
//                                                                  //
// $ID$                                                             //
//                                                                  //
// file_snaplock.c                                                  //
//                                                                  //
// Brief information of the contents                                //
//                                                                  //
// Copyright 2002-2003 Network Appliance, Inc. All rights           //
// reserved. Specifications subject to change without notice.       //
//                                                                  //
// This SDK sample code is provided AS IS, with no support or       //
// warranties of any kind, including but not limited to             //
// warranties of merchantability or fitness of any kind,            //
// expressed or implied.  This code is subject to the license       //
// agreement that accompanies the SDK.                              //
//                                                                  //
//Sample for usage of following file-snaplock group API:            //
//file-get-snaplock-retention-time                                  //
//file-snaplock-retention-time-list-info                            //
//file-set-snaplock-retention-time                                  //
//file-get-snaplock-retention-time-list-info-max                    //
//                                                                  //
// Usage:                                                           //
// file_snaplock <filer> <user> <password> <operation>              //
//              <value1> [<value2>]                                 //
//                                                                  //
// <filer>      -- Name/IP address of the filer                     //
// <user>       -- User name                                        //
// <password>   -- Password                                         //
// <operation>  -- file-get-snaplock-retention-time                 //
//         file-set-snaplock-retention-time                         //
//         file-snaplock-retention-time-list-info                   //
//         file-get-snaplock-retention-time-list-info-max           //
// <value1>     -- This depends on the operation                    //
// <value2>     -- This depends on the operation                    //
//                                                                  //
//==================================================================//


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netapp_api.h>


void usage() {
        printf("\nUsage : file_snaplock <filer> <user> <passwd> <operation> [<value1>] [<value2>] \n");
        printf("<filer>  -- ");
        printf("Name/IP address of the filer\n");
        printf("<user>   -- User Name\n");
        printf("<passwd> -- Password\n");
        printf("<operation> -- \n");
        printf("\tfile-get-snaplock-retention-time\n");
        printf("\tfile-set-snaplock-retention-time\n");
        printf("\tfile-snaplock-retention-time-list-info\n");
        printf("\tfile-get-snaplock-retention-time-list-info-max\n");
        printf("<value1>        --file path\n");
}



/****************************************************************************
 Name: Main

 Description: Initializes the server context object and invokes the appropriate
              ONTAP API as per the command line input

 Parameters:
      IN:
        argc    - number of command line arguments
        argv    - Array of command line arguments

 Return value: None
******************************************************************************/

int main(int argc, char* argv[])
{
        na_server_t*    s;
        na_elem_t       *out,*in;
        na_elem_t       *pathnames,*pathname_info;
        na_elem_t*      nextElem = NULL;
        na_elem_t*      retention_list = NULL;
        na_elem_iter_t  iter;
        char*           filerip    = argv[1];
        char*           user       = argv[2];
        char*           passwd     = argv[3];
        char*           operation  = argv[4];
        char            err[256];
        char*           path       = NULL;
        int             retention_time_out = 0;
        char*           retention_time_in = NULL;
        int             max_list_entries = 0;
        int             path_counter = 0;
        const char*     retention_time = NULL;

        if (argc < 5) {
                usage();
                return -1;
        }

        // One-time initialization of system on client
        if (!na_startup(err, sizeof(err))) {
                fprintf(stderr, "Error in na_startup: %s\n", err);
                return -2;
        }

        //
        // Initialize connection to server, and request version 1.0 of the API set.
        //
        s = na_server_open(filerip, 1, 0);

        //
        // Set connection style (HTTP)
        //
        na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
        na_server_set_transport_type(s,NA_SERVER_TRANSPORT_HTTP, NULL);
 	na_server_adminuser(s,user,passwd);

        if(!strcmp(operation, "file-get-snaplock-retention-time")) {

                if(argc < 6) {

                        fprintf(stderr, "Usage: file_snaplock <filerip> <user> <password> ");
                        fprintf(stderr, "<file-get-snaplock-retention-time> <filepathname>\n");
                        na_server_close(s);
                        na_shutdown();
                        return -1;
                }

                path = argv[5];
                in = na_elem_new("file-get-snaplock-retention-time");
                na_child_add_string(in,"path",path);
                out = na_server_invoke_elem(s,in);
                if (na_results_status(out) != NA_OK) {
                        printf("Error %d: %s\n", na_results_errno(out),
                                na_results_reason(out));
                        na_elem_free(out);
                        na_server_close(s);
                        na_shutdown();
                        return -3;
                }
                retention_time_out = na_child_get_int(out,"retention-time",-1);
                printf("Retention time = %d\n",retention_time_out);
                na_elem_free(out);

        } else if(!strcmp(operation, "file-get-snaplock-retention-time-list-info-max")) {

                if(argc < 5) {
                        fprintf(stderr, "Usage: file_snaplock <filerip> <user> <password> ");
                        fprintf(stderr, "<file-get-snaplock-retention-time-list-info-max>\n");
                        na_server_close(s);
                        na_shutdown();
                        return -1;
                }

                in = na_elem_new("file-get-snaplock-retention-time-list-info-max");
                out = na_server_invoke_elem(s,in);
                if (na_results_status(out) != NA_OK) {
                        printf("Error %d: %s\n", na_results_errno(out),
                                na_results_reason(out));
                        na_elem_free(out);
                        na_server_close(s);
                        na_shutdown();
                        return -3;
                }
                max_list_entries = na_child_get_int(out,"max-list-entries",-1);
                printf("max list entries = %d\n",max_list_entries);
                na_elem_free(out);

 	} else if(!strcmp(operation, "file-snaplock-retention-time-list-info")) {

                if(argc < 6) {
                        fprintf(stderr, "Usage: file_snaplock <filerip> <user> <password> ");
                        fprintf(stderr, "<file-snaplock-retention-time-list-info> <filepathname> ...\n");
                        na_server_close(s);
                        na_shutdown();
                        return -1;
                }
                in = na_elem_new("file-snaplock-retention-time-list-info");
                pathnames = na_elem_new("pathnames");
                path_counter = 5;/* Here it has been hard coded as 5 because first volume is specified at
                                    5th position from cmd prompt */
                pathname_info = na_elem_new("pathname-info");
                while(path_counter < argc)
                {
                        na_child_add_string(pathname_info, "pathname",argv[path_counter]);
                        path_counter++;
                }
                na_child_add(pathnames,pathname_info);
                na_child_add(in, pathnames);
                out = na_server_invoke_elem(s,in);
                if (na_results_status(out) != NA_OK) {
                        printf("Error %d: %s\n", na_results_errno(out),
                                na_results_reason(out));
                        na_elem_free(out);
                        na_server_close(s);
                        na_shutdown();
                        return -3;
                }
                // list the retention time for each path specified

                retention_list = na_elem_child(out, "file-retention-details");
                if (retention_list == NULL) {
                        // no data to list
                        na_elem_free(out);
                        na_server_close(s);
                        na_shutdown();
                        return -3;
                }

                printf("\nPath Name                     Retention Date\n");
                printf("----------------------------------------------");
                // Iterate through retention date list
                for (iter=na_child_iterator(retention_list); (nextElem =na_iterator_next(&iter)) != NULL;  ) {
                        printf("\n%-30s",na_child_get_string(nextElem, "pathname"));
                        retention_time = na_child_get_string(nextElem, "formatted-retention-time");
                        if(retention_time != NULL) {
                                printf(" %s",retention_time);
                         }
                }
                printf("\n----------------------------------------------\n");
 	} else if(!strcmp(operation, "file-set-snaplock-retention-time")) {

                if(argc < 7) {
                        fprintf(stderr, "Usage: file_snaplock <filerip> <user> <password> ");
                        fprintf(stderr, "<file-set-snaplock-retention-time> <filepathname> <retention time>\n");
                        na_server_close(s);
                        na_shutdown();
                        return -1;
                }

                path = argv[5];
                retention_time_in = argv[6];
                in = na_elem_new("file-set-snaplock-retention-time");
                na_child_add_string(in,"path",path);
                na_child_add_string(in,"retention-time",retention_time_in);
                out = na_server_invoke_elem(s,in);
                if (na_results_status(out) != NA_OK) {
                        printf("Error %d: %s\n", na_results_errno(out),
                                na_results_reason(out));
                        na_elem_free(out);
                        na_server_close(s);
                        na_shutdown();
                        return -3;
                }

        } else {
                usage();
                return -1;
        }

        na_server_close(s);
        na_shutdown();

        return 0;

}


