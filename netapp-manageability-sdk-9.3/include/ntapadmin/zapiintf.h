/*
 * $Id: //depot/prod/DOT/fsb/ontap/files/ntapadmin/zapiintf.h#1 $
 *
 * Network Appliance Zapi Service IDL File
 *
 * This module defines the data structures returned by the
 * Zapi Managment RPCs
 *
 * (c)1999-2002 Network Appliance, Inc. All Rights Reserved.
 */

#ifndef _ZAPIINTF_
#define _ZAPIINTF_

typedef struct _ZA_UNICODE_STRING {
    USHORT Length;
    USHORT MaximumLength;

#ifdef IDL_PASS
	[string]
#endif
		WCHAR  *Buffer;

} ZA_UNICODE_STRING, *PZA_UNICODE_STRING;

#endif /*_ZAPIINTF_*/

