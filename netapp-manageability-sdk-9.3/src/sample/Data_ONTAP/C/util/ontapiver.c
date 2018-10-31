//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// ontapiver.c                                                //
//                                                            //
// Sample code which retrieves the API version of a filer     //
// by trying to request a too-large version # and             //
// interpreting the error message that comes back.            //
//                                                            //
// Copyright 2002-2003 Network Appliance, Inc. All rights     //
// reserved. Specifications subject to change without notice. //
//                                                            //
// This SDK sample code is provided AS IS, with no support or //
// warranties of any kind, including but not limited to       //
// warranties of merchantability or fitness of any kind,      //
// expressed or implied.  This code is subject to the license //
// agreement that accompanies the SDK.                        //
//                                                            //
// tab size = 4                                               //
//                                                            //
//============================================================//

#include "ontapiver.h"

//============================================================//

//
// find out whether it's okay to use version x.y calls
// where x = majorversion and y = minorversion
//
int na_has_ontapi_version(
						const char* filername,
						const char* user,
						const char* passwd,
						int			majorversion,
						int			minorversion)
{
	int		major, minor;

	if (na_get_ontapi_version(filername, user, passwd,
								&major, &minor))
		return 0;

	if (major == majorversion && 
		minor >= minorversion)

		return 1;
	else
		return 0;
}

//============================================================//

int na_get_ontapi_version(
						const char* filername, 
						const char* user,
						const char* passwd,
						int* majorversion,
						int* minorversion)
{
	na_server_t*	s;
	na_elem_t*		out;
	int 			majorbig = 99;
	int 			minorbig = 999;
	int 			ret = 0;

	//
	// Initialize connection to server.
	// We request version 99.999, just so we get back the
	// error message about which version it really supports.
	//
	s = na_server_open(filername, majorbig, minorbig);

	na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
	na_server_adminuser(s, user, passwd);

	//
	// We expect this API to fail, because we've
	// specified too-large version numbers in the na_server_open call.
	//
	out = na_server_invoke(s, "system-get-version", NULL);
	if (na_results_status(out) != NA_OK) {

		int			e = na_results_errno(out);
		const char* s1 = na_results_reason(out);
		const char*	s2;

		//
		// We expect to get back an error EAPIUNSUPPORTEDVERSION
		// with a "reason" string of the form:
		// "Version #.# was requested, but only #.# is supported."
		//
		switch (e) {
		case EAPIUNSUPPORTEDVERSION:
			s2 = strstr(s1,"only ");
			if (s2 == NULL || sscanf(s2,"%*s %d.%d",
							majorversion,minorversion) != 2) {
					*majorversion = -1;
					*minorversion = -1;
			}
			ret = 0;
			break;
		case -1:
			//
			// For API version 1.0, ONTAP doesn't
			// return EAPIUNSUPPORTEDVERSION,
			// so we check the error message explicitly.
			//
			if ( strstr(s1,"unsupported version") != NULL ) {
					*majorversion = 1;
					*minorversion = 0;
					break;
			}
			// fall through
		default:
			fprintf(stderr, "Unexpected Error %d: %s\n", e, s1);
			ret = -2;
			break;
		}
	}
	else {
			fprintf(stderr, "Unexpected success!?  "
					"We didn't expect a request for "
					"API version 99.99 to succeed!\n");
			ret = -3;
	}

	//
	// free the resources used by the result of the call
	//
	na_elem_free(out);
	na_server_close(s);

	return ret;
}

