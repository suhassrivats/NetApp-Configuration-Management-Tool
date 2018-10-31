//======================================================================//
//                                                                      //
// $ID$                                                                 //
//                                                                      //
// nfs.c                                                                //
//                                                                      //
// Brief information of the contents                                    //
//                                                                      //
// Copyright 2002-2003 Network Appliance, Inc. All rights               //
// reserved. Specifications subject to change without notice.           //
//                                                                      //
// This SDK sample code is provided AS IS, with no support or           //
// warranties of any kind, including but not limited to                 //
// warranties of merchantability or fitness of any kind,                //
// expressed or implied.  This code is subject to the license           //
// agreement that accompanies the SDK.                                  //
//                                                                      //
//  Sample for usage of following nfs group API:                        //
//                      nfs-enable                                      //
//                      nfs-disable                                     //
//                      nfs-status                                      //
//                      nfs-exportfs-list-rules                         //
//                                                                      //
// Usage:                                                               //
// nfs <filer> <user> <password> <operation>                            //
//                                                                      //
// <filer>      -- Name/IP address of the filer                         //
// <user>       -- User name                                            //
// <password>   -- Password                                             //
// <operation>  --                                                      //
//                 enable                                               //
//                 disable                                              //
//                 status                                               //
//                 list                                                 //
//======================================================================//


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netapp_api.h>


void print_usage() {
        printf("\nUsage : nfs <filer> <user> <passwd> <operation> \n");
        printf("<filer> -- ");
        printf("Name/IP address of the filer\n");
        printf("<user>  -- User Name\n");
        printf("<passwd>        -- Password\n");
        printf("<operation>     --\n");
        printf("\tenable - To enable NFS Service\n");
        printf("\tdisable - To disable NFS Service\n");
        printf("\tstatus - To print the status of NFS Service\n");
        printf("\tlist - To list the NFS export rules\n");
        exit (-1);
}

/****************************************************************************
 Name: Main

 Description: Initializes the server context object and calls the
              appropriate nfs API commands based on the input arguments

 Parameters:
      IN:
        argc    - number of command line arguments
        argv    - Array of command line arguments

 Return value: None
******************************************************************************/

