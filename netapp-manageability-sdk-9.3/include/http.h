/*
 * $Id: //depot/prod/zephyr/Rlufthansaair/src/libnetapp/http.h#1 $
 *
 * Copyright (c) 2003 Network Appliance, Inc.
 * All rights reserved.
 */

#ifndef	_LIBNETAPP_HTTP_CLIENT_H
#define	_LIBNETAPP_HTTP_CLIENT_H 1

#include "generics.h"
#include <stdarg.h>

#include "stab.h"
#include "zfd.h"
#include "shttpc.h"


#ifdef __cplusplus
extern "C" {
#endif

/*------------------------------------------------------------------
 *
 *  http_url_t - a URL parsed into its components
 *
 *  Members:
 *
 *      hu_url_copy     Writable copy of the original URL.  We
 *                      write \0 characters into this one to avoid
 *                      having to create additional copies of each
 *                      field.
 *
 *                      The other (char *) fields in this structure
 *                      point to locations within hu_url_copy.
 *
 *      hu_host         Name (or address) of the host.
 *
 *      hu_port         Port number (default: 80).
 *
 *      hu_path         Request URI (default: /).  This path always
 *                      begins after the slash.
 *
 *      hu_username     Username to use for authentication (default: empty).
 *
 *      hu_password     Password to use for authentication (default: empty).
 *
 *------------------------------------------------------------------*/

typedef struct {
        char *          hu_url_copy;
        const char *    hu_host;
        uint16_t        hu_port;
        const char *    hu_path;
        const char *    hu_username;
        const char *    hu_password;
	bool_t		hu_is_ssl;
} http_url_t;

typedef struct AuthInfo {
    char* username;
    char* password;
    char* domain;
} AuthInfo;


_EXTERN int	http_set_snoop( int value );
_EXTERN int	http_parse_url(const char * url, http_url_t * purl);
_EXTERN void	http_free_url(http_url_t * purl);
_EXTERN int	http_open_url_socket(
			const char *	url,
			shttpc_t *	socketP,
			AuthInfo *	authInfo );

union zfd_setopt;

_EXTERN int	http_open_url_socket_reserved_ex(
			const char *	url,
			shttpc_t *	socketP,
			AuthInfo *	authInfo,
			bool_t		reserved,
			shttpc_type_t	conn_type);

_EXTERN int	http_open_url_socket_reserved_ex_wt(
			const char *	url,
			shttpc_t *	socketP,
			AuthInfo *	authInfo,
			bool_t		reserved,
			shttpc_type_t	conn_type,
			int timeout);

_EXTERN int	http_open_url_socket_reserved_ex_wt_wcert(
			const char *	url,
			shttpc_t *	socketP,
			AuthInfo *	authInfo,
			bool_t		reserved,
			shttpc_type_t	conn_type,
			int timeout,
			cert_auth_info *cert_info,
			bool_t		use_sslv3);

_EXTERN int	http_open_url_socket_reserved(
			const char *	url,
			shttpc_t *	socketP,
			AuthInfo *	authInfo,
			bool_t		reserved );

_EXTERN int	http_open_socket_ex(
			const char *	host,
			uint16_t	port,
			shttpc_t *	socketP,
			shttpc_type_t conn_type);

_EXTERN int	http_open_socket(
			const char *	host,
			uint16_t	port,
			shttpc_t *	socketP );

_EXTERN int	http_open_socket_reserved(
			const char *	host,
			uint16_t	port,
			shttpc_t *	socketP,
			bool_t		reserved );

_EXTERN int	http_get_request(
			shttpc_t	sock,
			const char *	url,
			const AuthInfo * auth_info,
			stab_t *      	headersp);

_EXTERN int	http_post_request(
			shttpc_t	sock,
			const char *	url,
			const AuthInfo * auth_info,
			const void *	post_data,
			size_t		post_data_len,
			stab_t *	headersp);

_EXTERN int	http_post_request_ex(
			shttpc_t	sock,
			const char *	url,
			const AuthInfo * auth_info,
			const void *	post_data,
			size_t		post_data_len,
			stab_t		headers,
			stab_t *	headersp);

_EXTERN int	http_strip_headers(
			shttpc_t		sock,
			stab_t *	headersp);

_EXTERN int	http_close(
			shttpc_t sock);

_EXTERN bool_t http_read_chunk(shttpc_t sock, char ** pbuf, size_t * pread);

#ifdef __cplusplus
} /* extern C */
#endif

#endif  /* _LIBNETAPP_HTTP_CLIENT_H */
