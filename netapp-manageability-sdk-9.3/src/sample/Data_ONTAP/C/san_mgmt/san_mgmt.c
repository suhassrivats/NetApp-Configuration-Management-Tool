//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// san_mgmt.c                                                 //
//                                                            //
// Application which uses ONTAPI APIs to perform SAN          //
// management operations for lun/igroup/fcp/iscsi             //
//                                                            //
// Copyright 2003 Network Appliance, Inc. All rights          //
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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "netapp_api.h"
//============================================================//

#define MAX_ARGS 25

typedef struct iscsi_portal_address
{
	int id;
	char inet_address[15];
	int port;
}iscsi_portal_address;

typedef struct iscsi_config_adapter
{
	char name[25];
	iscsi_portal_address iscsi_pa;
	char state[10];
	char status[100];
}iscsi_config_adapter;

typedef struct iscsi_connected_initiators
{
	char initiator_name[256];
	char isid[20];
	int portal_group_id;
}iscsi_connected_initiators;

typedef struct iscsi_adapter_initiators
{
	char name[25];
	iscsi_connected_initiators iscsi_ci;
}iscsi_adapter_initiators;

typedef struct iscsi_interface_list_info
{
	char name[25];
	char is_enabled[10];
	char tpgroup_name[25];
	int tpgroup_tag;
}iscsi_interface_list_info;

//helper function which safely copies the source string into
//the destination string
char* safestrcpy(char* dst, const char* src) {
	if(dst != NULL) {
		if(src != NULL) {
			strcpy(dst, src);
		}
		else
			dst[0] = 0;
	}
	return dst;
}

//helper function which safely compares the string s1 to the string s2.
//returns 0 if both strings are equal
int safestrcmp(const char* s1, const char* s2) {
	if (s1 == NULL) {
		return -1;
	}
	return ((strcmp(s1,s2)));
}

// list of Usage fuctions

void printUsage() {
	fprintf(stderr, "Usage: san_mgmt <filer> <user> <password> <command> \n");
	fprintf(stderr, "<filer>	  -- Name/IP address of the filer \n");
	fprintf(stderr, "<user> 	  -- User name\n");
	fprintf(stderr, "<password>   -- Password\n\n");
	fprintf(stderr, "Possible commands are:\n");
	fprintf(stderr, "lun  igroup  fcp  iscsi\n\n");
}

void printLUNUsage() {
	fprintf(stderr, "Usage: san_mgmt <filer> <user> <password> lun");
	fprintf(stderr,	" <command> \n\n");
	fprintf(stderr, "Possible commands are:\n");
    	fprintf(stderr, "create  destroy  show  clone  map  unmap  show-map\n");
}

void printCloneUsage() {
	fprintf(stderr, "Usage: san_mgmt <filer> <user> <password> lun clone");
	fprintf(stderr,	" <command> \n\n");
	fprintf(stderr, "Possible commands are:\n");
	fprintf(stderr, "create  start  stop  status\n");
}

void printIGroupUsage() {
	fprintf(stderr, "Usage: san_mgmt <filer> <user> <password> igroup");
	fprintf(stderr,	" <command> \n\n");
	fprintf(stderr, "Possible commands are: \n");
	fprintf(stderr, "create  add  destroy  show \n");
}

void printFCPUsage() {
	fprintf(stderr, "Usage: san_mgmt <filer> <user> <password> fcp");
	fprintf(stderr,	" <command> \n\n");
	fprintf(stderr, "Possible commands are: \n");
	fprintf(stderr, "start  stop  status  config  show  stats\n");
}

void printFCPConfigUsage() {
	fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> ");
	fprintf(stderr,"fcp config <adapter> < [ up | down ] ");
	fprintf(stderr,"[ mediatype { ptp | auto | loop } ] ");
	fprintf(stderr,"[ speed { auto | 1 | 2 | 4 } ] >\n");
}

void printISCSIUsage() {
	fprintf(stderr, "Usage: san_mgmt <filer> <user> <password> iscsi");
	fprintf(stderr,	" <command> \n\n");
	fprintf(stderr, "Possible commands are: \n");
	fprintf(stderr, "start  stop  status  interface  ");
	fprintf(stderr, "portal  adapter  show \n");
}

void printISCSIInterfaceUsage() {
   	fprintf(stderr, "Usage: san_mgmt <filer> <user> <password> iscsi");
	fprintf(stderr,	" interface <command> \n\n");
	fprintf(stderr, "Possible commands are: \n");
	fprintf(stderr, "enable  disable  show\n");
}

void printISCSIAdapterUsage() {
   	fprintf(stderr, "Usage: san_mgmt <filer> <user> <password> iscsi");
	fprintf(stderr,	" adapter <command> \n\n");
	fprintf(stderr, "Possible commands are: \n");
	fprintf(stderr, "show show-initiators \n");
}

