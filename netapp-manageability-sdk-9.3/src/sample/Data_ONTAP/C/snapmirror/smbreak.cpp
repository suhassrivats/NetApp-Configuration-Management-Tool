//================================================================//
//                                                                //
//$Id:$                                                           //
//                                                                //
// smbreak.cpp                                                    //
// Program implements snapmirror commands at Windows cmd prompt   //
//                                                                //
// Copyright 2005 Network Appliance, Inc. All rights              //
// reserved. Specifications subject to change without notice.     //
//                                                                //
// This SDK sample code is provided AS IS, with no support or     //
// warranties of any kind, including but not limited to           //
// warranties of merchantability or fitness of any kind,          //
// expressed or implied.  This code is subject to the license     //
// agreement that accompanies the SDK.                            //
//                                                                //
//================================================================//

#include <stdlib.h>
#include <netapp_api.h>
#include <string.h>
#include <Windows.h>
extern int getopt (int, char **, char *);
extern char *	optarg;
extern  int    use_rpc ;            						
extern  char   user[] ;        							
extern  char   passwd[] ;    							
int smbreak(int argc, char **argv)
{
        na_server_t*    s;
        na_elem_t*      out;
	na_elem_iter_t iter;
	na_elem_t *c, *e;
        char   err[256];
	char	a;
	int	argflag = 0, verbose = 0, quiet = 0, found = 0, 				delay = 10;
	char	*filer, drel[255], dst[255], state[128];

	if (argc < 3 || argc > 4)
	{
		fprintf (stderr, "Usage: sm break [-v] dst_filer: dst_vol | dst_qtree\n");
			exit (5);
	}

	filer = (char *)malloc (255);
	while ((a=getopt(argc, argv, "v")) > 0)
	{
		if (a == 'v')
		{
			verbose = 1;
			argflag++;
		}
	}
        if (!na_startup(err, sizeof(err))) {
                fprintf(stderr, "Error in na_startup: %s\n", err);
                return -1;
        }
	strcpy (drel, argv[1 + argflag]);
	filer = strtok(argv[1 + argflag], ":");
        s = na_server_open(filer, 1, 1);

        if ( use_rpc) {
               na_server_style(s, NA_STYLE_RPC);
        }
        else {
               na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
               na_server_adminuser(s, user, passwd);
        }
		// First let's quiesce the relationship
	if (verbose) 
	printf ("Quiesceing the relationship...\n");
	out = na_server_invoke (s, "snapmirror-quiesce", 							"destination-location", drel, NULL);
	if (na_results_status(out) != NA_OK)
	{
       		printf("Error %d: %s\n", na_results_errno(out), 					na_results_reason(out));
       		return -2;
	}


	// Now wait until it's quiesced
	while (!quiet)
	{
	  out = na_server_invoke (s, "snapmirror-get-status", NULL);
	  if (na_results_status(out) != NA_OK)
	  {
       		 printf("Error %d: %s\n", na_results_errno(out), 					na_results_reason(out));
          		 return -2;
	  }
	  c = na_elem_child(out, "snapmirror-status");
	  for (iter=na_child_iterator(c); 							(e=na_iterator_next(&iter)) != NULL;)
	  {
		strcpy (dst, na_child_string(e, "destination-location"));
			strcpy (state, na_child_string(e, "state"));
		if (!strcmp (dst, drel))
		{
		   if (verbose) printf ("FOUND: %s : %s\n", dst, state);
		   found = 1;
		   break;
		}
	  }
        if (!found)
	  {
		fprintf (stderr, "SnapMirror relationship not found.\n");
		exit (1);
	   }
  	if (!strcmp (state, "quiesced"))
		quiet = 1;
	   else
	   {
		if (verbose) 										printf ("State is %s\nSleeping for %d seconds\n"					, state, delay);
			Sleep (delay*1000);
	    }
	} // end while

	// Now we are quiesced, we can break

	if (verbose) 									printf ("Quiese complete..breaking\n");
	out = na_server_invoke (s, "snapmirror-break", 								"destination-location", drel, NULL);
	if (na_results_status(out) != NA_OK)
	{
     	     printf("Error %d: %s\n", na_results_errno(out), 						na_results_reason(out));
     	     return -2;
	}
	free (filer);
        na_elem_free(out);
	if (verbose) 
		printf ("SnapMirror to %s is broken\n", drel);
	    return 0;
}    
