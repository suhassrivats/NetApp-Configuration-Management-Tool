/*
 * $Id: //depot/prod/zephyr/Rlufthansaair/src/libnetapp/netapp_api.h#1 $
 *
 * Copyright (c) 2003-2005 Network Appliance, Inc.
 * All rights reserved.
 */

/*
 * This include file defines the functions needed to
 * make use of the Network Appliance ONTAP APIs.
 */

#ifndef _NETAPP_API_H
#define _NETAPP_API_H 1

#include <stdio.h>
#include <generics64.h>

#ifdef __cplusplus
#define	_EXTERN	extern "C"
#else
#define _EXTERN extern
#endif

#include <sys/types.h>

typedef enum na_style_t {
	NA_STYLE_LOGIN_PASSWORD,
	NA_STYLE_RPC,
	NA_STYLE_HOSTSEQUIV,
	NA_STYLE_ZSM,         /*Use the ZAPI Socket Manager() protocol*/
	NA_STYLE_CERTIFICATE
} na_style_t;

typedef enum na_server_type_t {
	NA_SERVER_TYPE_FILER = 0,
	NA_SERVER_TYPE_NETCACHE = 1,
	NA_SERVER_TYPE_AGENT = 2,
	NA_SERVER_TYPE_DFM = 3,
	NA_SERVER_TYPE_CLUSTER = 4,
	NA_SERVER_TYPE_OCUM = 5,
} na_server_type_t;

typedef enum na_server_transport_t {
	/* Keep in sync with na_server_transport_map. */
	NA_SERVER_TRANSPORT_HTTP = 0,
	NA_SERVER_TRANSPORT_HTTPS,
	NA_SERVER_TRANSPORT_ZSM,
	NA_SERVER_TRANSPORT_ZSMS,
} na_server_transport_t;

typedef enum na_debug_style_t {
	NA_NO_DEBUG = 0,
	NA_PRINT_DONT_PARSE = 1,
	NA_DONT_PRINT_DONT_PARSE = 2,
} na_debug_style_t;

/*
 * Forward declarations of structures and unions.
 */
union zfd_setopt;
struct na_server_t;
struct na_elem_t;

typedef struct na_elem_t na_elem_t;
typedef struct na_server_t na_server_t;
typedef struct na_elem_iter_t na_elem_iter_t;

/*
 * This is the only structure whose insides are exposed,
 * to make iterator usage easier.
 */
struct na_elem_iter_t {
	na_elem_t *next;
};

/* status values */
#define NA_OK 1
#define NA_FAILED 0

_EXTERN int		na_startup(char *errbuff, int errbuffsize);
_EXTERN int		na_startup_without_ntapadmin(char *errbuff, int errbuffsize);
_EXTERN void		na_shutdown(void);
_EXTERN int		na_is_started(void);

/*
 * Allocation and freeing
 */
_EXTERN	na_elem_t *	na_elem_new(const char * name);
_EXTERN	na_elem_t *	na_elem_new_const_name(const char * name);
_EXTERN void		na_elem_free(na_elem_t * e);
_EXTERN void		na_free(const void * ptr);

/*
 * Formatting
 */
_EXTERN char *		na_elem_sprintf(na_elem_t * e);

/*
 * Child element get/set
 */
_EXTERN	na_elem_t *	na_elem_child(na_elem_t *, const char *);
_EXTERN int		na_elem_set_content(na_elem_t * e, const char * value);
_EXTERN const char *	na_elem_get_name(na_elem_t * e);
_EXTERN const char *	na_elem_get_content(na_elem_t * e);
_EXTERN int		na_elem_has_children(na_elem_t * e);
_EXTERN	na_elem_t *	na_child_add(na_elem_t *, na_elem_t *);
_EXTERN na_elem_t *	na_child_const_add_string(na_elem_t * e,
					    const char * name, const char * value);
_EXTERN na_elem_t *	na_child_add_string(na_elem_t * e,
					    const char * name, const char * value);
_EXTERN	const char *	na_child_get_string(na_elem_t *, const char *);
_EXTERN na_elem_iter_t	na_child_iterator(na_elem_t * e);
_EXTERN char *		na_child_get_string_encrypted(na_elem_t * n,
				const char * name, const char *key);
_EXTERN na_elem_t *	na_child_add_string_encrypted(na_elem_t * n,
				const char * name, const char * contents,
				const char * key);
_EXTERN	int		na_child_get_int(na_elem_t *, const char *, int);
_EXTERN na_elem_t *	na_child_add_int(na_elem_t * e,
				const char * name, int);
_EXTERN int64_t	na_child_get_int64(na_elem_t *, const char *,
				int64_t);
_EXTERN na_elem_t *	na_child_add_int64(na_elem_t * e,
				const char * name, int64_t);
_EXTERN uint64_t	na_child_get_uint64(na_elem_t *, const char *,
				uint64_t);
_EXTERN na_elem_t *	na_child_add_uint64(na_elem_t * e,
				const char * name, uint64_t);
_EXTERN void		na_encrypt_basic(const char *key,
				const char* input, char *output, size_t nbytes);
_EXTERN na_elem_t *     na_zapi_get_elem_from_raw_xmlinput(char *val);

_EXTERN uint32_t	na_child_get_uint32(na_elem_t *, const char *,
				uint32_t);
_EXTERN na_elem_t *	na_child_add_uint32(na_elem_t * e,
				const char * name, uint32_t);

#ifndef NETAPP_INTERNAL_API
/*
 * new get/set convenience routines in 1.3 
 */
_EXTERN int          	na_child_get_bool(na_elem_t *, const char *,
                                int);
