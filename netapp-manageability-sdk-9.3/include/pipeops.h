/*
 * $Id: //depot/prod/zephyr/Rlufthansaair/src/libpipe/pipeops.h#1 $
 *
 * Copyright (c) 1997-2002 Network Appliance, Inc.
 * All rights reserved.
 *
 * This file defines the format of the operations passed to \PIPE\NETAPPSVC
 *
 * Note that this file is included in both the filer and in Windows apps
 *
 * all paths are full UNCs
 *		\\server\share\path
 */

#ifndef _pipeops_H
#define _pipeops_H

#ifndef _WINNT_
#include <smb/windef.h>
#endif

#define CIFS_RPC_SET_NAME_SIZE 128
#define CIFS_RPC_GET_NAME_SIZE 100
#define CIFS_VERSION_SIZE 128
#define CIFS_SH_VERSION_SIZE 64


#ifndef FILER
/*
 * Pipeops is defined with Windows compatible types.
 * If FILER is defined then the file is being included
 * into the filer code.
 */
typedef WORD PackedLEushort;
typedef DWORD PackedLEulong;
#define MAX_PATH	  260

#endif

/*
 * This is the Unix max path. Used for symlink destination buffer size.
 */
#define MAX_UPATH	 1024

/*
 ****************************************************************
 *
 * Filer pipe operations
 *
 ****************************************************************
 */

/*
 * Pre-5.3 filers only understand these:
 */
#define NETAPP_SVC_GET		1   /* Get file information     */
#define NETAPP_SVC_SET		2   /* Change NFS permissions   */
#define NETAPP_SVC_CHOWN	3   /* Change Ownership         */
#define NETAPP_GETVER		4   /* Get Filer Version        */
#define NETAPP_SVC_GET1		5   /* Newer Get operation that 
                                     *    also returns group    */
#define NETAPP_SVC_CHGRP	6   /* change group             */

/*
 * Filers 5.3 and forward use these, but also understand others.
 * WARNING: support for ops 1-6 may be deleted in future versions
 *          of the NetApp filer OS.
 */
#define NETAPP_SVC_GET2	       101  /* Yet another Get          */
#define NETAPP_SVC_SET2	       102  /* Unicode Set              */
#define NETAPP_SVC_CHOWN2      103  /* Unicode chown            */
#define NETAPP_GETVER2	       104  /* Unicode getversion       */
/* no 105 */
#define NETAPP_SVC_CHGRP2      106  /* Unicode chgrp            */

/*
 * Only available in 6.2.1 and later.
 */
#define NETAPP_SVC_GET3	       107  /* GET2 not following symlinks */
#define NETAPP_SVC_SYMLINK     108  /* Create a symlink            */
#define NETAPP_SVC_READLINK    109  /* Return contents of symlink  */

/*
 ****************************************************************
 *
 *  Use a GetParmsSVC structure to request information 
 *  about a file, which is then returned in a Get*_R structure.
 *
 ****************************************************************
 */

typedef struct {
	PackedLEushort	operation;	/* See above*/
	CHAR		path[MAX_PATH];	/* zero terminated ASCII path to file*/
} GetParmsSVC, GetParmsSVC1;


typedef struct {
	PackedLEushort	canChown;/* Does this user have chown priv?*/
	PackedLEushort	canChmod;/* Does the user have chmod priv?*/
	PackedLEulong	perms;	 /* UNIX file perms*/
	CHAR		owner[CIFS_RPC_GET_NAME_SIZE];
			/* zero terminated ASCII string of owner*/
} GetParmsSVC_R;

typedef struct {
	PackedLEushort	canChown;/* Does this user have chown and chgrp priv?*/
	PackedLEushort	canChmod;/* Does the user have chmod priv?*/
	PackedLEulong	perms;	 /* UNIX file perms*/
	PackedLEushort	isLink;  /* true if file is symlink*/
	CHAR		owner[CIFS_RPC_GET_NAME_SIZE];
			/* zero terminated ASCII string of owner*/
	CHAR		group[CIFS_RPC_GET_NAME_SIZE];
			/* zero terminated ASCII string of group*/
} GetParmsSVC1_R;


