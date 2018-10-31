//============================================================//
//                                                            //
// $Id: //depot/prod/zephyr/corsair/src/sample/C/apitest/apitest.c#1 $
//                                                            //
// apitest.c                                                   //
//                                                            //
// Exploratory application for ONTAPI APIs                    //
// It lets you call any ONTAPI API with named arguments       //
//    (essentially a command-line version of the zexplore     //
//     utility)                                               //
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

//234567890123456789012345678901234567890123456789012345678901234567890123456789

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if !defined(_WIN32) && !defined(_AIX)
#include <unistd.h>
#endif

#include "netapp_api.h"

#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE 1
#endif

#ifdef _WIN32
#define strcasecmp(s1, s2) stricmp(s1, s2)
#endif

#define DEFAULT_SSL_PORT 443
#define DEFAULT_HTTP_PORT 80

#ifdef	WIN32
#ifdef _WIN64
typedef		unsigned __int64	uintptr_t;
typedef		__int64			intptr_t;
#else
typedef		unsigned int		uintptr_t;
typedef		int			intptr_t;
#endif
#endif /* WIN32 */



//============================================================//

void
usage(const char* p)
{
	fprintf(stderr, "\nUsage:\n\n");
	fprintf(stderr, "  %s {options} <host> <user> <password> <API> [ <paramname> <arg> ...]\n", p);
	fprintf(stderr, "\nOptions:\n\n");
	fprintf(stderr, "  -i 	       API specified as XML input, "
		"on the command line\n");
	fprintf(stderr, "  -I 	       API specified as XML input, "
		"on standard input\n");
	fprintf(stderr, "  -t {type}   Server type(type = filer, dfm, ocum, agent, netcache)\n");
	fprintf(stderr, "  -v {vfiler name | vserver name}   For vfiler-tunneling or vserver-tunneling \n");
	fprintf(stderr, "  -r          Use RPC transport (Windows)\n");
	fprintf(stderr, "  -n          Use HTTP\n");
	fprintf(stderr, "  -p {port}   Override port to use\n");
	fprintf(stderr, "  -x          Show the XML input and output\n");
	fprintf(stderr, "  -X          Show the raw XML input and output\n");
	fprintf(stderr, "  -c          Connection timeout\n");
	fprintf(stderr, "  -h          Use Host equiv authentication mechanism\n");
	fprintf(stderr, "  -o {originator-id}   Pass Originator Id \n");
	fprintf(stderr, "  -z {cluster uuid | vserver name}   Pass remote peered cluster uuid or vserver name (only with vserver-tunneling) for redirecting APIs \n");
	fprintf(stderr, "  -C {cert-file}  Client certificate file to use\n");
	fprintf(stderr, "  -K {key-file}   Private key file to use. If not specified, then the certificate file will be used\n");
	fprintf(stderr, "  -P {key-passwd} Passphrase to access the private key file\n");
	fprintf(stderr, "  -T {ca-file}    File containing trusted certificate(s) to be used for server certificate verification\n");
	fprintf(stderr, "  -S          Enable server certificate verification\n");
	fprintf(stderr, "  -H          Enable hostname verification\n");
	fprintf(stderr, "\nNote: \n");
	fprintf(stderr, "     Use server type 'dfm' (-t dfm) for OnCommand Unified Manager server version 5.2 or earlier.\n");
	fprintf(stderr, "     Use server type 'ocum' (-t ocum) for OnCommand Unified Manager server version 6.0 or later.\n\n");
	fprintf(stderr, "     Use '-z' option to pass the UUID of a remote peered cluster to which the APIs are to be redirected from current cluster server context.\n");
	fprintf(stderr, "     Use '-z' option with '-v' option to pass the name of a remote peered vserver to which the APIs are to be redirected from current cluster server context.\n\n");
	fprintf(stderr, "     By default username and password shall be used for client authentication, specify\n");
	fprintf(stderr, "      -C option for using Certificate Based Authentication (CBA).\n");
	fprintf(stderr, "     Server certificate and Hostname verification is disabled by default for CBA.\n");
	fprintf(stderr, "     -T option can also be used for building the client certificate chain.\n");
	fprintf(stderr, "     All the certificates provided should be in PEM format.\n");
	fprintf(stderr, "     Do not provide username and password for -h, -r or CBA options.\n");
	fprintf(stderr, "     The username or UID of the user administering the storage systems can be passed\n");
	fprintf(stderr, "     to ONTAP as originator-id for audit logging.\n");
	fprintf(stderr, "\nExamples:\n\n");
	fprintf(stderr, "   apitest amana root meat system-get-version\n");
	fprintf(stderr, "   apitest amana root meat quota-report volume vol0\n");
	fprintf(stderr, "   apitest -z 93ae35b1-9009-11e3-8626-123478563412 toaster admin password vserver-get-iter\n");
	fprintf(stderr, "   apitest -v vs0 -z vs0_backup toaster admin password vserver-get-iter\n");
	fprintf(stderr, "   apitest -t dfm -C my_cert.pem -K my_key.pem -P keypasswd amana dfm-about\n");
	fprintf(stderr, "   apitest -t dfm -C my_cert.pem -K my_key.pem -P keypasswd -S -T server_cert.pem amana dfm-about\n");
	fprintf(stderr, "\n");
}

