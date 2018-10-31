/*
 * $Id: //depot/prod/DOT/fsb/ontap/files/ntapadmin/adminintf.h#1 $
 *
 * Network Appliance Snapshot Service IDL File
 *
 * This module defines common definitions used by the ntapadmin
 * API and the underlying 
 *
 *
 * (c)1999 Network Appliance, Inc. All Rights Reserved.
 */

#ifndef _NTAPADMININTF_
#define _NTAPADMININTF_

#ifndef OLD_LARGE_INTEGER_DEFINED

typedef struct _OLD_LARGE_INTEGER {
    ULONG LowPart;
    LONG HighPart;
} OLD_LARGE_INTEGER;

typedef struct _OLD_ULARGE_INTEGER {
    ULONG LowPart;
    ULONG HighPart;
} OLD_ULARGE_INTEGER;

#endif /*OLD_LARGE_INTEGER_DEFINED*/


#define OLD_ULARGE_INTEGER_TO_LONGLONG(LL, LINT) \
	((LONGLONG)LINT.HighPart << 32) + \
		LINT.LowPart;

#define OLD_ULARGE_INTEGER_TO_ULONGLONG(ULL, LINT) \
	((ULONGLONG)LINT.HighPart << 32) + \
		LINT.LowPart;


#ifndef ISTRING
#ifdef IDL_PASS
#define ISTRING [unique, string]
#else
#define ISTRING
#endif
#endif

#ifndef SIZEIS
#ifdef IDL_PASS
#define SIZEIS(var) [size_is(var)]
#else
#define SIZEIS(var)
#endif
#endif

#ifndef RPC_UNIQUE
#ifdef IDL_PASS
#define RPC_UNIQUE [unique]
#else
#define RPC_UNIQUE
#endif
#endif

#endif /*_NTAPADMININTF_*/