int main(int argc, char* argv[])
{
        na_server_t*    s;
        na_elem_t       *out,*in,*export_info;
        na_elem_t*      nextElem = NULL;
        na_elem_t*      nextHost = NULL;
        na_elem_iter_t  iter, hostIter;
        char*           filerip    = argv[1];
        char*           user       = argv[2];
        char*           passwd     = argv[3];
        char*           operation  = argv[4];
        char            err[256];

        if (argc < 5) {
                print_usage();

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

	if(!strcmp(operation, "enable")) {


                in = na_elem_new("nfs-enable");
                out = na_server_invoke_elem(s,in);
                if (na_results_status(out) != NA_OK) {
                        printf("Error %d: %s\n", na_results_errno(out),
                                na_results_reason(out));
                        na_elem_free(out);
                        na_server_close(s);
                        na_shutdown();
                        return -3;
                }
				else {
					printf("enabled successfully!\n");
				}

        } else if(!strcmp(operation, "disable")) {


                in = na_elem_new("nfs-disable");
                out = na_server_invoke_elem(s,in);
                if (na_results_status(out) != NA_OK) {
                        printf("Error %d: %s\n", na_results_errno(out),
                                na_results_reason(out));
                        na_elem_free(out);
                        na_server_close(s);
                        na_shutdown();
                        return -3;
                }
				else {
					printf("disabled successfully!\n");
				}

        } else if(!strcmp(operation, "status")) {


                in = na_elem_new("nfs-status");
                out = na_server_invoke_elem(s,in);
                if (na_results_status(out) != NA_OK) {
                        printf("Error %d: %s\n", na_results_errno(out),
                                na_results_reason(out));
                        na_elem_free(out);
                        na_server_close(s);
                        na_shutdown();
                        return -3;
                }
                if (!strcmp(na_child_get_string(out,"is-enabled"),"true")) {
                        printf("NFS Server is enabled\n");
                } else {
                        printf("NFS Server is disabled\n");
                }

	 }else if(!strcmp(operation, "list")) {


                in = na_elem_new("nfs-exportfs-list-rules");

                out = na_server_invoke_elem(s,in);
                if (na_results_status(out) != NA_OK) {
                        printf("Error %d: %s\n", na_results_errno(out),
                                na_results_reason(out));
                        na_elem_free(out);
                        na_server_close(s);
                        na_shutdown();
                        return -3;
                }

                export_info = na_elem_child(out,"rules");
                if (export_info == NULL) {
                        // no data to list
                        na_elem_free(out);
                        na_server_close(s);
                        na_shutdown();
                        return -3;
                }
                // Iterate through retention date list
                for (iter=na_child_iterator(export_info); (nextElem =na_iterator_next(&iter)) != NULL;  ) {

                        char path_name[1024] = "";
                        char rw_list[1024] = "rw=";
                        char ro_list[1024] = "ro=";
                        char root_list[1024] = "root=";
                        char *host_name = NULL;
                        na_elem_t *results = NULL;

                        strcpy(path_name,na_child_get_string(nextElem,"pathname"));

                        if(na_elem_child(nextElem,"read-only") != NULL){
                                results = na_elem_child(nextElem,"read-only");

                                for (hostIter=na_child_iterator(results); (nextHost =na_iterator_next(&hostIter)) != NULL;  ) {

                                        if(na_child_get_string(nextHost,"all-hosts") != NULL){
                                                host_name = (char *)na_child_get_string(nextHost,"all-hosts");
                                                if(!strcmp(host_name,"true")){
                                                        strcat(ro_list,"all-hosts");
                                                        break;
                                                }
                                        } else if(na_child_get_string(nextHost,"name") != NULL) {
                                                host_name = (char *)na_child_get_string(nextHost,"name");
                                                strcat(ro_list,host_name);
                                                strcat(ro_list,":");
                                        }
                                }
                        }

			if(na_elem_child(nextElem,"read-write") != NULL){
                                results = na_elem_child(nextElem,"read-write");

                                for (hostIter=na_child_iterator(results); (nextHost =na_iterator_next(&hostIter)) != NULL;  ) {

                                        if(na_child_get_string(nextHost,"all-hosts") != NULL){
                                                host_name = (char *)na_child_get_string(nextHost,"all-hosts");
                                                if(!strcmp(host_name,"true")){
                                                        strcat(rw_list,"all-hosts");
                                                        break;
                                                }
                                        } else if(na_child_get_string(nextHost,"name") != NULL) {
                                                host_name = (char *)na_child_get_string(nextHost,"name");
                                                strcat(rw_list,host_name);
                                                strcat(rw_list,":");
                                        }
                                }
                        }
                        if(na_elem_child(nextElem,"root") != NULL){
                                results = na_elem_child(nextElem,"root");

                                for (hostIter=na_child_iterator(results); (nextHost =na_iterator_next(&hostIter)) != NULL;  ) {

                                        if(na_child_get_string(nextHost,"all-hosts") != NULL){
                                                host_name = (char *)na_child_get_string(nextHost,"all-hosts");
                                                if(!strcmp(host_name,"true")){
                                                        strcat(root_list,"all-hosts");
                                                        break;
                                                }
                                        } else if(na_child_get_string(nextHost,"name") != NULL) {
                                                host_name = (char *)na_child_get_string(nextHost,"name");
                                                strcat(root_list,host_name);
                                                strcat(root_list,":");
                                        }
                                }
                        }

                        strcat(path_name, "  ");
                        if(strcmp(ro_list,"ro=")) {
                                strcat(path_name,ro_list);
                        }
                        if(strcmp(rw_list,"rw=")) {
                                if(strstr(path_name,ro_list) != NULL) {
                                        strcat(path_name,",");
                                }
                                strcat(path_name,rw_list);
                        }
                        if(strcmp(root_list,"root=")) {
                                if((strstr(path_name,ro_list) != NULL) || (strstr(path_name,rw_list) != NULL)) {
                                        strcat(path_name,",");
                                }
                                strcat(path_name,root_list);
                        }


                        printf("%s\n",path_name);
                }

 	} else {
                printf("Invalid Operation \n");
                print_usage();
        }

        na_elem_free(out);
        na_server_close(s);
        na_shutdown();

        return 0;

}

