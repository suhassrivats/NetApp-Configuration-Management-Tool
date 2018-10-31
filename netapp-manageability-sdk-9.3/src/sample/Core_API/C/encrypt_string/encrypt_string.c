//================================================================//
//						                  //
// $Id:$                                                          //
// encrypt_string.c					       	  //
//								  //
// Demonstrates usage of na_child_add_string_encrypted() and	  //
//		na_child_get_string_encrypted() core APIs	  //
//								  //
// Copyright 2007 Network Appliance, Inc. All rights		  //
// reserved. Specifications subject to change without notice.     //
//								  //
// This SDK sample code is provided AS IS, with no support or 	  //
// warranties of any kind, including but not limited to 	  //
// warranties of merchantability or fitness of any kind,	  //
// expressed or implied.  This code is subject to the license     //
// agreement that accompanies the SDK.				  //
//								  //
//								  //
// Usage: encrypt_string <filer> <user> <password> <test-password>//
//================================================================//
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<netapp_api.h>
 
int main(int argc, char* argv[])
{
	na_server_t*    s;
	na_elem_t*      out, *req; 
	char            err[256];
	char*           filername = argv[1];
	char*           user = argv[2];
	char*           passwd = argv[3];
	char*           test_passwd = argv[4];
	char *          str = NULL;
	char*           verbuf = NULL;
	char*		dec_str = NULL;
 
	if (argc < 5) {
		fprintf(stderr,	"Usage: encrypt_string <filer> <user> <password> <test-password>\n");
		return -1;
	}
 
	// One-time initialization of system on client 
	if (!na_startup(err, sizeof(err))) {
	       fprintf(stderr, "Error in na_startup: %s\n", err);
	       return -2;
	}

	//Initialize connection to server, and
	//request version 1.1 of the API set.
	s = na_server_open(filername, 1, 1);
 
	// Set connection style (HTTP)
	na_server_style(s, NA_STYLE_LOGIN_PASSWORD); 
	na_server_adminuser(s, user, passwd);
 
	// Note: 'test-password-set' API is unsupported.
	// It's used here to demonstrate use 
	// na_child_add_string_encrypted(). 

	// 'test-password-set' is a test routine to test 
	// encrypted values.
	//
	// Input Name : password
	// Type		: string encrypted
	// Description	: Test password
	//
	// Output Name : decrypted-password
	// Type		: string
	// Description : Resulting decrypted password. 

 	req = na_elem_new("test-password-set");  

	// na_child_add_string_encrypted():	
	//
	//Creates a new element with key 'password' (second argument)
	//and value 'test_passwd' (third argument), encrypts data contained 
	//in value (third argument) with the encryption key (fourth argument) 
	//and adds the new element as a nested element of 'req' 
	//(first argument).
	//
	// Note : NULL is the *only* value that should be passed as the 
	// fourth argument.

 	na_child_add_string_encrypted(req,"password",test_passwd,NULL);  

	dec_str = na_child_get_string_encrypted(req,"password",NULL);
	if(dec_str == NULL) {
		dec_str = '\0';
	}
	printf("Expected decrypted password:%s\n\n",dec_str);

 	out = na_server_invoke_elem(s, req);
 
 	if (na_results_status(out) != NA_OK) {
 		printf("Error %d: %s\n", na_results_errno(out), 
					na_results_reason(out)); return -1;
 	} else {
 		str = na_elem_sprintf(out);
 		printf("Returned value : %s\n", str);
 	}
	//free the resources used by the result of the call  
	na_elem_free(out);
	na_free(dec_str);
 	na_server_close(s);
 	na_shutdown();
 	return 0;
}
