//================================================================//
//						                  //
// $Id: $							//
// snmp.c					        	  //
//								  //
// ONTAPI API Category: SNMP					  //
// Sample code for the following functionality:			  //
//		Add new SNMP community				  //
//		Delete specific SNMP community			  //
//		Delete all SNMP communities			  //
//		Disable SNMP interface				  //
//		Enable SNMP interface				  //
//		SNMP get for specific OID			  //
//		SNMP getnext for specific OID			  //
//		SNMP Status					  //
//		Disable Traps					  //
//		Enable Traps					  //
//		Add Trap Host					  //
//		Delete Trap Host				  //
//								  //	
//								  //
// This program demonstrates how to handle arrays		  //
//								  //
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
// Usage:							  //
// snmp <filer> <user> <password> <operation> [<value1>] [<value2>]//
// <filer> 	-- Name/IP address of the filer			  //
// <user>  	-- User name					  //
// <password> 	-- Password					  //
// <operation> 	-- addCommunity/deleteCommunity/deleteCommunityAll//
//		   snmpDisable/snmpEnable/snmpget/snmpgetnext/	  // 
//	     	   snmpStatus/trapDisable/trapEnable/addTrapHost  //
//	     	   deleteTrapHost 	  			  //
// <value1>	-- This depends on the operation		  //
// <value2> 	-- This depends on the operation		  //
//================================================================//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "netapp_api.h"
#include "snmp.h"

