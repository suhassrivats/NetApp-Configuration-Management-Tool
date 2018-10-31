//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// ontapiver.h                                                //
//                                                            //
// Sample code which retrieves the API version of a filer     //
// by trying to request a too-large version # and             //
// interpreting the error message that comes back.            //
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

#ifndef ONTAPI_VER_H
#define ONTAPI_VER_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netapp_api.h>
#include <netapp_errno.h>


int na_has_ontapi_version(
						const char* filername,
						const char* user,
						const char* passwd,
						int			majorversion,
						int			minorverions);

int na_get_ontapi_version(
 						const char* filername,
						const char* user,
						const char* passwd,
						int* majorversion,
						int* minorversion);

#endif
