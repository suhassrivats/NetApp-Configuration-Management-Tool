/*
 * $Id: //depot/prod/DOT/fsb/ontap/files/ntapadmin/cifsadminintf.h#1 $
 *
 * Network Appliance Snapshot Service IDL File
 *
 * This module defines the data structures returned by the
 * CIFS Managment RPCs
 *
 *
 * (c)1999 Network Appliance, Inc. All Rights Reserved.
 */

#ifndef _CIFSADMININTF_
#define _CIFSADMININTF_
#include <adminintf.h>

typedef struct _CA_UNICODE_STRING {
    USHORT Length;
    USHORT MaximumLength;

#ifdef IDL_PASS
	[string]
#endif
    WCHAR  *Buffer;

} CA_UNICODE_STRING, *PCA_UNICODE_STRING;

typedef struct{
    ISTRING WCHAR  *Buffer;
} CA_WCHAR;


typedef struct  {
    ULONG Count;
    SIZEIS(Count)  CA_UNICODE_STRING  *Element;   /* Set to NULL before call !!!*/
} CA_RETURNED_USTRING_ARRAY;

typedef struct  {
    ULONG Count;
    SIZEIS(Count) ULONG * Element;

} CA_ULONG_ARRAY;




/*******************************************************
 * Defined Capabilities
 *
 * Init a ULONG arrary and init with the following
 */

/* Basic Admin Capabilities, snapshots, vol status, cifs admin */
/*
 * NOTE: Please update /test/cifs/snaptest/snaptest.cpp whenever
 * 		a new capability is added.
 */
typedef enum {
	ADMIN_RPC_CAPABILITY_INIT,	/* Initial capabilities */
	ADMIN_RPC_CAPABILITY_QUOTA_V1,	/* Intial quota implementation */
	ADMIN_RPC_CAPABILITY_REALLOCATE,/* File Reallocate - Defrag */
	ADMIN_RPC_CAPABILITY_SNAPRESTOR,/* Vol Snap Restore->Non-Root vol only */
	ADMIN_RPC_CAPABILITY_VLD_CONFIG,/* Ability to query UNIX security
					 * lookup routines
					 */
	ADMIN_RPC_CAPABILITY_VLD_LIC_1,	/* Licenses for 2001 windev products */
	ADMIN_RPC_CAPABILITY_QUOTA_V2,  /* V1 quotas plus soft quotas */
	ADMIN_RPC_CAPABILITY_FILERESTOR,/* Single File Snap (SFS) Restore */
	ADMIN_RPC_CAPABILITY_VDISKMGMT, /* Vdisk Management */
	ADMIN_RPC_CAPABILITY_SPCRESERVE,/* Volume Space Reservation */
	ADMIN_RPC_CAPABILITY_EMS_ASUP,	/* EMS->(syslog & snmp) & Autosupport */
	ADMIN_RPC_CAPABILITY_SNAPMIRROR,/* Volume & Qtree Snapmirror */

	/* Entry must be last */
	NUM_ADMIN_RPC_CAPABILITIES 
}ADMIN_RPC_CAPABILITIES;


/*
 * Data structures required by NetMapUNIXUser and NetMapNTUser
 *
 * Note I had trouble with conflicts between the generated IDL
 * and standard NT definitions.  From the MS IDL, the MS folks
 * had the same problem.  As a result some standard MS definitions
 * are duplicated here.
 */

typedef struct _CA_UNIX_ID{
	ULONG		uid;
	CA_UNICODE_STRING	unixName;
	CA_RETURNED_USTRING_ARRAY  groupNames;
	CA_ULONG_ARRAY	gids;
}CA_UNIX_ID;

#ifdef IDL_PASS

typedef struct _CA_SID_IDENTIFIER_AUTHORITY {
    UCHAR  Value[6];
} CA_SID_IDENTIFIER_AUTHORITY;

