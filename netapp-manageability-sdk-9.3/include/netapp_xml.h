/*
 * $Id: //depot/prod/zephyr/Rlufthansaair/src/libnetapp/netapp_xml.h#1 $
 * Copyright (c) 2003 Network Appliance, Inc.
 * All rights reserved.
 */
#ifndef _NETAPP_XML_
#define _NETAPP_XML_

#include "zfd.h"
#include "shttpc.h"
#include "nc_api.h"
#include <libxml/parser.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * The results from a single XML request
 */
struct xml_results {
	int	status;			/* Result of request */
	char	*reason;		/* Reason for failure (if any) */
	char	*details;		/* Detailed reasons for failure */
	char 	*name;			/* name attribute */
	char	*value;			/* value element */
	stab_t	attributes;
	array_t	attrs;			/* array of attributes */
	array_t	flist;			/* array of file names */
};

/*
 * Context used when parsing XML responses from caches. 
 */
struct xml_ctx {
	nc_api_error_t	api_error;	/* error during protocol establishment*/
	char	*parse_error;		/* Details of parsing error */

	char	*pcdata;		/* Parsed Character Data */
	size_t	pcdata_len;		/* Current size of pcdata buf */

	struct xml_results *current;	/* current result */
	array_t results;		/* vector of xml_results */

	/* Things needed while saving element hierarchy */
	struct na_elem_stack_t * elemStack;
	int elemStacksize;
	int elemDepth;
	/* 
	 * parent parserCtxt pointer to store parsing errors 
	 * that are found in start/end element handlers
	 */
	xmlParserCtxtPtr parserCtxt;
};

bool_t xml_parse(shttpc_t sock, struct xml_ctx *ctx, int len);
bool_t xml_parse_chunked_encoding(shttpc_t sock, struct xml_ctx *ctx);
int xml_parse_string(const char *xml, struct xml_ctx *ctx);
void xml_release(struct xml_ctx *ctx);
struct xml_ctx *xml_create(void);
void xml_global_init(void);
void xml_global_free(void);

#ifdef __cplusplus
}
#endif

#endif
