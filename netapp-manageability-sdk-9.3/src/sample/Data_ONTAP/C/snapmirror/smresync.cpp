//================================================================//
//								  //
//$Id:$ 							  //
//								  //
// smresync.cpp 						  //
// Program implements snapmirror commands at Windows cmd prompt   //
//								  //
// Copyright 2005 Network Appliance, Inc. All rights		  //
// reserved. Specifications subject to change without notice.	  //
//								  //
// This SDK sample code is provided AS IS, with no support or	  //
// warranties of any kind, including but not limited to 	  //
// warranties of merchantability or fitness of any kind,	  //
// expressed or implied.  This code is subject to the license	  //
// agreement that accompanies the SDK.				  //
//								  //
//================================================================//

#include <stdlib.h>
#include <netapp_api.h>
#include <string.h>
#include <Windows.h>
extern int getopt (int, char **, char *);
extern char *	optarg;
extern int use_rpc;								
extern	char user[] ;				
extern	char passwd[];			
int sminit(int argc, char **argv)
{
	na_server_t*	s;
	na_elem_t*	out;
	char	err[256];
	char	a;
	int 	kbrate = 0, argflag = 0, verbose = 0;
	char	*filer, srel[255], drel[255];
	char	snapshot[255], kbstr[10];

	snapshot[0] = '\0';
	if (argc < 3 || argc > 8)
	{
		fprintf (stderr, "Usage: sm resync [-v] [-k kbytes] [-s snapshot] src_filer:src_vol|src_qtree dst_filer:dst_vol|dst_qtree\n");
		exit (5);
	}

	filer = (char *)malloc (255);
	while ((a=getopt(argc, argv, "k:s:v")) > 0)
	{
		if (a == 'k')
		{
			kbrate = atoi(optarg);
			sprintf (kbstr, "%d", kbrate);
			argflag += 2;
		}
		else if (a == 's')
		{
			strcpy (snapshot, optarg);
			argflag += 2;
		}
		else if (a == 'v')
		{
			verbose = 1;
			argflag++;
		}
	}
	if (!na_startup(err, sizeof(err))) {
			fprintf(stderr, "Error in na_startup: %s\n", err);
			return -1;
	}
	strcpy (srel, argv[1 + argflag]);
	strcpy (drel, argv[2 + argflag]);
	filer = strtok(argv[2 + argflag], ":");
	if (verbose) 										printf ("Conntect to filer: %s\nKbrate = %d\nSnapshot = %s\n", 
			filer, kbrate, snapshot);
			
	s = na_server_open(filer, 1, 1);

	if ( use_rpc) {
		na_server_style(s, NA_STYLE_RPC);
	}
	else {
		na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
		na_server_adminuser(s, user, passwd);
	}

	if (kbrate <= 0 && !strcmp (snapshot, ""))
	out = na_server_invoke(s, "snapmirror-initialize",							 "source-location",
				srel, "destination-location", 							drel, NULL);
	else if (kbrate > 0 && !strcmp (snapshot, ""))
	out = na_server_invoke (s, "snapmirror-initialize", 							"source-location", srel, 							"destination-location", drel,
				"max-transfer-rate", kbstr,
				NULL);
	else if (kbrate <= 0 && strcmp (snapshot, ""))
	out = na_server_invoke (s, "snapmirror-initialize", 							"source-location", srel,							"destination-location", drel,
				"source-snapshot",snapshot, NULL						);
			
	else if (kbrate > 0 && strcmp (snapshot,""))
	out = na_server_invoke (s, "snapmirror-initialize", 							"source-location", srel,
				"destination-location", drel,
				"max-transfer-rate", kbstr,
				"source-snapshot", snapshot, 							NULL);
			
	if (na_results_status(out) != NA_OK) {
	  printf("Error %d: %s\n", na_results_errno(out), 					na_results_reason(out));
	  return -2;
	}	  
	free (filer);
	na_elem_free(out);
	if (verbose) 										printf ("SnapMirror between  %s and %s has started\n", 					srel, drel);
	return 0;
}	 
