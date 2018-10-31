//============================================================//
//                                                            //
// $Id:$                                                       //
//                                                            //
// snmp.h                                                  //
//                                                            //
// Structure Definition 	                              //
//                                                            //
// Copyright 2007 Network Appliance, Inc. All rights          //
// reserved. Specifications subject to change without notice. // 
//                                                            //
// This SDK sample code is provided AS IS, with no support or //
// warranties of any kind, including but not limited to       //
// warranties of merchantability or fitness of any kind,      //
// expressed or implied.  This code is subject to the license //
// agreement that accompanies the SDK.                        //
//                                                            //
//		                   	                      //
//============================================================//



#define MAX_NAME 128

typedef struct {
	char oid[MAX_NAME];
	char value[MAX_NAME];
	char isValueHexadecimal[MAX_NAME];
	char contact[MAX_NAME];
	char isTrapEnabled[MAX_NAME];
	char location[MAX_NAME];
	char accessControl[MAX_NAME];
	char community[MAX_NAME];
	char hostName[MAX_NAME];
	char ipAddress[MAX_NAME];
} snmpInfo, *snmpInfoPtr;
