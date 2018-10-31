//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// snapman.c                                                  //
//                                                            //
// Application which uses ONTAPI APIs to get snapshot lists	  //
// and schedules, and take, rename and delete snapshots.      //
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
//                                                            //
// See Usage() for command-line syntax                        //
//															  //
//============================================================//

//234567890123456789012345678901234567890123456789012345678901234567890123456789

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "../util/netapp.h"
#include "../util/ontapiver.h"

//============================================================//
//
// portability
//
#ifdef WIN32
	#define strcasecmp _stricmp
#endif

//============================================================//

void Usage(char* argv[]);
void GetSchedule(NaServerPtr nsp, const char* volname);
void CreateSnapshot(NaServerPtr nsp, const char* volname, 
									   const char* snapname);
void RenameSnapshot(NaServerPtr nsp, const char* volname,
									   const char* oldsnapname, 
									   const char* newsnapname);
void DeleteSnapshot(NaServerPtr nsp, const char* volname,
									   const char* snapname);
void ListInfo(NaServerPtr nsp, const char* volname);

//============================================================//

int main(int argc, char* argv[])
{
	int			ret = 0;
	char		err[4096];
	char*		filer = argv[2];
	char*		user = argv[3];
	char*		passwd = argv[4];
	NaServer	server;
	
	if (argc < 6) 
		Usage(argv);

	//
	// One-time initialization of system on client
	//
    if (!na_startup(err, sizeof(err))) {
            fprintf(stderr, "Error in na_startup: %s\n", err);
            return -2;
    }

	//
	// request ONTAPI version 1.1
	//
	if (!NaServerInit(&server, filer, user, passwd, 1, 1)) {
		fprintf(stderr, "This filer doesn't support ONTAPI version 1.1\n");
		return -3;
	}

	if (strcasecmp(argv[1], "-g") == 0)
		GetSchedule(&server, argv[5]);
	else if (strcasecmp(argv[1], "-c") == 0)
		CreateSnapshot(&server, argv[5], argv[6]);
	else if (strcasecmp(argv[1], "-r") == 0)
		RenameSnapshot(&server, argv[5], argv[6], argv[7]);
	else if (strcasecmp(argv[1], "-d") == 0)
		DeleteSnapshot(&server, argv[5], argv[6]);
	else if (strcasecmp(argv[1], "-l") == 0)
		ListInfo(&server, argv[5]);
	else
		Usage(argv);	

	na_shutdown();
	return 0;
}

//============================================================//

void Usage(char* argv[])
{
	fprintf(stderr, 
		"Usage: snapman -g <filer> <user> <pw> <vol> \n"
		"               -l <filer> <user> <pw> <vol> \n"
		"               -c <filer> <user> <pw> <vol> <snapshotname> \n"
		"               -r <filer> <user> <pw> <vol> <oldsnapshotname> <newname> \n"
		"               -d <filer> <user> <pw> <vol> <snapshotname> \n\n");
	fprintf(stderr, "E.g. snapman -l filer1 root 6a55w0r9 vol0 \n\n");
	fprintf(stderr, 
		"Use -g to get the snapshot schedule\n"
		"    -l to list snapshot info \n"
		"    -c to create a snapshot \n"
		"    -r to rename one \n"
		"    -d to delete one \n");

	exit(-1);
}

//============================================================//

void GetSchedule(NaServerPtr nsp, const char* volname)
{
	SnapshotSchedule		sssched;

	//
	// get the schedule
	//
	safestrcpy(nsp->volname, volname);

	if (NaServerOpen(nsp) == 0)
		return;

	SnapshotGetSchedule(nsp, &sssched);

	NaServerClose(nsp);

	//
	// print it out
	//
	printf("\n");
	printf("Snapshot schedule for volume %s on filer %s:\n", 
											volname, nsp->filer);
	printf("\n");
	printf("Snapshots are taken on minutes [%s] of each hour (%d kept)\n",
			sssched.whichminutes, sssched.minutes);
	printf("Snapshots are taken on hours [%s] of each day (%d kept)\n", 
			sssched.whichhours, sssched.hours);
	printf("%d nightly snapshots are kept\n", sssched.days);
	printf("%d weekly snapshots are kept\n", sssched.weeks);
	printf("\n");
}

//============================================================//

void CreateSnapshot(NaServerPtr nsp, const char* volname, 
                                        const char* snapname)
{
	strcpy(nsp->volname, volname);

	if (NaServerOpen(nsp) == 0)
		return;

	SnapshotCreate(nsp, snapname);

	NaServerClose(nsp);
}

//============================================================//

void RenameSnapshot(NaServerPtr nsp, const char* volname, 
                                        const char* oldsnapname, 
                                        const char* newsnapname)
{
	strcpy(nsp->volname, volname);

	if (NaServerOpen(nsp) == 0)
		return;

	SnapshotRename(nsp, oldsnapname, newsnapname);

	NaServerClose(nsp);
}

//============================================================//

void DeleteSnapshot(NaServerPtr nsp, const char* volname, 
                                        const char* snapname)
{
	strcpy(nsp->volname, volname);

	if (NaServerOpen(nsp) == 0)
		return;

	SnapshotDelete(nsp, snapname);

	NaServerClose(nsp);
}

//============================================================//


void ListInfo(NaServerPtr nsp, const char* volname)
{
	SnapshotInfoPtr				ssinfo = NULL;
	int							nssitems = 0;

	strcpy(nsp->volname, volname);

	if (NaServerOpen(nsp) == 0)
		return;

	//
	// Get info
	//
	SnapshotListInfo(nsp, &ssinfo, &nssitems);

	//
	// print snapshot info
	//
	if (nssitems) {
		printf("Snapshots on volume %s: \n\n", volname);         
		printf("NAME                    DATE                    BUSY   NBLOCKS CUMNBLOCKS  DEPENDENCY\n");
		printf("-------------------------------------------------------------------------------------\n");
	}
	else {
		printf("No snapshots on volume %s \n\n", volname);
	}
	while (nssitems) {

		char* tmp = asctime(localtime((time_t*)&ssinfo->accesstime));

		tmp[24] = 0;
		printf("%-23s %-24s  %d %10d %10d  %s\n",
				ssinfo->name,
				tmp,
				ssinfo->busy,
				ssinfo->total,
				ssinfo->cumtotal,
				ssinfo->dependency); 
	
		ssinfo++;
		nssitems--;
	}
	printf("\n");
		
	NaServerClose(nsp);
	
}

//============================================================//
//============================================================//
//============================================================//
//============================================================//
//============================================================//



