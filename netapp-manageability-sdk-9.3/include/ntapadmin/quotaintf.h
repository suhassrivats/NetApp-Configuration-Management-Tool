/*
 * $Id: //depot/prod/DOT/fsb/ontap/files/ntapadmin/quotaintf.h#1 $
 *
 * Network Appliance Quota Service IDL File
 *
 * This module defines the data structures returned
 * by the Quota Management RPCs).
 *
 * (c)2000 Network Appliance, Inc. All Rights Reserved.
 */

#ifndef _QUOTAINTF_
#define _QUOTAINTF_

typedef struct _Q_UNICODE_STRING {	
	USHORT Length;
	USHORT MaximumLength;

#ifdef IDL_PASS
	[ string ]
#endif
	WCHAR *Buffer;
} Q_UNICODE_STRING, *PQ_UNICODE_STRING;

#ifdef IDL_PASS

typedef struct _Q_SID_IDENTIFIER_AUTHORITY {
    UCHAR  Value[6];
} Q_SID_IDENTIFIER_AUTHORITY;

typedef struct _Q_SID {
   UCHAR Revision;
   UCHAR SubAuthorityCount;
   Q_SID_IDENTIFIER_AUTHORITY IdentifierAuthority;
   [size_is(SubAuthorityCount)] ULONG SubAuthority[*];
} Q_SID;

#else
/*
 * use definition from win32 on WIN32.  On filer use NTSID
 */
#define Q_SID SID
#endif

/*
 * This indicates the current state of quotas on the volume.
 *
 */
typedef enum {
	QUOTASVC_QUOTA_NONE,
	QUOTASVC_QUOTA_OFF,
	QUOTASVC_QUOTA_ON,
	QUOTASVC_QUOTA_INIT,
	QUOTASVC_QUOTA_RESIZE,
	QUOTASVC_QUOTA_SHUTDOWN
}QUOTASVC_QUOTA_STATE;

/*
 * This indicates which step of an initialization or resize
 * is in progress.
 */
typedef enum {
	QUOTASVC_NONE,
	QUOTASVC_IN_SETUP,
	QUOTASVC_ON_SCAN_QUEUE,
	QUOTASVC_ETC_SCAN,
	QUOTASVC_VOL_SCAN,
	QUOTASVC_INIT_DONE
} QUOTASVC_QUOTA_SUB_STATE;

/*
 * This indicates the type of user quota, derived or
 * explicit.  All quotas are temporarily marked as derived
 * during a resize, so at such times we can't tell if it 
 * really is derived.
 */
typedef enum {
	QUOTASVC_NO_USER_QUOTA,
	QUOTASVC_EXPLICIT_QUOTA,
	QUOTASVC_DERIVED_QUOTA,
	QUOTASVC_DERIVED_RESIZING
} QUOTASVC_QUOTA_SOURCE;

/*
 * This structure returns information about a user's quota. 
 * The space values are in units of 1Kb (1024 bytes).
 */
typedef struct _Quotasvc_quota_info {
	OLD_ULARGE_INTEGER	spaceThreshold;
	OLD_ULARGE_INTEGER      spaceLimit;
	OLD_ULARGE_INTEGER	spaceUsed;
	OLD_ULARGE_INTEGER	fileLimit;
	OLD_ULARGE_INTEGER	filesUsed;
	QUOTASVC_QUOTA_SOURCE   source;

} QUOTASVC_QUOTA_INFO;

/*
 * Same as QUOTASVC_QUOTA_INFO with the addition of Soft file limits
 * and Soft space limits.
 */
typedef struct _Quotasvc_quota_info2 {
	OLD_ULARGE_INTEGER	spaceThreshold;
	OLD_ULARGE_INTEGER      spaceLimit;
	OLD_ULARGE_INTEGER      spaceLimitSoft;
	OLD_ULARGE_INTEGER	spaceUsed;
	OLD_ULARGE_INTEGER	fileLimit;
	OLD_ULARGE_INTEGER      fileLimitSoft;
	OLD_ULARGE_INTEGER	filesUsed;
	QUOTASVC_QUOTA_SOURCE   source;

} QUOTASVC_QUOTA_INFO2;


typedef enum {
	QUOTASVC_NO_DEFAULT_QUOTA,
	QUOTASVC_DEFAULT_EXISTS
} QUOTASVC_DEFAULT_FLAG;

