//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// server.c                                                   //
//                                                            //
// Utility routines.                                          //
//                                                            //
// Copyright 2003 Network Appliance, Inc. All rights		  //
// reserved. Specifications subject to change without notice. // 
//                                                            //
// This SDK sample code is provided AS IS, with no support or //
// warranties of any kind, including but not limited to       //
// warranties of merchantability or fitness of any kind,      //
// expressed or implied.  This code is subject to the license //
// agreement that accompanies the SDK.                        //
//                                                            //
// tab size = 4												  //
//															  //
//============================================================//

//234567890123456789012345678901234567890123456789012345678901234567890123456789

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "netapp.h"
#include "ontapiver.h"

//============================================================//

char* safestrncpy(char* dst, const char* src, int n)
{
	if (dst) {
		if (src) {
			strncpy(dst, src, n-1);
			dst[n-1] = 0;
		}
		else
			dst[0] = 0;
	}
	return dst;
}

//============================================================//

char* safestrcpy(char* dst, const char* src)
{
	if (dst) {
		if (src) {
			strcpy(dst, src);
		}
		else
			dst[0] = 0;
	}
	return dst;
}

//============================================================//

int NaServerInit(NaServerPtr nsp, const char* filer,
								  const char* user,
								  const char* passwd,
								  int         majorver,
								  int		  minorver)

{
	if (nsp == NULL)
		return 0;

	memset(nsp, 0, sizeof(NaServer));

	if (na_has_ontapi_version(filer, user, passwd, 
								majorver, minorver) == 0)
		return 0;
		
	safestrcpy(nsp->filer, filer);
	safestrcpy(nsp->user, user);
	safestrcpy(nsp->passwd, passwd);
	nsp->minorver = minorver;
	nsp->majorver = majorver;
	nsp->volname[0] = 0;
	nsp->server = NULL;

	return 1;
}

//============================================================//

int NaServerOpen(NaServerPtr nsp)
{
	if (nsp == NULL) 
		return 0;

	//
	// close it if it's already open
	//
	if (nsp->server)
		NaServerClose(nsp);

	// 
	// open server connection
	//
	nsp->server = na_server_open(nsp->filer, nsp->majorver, 
											 nsp->minorver);
	if (nsp->server == NULL) {
		fprintf(stderr, "Couldn't open connection to server %s\n",
				nsp->filer);
		return 0;
	}

    na_server_style(nsp->server, NA_STYLE_LOGIN_PASSWORD);
    na_server_adminuser(nsp->server, nsp->user, nsp->passwd);

	return 1;
}

//============================================================//

int NaServerClose(NaServerPtr nsp)
{
	if (nsp && nsp->server) {
		na_server_close(nsp->server);
		nsp->server = NULL;
	}
	return 0;
}

//============================================================//