//process clone operation
int processClone(int argc, char *argvBuff[],na_server_t* s) {
	char*			operation = NULL;
	int				i = 0;
	int             index = 7;
	na_elem_t *in = NULL;
	na_elem_t *out = NULL;
	na_elem_t* outputElem = NULL;
	na_elem_t*		ss;
	na_elem_t * 		elem = 0;
	na_elem_t* next_elem=0;
	na_elem_iter_t	iter;

	if(argc == 6) {
		printCloneUsage();
        	return 0;
	}
	operation = argvBuff[6];

	if(!strcmp(operation,"create")) {
		if(argc < 10) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> lun ");
			fprintf(stderr,"clone create <parent-lun-path> <parent-snap> ");
			fprintf(stderr,"<path> [-sre <space-res-enabled>] \n");
		  	return -1;
		}
		in = na_elem_new("lun-create-clone");
		na_child_add_string(in, "parent-lun-path",argvBuff[index++]);
		na_child_add_string(in, "parent-snap",argvBuff[index++]);
		na_child_add_string(in, "path",argvBuff[index++]);

		if(!safestrcmp(argvBuff[index],"-sre"))	{
		  na_child_add_string(in,"space-reservation-enabled",argvBuff[++index]);
		}
		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
				printf("Error %d: %s\n", na_results_errno(out),
				na_results_reason(out));
				return -3;
		}
		else {
			printf("Operation successful!\n");
		}
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation,"start")) {
		if(argc < 8) {
		  fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> lun ");
		  fprintf(stderr,"clone start <lun-path> \n");
		  return -1;
		}
		in = na_elem_new("lun-clone-start");
		na_child_add_string(in, "path",argvBuff[index]);

		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
				printf("Error %d: %s\n", na_results_errno(out),
				na_results_reason(out));
				return -3;
		}
		else {
			printf("Operation successful!\n");
		}
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation,"stop")) {
		if(argc < 8) {
		  fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> lun ");
		  fprintf(stderr,"clone stop <lun-path> \n");
		  return -1;
		}
		in = na_elem_new("lun-clone-stop");
		na_child_add_string(in, "path",argvBuff[index]);

		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
				printf("Error %d: %s\n", na_results_errno(out),
				na_results_reason(out));
				return -3;
		}
		else {
			printf("Operation successful!\n");
		}
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation,"status")) {
		in = na_elem_new("lun-clone-status-list-info");
		if(!safestrcmp(argvBuff[index],"help")) {
                	fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> lun ");
			fprintf(stderr,"clone status [<lun-path>] \n");
                return -1;
		}
		if(argvBuff[index] != NULL) {
			na_child_add_string(in, "path",argvBuff[index]);
		}
		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			outputElem = na_elem_child(out, "clone-status");
			if (outputElem == NULL) {
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}
			printf("--------------------------------------------\n");

			for (iter = na_child_iterator(outputElem);
				(ss = na_iterator_next(&iter)) != NULL;  ) {
				if ((na_child_get_string(ss, "path"))!= NULL) {
						printf("path: %s\n",na_child_get_string(ss, "path"));
				}
				if ((na_child_get_string(ss, "blocks-completed"))!= NULL) {
					printf("size: %s\n",na_child_get_string(ss, "blocks-completed"));
				}
				if ((na_child_get_string(ss, "blocks-total"))!= NULL) {
					printf("online: %s\n",na_child_get_string(ss, "blocks-total"));
				}
				printf("------------------------------------------\n");
			}
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return 0;
		}
	}
	else {
        	printCloneUsage();
	        return -1;
    	}
}

