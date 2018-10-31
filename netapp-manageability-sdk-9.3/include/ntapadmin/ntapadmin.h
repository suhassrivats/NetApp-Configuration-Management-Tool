// $Id: //depot/prod/DOT/fsb/ontap/files/ntapadmin/ntapadmin.h#1 $
// Copyright(c) 1999, Network Appliance, Inc. All Rights Reserved.


// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the NTAPADMIN_EXPORTS
// symbol defined on the command line. this symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// NTAPADMIN_API functions as being imported from a DLL, wheras this DLL sees symbols
// defined with this macro as being exported.

#ifdef _USRDLL

#ifdef NTAPADMIN_EXPORTS
#define NTAPADMIN_API __declspec(dllexport)
#else
#define NTAPADMIN_API __declspec(dllimport)
#endif

#else

// If we're compiling a static library (_USRLIB),
// eliminate NTAPADMIN_API altogether
#define NTAPADMIN_API

#endif

#ifndef _NTDEF_
typedef LONG NTSTATUS, *PNTSTATUS;
#endif

#include <adminintf.h>
#include <snapintf.h>
#include <volintf.h>
#include <quotaintf.h>
#include <cifsadminintf.h>
#include <vdiskintf.h>
#include <zapiintf.h>
#include <snapmirrorintf.h>

extern CRITICAL_SECTION g_callGuard_cifsadminsvc;
extern CRITICAL_SECTION g_callGuard_snapsvc;
extern CRITICAL_SECTION g_callGuard_quotasvc;
extern CRITICAL_SECTION g_callGuard_snapmirrorsvc;
extern CRITICAL_SECTION g_callGuard_vdisksvc;
extern CRITICAL_SECTION g_callGuard_volsvc;
extern CRITICAL_SECTION g_callGuard_zapisvc;