/*
 ****************************************************************
 *
 * Get2 operation: Unicode compliant, more info.
 * Get3 also uses this format.
 *
 ****************************************************************
 */

	/*
	 * privs flags
	 */
#define		NTP_NO_PRIV	0
#define		NTP_CAN_CHOWN	1
#define		NTP_CAN_CHGRP	2
#define		NTP_CAN_CHMOD	4

	/* 
	 * filetype flags
	 */
#define		NTP_UNKNOWN	0
#define		NTP_REGULAR	1
#define		NTP_DIR		2
#define		NTP_SYMLINK	4
#define		NTP_BLOCKDEV	8
#define		NTP_CHARDEV	16
#define		NTP_SOCKET	32
#define		NTP_FIFO	64

	/*
	 * filertype flags
	 */
#define		NTP_NETAPP	1
#define		NTP_SAMBA	2

	/*
	 * secstyle flags
	 */
#define		NTP_UNIXTREE	 1	/* NetApp UNIX qtree */
#define		NTP_NTFSTREE	 2	/* NetApp NTFS qtree */
#define		NTP_MIXEDTREE	 4	/* NetApp mixed qtree */
#define		NTP_HAS_ACL	 8	/* File has an NT ACL */

	/*
	 * DOSAttr flags
	 */
#define		NTP_DOS_RO	1
#define		NTP_DOS_H	2
#define		NTP_DOS_S	4
#define		NTP_DOS_A	8

typedef struct{
	PackedLEushort	operation;
	WCHAR		path[MAX_PATH];	/* ZT UC path to file*/
} GetParmsSVC2;


typedef struct {
	WCHAR		owner[CIFS_RPC_GET_NAME_SIZE];	/* owner name (ZT) */
	WCHAR		group[CIFS_RPC_GET_NAME_SIZE]; 	/* group name (ZT) */
	PackedLEulong	uid;		/* userid of owner 		*/
	PackedLEulong	gid;		/* groupid of owner 		*/
		/*
		 * Does user have chown, chgrp or chmod privilege?
		 */
	u_char		privs;	
		/*
		 * Type of file: regular, dir, symlink, etc.	
		 */
	u_char		filetype;	

		/* 
		 * Type of filer (NetApp, Samba, etc).
		 */
	u_char		filertype;
		/*
		 * Whether the file and filesystem are of NFS, NTFS,
		 * or mixed type, have ACLs etc.  					
		 */
	u_char		secstyle;

		/* standard Unix stuff and DOS attributes */
	PackedLEulong	perms;		/* UNIX file perms 		*/
	PackedLEulong	atime;		/* last access time (secs)	*/
	PackedLEulong 	mtime;		/* time of last modification 	*/
	PackedLEulong	ctime;		/* time of last change 		*/
	PackedLEulong 	crtime;		/* time of creation 		*/
	PackedLEulong	sizelo;		/* loword of file size		*/
	PackedLEulong	sizehi;		/* hiword of file size		*/
	PackedLEulong	DOSattr;	/* DOS attributes (S,H,A,RO)	*/
		/* 
		 * The effective Unix permissions on a file if it is not
		 * a native Unix file.
		 */	
	PackedLEulong	synthperms;	/* synthesized perms		*/
	PackedLEulong	synthflags;	/* synthesized flags		*/

		/* 
		 * Available for any use.  MUST be set to zero if unused 
		 */
	PackedLEulong	userbits;

} GetParmsSVC2_R;

/*
 ****************************************************************
 *
 * Set operations
 *
 ****************************************************************
 */

/*
 *  The following is for a set type operation. No data is returned in
 *  the response.
 */
typedef struct{
	PackedLEushort	operation;	/* See above*/
	PackedLEushort	pad;
	PackedLEulong	perms;		/* UNIX file perms*/
	CHAR		path[MAX_PATH];
		/* zero terminated ASCII path to file*/
} SetParmsSVC;

/*
 ****************************************************************
 *
 * Set2 operation: Unicode compliant, more info.
 *
 ****************************************************************
 */

