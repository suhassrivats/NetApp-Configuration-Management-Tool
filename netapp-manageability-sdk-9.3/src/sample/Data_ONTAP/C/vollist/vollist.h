//============================================================//
//                                                            //
// $Id: //depot/prod/zephyr/belair/src/sample/C/vollist/vollist.h#1 $                                                       //
//                                                            //
// vollist.h                                                  //
//                                                            //
// Structure Definition 	                              //
//                                                            //                //                                                            //  
// Copyright 2005 Network Appliance, Inc. All rights          //
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
	int		disk_count; 
	int		files_total;				
	int		files_used;	
        char	 	name[MAX_NAME];
        char	 	state[MAX_NAME];
} VolumeInfo, *VolumeInfoPtr;