#ifdef  __cplusplus
extern "C" {
#endif


/*******************************************************************
 * Snap Interface
 */

/*
 * This routine will return a list of snapshots for the specified
 * volume
 */
NTAPADMIN_API NTSTATUS NtapNetGetSnapInfo(WCHAR* serverName, 
				     WCHAR* volName,
				     SNAPLIST_BUFFER* snapList,
				     ULARGE_INTEGER* blks_used,
				     ULARGE_INTEGER* blks_total,
				     ULARGE_INTEGER* blks_reserved);

/*
 * This will create a new snapshot on the specified volume
 */
NTAPADMIN_API NTSTATUS NtapNetCreateSnapshot(WCHAR* serverName, 
				     WCHAR* volName,
				     WCHAR* snapName);
/*
 * This will delete a new snapshot from the specified volume
 */
NTAPADMIN_API NTSTATUS NtapNetDeleteSnapshot(WCHAR* serverName, 
				     WCHAR* volName,
				     WCHAR* snapName);
/*
 * This will rename a new snapshot from the specified volume
 */
NTAPADMIN_API NTSTATUS NtapNetRenameSnapshot(WCHAR* serverName, 
				     WCHAR* volName,
				     WCHAR* oldSnapName,
				     WCHAR* newSnapName);
/*
 * This will get the snapshot schedule for the specified volume
 */
NTAPADMIN_API NTSTATUS NtapNetGetSnapSchedule(WCHAR* serverName, 
				     WCHAR* volName,
				     Snapsvc_schedule* sched);
/*
 * This will set the snapshot schedule for the specified volume
 */
NTAPADMIN_API NTSTATUS NtapNetSetSnapSchedule(WCHAR* serverName, 
				     WCHAR* volName,
				     Snapsvc_schedule* sched);
/*
 * This will set the snapshot reserve for the specified volume
 */
NTAPADMIN_API NTSTATUS NtapNetSetSnapReserve(WCHAR* serverName, 
				     WCHAR* volName,
				     ULONG reservePercent);
/*
 * This will get the snapshot reserve for the specified volume
 */
NTAPADMIN_API NTSTATUS NtapNetGetSnapReserve(WCHAR* serverName, 
				     WCHAR* volName,
				     ULONG *reservePercent,
				     ULARGE_INTEGER* reserveBytes);
/*
 * This will reallocate the blocks within the specified file
 * Used for Defrag.
 */
NTAPADMIN_API NTSTATUS NtapNetFileReallocate(WCHAR* serverName, 
				     WCHAR* filePath);

/*
 * This will allows us to evaluate the degree of fragmentation 
 * of a file.
 */
NTAPADMIN_API NTSTATUS NtapNetFileMeasureLayout(WCHAR* serverName, 
				     WCHAR* filePath);

/*
 * Single File Restore.
 */
NTAPADMIN_API NTSTATUS NtapNetFileRestore(WCHAR* serverName, 
				     WCHAR* ucSnapName,
				     WCHAR* ucFilePath,
				     WCHAR* ucRestoreAsPath);

/*
 * EMS -> syslog, SNMP, AutoSupport.
 */
NTAPADMIN_API NTSTATUS NtapNetEMSAsup(WCHAR* serverName,
				     ULONG  eventID,
				     WCHAR* eventSource,
				     WCHAR* appVersion,
				     WCHAR* category,
				     WCHAR* errorDescription,
				     APP_ASUP_LOG_LEVEL  logLevel,
				     UCHAR  asup);

/********************************************************************
 * Volume Interface
 */

/* NetGetVolList
 *
 * Return basic information on each volume including
 * the number of disk, raid groups, and state
 */

NTAPADMIN_API NTSTATUS NtapNetGetVolList(
	/*in*/	WCHAR* serverName,
	/*out*/	VOLLIST_BUFFER* Buffer,
	/*out*/	ULONG* totalNumDisks);


/* 
 * NetapNetGetVolUsage 
 *
 * Return information required for a df command.  This
 * includes
*/
NTAPADMIN_API NTSTATUS NtapNetGetVolUsage(
	/*in*/WCHAR* serverName,
	/*in*/WCHAR *volumeName,
	/*
	 * This is the information about the current snapshot
	 */ 
	/*out*/OLD_LARGE_INTEGER	*totalBlocks,
	/*out*/OLD_LARGE_INTEGER	*totalAvail,

	/*out*/UCHAR			*hasSnapshot,  /* Does this vol have
							* a snapshot?
							*/
	/* out */ OLD_LARGE_INTEGER	*totalSnapBlocks,
	/*out*/ OLD_LARGE_INTEGER	*totalSnapAvail

);

/*
 * NtapNetSnapRestore
 *
 * This will revert a series of volumes to former snapshots.
 * All of the former snapshots must exist.  This command will
 * revert all or revert none.
 * Note that this command requires that the filer be licensed
 * for SnapRestore.  This will fail with STATUS_LICENSE_VIOLATION
 * if this is not so.
 *
 * Note that this operation does causes the system to reboot.
 * The reboot will occur a specified number of seconds following
 * completion of the RPC
 */
NTAPADMIN_API NTSTATUS NtapNetSnapRestore(
 	/*in*/	WCHAR* serverName,
 	/*in*/	WCHAR* volumeName,
 	/*in*/	WCHAR* snapName
);
/*
 * NtapNetFileCopy
 *
 * This will copy a portion of a file from the source to the destination.
 * The user will have to have exclusive access and proper
 * security rights to both files plus to the referenced
 * shares. 
 *
 * Src and destination are UNC paths. They must be legal
 * UNC paths on the filer.  Share Level ACLs are enforced. 
 *
 * Offset and Length are the portion of the file to copy.  If offset is
 * 0 the file is truncated before the first write.  Max Length is 
 * MAX_NETFILECOPY_LENGTH. 
 *
 * NetFileCopyCookie is used as a integrity  check between file copies. 
 * Offset == 0, the *NetFileCopyCookie must be NULL. A cookie will be
 * allocated and returned. Each following call needs to 
 * return the original cookie. It can be released with FreeNetCopyCookie once the 
 * copy is complete
 * 
 * Note that the caller of this interface must be root to 
 * copy files without ACLs.  The user must be a member of the local
 * Administrators or Backup Operators groups.
 *
 * This function returns the following status messages 
 *
 * STATUS_OBJECT_PATH_INVALID syntax error in path
 * STATUS_BAD_NETWORK_PATH    server/share name not valid
 * STATUS_ACCESS_VIOLATION    user does not have sufficient rights
 * STATUS_UNEXPECTED_IO_ERROR I/O error during copy
 * STATUS_NO_SECURITY_ON_OBJECT Failure in setting the security info
 * STATUS_FILE_INVALID		src/dest File changed during the copy
 * STATUS_INSUFFICIENT_RESOURCES could not complete due to resources
 *
 * Other errors are identical to those opening a file.
 * 
 */
NTAPADMIN_API NTSTATUS NtapNetFileCopy(
 	/*in*/	 WCHAR* serverName,
	/*in*/	 WCHAR* DestUNCPath,
	/*in*/	 WCHAR* SrcUNCPath,
	/*in*/   ULARGE_INTEGER Offset,
	/*in*/	 ULONG Length,
	/*in,out*/ void** NetFileCopyCookie
);

NTAPADMIN_API void FreeNetCopyCookie(void** netFileCopyCookie);

/*
 *  Raid List
 *
 * This RPC returns the information required to reconstruct the
 * sysconfig -r and sysconfig -d commands.  level will control
 * which information is returned.  
 *
 *	DISK_LIST_INFO_VOL	will return info on the disks in a vol
 *	DISK_LIST_INFO_SPARE	will return info on the spare disks
 *	DISK_LIST_INFO_PARTNER	will return info on partner disks.
 *
 *	rdList will return the volumes controlled by this unit
 *  partnerList will return the volumes controlled by partner
 */
NTAPADMIN_API NTSTATUS NtapNetGetDiskListByVol(
	/*in*/	WCHAR* serverName,
	/*in*/ ULONG /*DISK_LIST_INFO_LEVEL*/	level,
	/*in*/ WCHAR *volumeName,
	/*out*/ DISK_LIST_INFORMATION* info
);


/*
 * Add Disks
 *
 * Add disks to the specified volume.  The CLI allows quite
 * a bit of flexibility in selecting disks.  This API assumes that
 * whatever GUI is driving this will have sorted out which disks
 * to add and all that needs to be done is to physically add them
 */
NTAPADMIN_API NTSTATUS NtapNetAddDisksToVol(
	/*in*/	WCHAR* serverName,
	/*in*/	WCHAR *volumeName,
	/*in*/	VOLSVC_ADDED_DISKLIST* dskList
);

/*
 * 5 VolInfoForShare
 *
 * This function will return the some share specific info.
 *		a. language being used on the volume hosting the share.  
 *		   The language code is returned as VOLSVC_FILER_LANG
 *		b. Qtree type for the share
 *		c. Whether oplocks are enabled.
 */
NTAPADMIN_API NTSTATUS NtapNetVolInfoForShare(
	/*in*/	WCHAR* serverName,
	/*in*/  WCHAR *shareName,
	/*out*/ VOLSVC_FILER_LANG* retLang,
	/*out*/ VOLSVC_QTREE_TYPE* retqtree,
	/*out*/ ULONG* retoplocksEnabled
);

/*
 * Check to see if the volume in question is a root volume.
 */
NTAPADMIN_API NTSTATUS NtapNetIsRootVolume(
	/*in*/	WCHAR* serverName,
	/*in*/	WCHAR *volumeName
);

/*
 * Query/Enable/Disable Volume Space Reservation.
 */
NTAPADMIN_API NTSTATUS NtapNetSpaceReservation(
	/* in */	WCHAR *serverName,
	/* in */	WCHAR *volumeName,
	/* in, out */	ULONG *value
);

/*
 * This function will either make an entry or delete 
 * an entry in the metafile.
 */
NTAPADMIN_API NTSTATUS NtapNetCreateDeleteVLDMetadir(
	/* in */	WCHAR *serverName,
	/* in */	WCHAR *vldFilePath,
	/* in */	UCHAR create	/* Is this a create or 
				 	 * a delete operation?
				 	 */
);

/********************************************************************
 * CIFS Admin Interface
 */

NTAPADMIN_API NTSTATUS NetGetFilerVersion(
	/* in */  WCHAR* serverName,
	/* out */ WCHAR**	verStr,
	/* out */ ULONG*	Count,
	/* out */ ULONG**	Capabilities 
		/* codes of additional capabilities
		 * see ADMIN_RPC_CAPABILITIES
		 */
	);

/*
 * This is basically an RPC version of wcc.  
 * Input is the unix User Name (or NT user name).
 * Output is the unix and NT user IDs 
 *
 * Note:
 *	this represents the real time identity. It may
 *	not reflect the actual identity of a currently loged in
 *	user.
 */

NTAPADMIN_API NTSTATUS 
NetMapUNIXUser(
   /* in */  WCHAR*		serverName,
   /* in */  WCHAR*		unixUserName,
   /* in */  ULONG		ipaddr,
   /* out */ CA_USER_IDENTITY*	identity);

NTAPADMIN_API NTSTATUS 
NetMapNTUser(
  /* in */  WCHAR*		serverName,
  /* in */  WCHAR*		ntUserName,
  /* in */  ULONG		ipaddr,
  /*out */  CA_USER_IDENTITY*	idList);

/*
 * This is basically an RPC version of cifs sessions -s  
 * Input is the NT User Name and client PC name.
 * Output is the unix and NT user IDs 
 *
 * Note:
 *	this represents the actual identities of a currently loged in
 *	user. It may not reflect what a new logon would receive.
 */
NTAPADMIN_API NTSTATUS 
NetGetUserMappings(
  /* in */  WCHAR*		serverName,
  /* in */  WCHAR*		ntUserName,
  /* in */  WCHAR*		WSName,
  /*out */  CA_USER_IDENTITY_ARRAY* idList);

/*
 * This is a temporary interface use to get well known registry keys.
 * It will be replaced by a more general interface in a later version
 * of ontap.  For the moment it will support gets of the keys required
 * to make security decisions
 */
NTAPADMIN_API NTSTATUS 
NetOnTapRegistryGet(
	/* in */  WCHAR*	serverName,
	/*[in, string, unique]*/   WCHAR*	registryKey,
	/*[out]*/ WCHAR**	retValue);

/* 
 * This routine could be used to check the license for various
 * products for OnTap Release.
 * Returns STATUS_SUCCESS if license is enabled.
 * This API cannot detect if a particular license is not
 * appropriate.
 */
NTAPADMIN_API NTSTATUS NetOnTapProdLicense(
	/*in*/	WCHAR* serverName,
	/*in*/	ONTAP_PROD_LICENSE license);

/*
 *	Get the UID that corresponds to a user name.
 *	Name is in UNICODE and will be translated to filer NFS
 *	character set before the lookup
 */
NTAPADMIN_API NTSTATUS
NetGetUserNamefromUnixUID (
	/* in */	WCHAR*	serverName,
	/* in */	LONG	uid,
	/* out */	WCHAR**	userName);
/*
 *	Get the name that corresponds to a UID.
 *	Name is in UNICODE and will be translated to filer NFS
 *	character set after the lookup
 */
NTAPADMIN_API NTSTATUS
NetGetUnixUIDfromUserName (
	/* in */	WCHAR*	serverName,
	/*in*/		WCHAR*	userName,
	/*out*/		LONG*	uid);
/*
 *	Get the GID that corresponds to a group name.
 *	Name is in UNICODE and will be translated to filer NFS
 *	character set before the lookup
 */
NTAPADMIN_API NTSTATUS
NetGetGroupNamefromUnixGID (
	/* in */	WCHAR*	serverName,
	/* in */	LONG	gid,
	/* out */	WCHAR**	groupName);
/*
 *	Get the name that corresponds to a UID.
 *	Name is in UNICODE and will be translated to filer NFS
 *	character set after the lookup
 */
NTAPADMIN_API NTSTATUS
NetGetUnixGIDfromGroupName (
	/* in */	WCHAR*	serverName,
	/*in*/		WCHAR*	groupName,
	/*out*/		LONG*	gid);
/*
 *  This interface will examine the search order used by the 
 *	name service and return information on how the filer is
 *	configured.
 *
 *	localFilesUsed	return non-zero if local filer files
 *			are being search for BOTH passwd and group.
 *			If either is not using local files, then 
 *			the routine will return 0.
 *
 *	nisUsed		return non-zero if EITHER passwd or group
 *			is searched via NIS.
 */
NTAPADMIN_API NTSTATUS
NetNssUsingLocalFiles(
	/* in */	WCHAR*	serverName,
	/* out*/	ULONG*  localFilesUsed,
	/* out*/	ULONG*  nisUsed);

/********************************************************************
 * Quota Interface
 */
/*
 * This turns quotas on on a volume.  It starts the process, but
 * does not wait to see if the scan of the quotas file is successful.	
 * Client should poll the volume, with NtapNetQuotaStatus to ensure
 * quotas were successfully started or to obtain the last error message
 * indicating why the quota on failed.
 */
NTAPADMIN_API NTSTATUS 
NtapNetQuotaOn(
	    /* in */ WCHAR * serverName,
	    /* in */ WCHAR * volumeName);

/*
 * Turn quotas off for a volume.  If a quota resize is in progress,
 * the "off" is delayed.  Use NtapNetQuotaStatus to poll for the
 * volume's quota system status.
 */
NTAPADMIN_API NTSTATUS 
NtapNetQuotaOff(
	    /* in */ WCHAR * serverName,
	    /* in */ WCHAR * volumeName);


/*
 * Issue a resize to change quota limits.  The resize is started
 * by this RPC, but it does not wait for the completion of the
 * re-scan of the /etc/quotas file.  Use NtapNetQuotaStatus to
 * obtain the last error message.
 */
NTAPADMIN_API NTSTATUS 
NtapNetQuotaResize(
	    /* in */ WCHAR * serverName,
	    /* in */ WCHAR * volumeName);

/*
 * Obtain the status of quotas on a volume.  The "qstate" field
 * indicates if quotas are on, off, resizing or initializing.
 * If resizing or initializing, the "qsubstate" field indicates what
 * stage of the resize or initialization and "completionPercent"
 * indicates how much of the "qsubstate" has completed (when the
 * substate is reading the /etc/quotas file or scanning the volume).
 *
 * The error message contains the text of the last error message of
 * a failed initialization or resize.
 * If there is an error message, its memory should be released by the 
 * caller, using HeapFree(GetProcessHead(), 0, errmessage)
 */
NTAPADMIN_API NTSTATUS 
NtapNetQuotaStatus(
	    /* in */ WCHAR * serverName,
	    /* in */ WCHAR * volumeName,
	    /* out */ QUOTASVC_QUOTA_STATE *qstate,
	    /* out */ QUOTASVC_QUOTA_SUB_STATE *qsubstate,
	    /* out */ ULONG * completionPercent,
	    /* out */ WCHAR ** errmessage);
/*
 * Obtain information about a user's quota, by providing the user's SID.
 * If the qtreeName is provided, obtain the user's quota for that qtree.
 * If the qtreeName is not provided, obtain the user's quota for the volume.
 * If no quota info for the SID , "source" will indicate that.
 * If there is quota info for the user, "source" will indicate if the
 * quota was explicitly stated in the quotas file or derived from
 * a default.  (Except during a resize, when all are temporarily marked
 * as derived.)
 * If a limit is "unlimited, the value 0xffffffffffffffff is returned.
 */
NTAPADMIN_API NTSTATUS
NtapNetQuotaReport(
	    /* in */ WCHAR* serverName, 
	    /* in */ WCHAR* volName,
	    /* in */ SID *  userSid,
	    /* in */ WCHAR* qtreeName,
	    /* out */ ULARGE_INTEGER *spacethreshold,
	    /* out */ ULARGE_INTEGER *spacelimit,
	    /* out */ ULARGE_INTEGER *spaceusage,
	    /* out */ ULARGE_INTEGER *fileslimit,
	    /* out */ ULARGE_INTEGER *fileusage,
	    /* out */ QUOTASVC_QUOTA_SOURCE *source);

/*
 * List all qtrees on a volume, as well as info about
 * their security style and oplock enable/disable setting.
 *
 * Caller must free the QUOTALIST_BUFFER and the qtreeName in
 * each entry of that buffer using HeapFree(GetProcessHeap(), 0, <addr>)
 */
NTAPADMIN_API NTSTATUS
NtapNetQuotaQtrees(
	    /* in */ WCHAR* serverName, 
	    /* in */ WCHAR* volName,
	    /* out */ QUOTALIST_BUFFER* Buffer);

/*
 * For a given volume and qtree, obtain any default settings for
 * users, groups and qtrees.
 * If qtreeName is null, obtain the information for the volume's 
 * defaults.
 * If a limit is unlimited, a 0xffffffffffffffff is returned.
 * If there is no default, the quota type's flag will indicate that.
 */
NTAPADMIN_API NTSTATUS 
NtapNetQuotaDefaults(
	    /* in */ WCHAR* serverName, 
	    /* in */ WCHAR* volName,
	    /* in */ WCHAR* qtreeName,
	    /* out */ QUOTASVC_QUOTA_DEFAULTS *qdinfo);

/*
 * Obtain information about a user's, group's or qtree's  quota,
 * by providing the name of the unix user, group or qtree.
 * The qtype parameter indicates which type is quota is requested.
 * If a user or group name is given, an optional qtreename may also be
 * provided.
 * If the qtreeName is provided, obtain the user/group's quota for that qtree.
 * If the qtreeName is not provided, obtain the user/group's quota for
 * the volume.
 * The user or group name must match the unix name by case (a case sensitive
 * lookup is done).
 * A tree name, and the qtreename parameter, is done with a case insensitive
 * lookup.
 * If no quota info for the name, "source" will indicate that.
 * If there is quota info for the user, "source" will indicate if the
 * quota was explicitly stated in the quotas file or derived from
 * a default.  (Except during a resize, when all are temporarily marked
 * as derived.)
 * If a limit is "unlimited, the value 0xffffffffffffffff is returned.
 */
NTAPADMIN_API NTSTATUS
NtapNetQuotaReportByName(
	    /* in */ WCHAR* serverName, 
	    /* in */ WCHAR* volName,
	    /* in */ WCHAR *name,
	    /* in */ QUOTASVC_QUOTA_TYPE qtype,
	    /* in */ WCHAR* qtreeName,
	    /* out */ ULARGE_INTEGER *spacethreshold,
	    /* out */ ULARGE_INTEGER *spacelimit,
	    /* out */ ULARGE_INTEGER *spaceusage,
	    /* out */ ULARGE_INTEGER *fileslimit,
	    /* out */ ULARGE_INTEGER *fileusage,
	    /* out */ QUOTASVC_QUOTA_SOURCE *source);

/*
 * Obtain information about a user's quota, by providing the user's SID.
 * If the qtreeName is provided, obtain the user's quota for that qtree.
 * If the qtreeName is not provided, obtain the user's quota for the volume.
 * If no quota info for the SID , "source" will indicate that.
 * If there is quota info for the user, "source" will indicate if the
 * quota was explicitly stated in the quotas file or derived from
 * a default.  (Except during a resize, when all are temporarily marked
 * as derived.)
 * If a limit is "unlimited, the value 0xffffffffffffffff is returned.
 * This include soft file limits and soft space limits.
 */
NTAPADMIN_API NTSTATUS
NtapNetQuotaReport2(
	    /* in */ WCHAR* serverName, 
	    /* in */ WCHAR* volName,
	    /* in */ SID *  userSid,
	    /* in */ WCHAR* qtreeName,
	    /* out */ ULARGE_INTEGER *spacethreshold,
	    /* out */ ULARGE_INTEGER *spacelimit,
		/* out */ ULARGE_INTEGER *spacelimitsoft,
	    /* out */ ULARGE_INTEGER *spaceusage,
	    /* out */ ULARGE_INTEGER *fileslimit,
	    /* out */ ULARGE_INTEGER *fileslimitsoft,
	    /* out */ ULARGE_INTEGER *fileusage,
	    /* out */ QUOTASVC_QUOTA_SOURCE *source);

/*
 * For a given volume and qtree, obtain any default settings for
 * users, groups and qtrees.
 * If qtreeName is null, obtain the information for the volume's 
 * defaults.
 * If a limit is unlimited, a 0xffffffffffffffff is returned.
 * If there is no default, the quota type's flag will indicate that.
 * This include soft file limits and soft space limits.
 */
NTAPADMIN_API NTSTATUS 
NtapNetQuotaDefaults2(
	    /* in */ WCHAR* serverName, 
	    /* in */ WCHAR* volName,
	    /* in */ WCHAR* qtreeName,
	    /* out */ QUOTASVC_QUOTA_DEFAULTS2 *qdinfo);

/*
 * Obtain information about a user's, group's or qtree's  quota,
 * by providing the name of the unix user, group or qtree.
 * The qtype parameter indicates which type is quota is requested.
 * If a user or group name is given, an optional qtreename may also be
 * provided.
 * If the qtreeName is provided, obtain the user/group's quota for that qtree.
 * If the qtreeName is not provided, obtain the user/group's quota for
 * the volume.
 * The user or group name must match the unix name by case (a case sensitive
 * lookup is done).
 * A tree name, and the qtreename parameter, is done with a case insensitive
 * lookup.
 * If no quota info for the name, "source" will indicate that.
 * If there is quota info for the user, "source" will indicate if the
 * quota was explicitly stated in the quotas file or derived from
 * a default.  (Except during a resize, when all are temporarily marked
 * as derived.)
 * If a limit is "unlimited, the value 0xffffffffffffffff is returned.
 * This include soft file limits and soft space limits.
 */
NTAPADMIN_API NTSTATUS
NtapNetQuotaReportByName2(
	    /* in */ WCHAR* serverName, 
	    /* in */ WCHAR* volName,
	    /* in */ WCHAR *name,
	    /* in */ QUOTASVC_QUOTA_TYPE qtype,
	    /* in */ WCHAR* qtreeName,
	    /* out */ ULARGE_INTEGER *spacethreshold,
	    /* out */ ULARGE_INTEGER *spacelimit,
	    /* out */ ULARGE_INTEGER *spacelimitsoft,
	    /* out */ ULARGE_INTEGER *spaceusage,
	    /* out */ ULARGE_INTEGER *fileslimit,
	    /* out */ ULARGE_INTEGER *fileslimitsoft,
	    /* out */ ULARGE_INTEGER *fileusage,
	    /* out */ QUOTASVC_QUOTA_SOURCE *source);

/*******************************************************************
 * Vdisk Interface
 */

/* RPC's to create and manage LUNs */
NTAPADMIN_API NTSTATUS NtapNetLUNCreate(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *lunpath,
	/* in */ OLD_LARGE_INTEGER *size);

NTAPADMIN_API NTSTATUS NtapNetLUNMap(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *lunpath,
	/* in */ WCHAR *initname,
	/* in */ ULONG *lun);

NTAPADMIN_API NTSTATUS NtapNetLUNUnmap(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *lunpath,
	/* in */ WCHAR *initname);

NTAPADMIN_API NTSTATUS NtapNetLUNMapStatus(
	/* in  */ WCHAR *serverName,
	/* in  */ WCHAR *lunpath,
	/* out */ ULONG *exportstatus);

NTAPADMIN_API NTSTATUS NtapNetLUNOnline(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *lunpath);

NTAPADMIN_API NTSTATUS NtapNetLUNOffline(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *lunpath);

NTAPADMIN_API NTSTATUS NtapNetLUNOnlineStatus(
	/* in  */ WCHAR *serverName,
	/* in  */ WCHAR *lunpath,
	/* out */ ULONG *onlinetstaus);

NTAPADMIN_API NTSTATUS NtapNetLUNSize(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *lunpath,
	/* out*/ OLD_LARGE_INTEGER *size);

NTAPADMIN_API NTSTATUS NtapNetLUNResize(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *lunpath,
	/* in */ OLD_LARGE_INTEGER *size,
	/* in */ ULONG *fflag);

NTAPADMIN_API NTSTATUS NtapNetLUNMove(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *lunpath,
	/* in */ WCHAR *newpath);

NTAPADMIN_API NTSTATUS NtapNetLUNFind(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *serialnumber,
	/* out*/ VDISK_LIST *vlist);

NTAPADMIN_API NTSTATUS NtapNetLUNDestroy(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *lunpath);

NTAPADMIN_API NTSTATUS NtapNetVLDtoLUN(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *vldpath,
	/* in */ WCHAR *lunpath);

NTAPADMIN_API NTSTATUS NtapNetLUNtoVLD(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *lunpath,
	/* out*/ VDISK_LIST *vlist);

NTAPADMIN_API NTSTATUS NtapNetPrepareSnapshotLUN(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *snappath,
	/* in */ WCHAR *lunpath);

NTAPADMIN_API NTSTATUS NtapNetSwitchSnapshotLUN(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *lunpath,
	/* in */ WCHAR *snappath);

NTAPADMIN_API NTSTATUS NtapNetLUNRawWrite(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *path,
	/* in */ OLD_LARGE_INTEGER *offset,
	/* in */ LONG *length,
	/* in */ BYTE *data);

NTAPADMIN_API NTSTATUS NtapNetLUNList(
	/* in  */ WCHAR *serverName,
	/* out */ VDISK_LIST *vlist);

NTAPADMIN_API NTSTATUS NtapNetLUNSFSRStatus(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *lunpath, 
	/* out*/ LONG  *status);

NTAPADMIN_API NTSTATUS NtapNetLUNFileAccess(
	/* in */ WCHAR* serverName,
	/* in */ WCHAR * lunpath,
	/* in */ LONG * accesstype);

NTAPADMIN_API NTSTATUS NtapNetLUNGetAttribute(
	/* in */ WCHAR * serverName,
	/* in */ WCHAR * vdiskpath,
	/* in */ WCHAR * attrKey,
	/* out*/ VDISK_LIST * attrVal);

NTAPADMIN_API NTSTATUS NtapNetLUNSetAttribute(
	/* in */ WCHAR * serverName,
	/* in */ WCHAR * vdiskpath,
	/* in */ WCHAR * attrKey,
	/* in */ WCHAR * attrVal);
	
NTAPADMIN_API NTSTATUS NtapNetLUNHasReservations(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *vdiskPath, 
	/* out*/ LONG *result);
	
NTAPADMIN_API NTSTATUS NtapNetLUNMaxSize(
	/* in */ WCHAR * serverName,
	/* in */ WCHAR * path,
	/* in */ LONG * snapshotflag,
	/* out*/ OLD_LARGE_INTEGER * size);

NTAPADMIN_API NTSTATUS NtapNetLUNPortHasReservation(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *vdiskPath, 
	/* in */ WCHAR *portname, 
	/* out*/ LONG *result);
	
NTAPADMIN_API NTSTATUS NtapNetLUNReservationHolder(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *vdiskPath, 
	/* out*/ WCHAR **portname);
	
NTAPADMIN_API NTSTATUS NtapNetLUNFileType(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *filePath, 
	/* out*/ LONG* status);

NTAPADMIN_API NTSTATUS NtapNetLUNSnapshotPath(
       /* in */ WCHAR *serverName,
       /* in */ WCHAR *vdiskPath, 
       /* out*/ VDISK_LIST *vlist);
		
NTAPADMIN_API NTSTATUS NtapNetLUNInitiatorLoggedIn(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *initiator, 
	/* out*/ LONG *result);
	
NTAPADMIN_API NTSTATUS NtapNetLUNRawRead(
	/* in */ WCHAR * serverName,
	/* in */ WCHAR * path,
	/* in */ OLD_LARGE_INTEGER * offset,
	/* in */ LONG *length,
	/* out*/ VDISK_DATA *data);

NTAPADMIN_API NTSTATUS NtapNetLUNReverseMap(
	/* in */ WCHAR * serverName,
	/* in */ WCHAR * initname,
	/* in */ ULONG * lun,
	/* out*/ VDISK_LIST * vlist);
		
/*******************************************************************
 * Zapi Interface
 */

NTAPADMIN_API NTSTATUS ZapiGetFilerVersion(
        /* in */  WCHAR* serverName,
        /* out */ WCHAR**       verStr
        );

NTAPADMIN_API NTSTATUS ZapiInvoke(
        /* in */        WCHAR* serverName,
        /* in */        WCHAR*  xmlin,
        /* out */       WCHAR** xmlout
        );

NTAPADMIN_API NTSTATUS ZapiInvokeUtf8(
	/*in*/	const char* server,
	/*in*/	const char* in,
	/*out*/ char**	out
	);
	
/*******************************************************************
 * Snapmirror Interface
 */

/*
 * 0 NtapNetQueryVolumeSnapMirror
 */
NTAPADMIN_API
NTSTATUS
NtapNetQueryVolumeSnapMirror (
	/* in */ WCHAR* serverName,
	/* in */ WCHAR* volumeName,
	/* in */ QUERY_SNAPMIRROR queryFlag,
	/* out */ UCHAR *query);

/*
 * 1 NtapNetFunctionVolumeSnapMirror
 */
NTAPADMIN_API
NTSTATUS
NtapNetFunctionVolumeSnapMirror (
	/* in */ WCHAR* serverName,
	/* in */ WCHAR* volumeName,
	/* in */ FUNCTION_SNAPMIRROR functionFlag);

/*
 * 2 NtapNetGetSnapMirrorDestinations
 */
NTAPADMIN_API
NTSTATUS
NtapNetGetSnapMirrorDestinations(
	/* in */ WCHAR* serverName,
	/* in */ WCHAR* volumeName,
	/* out */ SNAPMIRROR_DESTINATIONS *destinations);

/*
 * 3 NtapNetGetSnapMirrorSchedule
 */
NTAPADMIN_API
NTSTATUS
NtapNetGetSnapMirrorSchedule(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *destinationFilerName,
	/* in */ WCHAR *destinationVolumeName,
	/* out */ WCHAR **sourceFilerName,
	/* out */ WCHAR **sourceVolumeName,
	/* out */ WCHAR **minutes,
	/* out */ WCHAR **hours,
	/* out */ WCHAR **daysOfMonth,
	/* out */ WCHAR **daysOfWeek);

/*
 * 4 NtapNetSetSnapMirrorSchedule
 */
NTAPADMIN_API
NTSTATUS
NtapNetSetSnapMirrorSchedule(
	/* in */ WCHAR *serverName,
	/* in */ WCHAR *destinationFilerName,
	/* in */ WCHAR *destinationVolumeName,
	/* in */ WCHAR *sourceFilerName,
	/* in */ WCHAR *sourceVolumeName,
	/* in */ WCHAR *minutes,
	/* in */ WCHAR *hours,
	/* in */ WCHAR *daysOfMonth,
	/* in */ WCHAR *daysOfWeek);


#ifdef  __cplusplus
}
#endif