//process LUN operation
int processLUN(int argc, char *argvBuff[],na_server_t* s) {
	char*			operation = NULL;
	int				i = 0;
	int             index = 6;
	na_elem_t *in = NULL;
	na_elem_t *out = NULL;
	na_elem_t* outputElem = NULL;
	na_elem_t*		ss;
	na_elem_t * 		elem = 0;
	na_elem_t* next_elem=0;
	na_elem_iter_t	iter;

	if(argc == 5) {
		printLUNUsage(); return 0;
	}

	operation = argvBuff[5];

	if(!strcmp(operation,"create")) {

		if(argc < 9) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> lun create ");
			fprintf(stderr,"<path> <size-in-bytes> <ostype> [-sre <space-res-enabled>] \n\n");
			fprintf(stderr,"space-res-enabled: true/false \n");
			fprintf(stderr,"ostype: solaris/windows/hpux/aix/linux/vmware.\n");
			return -1;
		}
		in = na_elem_new("lun-create-by-size");
		na_child_add_string(in, "path",argvBuff[index++]);
		na_child_add_int(in, "size",atoi(argvBuff[index++]));
		na_child_add_string(in,"type",argvBuff[index++]);

		if(!safestrcmp(argvBuff[index],"-sre")) {
			na_child_add_string(in,"space-reservation-enabled",argvBuff[++index]);
			++index;
		}
		
		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Operation successful!\n");
		}

		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation,"destroy")) {
		if((argc < 7) || (argc == 7 && !safestrcmp(argvBuff[6],"-f"))) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> lun destroy ");
			fprintf(stderr,"[-f] <lun-path> \n\n");
			fprintf(stderr,"If -f is used, the LUN specified would be deleted ");
			fprintf(stderr, "even in online and/or mapped state.\n");
			return -1;
		}

		in = na_elem_new("lun-destroy");
		if(!safestrcmp(argvBuff[index],"-f")) {
			na_child_add_string(in,"force","true");
			index++;
		}

		na_child_add_string(in,"path",argvBuff[index]);
		out = na_server_invoke_elem(s,in);

		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Operation successful!\n");
		}
		na_server_close(s);
		na_shutdown();
		return 0;

	}
	else if(!strcmp(operation,"show")) {

		if(!safestrcmp(argvBuff[index],"help")) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> ");
			fprintf(stderr, "lun show [<lun-path>]\n");
			return -1;
		}
		in = na_elem_new("lun-list-info");

		if(argvBuff[index] != NULL)	{
			na_child_add_string(in, "path",argvBuff[index]);
		}

		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			outputElem = na_elem_child(out, "luns");
			if (outputElem == NULL) {
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}
			printf("--------------------------------------------\n");

			for (iter = na_child_iterator(outputElem);
				(ss = na_iterator_next(&iter)) != NULL;  ) {

				if ((na_child_get_string(ss, "path"))!= NULL) {
						printf("path: %s\n",na_child_get_string(ss, "path"));
				}

				if ((na_child_get_string(ss, "size"))!= NULL) {
					printf("size: %s\n",na_child_get_string(ss, "size"));
				}
				if ((na_child_get_string(ss, "online"))!= NULL) {
					printf("online: %s\n",na_child_get_string(ss, "online"));
				}
				if ((na_child_get_string(ss, "mapped"))!= NULL) {
					printf("mapped: %s\n",na_child_get_string(ss, "mapped"));
				}
				if ((na_child_get_string(ss, "read-only"))!= NULL) {
					printf("read-only: %s\n",na_child_get_string(ss, "read-only"));
				}
				if ((na_child_get_string(ss, "staging"))!= NULL) {
					printf("staging: %s\n",na_child_get_string(ss, "staging"));
				}
				if ((na_child_get_string(ss, "share-state"))!= NULL) {
					printf("share-state: %s\n",na_child_get_string(ss, "share-state"));
				}
				if ((na_child_get_string(ss, "multiprotocol-type"))!= NULL) {
					printf("multiprotocol-type: %s\n",na_child_get_string(ss, "multiprotocol-type"));
				}
				if ((na_child_get_string(ss, "uuid"))!= NULL) {
					printf("uuid: %s\n",na_child_get_string(ss, "uuid"));
				}
				if ((na_child_get_string(ss, "serial-number"))!= NULL) {
					printf("serial-number: %s\n",na_child_get_string(ss, "serial-number"));
				}
				if ((na_child_get_string(ss, "block-size"))!= NULL) {
					printf("block-size: %s\n",na_child_get_string(ss, "block-size"));
				}
    			if ((na_child_get_string(ss, "is-space-reservation-enabled"))!= NULL) {
					printf("is-space-reservation-enabled: %s\n",na_child_get_string(ss, "is-space-reservation-enabled"));
				}
				printf("------------------------------------------\n");
				}
			}
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return 0;
	}
	else if(!strcmp(operation,"clone"))	{
		processClone(argc,argvBuff,s);
    }
	else if(!strcmp(operation, "map")) {

		if(argc < 8) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> lun map ");
			fprintf(stderr,"<initiator-group> <lun-path> [-f <force>] [-id <lun-id>]\n");
			return -1;
		}
		in = na_elem_new("lun-map");
		na_child_add_string(in, "initiator-group",argvBuff[index++]);
		na_child_add_string(in, "path",argvBuff[index++]);

	    if(!safestrcmp(argvBuff[index],"-f")) {
			na_child_add_string(in,"force",argvBuff[++index]);
			++index;
	    }

	    if(!safestrcmp(argvBuff[index],"-id")) {
			na_child_add_string(in,"lun-id",argvBuff[++index]);
			++index;
	    }
	    out = na_server_invoke_elem(s,in);
	    if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Operation successful!\n");
		}
		na_server_close(s);
		na_shutdown();
		return 0;
	}
    else if(!strcmp(operation, "unmap")) {
		na_elem_t *in = NULL;

		if(argc < 8) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> lun ");
			fprintf(stderr,"unmap <initiator-group> <lun-path>\n");
			return -1;
		}

		in = na_elem_new("lun-unmap");
		na_child_add_string(in, "initiator-group",argvBuff[index++]);
		na_child_add_string(in, "path",argvBuff[index++]);

		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
				printf("Error %d: %s\n", na_results_errno(out),
				na_results_reason(out));
				return -3;
		}
		else {
			printf("Operation successful!\n");
		}
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation, "show-map"))	{
		na_elem_t *in = NULL;
		char *value = NULL;

		if(argc < 7) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> ");
			fprintf(stderr,"lun show-map <lun-path>\n");
			return -1;
		}

		in = na_elem_new("lun-map-list-info");
		na_child_add_string(in, "path",argvBuff[index]);

		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			outputElem = na_elem_child(out, "initiator-groups");
			if (outputElem == NULL) {
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}
			printf("--------------------------------------------\n");

			for (iter = na_child_iterator(outputElem);
				(ss = na_iterator_next(&iter)) != NULL;  ) {

				value = (char *)na_child_get_string(ss, "initiator-group-name");
				if(value != NULL) {
					printf("initiator-group-name: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "initiator-group-type");
				if(value!= NULL) {
					printf("initiator-group-type: %s\n",value);
				}
	            value = (char *)na_child_get_string(ss, "initiator-group-os-type");
				if(value!= NULL) {
					printf("initiator-group-os-type: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "initiator-group-throttle-reserve");
				if(value!= NULL) {
					printf("initiator-group-throttle-reserve: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "initiator-group-throttle-borrow");
				if(value!= NULL) {
					printf("initiator-group-throttle-borrow: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "initiator-group-vsa-enabled");
				if(value!= NULL) {
					printf("initiator-group-vsa-enabled: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "initiator-group-alua-enabled");
				if(value!= NULL) {
					printf("initiator-group-alua-enabled: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "lun-id");
				if(value!= NULL) {
					printf("lun-id: %s\n",value);
				}
				printf("------------------------------------------\n");
			}
			na_server_close(s);
			na_shutdown();
			return 0;
		}
	}
    else {
		printLUNUsage();
	}
	return 0;
}

//process  igroup operation
int processIGroup(int argc, char *argvBuff[],na_server_t* s) {
	char*			operation = NULL;
	int				i = 0;
	int             index = 6;
	na_elem_t *in = NULL;
	na_elem_t *out = NULL;

	na_elem_t*      igroups = NULL;
	na_elem_t*		igroup = NULL;
	na_elem_iter_t	igiter;
	na_elem_t*      initiators = NULL;
	na_elem_t*		initiator = NULL;
	na_elem_iter_t	initer;

	if(argc == 5) {
		printIGroupUsage();
		return 0;
	}

	operation = argvBuff[5];

	if(!strcmp(operation, "create")) {

		if(argc < 8) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> ");
			fprintf(stderr,"igroup create <igroup-name> <igroup-type> ");
			fprintf(stderr,"[-bp <bind-portset>] [-os <os-type>]\n\n");
			fprintf(stderr,"igroup-type: fcp/iscsi\n");
			fprintf(stderr,"os-type: solaris/windows/hpux/aix/linux/vmware. ");
			fprintf(stderr,"If not specified, \"default\" is used.\n");
			return -1;
		}
		in = na_elem_new("igroup-create");
		na_child_add_string(in, "initiator-group-name",argvBuff[index++]);
		na_child_add_string(in, "initiator-group-type",argvBuff[index++]);

		if(!safestrcmp(argvBuff[index],"-bp")) {
			na_child_add_string(in,"bind-portset",argvBuff[++index]);
			++index;
		}
		if(!safestrcmp(argvBuff[index],"-os")) {
			na_child_add_string(in,"os-type",argvBuff[++index]);
			++index;
		}

		out = na_server_invoke_elem(s,in);

		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Operation successful!\n");
		}

		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation, "add")) {

		if((argc < 8) || ((argc == 8) && (!strcmp(argvBuff[6],"-f")))) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> ");
			fprintf(stderr,"igroup add [-f] <igroup-name> <initiator>");
			fprintf(stderr,"\n-f: forcibly add the initiator, disabling mapping ");
			fprintf(stderr,"and type conflict checks with the cluster partner.\n");
			return -1;
		}

		in = na_elem_new("igroup-add");

		if(!safestrcmp(argvBuff[index],"-f")) {
			++index;
			na_child_add_string(in,"force","true");
		}
		na_child_add_string(in, "initiator-group-name",argvBuff[index++]);
		na_child_add_string(in, "initiator",argvBuff[index++]);

		out = na_server_invoke_elem(s,in);

		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Operation successful!\n");
		}

		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation, "destroy")) {

		if((argc < 7) || ((argc == 7) && (!strcmp(argvBuff[6],"-f")))) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> igroup ");
			fprintf(stderr,"destroy [-f] <igroup-name>\n");
			fprintf(stderr,"\n-f: forcibly destroy the initiator group, even if ");
			fprintf(stderr,"there are existing lun maps.\n");
			return -1;
		}

		if(!safestrcmp(argvBuff[index],"-f")) {
			++index;
			na_child_add_string(in,"force","true");
		}
		in = na_elem_new("igroup-destroy");
		na_child_add_string(in, "initiator-group-name",argvBuff[index]);

		out = na_server_invoke_elem(s,in);

		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Operation successful!\n");
		}

		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation, "show"))	{
		na_elem_t *in = NULL;
		char *value = NULL;

    	if(!safestrcmp(argvBuff[index],"help")) {
		  fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> ");
          fprintf(stderr,"igroup show [<igroup-name>]\n");
		  return -1;
		}

		in = na_elem_new("igroup-list-info");

		if(argvBuff[index] != NULL) {
		  na_child_add_string(in,"initiator-group-name",argvBuff[index++]);
		}

		out = na_server_invoke_elem(s,in);

		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			igroups = na_elem_child(out, "initiator-groups");
			if (igroups == NULL) {
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}

			printf("----------------------------------------------------\n");

			for (igiter = na_child_iterator(igroups);
			(igroup = na_iterator_next(&igiter)) != NULL;  ) {
				value = (char *)na_child_get_string(igroup, "initiator-group-name");
				if(value != NULL) {
					printf("name: %s\n",value);
				}
				value = (char *)na_child_get_string(igroup, "initiator-group-type");
				if(value!= NULL) {
					printf("type: %s\n",value);
				}
				value = (char *)na_child_get_string(igroup, "initiator-group-os-type");
				if(value!= NULL) {
					printf("os-type: %s\n",value);
				}
				value = (char *)na_child_get_string(igroup, "initiator-group-throttle-reserve");
				if(value!= NULL) {
					printf("throttle-reserve: %s\n",value);
				}
				value = (char *)na_child_get_string(igroup, "initiator-group-throttle-borrow");
				if(value!= NULL) {
					printf("throttle-borrow: %s\n",value);
				}
				value = (char *)na_child_get_string(igroup, "initiator-group-vsa-enabled");
				if(value!= NULL) {
							printf("vsa-enabled: %s\n",value);
				}
				value = (char *)na_child_get_string(igroup, "initiator-group-alua-enabled");
				if(value!= NULL) {
					printf("alua-enabled: %s\n",value);
				}
                initiators = na_elem_child(igroup,"initiators");
                if(initiators != NULL) {
                    //initiators = na_elem_child(initiators,"initiator-info");
                    if(initiators != NULL) {
                        printf("initiators:\n");
                        for (initer = na_child_iterator(initiators);
			            (initiator = na_iterator_next(&initer)) != NULL;  ) {
				            value = (char *)na_child_get_string(initiator, "initiator-name");
				            printf("  %s\n",value);
                        }
                        printf("\n");
                    }
                }
     			printf("--------------------------------------------------\n");
		}
		na_server_close(s);
		na_shutdown();
		return 0;
		}
	}
	else {
		printIGroupUsage();
	}
	return 0;
}