/*
 * This structure returns information about a default quota for
 * a volume or qtree.  Space limit and threshold is in units of
 * 1Kb (1024 bytes).
 */
typedef struct _Quotasvc_quota_defaults {
	QUOTASVC_DEFAULT_FLAG u_flag; 
	OLD_ULARGE_INTEGER  u_spaceThreshold;  /* user default */
	OLD_ULARGE_INTEGER  u_spaceLimit;
	OLD_ULARGE_INTEGER  u_fileLimit;
	QUOTASVC_DEFAULT_FLAG g_flag;
	OLD_ULARGE_INTEGER  g_spaceThreshold; /* group default */
	OLD_ULARGE_INTEGER  g_spaceLimit;
	OLD_ULARGE_INTEGER  g_fileLimit;
	QUOTASVC_DEFAULT_FLAG t_flag;
	OLD_ULARGE_INTEGER  t_spaceThreshold; /* tree default */
	OLD_ULARGE_INTEGER  t_spaceLimit;
	OLD_ULARGE_INTEGER  t_fileLimit;


} QUOTASVC_QUOTA_DEFAULTS;


/*
 * Same as QUOTASVC_QUOTA_DEFAULTS with the addition of
 * soft file limits and soft space limits.
 */
typedef struct _Quotasvc_quota_defaults2 {
	QUOTASVC_DEFAULT_FLAG u_flag; 
	OLD_ULARGE_INTEGER  u_spaceThreshold;  /* user default */
	OLD_ULARGE_INTEGER  u_spaceLimit;
	OLD_ULARGE_INTEGER  u_spaceLimitSoft;
	OLD_ULARGE_INTEGER  u_fileLimit;
	OLD_ULARGE_INTEGER  u_fileLimitSoft;
	QUOTASVC_DEFAULT_FLAG g_flag;
	OLD_ULARGE_INTEGER  g_spaceThreshold; /* group default */
	OLD_ULARGE_INTEGER  g_spaceLimit;
	OLD_ULARGE_INTEGER  g_spaceLimitSoft;
	OLD_ULARGE_INTEGER  g_fileLimit;
	OLD_ULARGE_INTEGER  g_fileLimitSoft;
	QUOTASVC_DEFAULT_FLAG t_flag;
	OLD_ULARGE_INTEGER  t_spaceThreshold; /* tree default */
	OLD_ULARGE_INTEGER  t_spaceLimit;
	OLD_ULARGE_INTEGER  t_spaceLimitSoft;
	OLD_ULARGE_INTEGER  t_fileLimit;
	OLD_ULARGE_INTEGER  t_fileLimitSoft;


} QUOTASVC_QUOTA_DEFAULTS2;
	
typedef enum {
	QUOTASVC_QTREE_OTHER,
	QUOTASVC_QTREE_NTFS,
	QUOTASVC_QTREE_MIXED,
	QUOTASVC_QTREE_UNIX
} QUOTASVC_QTREE_TYPE;

typedef enum {
	QUOTASVC_OPLOCKS_ENABLED,
	QUOTASVC_OPLOCKS_DISABLED
} QUOTASVC_OPLOCKS_SETTING;

/*
 * Provide a summary of information about a qtree
 */
typedef struct _QUOTASVC_LIST {
	ISTRING WCHAR* 	qtreeName;     /* name of the qtree */
	QUOTASVC_QTREE_TYPE type;        /* security style of wtree */
	QUOTASVC_OPLOCKS_SETTING oplocks;  /* oplocks enabled or not */

} QUOTASVC_LIST;

/*
 * This structure is used to return all of the current qtrees of
 * a volume.  Buffer is an array of QUOTASVC_LIST whose maximum index
 * is NumQtrees.
 */
typedef struct _QUOTALIST_BUFFER {
	ULONG NumQtrees;
	SIZEIS(NumQtrees) QUOTASVC_LIST *Buffer;
} QUOTALIST_BUFFER;

/*
 * The type of quota information requested: user, group or qtree.
 */
typedef enum {
	QUOTASVC_QTYPE_NONE,
	QUOTASVC_QTYPE_USER,
	QUOTASVC_QTYPE_GROUP,
	QUOTASVC_QTYPE_QTREE
} QUOTASVC_QUOTA_TYPE;


#endif /*_QUOTAINTF_*/