typedef struct _CA_SID {
   UCHAR Revision;
   UCHAR SubAuthorityCount;
   CA_SID_IDENTIFIER_AUTHORITY IdentifierAuthority;
   [size_is(SubAuthorityCount)] ULONG SubAuthority[*];
} CA_SID;

#else
/*
 * use definition from win32 on WIN32.  On filer use NTSID
 */
#define CA_SID SID
#endif

typedef struct{
	RPC_UNIQUE CA_SID	*Sid;
}CA_SID_INFORMATION;



typedef struct  _CA_PSID_ARRAY{
    ULONG Count;
    SIZEIS(Count) CA_SID_INFORMATION *Sids;
} CA_PSID_ARRAY;


/*
 * This is the structure used to represent the UNIX and
 * NT identities of a single user on the system.  Depending
 * on the interface the identity is either live (ie. represented
 * by real connections) or real time (what the user would have if
 * he logged into the system at this instant.
 */
typedef struct _CA_USER_IDENTITY{
	CA_UNIX_ID	uID;
	CA_PSID_ARRAY	ntID;
}CA_USER_IDENTITY;

typedef struct  _CA_USER_IDENTITY_ARRAY{
    ULONG Count;
    SIZEIS(Count) CA_USER_IDENTITY *ids;
} CA_USER_IDENTITY_ARRAY;


/*
 * Enum defines for License check on various OnTap product
 * release. This information has been borrowed from 
 * /prod/common/cmds/enable.h
 *
 * NOTE: These definitions are used in windows applications.
 *       If the definition is included in a shipping release
 *	 of the product, then it should be considered frozen.
 *
 *	If you change these definitions then the version of
 *	ntapadmin.dll must be changed.
 */

typedef enum {
	NTAP_LICENSE_NFS,		/* 4 */
	NTAP_LICENSE_CIFS,		/* 5 */
	NTAP_LICENSE_HTTP,		/* 6 */
	NTAP_LICENSE_NETCACHE,		/* 7 */
	NTAP_LICENSE_HA,		/* 8 */
	NTAP_LICENSE_VOLCOPY,		/* 9 */
	NTAP_LICENSE_REPLICATE,		/* 10 */
	NTAP_LICENSE_SNAPRESTORE,	/* 11 */
	NTAP_LICENSE_NNTP,		/* 12 */
	NTAP_LICENSE_MMSSTREAM,		/* 13 */
	NTAP_LICENSE_REALSTREAM,	/* 14 */
	NTAP_LICENSE_SNAPMGR,		/* 15 */
	NTAP_LICENSE_DAFS,		/* 16 */
	NTAP_LICENSE_SYNCMIRROR,	/* 17 */
	NTAP_LICENSE_VFILER,		/* 18 */
	NTAP_LICENSE_ICAP,		/* 19 */
	NTAP_LICENSE_GRM,		/* 20 */
	NTAP_LICENSE_QTSTREAM,		/* 21 */
	NTAP_LICENSE_NCAGENT,		/* 22 */
	NTAP_LICENSE_MMSSTREAM_PRO,	/* 23 */
	NTAP_LICENSE_VLD,		/* 24 */
	NTAP_LICENSE_SNAPMGRSQL,	/* 25 */
	NTAP_LICENSE_SNAPVAULT_CLIENT,	/* 26 */
	NTAP_LICENSE_SNAPVAULT_SERVER,	/* 27 */
	NTAP_LICENSE_SNAPMGR_DOMINO,	/* 28 */
	NTAP_LICENSE_PNFS,		/* 29 */
	NTAP_LICENSE_REMOTESYNCMIRROR,	/* 30 */
	NTAP_LICENSE_FCP,		/* 31 */
	NTAP_LICENSE_ISCSI,		/* 32 */
	NTAP_LICENSE_REALPRO,		/* 33 */
	NTAP_LICENSE_MMSULTRA,		/* 34 */
	NTAP_LICENSE_REALULTRA		/* 35 */
} ONTAP_PROD_LICENSE;


#endif /*_CIFSADMININTF_*/