//============================================================//

#ifdef _WIN32

/*
 * This version of getopt came from the Visual C++ help files,
 * it's a free version from IBM.  Only needed on Windows.
 */

#include <string.h>

char *optarg = NULL;	/* pointer to the start of the option argument  */
int optind = 1;		/* number of the next argv[] to be evaluated    */
int opterr = 1;		/* non-zero if a question mark should be returned 
			   when a non-valid option character is detected */

/* handle possible future character set concerns by putting this in a macro */
#define _next_char(string)  (char)(*(string+1))

int
getopt (int argc, char *argv[], char *opstring)
{
	static char *pIndexPosition = NULL;
					/* place inside current argv string */
	char *pArgString = NULL;	/* where to start from next */
	char *pOptString;		/* the string in our program */

	if (pIndexPosition != NULL) {
		/* we last left off inside an argv string */
		if (*(++pIndexPosition)) {
			/* there is more to come in the most recent argv */
			pArgString = pIndexPosition;
		}
	}
	if (pArgString == NULL) {
		/* we didn't leave off in the middle of an argv string */
		if (optind >= argc) {
			/* more command-line arguments than argument count */
			pIndexPosition = NULL;
			/* not in the middle of anything */
			return EOF;
			/* used up all command-line arguments */
		}		
		/*
		 * If the next argv[] is not an option,
		 * there can be no more options.
		 */
		pArgString = argv[optind++];	/* set this to next argument */
		if (('/' != *pArgString) && ('-' != *pArgString)) {
			--optind;	/* point to arg once we're done */
			optarg = NULL;	/* no argument follows the option */
			pIndexPosition = NULL;
			return EOF;
		}
		/* check for special end-of-flags markers */
		if ((strcmp (pArgString, "-") == 0)
			|| (strcmp (pArgString, "--") == 0)) {
			optarg = NULL;	/* no argument follows the option */
			pIndexPosition = NULL;
			return EOF;
		}
		pArgString++;		/* look past the / or - */
	}
	if (':' == *pArgString) {			
		/* is it a colon? */
		return (opterr ? (int) '?' : (int) ':');
	} else if ((pOptString = strchr (opstring, *pArgString)) == 0) {
		optarg = NULL;		/* no argument follows the option */
		pIndexPosition = NULL;	/* not in the middle of anything */
		return (opterr ? (int) '?' : (int) *pArgString);
	} else {
		if (':' == _next_char (pOptString)) {
			/* is the next letter a colon? */
			/* It is a colon.  Look for an argument string. */
			if ('\0' != _next_char (pArgString)) {
				/* argument in this argv? */
				optarg = &pArgString[1];
				/* Yes, it is */
			} else {
				if (optind < argc)
					optarg = argv[optind++];
				else {
					optarg = NULL;
					return (opterr ?
						(int) '?' : (int) *pArgString);
				}
			}
			pIndexPosition = NULL;
			/* not in the middle of anything */
		} else {
			/* it's not a colon, so just return the letter */
			optarg = NULL;	/* no argument follows the option */
			pIndexPosition = pArgString;
			/* point to the letter we're on */
		}
		return (int) *pArgString;  /* return the letter that matched */
	}
}
#endif

