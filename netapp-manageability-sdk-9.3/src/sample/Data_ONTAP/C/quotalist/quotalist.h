//============================================================//
//                                                            //
// $Id:$						      // 
//                                                            //
// quotalist.h                                                //
//                                                            //
// Structure Definition 	                              //
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
	char		quota_target[MAX_NAME]; 
	char 		volume[MAX_NAME];				
	char		qtree[MAX_NAME];	
        char	 	quota_type[MAX_NAME];
} QuotaInfo, *QuotaInfoPtr;


