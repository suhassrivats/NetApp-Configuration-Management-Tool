//============================================================//
//                                                            //
// $Id:$                                                       //
//                                                            //
// optmgmt.h                                                  //
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
        char	 	name[MAX_NAME];
        char	 	value[MAX_NAME];
	char 		clusterConstraint[MAX_NAME];
} OptionInfo,*OptionInfoPtr;