//process FCP operation
int processFCP(int argc, char *argvBuff[],na_server_t* s) {

	char*			operation = NULL;
	int				i = 0;
    int             index = 7;
	na_elem_t *in = NULL;
	na_elem_t *out = NULL;

	na_elem_t* outputElem = NULL;
	na_elem_t*		ss = NULL;
	na_elem_t * 		elem = 0;
	na_elem_t* next_elem=0;
	na_elem_iter_t	iter;

	if(argc == 5) {
        printFCPUsage();
        return -1;
	}

	operation = argvBuff[5];

    if(!strcmp(operation, "show")) {
		na_elem_t *in = NULL;
		char *value = NULL;
		index = 6;

	    if(!safestrcmp(argvBuff[index],"help")) {
	        fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> ");
	        fprintf(stderr,"fcp show [<fcp-adapter>] \n");
	        return -1;
	    }

		in = na_elem_new("fcp-adapter-list-info");

	    if(argvBuff[index] != NULL) {
	        na_child_add_string(in,"fcp-adapter",argvBuff[index]);
	    }
	    out = na_server_invoke_elem(s,in);

	    if (na_results_status(out) != NA_OK) {
				printf("Error %d: %s\n", na_results_errno(out),
				na_results_reason(out));
				return -3;
		}
	    else {
			outputElem = na_elem_child(out, "fcp-config-adapters");
			if (outputElem == NULL) {
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}
			printf("--------------------------------------------\n");

			for (iter = na_child_iterator(outputElem);
				(ss = na_iterator_next(&iter)) != NULL;  ) {
				  value = (char *)na_child_get_string(ss, "adapter");
				if(value != NULL) {
					printf("adapter: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "node-name");
				if(value!= NULL) {
					printf("node-name: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "port-name");
				if(value!= NULL) {
					printf("port-name: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "port-address");
				if(value!= NULL) {
					printf("port-address: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "adapter-type");
				if(value!= NULL) {
					printf("adapter-type: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "media-type");
				if(value!= NULL) {
					printf("media-type: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "partner-adapter");
				if(value!= NULL) {
					printf("partner-adapter: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "standby");
				if(value!= NULL) {
					printf("standby: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "speed");
				if(value!= NULL) {
					printf("speed: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "fabric-established");
				if(value!= NULL) {
					printf("fabric-established: %s\n",value);
				}
				printf("------------------------------------------\n");
			}
			na_server_close(s);
			na_shutdown();
			return 0;
		}
	}
	else if(!strcmp(operation, "stats")) {
	    na_elem_t *in = NULL;
	    char *value = NULL;
	    int index  = 6;

		if(!safestrcmp(argvBuff[6],"help")) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> fcp stats [<fcp-adapter>] \n");
			return -1;
		}
		in = na_elem_new("fcp-adapter-stats-list-info");

		if(argvBuff[index] != NULL) {
			na_child_add_string(in,"fcp-adapter",argvBuff[index]);
		}

		out = na_server_invoke_elem(s,in);

		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			outputElem = na_elem_child(out, "fcp-adapter-stats");
			if (outputElem == NULL) {
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}

			printf("--------------------------------------------\n");

			for (iter = na_child_iterator(outputElem);
			(ss = na_iterator_next(&iter)) != NULL;  ) {

				value = (char *)na_child_get_string(ss, "adapter");
				if(value != NULL) {
					printf("adapter: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "adapter-resets");
				if(value!= NULL) {
					printf("adapter-resets: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "frame-overruns");
				if(value!= NULL) {
					printf("frame-overruns: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "frame-underruns");
				if(value!= NULL) {
					printf("frame-underruns: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "initiators-connected");
				if(value!= NULL) {
					printf("initiators-connected: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "link-breaks");
				if(value!= NULL) {
					printf("link-breaks: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "lip-resets");
				if(value!= NULL) {
					printf("lip-resets: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "queue-depth");
				if(value!= NULL) {
					printf("queue-depth: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "scsi-requests-dropped");
				if(value!= NULL) {
					printf("scsi-requests-dropped: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "spurious-interrupts");
				if(value!= NULL) {
					printf("spurious-interrupts: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "total-logins");
				if(value != NULL) {
					printf("total-logins: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "total-logouts");
				if(value != NULL) {
					printf("total-logouts: %s\n",value);
				}
				value = (char *)na_child_get_string(ss, "crc-errors");
				if(value != NULL) {
					printf("crc-errors: %s\n",value);
				}
				printf("------------------------------------------\n");
			}
			na_server_close(s);
			na_shutdown();
			return 0;
		}
	}
	else if(!strcmp(operation, "config")) {
		na_elem_t *in = NULL;

		if(argc < 8) {
			printFCPConfigUsage();
			return -1;
		}
		if(!safestrcmp(argvBuff[index],"up")) {
			in = na_elem_new("fcp-adapter-config-up");
			na_child_add_string(in, "fcp-adapter",argvBuff[6]);
		}
		else if(!safestrcmp(argvBuff[index],"down")) {
			in = na_elem_new("fcp-adapter-config-down");
			na_child_add_string(in, "fcp-adapter",argvBuff[6]);
		}
		else if(!safestrcmp(argvBuff[index],"mediatype")) {
			in = na_elem_new("fcp-adapter-config-media-type");
			na_child_add_string(in, "fcp-adapter",argvBuff[6]);
			na_child_add_string(in, "media-type",argvBuff[++index]);
		}
		else if(!safestrcmp(argvBuff[index],"speed")) {
			in = na_elem_new("fcp-adapter-set-speed");
			na_child_add_string(in, "fcp-adapter",argvBuff[6]);
			na_child_add_string(in, "speed",argvBuff[++index]);
		}
		else {
			printFCPConfigUsage();
			return -1;
		}
		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Operation successful!\n");
		}
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation, "start")) {
		na_elem_t *in = NULL;

		in = na_elem_new("fcp-service-start");
		out = na_server_invoke_elem(s,in);

		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Operation successful!\n");
		}
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation, "stop"))	{
		na_elem_t *in = NULL;

		in = na_elem_new("fcp-service-stop");
		out = na_server_invoke_elem(s,in);

		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Operation successful!\n");
		}
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation, "status")) {
		na_elem_t *in = NULL;
		na_elem_t *outputElem = NULL;
		char *value = NULL;

		in = na_elem_new("fcp-service-status");
		out = na_server_invoke_elem(s,in);

		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		value = (char *)na_child_get_string(out,"is-available");
		if(!strcmp(value,"true")) {
			printf("FCP service is running.\n");
		}
		else {
			printf("FCP service is not running.\n");
		}
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else {
		printFCPUsage();
		return 0;
	}
	return 0;
}

//process iSCSI interface operation
int processISCSIInterface(int argc, char *argvBuff[],na_server_t* s) {
	char*			operation = NULL;
	char*           value = NULL;
	int				i = 0;
	int index = 7;
	na_elem_t *in = NULL;
	na_elem_t *out = NULL;

	na_elem_t* outputElem = NULL;
	na_elem_t*		ss = NULL;
	na_elem_t * 		elem = 0;
	na_elem_t* next_elem=0;
	na_elem_iter_t	iter;

	if(argc < 7) {
		printISCSIInterfaceUsage();
		return -1;
	}

	operation = argvBuff[6];

	if(!strcmp(operation, "show")) 	{
		na_elem_t *in = NULL;

		if(!safestrcmp(argvBuff[index],"help")) {
	        fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> iscsi ");
	        fprintf(stderr,"interface show <interface-name> \n");
			return -1;
		}

		in = na_elem_new("iscsi-interface-list-info");
	 	if(argvBuff[index] != NULL) {
			na_child_add_string(in, "interface-name",argvBuff[index++]);
		}

		out = na_server_invoke_elem(s,in);

	    if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			iscsi_interface_list_info IL;
			outputElem = na_elem_child(out, "iscsi-interface-list-entries");

			if (outputElem == NULL) {
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}
			printf("------------------------------------------------------\n");
			for (iter = na_child_iterator(outputElem);
			(ss = na_iterator_next(&iter)) != NULL;  ) {
                safestrcpy(IL.name,na_child_get_string(ss,"interface-name"));
				safestrcpy(IL.is_enabled,na_child_get_string(ss,"is-interface-enabled"));
				safestrcpy(IL.tpgroup_name,na_child_get_string(ss,"tpgroup-name"));
				IL.tpgroup_tag = na_child_get_int(ss,"tpgroup-tag",-1);

				printf("interface-name:%s\n",IL.name);
				printf("is-interface-enabled:%s\n",IL.is_enabled);
				printf("tpgroup-name:%s\n",IL.tpgroup_name);
				printf("tpgroup-tag:%d\n",IL.tpgroup_tag);
				printf("----------------------------------------------------\n");
			}
		}
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation, "enable")) {
		na_elem_t *in = NULL;

		if(argc < 8) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> iscsi ");
			fprintf(stderr,"interface enable <interface-name> \n");
			return -1;
		}
		in = na_elem_new("iscsi-interface-enable");
		na_child_add_string(in, "interface-name",argvBuff[index++]);

        out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
				printf("Error %d: %s\n", na_results_errno(out),
				na_results_reason(out));
				return -3;
		}
		else {
			printf("Operation successful!\n");
		}
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation, "disable")) {
		na_elem_t *in = NULL;

		if(argc < 8) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> iscsi ");
			fprintf(stderr," interface disable <interface-name> \n");
			return -1;
		}
		in = na_elem_new("iscsi-interface-disable");
		na_child_add_string(in, "interface-name",argvBuff[index++]);

		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
				printf("Error %d: %s\n", na_results_errno(out),
				na_results_reason(out));
				return -3;
		}
		else {
			printf("Operation successful!\n");
		}
		na_server_close(s);
		na_shutdown();
		return 0;
	}
    else {
        printISCSIInterfaceUsage();
    }
    return 0;
}

//process iSCSI adapter operation
int processISCSIAdapter(int argc, char *argvBuff[],na_server_t* s) {
	char*			operation = NULL;
	char*           value = NULL;
	int				i = 0;
	int index = 7;
	na_elem_t *in = NULL;
	na_elem_t *out = NULL;

	na_elem_t* outputElem = NULL;
	na_elem_t*		ss = NULL;
	na_elem_t * 		elem = 0;
	na_elem_t* next_elem=0;
	na_elem_iter_t	iter;


	if(argc < 7) {
		printISCSIAdapterUsage();
        return -1;
	}

	operation = argvBuff[6];

	if(!strcmp(operation, "show")) {
		na_elem_t *in = NULL;
		int index = 7;

	if(!safestrcmp(argvBuff[index],"help")) {
		fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> iscsi ");
		fprintf(stderr, "adapter show [<adapter>]\n");
		return -1;
	}
	in = na_elem_new("iscsi-adapter-list-info");

	if(argvBuff[index] != NULL) {
		na_child_add_string(in, "iscsi-adapter",argvBuff[index++]);
	}

    out = na_server_invoke_elem(s,in);

    if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n", na_results_errno(out),
		na_results_reason(out));
		return -3;
	}
	else {
			iscsi_config_adapter CA;
			outputElem = na_elem_child(out, "iscsi-config-adapters");
			if (outputElem == NULL) {
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}

		printf("------------------------------------------------------\n");
		for (iter = na_child_iterator(outputElem);
			(ss = na_iterator_next(&iter)) != NULL;  ) {

			safestrcpy(CA.name,na_child_get_string(ss,"name"));
			safestrcpy(CA.state,na_child_get_string(ss,"state"));
			safestrcpy(CA.status,na_child_get_string(ss,"status"));

			printf("adapter-name:%s\nstate:%s\n",CA.name,CA.state);
			if(CA.status[0] !='\0') {
				printf("status:%s\n",CA.status);
			}

			if ((na_elem_child(ss, "portal-addresses"))!= NULL) {
				na_elem_iter_t	piter;
				na_elem_t*		pelem;
				na_elem_t*      portal_elem;

				portal_elem = na_elem_child(ss, "portal-addresses");

				printf("portal addresses:\n");
				for (piter = na_child_iterator(portal_elem);
					(pelem = na_iterator_next(&piter)) != NULL;  ) {
						CA.iscsi_pa.id = na_child_get_int(pelem,"id",-1);
						safestrcpy(CA.iscsi_pa.inet_address,na_child_get_string(pelem,"inet-address"));
						CA.iscsi_pa.port = na_child_get_int(pelem,"port",-1);
						printf("\tportal id:%d\n\tip-address:%s\n\tport:%d\n\n",CA.iscsi_pa.id,CA.iscsi_pa.inet_address,CA.iscsi_pa.port);
				}
				printf("\n");
			}
			printf("----------------------------------------------------\n");
		}
	}
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation, "show-initiators")) {
		na_elem_t *in = NULL;
		int index = 7;

		if(!safestrcmp(argvBuff[index],"help")) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> iscsi ");
			fprintf(stderr, "adapter show-initiators [<adapter>]\n");
			return -1;
		}

		in = na_elem_new("iscsi-adapter-initiators-list-info");
	    if(argvBuff[index] != NULL) {
			na_child_add_string(in, "iscsi-adapter",argvBuff[index++]);
	    }

		out = na_server_invoke_elem(s,in);

	    if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
		    iscsi_adapter_initiators AI;

			outputElem = na_elem_child(out, "iscsi-adapters");
			if (outputElem == NULL) {
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}
			printf("------------------------------------------------------\n");
			for (iter = na_child_iterator(outputElem);
			(ss = na_iterator_next(&iter)) != NULL;  ) {
				safestrcpy(AI.name,na_child_get_string(ss,"name"));
				printf("adapter-name:%s\n",AI.name);

				if ((na_elem_child(ss, "iscsi-connected-initiators"))!= NULL) {
					na_elem_iter_t	piter;
					na_elem_t*		pelem;
					na_elem_t*      portal_elem;

					portal_elem = na_elem_child(ss, "iscsi-connected-initiators");

				  printf("iscsi-connected-initiators:\n");
					for (piter = na_child_iterator(portal_elem);
						(pelem = na_iterator_next(&piter)) != NULL;  ) {
							safestrcpy(AI.iscsi_ci.initiator_name,na_child_get_string(pelem,"initiator-name"));
							safestrcpy(AI.iscsi_ci.isid,na_child_get_string(pelem,"isid"));
							AI.iscsi_ci.portal_group_id = na_child_get_int(pelem,"portal-group-id",-1);
							printf("\tinitiator-name:%s\n\tisid:%s\n\tportal group id:%d\n\n",AI.iscsi_ci.initiator_name,AI.iscsi_ci.isid,AI.iscsi_ci.portal_group_id);
					}
				}
				printf("----------------------------------------------------\n");
			}
		}
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 0;
	}
    else {
        printISCSIAdapterUsage();
    }
    return 0;
}

//process iSCSI operation
int processISCSI(int argc, char *argvBuff[],na_server_t* s) {
	char*			operation = NULL;
	char*           value = NULL;
	int				i = 0;
	na_elem_t *in = NULL;
	na_elem_t *out = NULL;

	na_elem_t* outputElem = NULL;
	na_elem_t*		ss = NULL;
	na_elem_t * 		elem = 0;
	na_elem_t* next_elem=0;
	na_elem_iter_t	iter;

	if(argc == 5) {
		printISCSIUsage();
		return -1;
	}

    operation = argvBuff[5];

	if(!strcmp(operation, "interface")) {
      processISCSIInterface(argc,argvBuff,s);
	}
	else if(!strcmp(operation, "start")) {
		na_elem_t *in = NULL;
        in = na_elem_new("iscsi-service-start");

		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Operation successful!\n");
		}
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation, "stop"))	{
		na_elem_t *in = NULL;

		in = na_elem_new("iscsi-service-stop");
    	out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			printf("Operation successful!\n");
		}
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation, "status")) {
		na_elem_t *in = NULL;

		in = na_elem_new("iscsi-service-status");
        out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		outputElem = na_elem_child(out, "is-available");
		if(outputElem != NULL) {
			value = (char *)na_elem_get_content(outputElem);
		}
		if(!strcmp(value,"true")) {
            printf("iSCSI service is running.\n");
		}
		else {
			printf("iSCSI service is not running.\n");
		}
	    na_server_close(s);
	    na_shutdown();
	    return 0;
	}
	else if(!strcmp(operation, "portal")) {
        //only show is supported currently
		if((argc < 7) || (safestrcmp(argvBuff[6],"show")!=0)) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> ");
			fprintf(stderr,"iscsi portal <command> \n\n");
			fprintf(stderr,"Possible commands are: \nshow \n\n");
			return -1;
		}
		in = na_elem_new("iscsi-portal-list-info");
		out = na_server_invoke_elem(s,in);
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			outputElem = na_elem_child(out, "iscsi-portal-list-entries");
			if (outputElem == NULL) {
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}
			printf("----------------------------------------------------\n");

			for (iter = na_child_iterator(outputElem);
			(ss = na_iterator_next(&iter)) != NULL;  ) {

                printf("interface-name:%s\n",na_child_get_string(ss,"interface-name"));
				printf("ip-address:%s\n",na_child_get_string(ss,"ip-address"));
                printf("ip-address:%d\n",na_child_get_int(ss,"ip-port",-1));
			    printf("tpgroup-tag:%d\n",na_child_get_int(ss,"tpgroup-tag",-1));

				printf("----------------------------------------------------\n");
			}
		}
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else if(!strcmp(operation, "adapter")) {
      processISCSIAdapter(argc,argvBuff,s);
	}
	else if(!strcmp(operation,"show")) {
		if((argc < 7) || (safestrcmp(argvBuff[6],"initiator")!=0)) {
			fprintf(stderr,"Usage: san_mgmt <filer> <user> <password> ");
			fprintf(stderr,"iscsi show <command> \n\n");
			fprintf(stderr,"Possible commands are: \ninitiator\n\n");
			return -1;
		}
		in = na_elem_new("iscsi-initiator-list-info");
		out = na_server_invoke_elem(s,in);

		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
			return -3;
		}
		else {
			outputElem = na_elem_child(out, "iscsi-initiator-list-entries");
			if (outputElem == NULL) {
				na_elem_free(out);
				na_server_close(s);
				na_shutdown();
				return 0;
			}
			printf("----------------------------------------------------\n");
			for (iter = na_child_iterator(outputElem);
			(ss = na_iterator_next(&iter)) != NULL;  ) {
				printf("initiator-aliasname:%s\n",na_child_get_string(ss,"initiator-aliasname"));
				printf("initiator-nodename:%s\n",na_child_get_string(ss,"initiator-nodename"));
				printf("isid:%s\n",na_child_get_string(ss,"isid"));
				printf("target-session-id:%s\n",na_child_get_string(ss,"target-session-id"));
				printf("tpgroup-tag:%d\n",na_child_get_int(ss,"tpgroup-tag",-1));
				printf("----------------------------------------------------\n");
			}
		}
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return 0;
	}
	else {
		printISCSIUsage();
		return -1;
	}
	return 0;
}

int main(int argc, char* argv[]) {
	na_server_t*	s = NULL;
	char			err[256];
	char*			filername = argv[1];
	char*			user = argv[2];
	char*			passwd = argv[3];
	char*			command = NULL;
	char*			argvBuff[25];
  	int				i = 0;

	if (argc < 5) {
		printUsage();
		return -1;
	}

	command = argv[4];

	//this will simplify processing input arguments
	for(i = 0 ; i < MAX_ARGS; i++) {
		if(i < argc) {
			argvBuff[i] = argv[i];
		}
		else {
			argvBuff[i] = NULL;
		}
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

	//process the given command
	if(!strcmp(command,"lun")) {
		processLUN(argc,argvBuff,s);
	}
	else if(!strcmp(command,"igroup")) {
		processIGroup(argc,argvBuff,s);
	}
	else if(!strcmp(command,"fcp") !=0) {
		processFCP(argc,argvBuff,s);
	}
	else if(!strcmp(command,"iscsi") !=0) {
		processISCSI(argc,argvBuff,s);
	}
	else {
		printUsage();
	}
	return 0;
}

//============================================================//