//============================================================//

static na_server_t *
make_server(char *host, na_server_type_t server_type,
	char *user, char *password, na_server_transport_t t,
	na_style_t style, int port, char *vfiler_name)
{
	na_server_t *		s;

	/*
	 * vfiler tunneling only works with apitest versions 1.7 and above
	 */
	if (vfiler_name != NULL) 
		s = na_server_open(host, 1, 7);
	else	
		s = na_server_open(host, 1, 0);

	if (0 == s) {
		fprintf(stderr, "na_server_open failed\n");
		exit(1);
	}

	na_server_style(s, style);

	//When host equiv is enabled,
	//do not set user name and passwd 
	if(style != NA_STYLE_HOSTSEQUIV && style != NA_STYLE_CERTIFICATE){
		na_server_adminuser(s, user, password);
	}
	
	na_server_set_server_type(s, server_type);

	if (vfiler_name != NULL) {
		int retval;
		retval = na_server_set_vfiler(s,vfiler_name);
		if (!retval) {
			exit(1);
		}	
	}	
	na_server_set_transport_type(s, t, 0);
	na_server_set_port(s, port);
		
	return s;
}

//============================================================//

char *
read_stdin()
{
	char *buff;
	int buffinc = 512;
	int buffsize;
	int buffsofar;
	char *buffp;
	int c;

	buffsize = 0;

	buffsize = buffinc;
	buff = malloc(buffsize);
	if (buff == NULL) {
		fprintf(stderr,"Unable to allocate memory for buffer\n");
		exit(1);
	}
	buffp = buff;
	buffsofar = 0;

	while ( (c=fgetc(stdin)) != EOF ) {
		if ( (buffsofar+1) >= buffsize ) {
			/* We need more space */
			buffsize += buffinc;
			buff = realloc(buff,buffsize);
			buffp = buff + buffsofar;
		}
		if (buffp == NULL) {
			fprintf(stderr,"Fatal logic error, buffp "
				"shouldn't be NULL!\n");
			exit(1);
		}
		*buffp++ = c;
		buffsofar++;
	}
	*buffp = 0;
	return buff;
}

//============================================================//

