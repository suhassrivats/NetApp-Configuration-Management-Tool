//================================================================//
//                                                                //
//$Id:$                                                           //
//                                                                //
// sm.cpp                                                         //
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
// Refer README.html for details on sm command usage              //
//                                                                //
//================================================================//

#include "stdafx.h"
#include <stdlib.h>
#include <netapp_api.h>
#include <string.h>
#include <Windows.h>

extern void argshift (int *, char **);
extern int smidle (int, char **);
extern int smbreak (int, char **);
extern int smresync (int, char **);
extern int sminit (int, char **);
extern int smupdate (int, char **);
int             use_rpc = 1;            					
char            user[] = "root";        					
char            passwd[] = "passwd";    					
void main(int argc, char **argv)
{
	int	ret;
	char	cmd[128];

	if(argc < 2) {
		printf("Argument missing. Possible arguments are idle,break,resync,init,initialize,update \n");
		exit(-1);
	}

	strcpy (cmd, argv[1]);
	argshift (&argc, argv);
	if (!strcmp (cmd, "idle"))
	{
 	 ret = smidle (argc, argv);
	}
	else if (!strcmp (cmd, "break"))
	{
	  ret = smbreak (argc, argv);
	}
	else if (!strcmp (cmd, "resync"))
	{
	  ret = smresync (argc, argv);
	}
	else if (!strcmp (cmd, "init") || !strcmp (cmd, "initialize"))
	{
	  ret = sminit (argc, argv);
	}
	else if (!strcmp (cmd, "update"))
	{
	  ret = smupdate (argc, argv);
	}
	else 
	{
	printf ("Not a valid command\n");
	}
}
