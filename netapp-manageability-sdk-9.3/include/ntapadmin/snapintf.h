/*
 * $Id: //depot/prod/DOT/fsb/ontap/files/ntapadmin/snapintf.h#1 $
 *
 * Network Appliance Snapshot Service IDL File
 *
 * This module defines the data structures returned by the
 * Snap Management RPCs
 *
 *
 * (c)1999 Network Appliance, Inc. All Rights Reserved.
 */

#ifndef _SNAPINTF_
#define _SNAPINTF_


/*
 * The following will define the information returned for each snapshot
 */
typedef struct _Snapsvc_stats{
	ISTRING WCHAR*		snapName;	/* Name of the snapshot*/
	OLD_LARGE_INTEGER	modTime;	/* Last access time of snapshot. */
	OLD_ULARGE_INTEGER 	total;		/* Blks in snapshot + active. */
	OLD_ULARGE_INTEGER 	cum_total;	/* Blks in snapshot + prev snaps + active. */
	ULONG			busy;		/* indication of whether snap is busy*/
	ULONG			type;		/* Type of snapshot inode. */
} Snapsvc_stats;


/*
 * This structure is used to return all of the current snapshots on a volume.
 * Buffer is an array of Snapsvc_stats whose maximum index is NumSnaps.
 */

typedef struct _SNAPLIST{
    ULONG   NumSnaps;
    SIZEIS(NumSnaps) Snapsvc_stats *Buffer;
} SNAPLIST_BUFFER;


/*
 * This structure is used to get and set the snapshot schedule
 */

typedef struct _Snapsvc_schedule {
	LONG	weeks;		/* # of "week.N" files to keep. */
	LONG	days;		/* # of "day.N" files to keep. */

	LONG	hours;		/* # of "hour.N" files to keep. */
	ULONG	hour_mask[1];	/* Hour list bit mask, only take hour-snapshot
				 * for true hours */
	LONG	mins;		/* # of "min.N" files to keep. */
	ULONG	min_mask[2];	/* Min bit mask, Only take min-snapshot
				 * for true mins. */
} Snapsvc_schedule;

/*
 * Enum defines for log level priority.
 * This information has been borrowed from 
 * //depot/prod/ontap/main/prod/common/sys/syslog.h
 *
 * NOTE: These definitions are used in windows applications.
 *       If the definition is included in a shipping release
 *	 of the product, then it should be considered frozen.
 */
typedef enum {
	APP_LOG_EMERG,	/* 0 */
	APP_LOG_ALERT,	/* 1 */
	APP_LOG_CRIT,	/* 2 */
	APP_LOG_ERR,	/* 3 */
	APP_LOG_WARNING,/* 4 */
	APP_LOG_NOTICE,	/* 5 */
	APP_LOG_INFO,	/* 6 */
	APP_LOG_DEBUG	/* 7 */
} APP_ASUP_LOG_LEVEL;

#endif /*_SNAPINTF_*/
