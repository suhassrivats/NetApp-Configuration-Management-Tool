//================================================================//
//                                                                //
//$Id:$                                                           //
//                                                                //
// smidle.cpp                                                     //
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
extern int use_rpc;
extern char user[];
extern char passwd[];
int smidle(int argc, char ** argv)
{
        na_server_t*    s;
        na_elem_t*      out;
	na_elem_iter_t iter;
	na_elem_t *c, *e;
        char            err[256];
	char	a;
	int	delay = 60, found = 0, idle = 0, argflag = 0,verbose = 0;
	char	*filer, src[255],dst[255],status[128], srel[255], 				drel[255];

	if (argc < 3 || argc > 6)
	{
		fprintf (stderr, "Usage: sm idle [-t sec] [-v] src_filer:src_vol|src_qtree dst_filer:dst_vol|dst_qtree\n");
		exit (5);
	}
	filer = (char *)malloc (255);
	while ((a=getopt(argc, argv, "t:v")) > 0)
	{
		if (a == 't')
		{
			delay = atoi(optarg);
			argflag += 2;
		}
		else if (a == 'v')
		{
			verbose = 1;
			argflag++;
		}
	}
	if (verbose) printf ("Delay set to %d seconds.\n", delay);
        if (!na_startup(err, sizeof(err))) {
              fprintf(stderr, "Error in na_startup: %s\n", err);
              return -1;
        }
	strcpy (srel, argv[1 + argflag]);
	strcpy (drel, argv[2 + argflag]);
	filer = strtok(argv[2 + argflag], ":");
	if (verbose) 									printf ("Conntect to filer: %s\n", filer);
    	s = na_server_open(filer, 1, 1);

        if ( use_rpc) {
              na_server_style(s, NA_STYLE_RPC);
        }
        else {
               na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
               na_server_adminuser(s, user, passwd);
        }
	while (!idle)
	{
      	    out = na_server_invoke(s, "snapmirror-get-status", NULL);
       		if (na_results_status(out) != NA_OK) {
           	     printf("Error %d: %s\n", na_results_errno(out), 						na_results_reason(out));
               		return -2;
          }     
          else { 
		c = na_elem_child(out, "snapmirror-status");
		for (iter=na_child_iterator(c); 							(e=na_iterator_next(&iter)) != NULL;)
		{
			strcpy (src, na_child_string(e, "source-location					"));
			strcpy (dst, na_child_string(e, "destination-loc					ation"));
			strcpy (status, na_child_string(e, "status"));
//			if (verbose) printf ("SRC=%s SREL=%s DEST=%s 								DREL=%s STATUS=%s\n", 								src, srel, dst, drel,								 status);
			if (!strcmp (src, srel) &&!strcmp (dst, drel))
			{
				if (verbose) 									printf ("FOUND: %s : %s : %s\n",							 src, dst, status);
				found = 1;
				break;
			}
		}
		if (!found)
		{
			fprintf (stderr, "SnapMirror relationship 						not found.\n");
			exit (1);
		}
		if (!strcmp (status, "idle"))
			idle = 1;
		else {
			if (verbose) 
			printf ("Status is %s\nSleeping for %d 							seconds\n", status, delay);
			Sleep (delay*1000);
		}
	  }
       }
	free (filer);
       	na_elem_free(out);
	if (verbose) 
	printf ("SnapMirror between %s and %s is Idle\n", src, dst);
        return 0;
}    
