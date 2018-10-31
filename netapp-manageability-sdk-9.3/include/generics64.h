/*
 * $Id: $
 *
 * Copyright (c) 2008 Network Appliance, Inc.
 * All rights reserved.
 */

/*****************************************************************
 *
 *  Header:
 *      generics64.h
 *
 *  Description:
 *
 *      This module defines generic types and type definitions
 *	required for 64 bit SDK core API support.
 *
 ****************************************************************/


#ifndef _LIBADT_GENERICS64_H
#define _LIBADT_GENERICS64_H

#if defined(__FreeBSD__) || defined(linux) || defined(sun)
#include <inttypes.h>	/* for PRI* etc */
#endif

#ifdef	WIN32
typedef		signed __int64		int64_t;
typedef		int64_t *		int64_ptr_t;
 
typedef		unsigned __int64	uint64_t;
typedef		uint64_t *		uint64_ptr_t;
 
typedef		__int64			offset_t;
#endif /* WIN32 */
 
#ifdef linux
typedef		int64_t			offset_t;
#endif

#ifdef	sun
typedef		int64_t *		int64_ptr_t;
typedef		uint64_t *		uint64_ptr_t;
#endif
 
#ifdef	__alpha__
typedef		long			int64_t;
typedef		int64_t *		int64_ptr_t;
typedef		unsigned long		uint64_t;
typedef		uint64_t *		uint64_ptr_t;

typedef		uint64_t		offset_t;
#endif
 
#if defined(__FreeBSD__)
typedef		uint64_t		offset_t;
#endif

#if !(defined(linux) || defined(sun) || defined(_HPUX) || defined(hpux) || \
	defined(_AIX) || defined(__FreeBSD__))
typedef		unsigned int		uint32_t;
#endif

#if !defined(linux)
typedef		uint32_t *		uint32_ptr_t;
#endif

#endif
