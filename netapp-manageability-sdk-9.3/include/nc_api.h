/*
 * NetCache 'C' API's exported from the cache
 */
#ifndef _NC_API_H
#define _NC_API_H

#include "stab.h"
#include "http.h"

#ifdef __cplusplus
extern "C" { 
#endif

/*
 * Return status from nc_api calls
 */

typedef enum {
	 NC_API_SUCCESS = 0,
	 NC_API_ERROR = -1,		/* Unknown; need to refine more */
	 NC_API_TRANSPORT_ERROR = -100,
	 NC_API_PARSE_ERROR = -101,
	 NC_API_AUTH_ERROR = -102,
	 NC_API_VERSION_ERROR = -103,	/* Incompatible NetCache version */
	 NC_API_TIMEOUT_ERROR = -104,	/* Results not available in time */
} nc_api_error_t;

const char * nc_api_error_msg(const nc_api_error_t api_error);

#define XML_PREFIX \
	"<?xml version='1.0' encoding='utf-8' ?>\n" \
	"<!DOCTYPE netapp SYSTEM 'file:/etc/netapp.dtd'>\n" \
	"<netapp version='1.0' xmlns='http://www.netapp.com/netcache/admin'>"

#define XML_POSTFIX "</netapp>"

typedef enum nc_api_transport {
	/* Keep in sync with nc_api_transport_map. */
	NC_API_TRANSPORT_UNKNOWN = -1,
	NC_API_TRANSPORT_HTTP,
	NC_API_TRANSPORT_HTTPS,
} nc_api_transport_t;

union zfd_setopt;
nc_api_error_t nc_api_set_transport(nc_api_transport_t transport,
	const union zfd_setopt *opt);

nc_api_error_t nc_api_set(const char *host, int port, const AuthInfo *auth,
	const char *key, const char *value, char **errors);
nc_api_error_t nc_api_set_with_timeout(const char *host, int port, 
	const AuthInfo *auth, const char *key, const char *value, int timeout);
nc_api_error_t nc_api_show(const char *host, int port, const AuthInfo *auth,
	const char *key, char *value, unsigned int valuesz, char **errors);
nc_api_error_t nc_api_clear(const char *host, int port, const AuthInfo *auth,
	const char *key);
nc_api_error_t nc_api_copy_file(const char *host, int port,
	const AuthInfo *auth, const char *src, const char *dst, char **errors);
nc_api_error_t nc_api_rename_file(const char *host, int port,
	const AuthInfo *auth, const char *src, const char *dst);
nc_api_error_t nc_api_remove_file(const char *host, int port,
	const AuthInfo *auth, const char *src);
nc_api_error_t nc_api_read_file(const char *host, int port,
	const AuthInfo *auth, const char *file, char **out);
nc_api_error_t nc_api_read_file_with_timeout(const char *host, int port, 
	const AuthInfo *auth, const char *file, int timeout, char **out);
nc_api_error_t nc_api_download(const char *host, int port, const AuthInfo *auth,
	const char *url, char **errors);
nc_api_error_t nc_api_commit(const char *host, int port, const AuthInfo *auth, 
	const char *file, char **errors);
nc_api_error_t nc_api_list(const char *host, int port, const AuthInfo *auth,
	array_t *list);
nc_api_error_t nc_api_remove(const char *host, int port, const AuthInfo *auth,
	const char *file, char **errors);
nc_api_error_t nc_api_reboot(const char *host, int port, const AuthInfo *auth,
	char **errors);
nc_api_error_t nc_api_configure(const char *host, const int port,
	const AuthInfo *auth, const char *config_data, char **errors);
nc_api_error_t nc_api_config_initialize(const char *host, int port,
	const AuthInfo *auth, const char *option, char **errors);
nc_api_error_t nc_api_config_clone(const char *host, int port,
	const AuthInfo *auth, char **out);
nc_api_error_t nc_api_stats_general(const char *host, int port,
	const AuthInfo *auth, array_t attrs, stab_t *results);
nc_api_error_t nc_api_stats_server(const char *host, int port,
	const AuthInfo *auth, array_t attrs, const char *sort, int limit,
	array_t *results);
nc_api_error_t nc_api_stats_client(const char *host, int port,
	const AuthInfo *auth, array_t attrs, array_t urls, array_t *results);
nc_api_error_t nc_api_stats_any(const char *host, int port,
	const AuthInfo *auth, const char *cmd, array_t *results);
array_t nc_api_stats_any_multi(array_t hosts, const char *request, int timeout);

#ifdef __cplusplus
} /* extern C */
#endif

#endif