typedef struct{
	PackedLEushort	operation;
	PackedLEushort	pad;
	PackedLEulong	perms;		/* UNIX file perms*/
	PackedLEulong	DOSattr;	/* DOS flags */
	PackedLEulong	atime;		/* last access time (secs)	*/
	PackedLEulong 	mtime;		/* time of last modification 	*/
	WCHAR		path[MAX_PATH];
		/* zero terminated Unicode path to file*/
} SetParmsSVC2;


/*
 ****************************************************************
 *
 *  The following are for a chown or chgrp type operation.  
 *  No data is returned in the response.  Owner/name is the new 
 *  owning user or group in a NETAPP_SVC_CHOWN operation.
 *
 ****************************************************************
 */

typedef struct{
	PackedLEushort	operation;	/* See above*/
	CHAR	owner[CIFS_RPC_SET_NAME_SIZE];
			/* zero terminated ASCII string of owner*/
	CHAR	path[MAX_PATH];	/* zero terminated ASCII path to file*/
} ChownSVC, ChgrpnSVC;

typedef struct {
	PackedLEushort	operation;
	WCHAR	name[CIFS_RPC_SET_NAME_SIZE];
	WCHAR	path[MAX_PATH];
} ChownSVC2, ChgrpnSVC2;

/*
 ****************************************************************
 *
 * The following is used to obtain the version strings of the filer.
 *
 ****************************************************************
 */

typedef struct{
	PackedLEushort	operation;	/* See above*/
} VersionSVC;

typedef struct{
	CHAR	shortVers[CIFS_SH_VERSION_SIZE];
			/* zero terminated ASCII string*/
	CHAR	longVers[CIFS_VERSION_SIZE];
			/* zero terminated ASCII string*/
} VersionSVC_R;

typedef struct {
	WCHAR	shortVers[CIFS_SH_VERSION_SIZE]; /* ZT UC string */
	WCHAR	longVers[CIFS_VERSION_SIZE];	 /* ZT UC string */
} VersionSVC2_R;


/*
 * Symlink manipulation
 */

typedef struct {
	PackedLEushort	operation;		/* See above*/
	WCHAR		path[MAX_PATH];		/* Path to create/read */
} SymlinkOp;

typedef struct {
	SymlinkOp	hdr;
	CHAR		destbuf[MAX_UPATH];	/* Symlink destination */
} SymlinkCreateSVC;

typedef struct {
	SymlinkOp	hdr;
} ReadlinkSVC;

typedef struct {
	CHAR		destbuf[MAX_UPATH];	/* Symlink destination */
} ReadlinkSVC_R;


/*
 ****************************************************************
 *
 * Stuff used by filers running 5.1 and later
 *
 ****************************************************************
 */

/*
 * sneak some info about the tree type into the high
 * order nibble of perm
 */
#define UNIX_TREE	0
#define NTFS_TREE	0x40000000
#define MIXED_TREE	0x80000000
#define HAS_ACL		0x10000000
#define DOS_RO		0x20000000

/*
 ****************************************************************
 *
 * These are the pipes that are used for NetApp administration functions
 *
 ****************************************************************
 */
#define PIPE_NETAPP  "\\PIPE\\NETAPPSVC"
#define GENERIC_PIPE "\\PIPE\\"
#define WIN95_GENERIC_PIPE "\\PIPE"

/*
 * These structures are used for the Netapp-specific FSCTL.
 */

typedef struct {
	PackedLEulong	magic;
	PackedLEulong	operation;	/* Same as pipe values */
} NetappFSCTL_H;

#define NETAPP_FSCTL_MAGIC 0x22074994

typedef struct {
	NetappFSCTL_H	hdr;
	PackedLEulong	perms;		/* UNIX file perms*/
	PackedLEulong	DOSattr;	/* DOS flags */
	PackedLEulong	atime;		/* last access time (secs)	*/
	PackedLEulong 	mtime;		/* time of last modification 	*/
} NetappFSCTL_SET;

typedef struct {
	NetappFSCTL_H	hdr;
	WCHAR		name[CIFS_RPC_SET_NAME_SIZE];
} NetappFSCTL_CHOWN, NetappFSCTL_CHGRP;

#define RETPATHSIZE 512
typedef struct {
	GetParmsSVC2_R	parms;
	WCHAR		path[RETPATHSIZE];
} NetappFSCTL_GET_R;


#endif /* _pipeops_H */