int main(int argc, char* argv[])
{
	int 		r = 1;
	na_server_t*	s;
	na_elem_t*		out;
	na_elem_t*		snmp;
	na_elem_t*		ss;
	na_elem_iter_t	iter;
	int 		neltsread = 0;
	char			err[256];
	char*			filername = argv[1];
	char*			user = argv[2]; 
	char*			passwd = argv[3];
	char* 			operation = argv[4];
	char*           	value1 = argv[5];
	char* 			value2 = argv[6];
	snmpInfoPtr info;
	snmpInfoPtr infoPtr;

	if (argc < 5) {
		fprintf(stderr, "Usage: snmp <filer> <user> <password>"); 
		fprintf(stderr,	" <operation> [<value1>] [<value2>]\n");
		fprintf(stderr, "<filer>      --"); 
		fprintf(stderr, "Name/IP address of the filer \n");
		fprintf(stderr, "<user>       -- User name\n");
		fprintf(stderr, "<password>   -- Password\n");
		fprintf(stderr, "<operation>  --"); 
		fprintf(stderr, " addCommunity/deleteCommunity/");
		fprintf(stderr, "deleteCommunityAll/snmpDisable\n");
		fprintf(stderr, "\t\tsnmpEnable/snmpget/");
		fprintf(stderr,	"snmpgetnext/snmpStatus/trapDisable/\n");
		fprintf(stderr, "\t\ttrapEnable/addTrapHost/");
		fprintf(stderr, "deleteTrapHost \n");
		fprintf(stderr, "<value1>\t-- This depends on the operation\n");
		fprintf(stderr, "<value2>\t-- This depends on the operation\n");
		return -1;
	}
	
	//
	// One-time initialization of system on client
	//
	
	if (!na_startup(err, sizeof(err))) {
		fprintf(stderr, "Error in na_startup: %s\n", err);
		return -2;
	}
	
	//
	// Initialize connection to server, and
	// request version 1.1 of the API set.
	//
	s = na_server_open(filername, 1, 1); 
	
	//
	// Set connection style (HTTP)
	//
	na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
	na_server_adminuser(s, user, passwd);

	//
	// Add new SNMP community
	// Usage: 
	// snmp <filer> <user> <password> addCommunity <access-control(ro/rw)> 
	// <community>
	//
	if(!strcmp(operation, "addCommunity"))
	{
		out = na_server_invoke(s, 
					"snmp-community-add", 
					"access-control", value1, 
					"community", value2, NULL);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Community added successfuly\n");
		}
		return 0;
	}

	//
	// Delete specific SNMP community
	// Usage: snmp <filer> <user> <password> deleteCommunity 
	// <access-control(ro/rw)> <community>
	//
	else if(!strcmp(operation, "deleteCommunity"))
	{
		out = na_server_invoke(s, "snmp-community-delete", 
			"access-control", value1, "community", value2, NULL);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Community deleted successfuly\n");
		}
		return 0;
	}

	//
	// Delete all SNMP communities
	// Usage: snmp <filer> <user> <password> deleteCommunityAll
	//
	else if(!strcmp(operation, "deleteCommunityAll"))
	{
		out = na_server_invoke(s, "snmp-community-delete-all", NULL);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Deleted all Communities successfuly\n");
		}
		return 0;
	}

	//
	// Disable SNMP interface
	// Usage: snmp <filer> <user> <password> snmpDisable
	//
	else if(!strcmp(operation, "snmpDisable"))
	{
		out = na_server_invoke(s, "snmp-disable", NULL);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Disabled SNMP interface\n");
		}
		return 0;
	}

	//
	// Enable SNMP interface
	// Usage: snmp <filer> <user> <password> snmpEnable
	//
	else if(!strcmp(operation, "snmpEnable"))
	{
		out = na_server_invoke(s, "snmp-enable", NULL);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Enabled SNMP interface\n");
		}
		return 0;
	}

	//
	// SNMP GET operation on specific Object Identifier. Only numeric OID's 
	// (ex: .1.3.6.1.4.1.789.1.1.1.0) are allowed.
	// Usage: snmp <filer> <user> <password> snmpget <ObjectIdentifier>
	//
	else if(!strcmp(operation, "snmpget"))
	{
		out = na_server_invoke(s, "snmp-get", "object-id", value1, NULL); 
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			snmp = na_elem_child(out, "value");
			if (snmp == NULL) {
				// Did not return any value
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 1;
			}

			//
			// Allocate memory for the retrieved object value
			//
			info = (snmpInfoPtr) malloc (sizeof(snmpInfo));
			if (info == NULL) {
				fprintf(stderr, 
					"Memory allocation err at line %d\n", 
					__LINE__);
				r = 0;
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}
			infoPtr = info;

			//
			// dig out the info
			//

			printf("--------------------------------------------\n");
	
			if ((na_child_get_string(out, "value")) != NULL)
			{
				strcpy(infoPtr->value, 
					na_child_get_string(out, "value"));
				printf("Value: %s\n", infoPtr->value);
			}

			if ((na_child_get_string(out, "is-value-hexadecimal")) 
				!= NULL)
			{
				strcpy(infoPtr->isValueHexadecimal, 
					na_child_get_string(out, 
							"is-value-hexadecimal"));
				printf("Is value hexadecimal: %s\n", 
					infoPtr->isValueHexadecimal);
			}
			printf("--------------------------------------------\n");
		}
		return 0;
	}

	//
	// SNMP GETNEXT operation on specific Object Identifier. 
	// Only numeric OID's (ex: .1.3.6.1.4.1.789.1.1.1.0) are allowed. 
	// Usage: snmp <filer> <user> <password> snmpgetnext <ObjectIdentifier>
	//
	else if(!strcmp(operation, "snmpgetnext"))
	{
		out = na_server_invoke(s, "snmp-get-next", "object-id", 
					value1, NULL);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
				na_results_reason(out));
			return -3;
		}
		else {
			snmp = na_elem_child(out, "next-object-id");
			if (snmp == NULL) {
				// Did not return any value
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 1;
			}

			//
			// Allocate memory for the retrieved object value
			//
			info = (snmpInfoPtr) malloc (sizeof(snmpInfo));
			if (info == NULL) {
				fprintf(stderr, 
					"Memory allocation err at line %d\n", 
					__LINE__);
				r = 0;
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}
			infoPtr = info;

			//
			// dig out the info
			//

			printf("--------------------------------------------\n");

			if ((na_child_get_string(out, "next-object-id")) != NULL)
			{
				strcpy(infoPtr->oid, 
					na_child_get_string(out, 
						"next-object-id"));
				printf("Object ID: %s\n", infoPtr->oid);
			}

			if ((na_child_get_string(out, "value")) != NULL)
			{
				strcpy(infoPtr->value, 
					na_child_get_string(out, "value"));
				printf("Value: %s\n", infoPtr->value);
			}

			if ((na_child_get_string(out, "is-value-hexadecimal")) 
				!= NULL)
			{
				strcpy(infoPtr->isValueHexadecimal, 
					na_child_get_string(out, 
						"is-value-hexadecimal"));
				printf("Is value hexadecimal: %s\n", 
					infoPtr->isValueHexadecimal);
			}
			printf("--------------------------------------------\n");
		}
		return 0;
	}

	//
	// SNMP status
	// Usage: snmp <filer> <user> <password> snmpStatus
	//
	else if(!strcmp(operation, "snmpStatus"))
	{
		out = na_server_invoke(s, "snmp-status", NULL);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			snmp = na_elem_child(out, "communities");
			if (snmp == NULL) {
				//Did not return any value
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 1;
			}

			//
			// Allocate memory
			//
			info = (snmpInfoPtr) malloc (sizeof(snmpInfo));
			if (info == NULL) {
				fprintf(stderr, 
					"Memory allocation err at line %d\n", 
					__LINE__);

				r = 0;
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}
			infoPtr = info;

			//
			// dig out the info
			//
			printf("--------------------------------------------\n");

			if ((na_child_get_string(out, "contact")) != NULL)
			{
				strcpy(infoPtr->contact, 
					na_child_get_string(out, "contact"));
				printf("Contact: %s\n", infoPtr->contact);
			}

			if ((na_child_get_string(out, "location")) != NULL)
			{
				strcpy(infoPtr->location, 
					na_child_get_string(out, "location"));
				printf("Location: %s\n\n", infoPtr->location);
			}

			if ((na_child_get_string(out,"is-trap-enabled")) != NULL)
			{
				strcpy(infoPtr->isTrapEnabled, 
					na_child_get_string(out, 
							"is-trap-enabled"));
				printf("Is Trap Enabled: %s\n", 
					infoPtr->isTrapEnabled);
			}

			printf("------------------------------------------\n\n");

			printf("\nAccess Control List:\n\n");

			for (iter = na_child_iterator(snmp);
			(ss = na_iterator_next(&iter)) != NULL;  ) {
				//
				// for each community, increase the size of the
				// array and use pointer arithmetic to get 
				// a pointer
				// to the last new and empty record
				//
				info = (snmpInfoPtr) realloc (info,
						(neltsread+1)*sizeof(snmpInfo));
				if (info == NULL) {
					fprintf(stderr, 
					"Memory allocation error at line %d\n",
						__LINE__);

					r = 0;
					na_elem_free(out);
					na_server_close(s);
					na_shutdown();
					return 0;
				}
				infoPtr = info + neltsread;

				//
				// dig out the info
				//

				if ((na_child_get_string(ss, "community")) 
					!= NULL)
				{
					strcpy(infoPtr->community, 
					na_child_get_string(ss, "community"));
					printf("Community String: %s\n", 
						infoPtr->community);
				}

				if ((na_child_get_string(ss, "access-control")) 
					!= NULL)
				{
					strcpy(infoPtr->accessControl, 
						na_child_get_string(ss, 
							"access-control"));
					printf("Access Control: %s\n", 
						infoPtr->accessControl);
				}

				printf("------------------------------------\n");

				neltsread++;
			}

			//
			// List out the trap hosts
			//
			snmp = na_elem_child(out, "traphosts");
			if (snmp == NULL) {
				// no trap host to list

				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 1;
			}

			//
			// Allocate memory for trap hosts
			//
			info = (snmpInfoPtr) malloc (sizeof(snmpInfo));
			if (info == NULL) {
				fprintf(stderr, 
					"Memory allocation err at line %d\n", 
					__LINE__);

				r = 0;
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}
			infoPtr = info;

			printf("\n\nTrap Hosts:\n\n");

			for (iter=na_child_iterator(snmp);
			(ss=na_iterator_next(&iter)) != NULL;  ) {
				//
				// for each trap host, increase the size of the
				// array and use pointer arithmetic to get a
				// pointer to the last new and empty record
				//
				info = (snmpInfoPtr) realloc (info,
					(neltsread+1)*sizeof(snmpInfo));
				if (info == NULL) {
					fprintf(stderr, 
					"Memory allocation error at line %d\n",
						__LINE__);

					r = 0;
					na_elem_free(out);
					na_server_close(s);
					na_shutdown();
					return 0;
				}
				infoPtr = info + neltsread;

				//
				// dig out the info
				//

				if ((na_child_get_string(ss, "host-name")) 
					!= NULL)
				{
					strcpy(infoPtr->hostName, 
					na_child_get_string(ss, "host-name"));
					printf("Host Name: %s\n", 
						infoPtr->hostName);
				}

				if ((na_child_get_string(ss, "ip-address")) 
					!= NULL)
				{
					strcpy(infoPtr->ipAddress, 
					na_child_get_string(ss, "ip-address"));
					printf("IP Address: %s\n", 
						infoPtr->ipAddress);
				}

				printf("------------------------------------\n");

				neltsread++;
			}
		}
		return 0;
	}

	//
	// Disable Trap
	// Usage: snmp <filer> <user> <password> trapDisable
	//
	else if(!strcmp(operation, "trapDisable"))
	{
		out = na_server_invoke(s, "snmp-trap-disable", NULL);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Disabled Traps\n");
		}
		return 0;
	}

	//
	// Enable Trap
	// Usage: snmp <filer> <user> <password> trapEnable
	//
	else if(!strcmp(operation, "trapEnable"))
	{
		out = na_server_invoke(s, "snmp-trap-enable", NULL);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Enabled Traps\n");
		}
		return 0;
	}

	//
	// Add trap host
	// Usage: snmp <filer> <user> <password> addTrapHost <hostName/IPAddress>
	//
	else if(!strcmp(operation, "addTrapHost"))
	{
		out = na_server_invoke(s, "snmp-traphost-add", "host", 
				value1, NULL);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Trap Host added successfuly\n");
		}
		return 0;
	}

	//
	// Delete trap host
	// Usage: 
	// snmp <filer> <user> <password> deleteTrapHost <host name/IP address>
	//
	else if(!strcmp(operation, "deleteTrapHost"))
	{
		out = na_server_invoke(s, "snmp-traphost-delete", 
				"host", value1, NULL);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
				na_results_reason(out));
			return -3;
		}
		else {
			printf("Trap Host deleted successfuly\n");
		}
		return 0;
	}
	
	else
	{
		fprintf(stderr, "Invalid operation\n");
		fprintf(stderr, 
			"--------------------------------------------------\n");
		fprintf(stderr,"Usage: <filer> <user> <password> <operation>");
		fprintf(stderr, " [<value1>] [<value2>]\n");
		fprintf(stderr, "<filer>\t-- Name/IP address of the filer \n");
		fprintf(stderr, "<user>\t-- User name\n");
		fprintf(stderr, "<password>   -- Password\n");
		fprintf(stderr, "<operation>  -- addCommunity/deleteCommunity/");
		fprintf(stderr, "deleteCommunityAll/snmpDisable\n");
		fprintf(stderr, "\t\tsnmpEnable/snmpget/snmpgetnext/snmpStatus");
		fprintf(stderr, "\n\t\ttrapDisable/trapEnable/addTrapHost/");
		fprintf(stderr, "deleteTrapHost \n");
		fprintf(stderr, "<value1>\t-- This depends on the operation\n");
		fprintf(stderr, "<value2>\t-- This depends on the operation\n");		
		return -1;
	}
	
	na_elem_free(out);
	na_server_close(s);
	na_shutdown();
	return 0;
		
}
