//================================================================//
//                                                                //
//$Id:$                                                           //
//                                                                //
// argshift.cpp                                                   //
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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

void argshift (int *ac, char **av)
{
	int i;
	assert(0 != *ac);
	for (i = 0; i < *ac; i++) {
		av[i] = av[i + 1];
	}
	(*ac)--;
	return;
}