_EXTERN na_elem_t *     na_child_add_bool(na_elem_t * e,
                                const char * name, int);
#endif

/*
 * Server open/close
 */
_EXTERN na_server_t *	na_server_open(const char * host,int major,int minor);
_EXTERN int		na_server_close(na_server_t *);
_EXTERN void		na_server_set_style(na_server_t * s, na_style_t style);
_EXTERN na_style_t	na_server_get_style(na_server_t * s);
_EXTERN int		na_server_set_timeout(na_server_t *s, int timeout);
_EXTERN int		na_server_get_timeout(na_server_t *s);
_EXTERN int		na_server_set_admin_user(na_server_t * s,
				const char * login, const char * password);
_EXTERN  int	na_server_set_vfiler(na_server_t *s,
				const char * vfilerserver);
_EXTERN  int	na_server_set_vserver(na_server_t *s, const char * vserver);
_EXTERN  const char *	na_server_get_vserver(na_server_t *s);
_EXTERN char * na_server_get_raw_xml_output(na_server_t *s);

_EXTERN na_elem_t *	na_server_invoke(na_server_t * s, const char * api, ...);
_EXTERN na_elem_t *	na_server_invoke_elem(na_server_t * s, na_elem_t * i);
_EXTERN  int	na_server_set_originator_id(na_server_t *s, const char * oid);
_EXTERN  int	na_server_set_target_cluster_uuid(na_server_t *s, const char * uuid);
_EXTERN  int	na_server_set_target_vserver_name(na_server_t *s, const char * vserver_name);
_EXTERN int na_server_set_application_name(const char * app_name);
_EXTERN const char * na_server_get_application_name();
_EXTERN const char * na_server_get_target_vserver_name(na_server_t *s);
_EXTERN const char * na_server_get_target_cluster_uuid(na_server_t *s);

// Core APIs for keep alive connection
_EXTERN int na_server_set_keep_alive(na_server_t *srv, int enable);
_EXTERN int na_server_get_keep_alive(na_server_t *srv);

_EXTERN int na_server_set_sslv3(na_server_t *srv, int enable);
_EXTERN int na_server_is_sslv3_enabled(na_server_t *srv);

// Core APIs for Certificate Based Authentication
_EXTERN int na_server_set_client_cert_and_key(na_server_t *srv, 
			const char *cert, const char *key, const char *passwd);
_EXTERN int na_server_set_ca_certs(na_server_t *srv, const char *CAfile);
_EXTERN int na_server_set_server_cert_verification(na_server_t *srv, int enable);
_EXTERN int na_server_is_server_cert_verification_enabled(const na_server_t *srv);
_EXTERN int na_server_set_hostname_verification(na_server_t *srv, int enable);
_EXTERN int na_server_is_hostname_verification_enabled(const na_server_t *srv);
/* 
 * #defines for backward compatibility
 */
#define na_server_adminuser  	na_server_set_admin_user
#define na_server_style		na_server_set_style

/*
 * What kind of server are we connecting to?  Filer, NetCache, and
 * so on.
 */

_EXTERN na_server_type_t	na_server_get_server_type(na_server_t *);
_EXTERN int			na_server_set_server_type(na_server_t *,
					na_server_type_t);

/*
 * What protocol should we use to connect?  HTTP, HTTPS, etc.
 */

_EXTERN na_server_transport_t	na_server_get_transport_type(na_server_t *);
_EXTERN int			na_server_set_transport_type(na_server_t *,
					na_server_transport_t transport,
					const union zfd_setopt * transportarg);

/*
 * Override the default port for the transport, if necessary.
 */

_EXTERN int			na_server_get_port(na_server_t *);
_EXTERN int			na_server_set_port(na_server_t *, int port);

/*
 * Get/set the default host lookup behavior, if necessary.
 *
 * NOTE: Setting the host lookup behavior is only allowed when using the
 *       ZAPI Socket Manager() protocol (NA_STYLE_ZSM) to communicate
 *       with ZAPI servers.
 *
 *       The default ZSM behavior is to accept only dotted IP address
 *       values in the host string, and thus not do any kind of name
 *       lookup.
 *
 *       The default behavior for everyone else is to accept any legal
 *       host string, and to do any lookup necessary to translate the
 *       name to an IP address.
 *
 * na_server_get_host_lookup() returns TRUE or FALSE, depending on
 *       whether the given ZAPI server object is set to do user lookups
 *       on the host name.
 *
 * na_server_set_host_lookup() sets the host lookup behavior for the
 *       given ZAPI server object to the given value, but only if it
 *       is using NA_STYLE_ZSM.  If successful, it returns TRUE.
 *       Otherwise, it returns FALSE.
 */
_EXTERN int             na_server_get_host_lookup(na_server_t *);
_EXTERN int             na_server_set_host_lookup(na_server_t *, int);
/*
 * Get/set debug styles on the server for low-level debugging.
 */
_EXTERN void		na_server_set_debugstyle(na_server_t * s,
				na_debug_style_t style);
_EXTERN na_debug_style_t na_server_get_debugstyle(na_server_t * s);

/*
 * Iterator
 */
_EXTERN na_elem_t *	na_iterator_next(na_elem_iter_t * e);

/*
 * Results
 */
_EXTERN int		na_results_status(na_elem_t * e);
_EXTERN const char *	na_results_reason(na_elem_t * e);
_EXTERN int		na_results_errno(na_elem_t * e);

/*
 * Aliases for old functions.
 */
#define	na_child_string(e,s) na_child_get_string((e),(s))
#define	na_child_int(e,p,n) na_child_get_int((e),(p),(n))

#endif
