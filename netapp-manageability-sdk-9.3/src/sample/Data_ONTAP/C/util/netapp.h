//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// netapp.h                                                   //
//                                                            //
// Encapsulations of some ONTAPI APIs                         //
//                                                            //                                                            //
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

#ifndef NETAPP_H
#define NETAPP_H

#include "netapp_api.h"

#define MAJORVER	1
#define MINORVER	1		// using ONTAPI version 1.1

#ifndef ENOFILE
	#define ENOFILE	2
#endif

#ifndef MAX_NAME
	#define MAX_NAME 128
#endif

#ifndef MAX_PATH
	#define MAX_PATH 1024
#endif

typedef struct {
	int		accesstime;				// seconds since 1-1-1970
	int		busy;				
	int		total;					// total 1024-byte blocks in this snapshot
	int		cumtotal;				// total 1024-byte blocks in this and
									//     all previous existing snapshots
	char	dependency[MAX_NAME];	// either "snapmirror" or "snapvault" or ""
	char	name[MAX_NAME];			// snapshot name
} SnapshotInfo, *SnapshotInfoPtr;

typedef struct {
	int		minutes;				// number of "minutely" snapshots to keep
	int		hours;					// number of hourly snapshots to keep
	int		days;					// number of daily snapshots to keep
	int		weeks;					// number of weekly snapshots to keep
	char	whichhours[MAX_NAME];	// list of which hours to keep
	char	whichminutes[MAX_NAME]; // list of which minutes to keep
} SnapshotSchedule, *SnapshotSchedulePtr;

typedef struct {	
	char			filer[MAX_NAME];	// filer to manage snapshots on
	char			volname[MAX_PATH];	// vol to manage, or blank for all
	na_server_t*	server;				// ONTAPI handle to filer
	char			user[MAX_NAME];		// login 
	char			passwd[MAX_NAME];	// password
	int				majorver;			// major version number
	int				minorver;			// minor version number
} NaServer, *NaServerPtr;

//============================================================//

// in server.c

int NaServerInit(NaServerPtr nsp, const char* filer,
								  const char* user,
								  const char* passwd,
								  int         majorver,
								  int		  minorver);
int NaServerOpen(NaServerPtr nsp);
int NaServerClose(NaServerPtr nsp);

// utility routines, also in server.c

char* safestrncpy(char* dst, const char* src, int n);
char* safestrcpy(char* dst, const char* src);


//============================================================//

// in snapshot.c

int SnapshotCreate(NaServerPtr nsp, const char* ssname);
int SnapshotDelete(NaServerPtr nsp, const char* ssname);
int SnapshotRename(NaServerPtr nsp, const char* oldssname,
					                const char* newssname);
int SnapshotListInfo(NaServerPtr nsp, SnapshotInfo** ssinfo, int* nitems);
int SnapshotGetSchedule(NaServerPtr nsp, SnapshotSchedulePtr sched);

//============================================================//

#endif

