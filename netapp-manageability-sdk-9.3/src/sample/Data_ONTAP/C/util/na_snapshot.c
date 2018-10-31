//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// snapshot.c                                                 //
//                                                            //
// Encapsulated ONTAPI calls.                                 //
//                                                            //
// When an output parameter is optional, the corresponding    //
// field in the structure being filled in is set to be an     //
// empty string.                                              //
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

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "netapp.h"

//============================================================//

int SnapshotCreate(NaServerPtr nsp, const char* ssname)
{
	int			r = 1;
	na_elem_t*	out;

	out = na_server_invoke(nsp->server, "snapshot-create", 
							"volume", nsp->volname,
							"snapshot", ssname,
							NULL);

	if (na_results_status(out) != NA_OK) {
		fprintf(stderr, "Error %d during snapshot-create: %s\n", 
						na_results_errno(out), na_results_reason(out));
        r = 0;
    }

	na_elem_free(out);
	return r;
}

//============================================================//

int SnapshotDelete(NaServerPtr nsp, const char* ssname)
{
	int			r = 1;
	na_elem_t*	out;

	out = na_server_invoke(nsp->server, "snapshot-delete", 
							"volume", nsp->volname,
							"snapshot", ssname,
							NULL);

	if (na_results_status(out) != NA_OK) {
		fprintf(stderr, "Error %d during snapshot-delete: %s\n", 
						na_results_errno(out), na_results_reason(out));
        r = 0;
    }

	na_elem_free(out);
	return r;
}

//============================================================//

int SnapshotRename(NaServerPtr nsp, const char* oldssname,
					                 const char* newssname)
{
	int			r = 1;
	na_elem_t*	out;

	out = na_server_invoke(nsp->server, "snapshot-rename", 
							"volume", nsp->volname,
							"current-name", oldssname,
							"new-name", newssname,
							NULL);

	if (na_results_status(out) != NA_OK) {
		fprintf(stderr, "Error %d during snapshot-rename: %s\n", 
						na_results_errno(out), na_results_reason(out));
        r = 0;
    }

	na_elem_free(out);
	return r;
}

//============================================================//

int SnapshotListInfo(NaServerPtr nsp, SnapshotInfo** ssinfo, int* nitems)
{
	int				r = 1;
	na_elem_t*		snapshots;
	na_elem_t*		out;
	na_elem_t*		ss;
	na_elem_iter_t	iter;
	SnapshotInfo*	info;
	SnapshotInfo*	infoptr;
	int				neltsread = 0;
	const char*		ptr;

	*ssinfo = NULL;

	out = na_server_invoke(nsp->server, "snapshot-list-info", 
							"volume", nsp->volname,
							NULL);

	if (na_results_status(out) != NA_OK) {
		fprintf(stderr, "Error %d during snapshot-list-info: %s\n", 
						na_results_errno(out), na_results_reason(out));
        r = 0;
		goto cleanup;
    }

	// 
	// get snapshot list
	//
	snapshots = na_elem_child(out, "snapshots");
	if (snapshots == NULL) {
		// no snapshots to report
		return 1;
	}

	//
	// allocate memory for first snapshot 
	//
	info = (SnapshotInfoPtr) malloc(sizeof(SnapshotInfo));
	if (info == NULL) {
		fprintf(stderr, "Memory allocation error at line %d\n", __LINE__);
		r = 0;
		goto cleanup;
	}

	// 
	// iterate through snapshot list
	//
	for(iter=na_child_iterator(snapshots); 
			(ss=na_iterator_next(&iter)) != NULL;  ) {
	
		//
		// for each snapshot, increase the size of the
		// array and use pointer arithmetic to get a pointer
		// to the last new and empty record
		//
		info = (SnapshotInfoPtr) realloc(info, 
							(neltsread+1)*sizeof(SnapshotInfo));
		if (info == NULL) {
			fprintf(stderr, "Memory allocation error at line %d\n", __LINE__);
			r = 0;
			goto cleanup;
		}
		infoptr = info + neltsread;

		//
		// dig out the info
		//
		infoptr->accesstime = na_child_get_int(ss, "access-time", 0);
		infoptr->total =	  na_child_get_int(ss, "total", 0);
		infoptr->cumtotal =   na_child_get_int(ss, "cumulative-total", 0);

		ptr = na_child_get_string(ss, "busy");
		if (strcmp(ptr, "true") == 0)
			infoptr->busy = 1;
		else
			infoptr->busy = 0;
		
		safestrcpy(infoptr->dependency, na_child_get_string(ss, "dependency"));
		safestrcpy(infoptr->name, na_child_get_string(ss, "name"));

		neltsread++;
	}
	*ssinfo = info;
	*nitems = neltsread;

cleanup:
	na_elem_free(out);
	return r;
}

//============================================================//

int SnapshotGetSchedule(NaServerPtr nsp, SnapshotSchedulePtr sched)
{
	int			r = 1;
	na_elem_t*	out;

	out = na_server_invoke(nsp->server, "snapshot-get-schedule", 
							"volume", nsp->volname,
							NULL);
	if (na_results_status(out) != NA_OK) {
		fprintf(stderr, "Error %d during snapshot-get-schedule: %s\n", 
						na_results_errno(out), na_results_reason(out));
        r = 0;
		goto cleanup;
    }

	sched->minutes = na_child_get_int(out, "minutes", 0);
	sched->hours =   na_child_get_int(out, "hours", 0);
	sched->days =    na_child_get_int(out, "days", 0);
	sched->weeks =   na_child_get_int(out, "weeks", 0);

	safestrcpy(sched->whichhours, na_child_get_string(out, "which-hours"));
	safestrcpy(sched->whichminutes, na_child_get_string(out, "which-minutes"));

cleanup:
	na_elem_free(out);
	return r;
}

//============================================================//