void
do_one_api(na_server_t *s, char **argv, int showxml, int inputxml)
{
	const char*	key;
	const char*	value;
	na_elem_t*	input = NULL;
	na_elem_t*	output = NULL;
	int		parms;
	char*		api;
	char*		xmlout = NULL;
	char		values[1024];
	char*		tok;
	na_elem_t*	elem;
	int		freeapi = FALSE;

	if (showxml == 2) {
		na_server_set_debugstyle(s, NA_PRINT_DONT_PARSE);
	}

	if (inputxml > 0) {
		if (inputxml == 1) {
			api = *argv++;
		} else {
			api = read_stdin();
			freeapi = TRUE;
		}
		input = na_zapi_get_elem_from_raw_xmlinput(api);
		if (input == NULL) {
			return;
		}
	}
	else {
		api = *argv++;
		//
		// if value is an array, 
		// Create an API element and load up the paramname-arg pairs
		// as child elements if there are any present.
		//
		parms = 0;
		input = na_elem_new(api);
		while ( *argv != NULL ) {
			key = *argv++;
			value = *argv++;
			//
			// if value is an array, make it so
			//
			// NOTE: the Unix command line strips out the quotes 
			// in "{ }", so this code needs to not look for them
			//
			if (value[0] == '{') {
				elem = na_elem_new(key);
				if (elem == NULL) {
					fprintf(stderr, "Error: couldn't "
						"create elem %s\n", key);
					exit(-2);
				}
				strncpy(values, value, 1024);
				values[1023] = 0;
				values[strlen(values)-1] = 0;	// get rid of '}'
				if (strlen(value) > 1023) {
					fprintf(stderr, 
						"Warning: values array is too long\n");
				}
				// tok = (char*) strtok(values+2, ",");
				tok = (char*) strtok(values+1, ", ");  // skip '{'
				while (tok) {
					//
					// the parsing code on the server side 
					// uses na_child_iterator to iterate
					// through children that we add here, so
					// no key is actually necessary.
					//
					//na_child_add_string(elem, key, tok);
					na_child_add_string(elem, "arg", tok);
					tok = (char*)strtok(NULL, ", ");
					if (tok == NULL || tok[0] == '}')
						break;
				}
				na_child_add(input, elem);
			}
			else {	
				//
				// a simple parameter
				//			
				if (value[0] == '@')
					na_child_add_string_encrypted(input,
						key, &value[1], NULL);
				else
					na_child_add_string(input, key, value);
			}
			parms += 2;
		}
	}


	//
	// Here is where the API is invoked
	//
	output = na_server_invoke_elem(s, input);
	if (output == NULL) {
		printf("Memory allocation error in na_server_invoke_elem\n");
		goto clean_up;
	}
	if (showxml == 0) {
		xmlout = na_elem_sprintf(output);
		printf("%s\n",xmlout);
	}
	else if (showxml == 1) {
		char *xmlinput = na_elem_sprintf(input);
		printf("INPUT:\n%s\n",xmlinput);
		na_free(xmlinput);

		printf("OUTPUT:\n");
		xmlout = na_elem_sprintf(output);
		printf("%s\n",xmlout);
	}
	else if ((showxml == 2) && (strcmp(na_results_reason(output), 
								"debugging bypassed xml parsing") != 0)) {
		printf("OUTPUT:\n");
		xmlout = na_elem_sprintf(output);
		printf("%s\n",xmlout);
	}

	//
	// Free up memory and close connection
	//
clean_up:
	if (freeapi == TRUE)
		free(api);
	if (xmlout != NULL)
		na_free(xmlout);
	if (output != NULL)
		na_elem_free(output);
	if (input != NULL)
		na_elem_free(input);
}

//============================================================//

int main(int argc, char **argv)
{
	char*		prog_name;
	char*		host;
	char*		user;
	char*		passwd;
	char		err[256];
	char*		server_type = NULL;
	char*		vfiler_name = NULL;
	int		error = FALSE;
	int		r = 0;
	char**		tmp = argv;
	int		num_parms = 0;
	na_server_transport_t transport;
	na_server_t *	s;
	na_style_t	apistyle;
	int		c;
	int 		use_port = -1;
	int		dofiler = 0;
	int		dovfiler = 0;
	int		dossl = 1;
	int		dodfm = 0;
	int		doocum = 0;
	int		doagent = 0;
	int		donetcache = 0;
	int		dorpc = 0;
	int		showxml = 0;
	int		inputxml = 0;
	int 		timeout_value = 0;
	int		set_timeout = 0;
	int		digits = 0;
	int		temp = 0;
	int 		host_eqiv = 0;
	int		use_cba = 0;
	int	need_server_cert_verification = 0;
	int	need_hostname_verification = 0;
	char*	cert_file = NULL;
	char*	key_file = NULL;
	char*	key_passwd = NULL;
	char*	ca_file = NULL;
	char*	originator_id = NULL;
	int	send_oid = 0;
	char*	remote_peer = NULL;
	int	do_remote_peering = 0;

	prog_name = *argv;

	while ( (c=getopt(argc,argv,"c:p:C:K:P:T:R:iIrnSt:v:o:z:xXhH")) != EOF ) {
		switch (c) {
		case 'C':
			use_cba = 1;
			dossl = 1;
			cert_file = optarg;
			break;
		case 'K':
			key_file = optarg;
			break;
		case 'P':
			key_passwd = optarg;
			break;
		case 'T':
			ca_file = optarg;
			break;
		case 'S':
			need_server_cert_verification = 1;
			break;
		case 'H':
			need_hostname_verification = 1;
			break;
		case 'i':
			inputxml = 1;
			break;
		case 'I':
			inputxml = 2;
			break;
		case 't':
			server_type = optarg;
			if (!strcasecmp(server_type, "dfm")) {

				dodfm = 1;
			}  else if (!strcasecmp(server_type, "ocum")) {

				doocum  = 1;
				dossl  = 1;
			}  else if (!strcasecmp(server_type, "agent")) {

				doagent = 1;
			}  else if (!strcasecmp(server_type, "netcache")) {
			
				donetcache = 1;
			}  else if (!strcasecmp(server_type, "filer")) {

				dofiler  = 1;
			}
			break;
		case 'v':
			vfiler_name = optarg;
			dovfiler = 1;
			break;
		case 'n':
			dossl = 0;
			break;
		case 'r':
#ifdef _WIN32
			dorpc = 1;
#else
			fprintf(stderr,
				"The -r option is only valid on Windows!\n");
			return (1);
#endif
			break;
		case 'p':
			use_port = atoi(optarg);
			if (use_port == 0) {
				fprintf(stderr, "Invalid port number provided: %s\n", optarg);
				return(1);
			}
			printf("Port used : %d\n", use_port);
			break;
		case 'x':
			showxml = 1;
			break;
		case 'X':
			showxml = 2;
			break;
		case 'c':
			 timeout_value = atoi(optarg);			 	 
			 temp = timeout_value;
			 do {
			 	temp = temp / 10;
				digits++;
			 }  while (temp > 0);
			 if(digits != strlen(optarg)){
				fprintf(stderr, "Invalid value for connection timeout: %s\n", optarg);
				return(1);
			 } else if(timeout_value <= 0){
				fprintf(stderr, "Invalid value for connection timeout."
					" Connection timeout value should be greater than 0.\n");
				return(1);
			 }
			 set_timeout = 1;
			 break;
		case 'h':
			 host_eqiv = 1;
			 break;
		case 'o':
			originator_id = optarg;
			send_oid = 1;
			break;
		case 'z':
			remote_peer = optarg;
			do_remote_peering = 1;
			break;
		case '?':
		default:
			fprintf(stderr,"Unrecognized option: %c\n",c);
			break;
		}
	}

	if((dodfm || doocum) && dovfiler) {
		fprintf(stderr,"The -v option is not a valid option for OnCommand Unified Manager server.\n");
		return (1);
	}

	if((dodfm || doocum) && dorpc) {
		fprintf(stderr,"The -r option is not a vaid option for OnCommand Unified Manager server.\n");
		return (1);
	}

	if((dodfm || doocum) && send_oid) {
		fprintf(stderr,"The -o option is not a vaid option for OnCommand Unified Manager server.\n");
		return (1);
	}

	if(host_eqiv && dorpc) {
		fprintf(stderr,"Invalid usage of authentication style. "
				"Do not use -r option and -h option together.\n");
		return (1);
	}
	if(dorpc && set_timeout) {
		fprintf(stderr,"Connection timeout value cannot be set for RPC authentication style.\n");
		return (1);
	}
	if (need_hostname_verification && !need_server_cert_verification) {
		fprintf(stderr, "Hostname verification cannot be enabled when "
				"server certificate verification is disabled.\n");
		return (1);
	}

	if (use_port == -1) {
		if ( dodfm )
			use_port = (dossl) ? 8488 : 8088;
		else if ( doagent )
			use_port = (dossl) ?  4093 : 4092;
		else if ( donetcache )
			use_port = (dossl) ? 443 : 80;
		else if ( doocum )
			use_port = 443;
		else
			use_port = (dossl) ? 443 : 80;
	}
	argv = &argv[optind];

	if (*argv == NULL) {
		fprintf(stderr, "Host not specified.\n");
		usage(prog_name);
		return(1);
	}
	host = *argv++;
	
	if(host_eqiv == 0 && use_cba == 0 && dorpc == 0) {
		if (*argv == NULL) {			
			fprintf(stderr, "User not specified.\n");
			usage(prog_name);
			return(1);			
		}
		user = *argv++;

		if (*argv == NULL) {			
			fprintf(stderr, "Password not specified.\n");
			usage(prog_name);
			return(1);
		}
		passwd = *argv++;
	}

	//
	// There's got to be at least one more argument, for the api,
	// except when we're using the -I option.
	//
	if (inputxml == 2) {
		// When using -I, no additional arguments are expected,
		// it all comes on stdin
		if (*argv != NULL) {
			fprintf(stderr, "The -I option expects no API "
				"on the command-line, "
				"it expects standard input\n");
			usage(prog_name);
			return(1);
		}
	} else {
		if (*argv == NULL) {
			fprintf(stderr, "API not specified.\n");
			usage(prog_name);
			return(1);
		}

		// 
		// Make sure there's an even number of arguments
		// after the api name
		//
		for (tmp=argv+1; *tmp != NULL; tmp++) {
			num_parms++;
		}
		if ((num_parms & 1) != 0 ) {
			fprintf(stderr, "Unexpected number of arguments - "
				"all parameters must be followed by arguments.\n");
			usage(prog_name);
			return(1);
		}
	}

	if (! na_startup(err,sizeof(err))) {
		fprintf(stderr,"Error in na_startup: %s\n.", err);
		return(1);
	}

	if (dossl) {
		transport = NA_SERVER_TRANSPORT_HTTPS;
	} else {
		transport = NA_SERVER_TRANSPORT_HTTP;
	}
	
	if ( dorpc ) {
		apistyle = NA_STYLE_RPC;
	}else if(host_eqiv){		
		apistyle = NA_STYLE_HOSTSEQUIV;
	}else if (use_cba) {
		apistyle = NA_STYLE_CERTIFICATE;
	}else{
		apistyle = NA_STYLE_LOGIN_PASSWORD;
	}

	//
	// This routine prepares for calling APIs on the host,
	// and gathers all the connection parameters,
	// but the actual connection is made for each API
	// (i.e. inside do_one_api()).
	//

	if (dodfm)  {

	s = make_server(host, NA_SERVER_TYPE_DFM,
			user, passwd, transport, apistyle, use_port, vfiler_name);
	} else if (doocum) {

	s = make_server(host, NA_SERVER_TYPE_OCUM,
			user, passwd, transport, apistyle, use_port, vfiler_name);
	} else if (doagent) {

	s = make_server(host, NA_SERVER_TYPE_AGENT,
			user, passwd, transport, apistyle, use_port, vfiler_name);
	} else if (donetcache) {

	s = make_server(host, NA_SERVER_TYPE_NETCACHE,
			user, passwd, transport, apistyle, use_port, vfiler_name);
	} else {

	s = make_server(host, NA_SERVER_TYPE_FILER,
			user, passwd, transport, apistyle, use_port, vfiler_name);
	}

	//Set the Timeout
	if(set_timeout == 1){
		na_server_set_timeout(s,timeout_value);
	}

	if(send_oid == 1){
		na_server_set_originator_id(s, originator_id);
	}

	if(do_remote_peering == 1){
		if(dovfiler == 1) {
			na_server_set_target_vserver_name(s, remote_peer);
		} else {
			na_server_set_target_cluster_uuid(s, remote_peer);
		}
	}

	if(use_cba) {
		na_server_set_client_cert_and_key(s, cert_file, key_file, key_passwd);
	}
	if (dossl || need_server_cert_verification) {
		if (!na_server_set_server_cert_verification(s, need_server_cert_verification)) {
			return (1);
		}
		if (need_server_cert_verification) {
			na_server_set_hostname_verification(s, need_hostname_verification);
		}
	}
	if(ca_file != NULL) {
		na_server_set_ca_certs(s, ca_file);
	}

	do_one_api(s, argv, showxml, inputxml);

	na_server_close(s);

	return 0;
}
