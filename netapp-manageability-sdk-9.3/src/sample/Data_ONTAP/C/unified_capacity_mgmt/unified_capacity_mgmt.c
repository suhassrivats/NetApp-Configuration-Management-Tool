//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// unified_capacity_mgmt.c                                    //
//                                                            //
// This sample code demonstrates the usage of ONTAPI APIs     //
// for doing capacity management for NetApp storage systems.  //
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
//                                                            //
//============================================================//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netapp_api.h>

#define RAID_OVERHEAD 1
#define WAFL_OVERHEAD 2
#define SYNC_MIRROR 3

#ifdef	WIN32
typedef		unsigned __int64	uint64_t;
#else
#if defined (linux)
#include <stdint.h>
#endif
#endif


_EXTERN uint64_t na_child_get_uint64(na_elem_t *, const char *,uint64_t);

//helper function which safely compares the string s1 to the string s2.
//returns 0 if both strings are equal
int safestrcmp(const char* s1, const char* s2)
{
	if (s1 == NULL) {
		return -1;
	}
	return ((strcmp(s1,s2)));
}


//print Usage function
void printUsage()
{
    fprintf(stderr, "Usage: unified_capacity_mgmt <filer> <user> <password> <command> \n");
    fprintf(stderr, "Possible commands are:\n");
    fprintf(stderr, "raw-capacity [<disk>]\n");
    fprintf(stderr, "formatted-capacity [<disk>]\n");
    fprintf(stderr, "spare-capacity \n");
    fprintf(stderr, "raid-overhead [<aggregate>]\n");
    fprintf(stderr, "wafl-overhead [<aggergate>]\n");
    fprintf(stderr, "allocated-capacity [<aggregate>]\n");
    fprintf(stderr, "provisioning-capacity [<aggregate>] \n");
    fprintf(stderr, "avail-user-data-capacity [-v <volume>] [-a <aggregate>] \n");
    fprintf(stderr, "\nNote: If no optional arguments are specified,");
    fprintf(stderr, " the command will output the value for the entire system \n");
}

//function to calculate either raw/formatted/spare capacity
 int calc_raw_fmt_spare_Capacity(int argc, char *argv[],na_server_t* s)
{
	char*           command = NULL;
	char*			raid_state = NULL;
	char            out_str[] = "total";
	int             index = 5;
	na_elem_t *in = NULL;
	na_elem_t *out = NULL;
	na_elem_t* outputElem = NULL;
	na_elem_t*		disk = NULL;
	na_elem_t * 		elem = 0;
	na_elem_t* next_elem=0;
	na_elem_iter_t	iter;
	na_elem_t*      disks = NULL;
	uint64_t total_raw_cap = 0;
	uint64_t total_format_cap = 0;
	uint64_t total_spare_cap = 0;

	command = argv[4];

	in = na_elem_new("disk-list-info");

	//check for disk option
	if(argc > 5) {
		//spare capacity should not have disk option
		if(!strcmp(command,"spare-capacity")) {
			printUsage();
			na_elem_free(in);
			return -1;
		}
		na_child_add_string(in, "disk",argv[index]);
		out_str[0] = '\0';
	}
	out = na_server_invoke_elem(s,in);
	if(na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n", na_results_errno(out),
		na_results_reason(out));
		na_elem_free(in);
    	na_elem_free(out);
		return -3;
	}
	disks = na_elem_child(out, "disk-details");
	if (disks  == NULL) {
		na_elem_free(in);
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return -3;
	}
	for (iter = na_child_iterator(disks);
        (disk = na_iterator_next(&iter)) != NULL;  ) {

		raid_state = (char *)na_child_get_string(disk, "raid-state");
		//calculate raw-capacity ?
		if(!strcmp(command,"raw-capacity")) {
			if (safestrcmp(raid_state,"broken") !=0) {
				total_raw_cap+= na_child_get_uint64(disk, "physical-space",0);
			}
		}
		//calculate formatted-capacity ?
		else if(!strcmp(command,"formatted-capacity")) {
			if (safestrcmp(raid_state,"broken") !=0) {
                total_format_cap+= na_child_get_uint64(disk, "used-space",0);
			}
		}
		//calculate spare-capacity ?
		else if(!strcmp(command,"spare-capacity")) {
			if (!safestrcmp(raid_state,"spare") || !safestrcmp(raid_state,"pending") 
				|| !safestrcmp(raid_state,"reconstructing")) {
				total_spare_cap+= na_child_get_uint64(disk, "used-space",0);
			}
		}
	}
	#ifdef WIN32
        if(!strcmp(command,"raw-capacity")) {
            printf("%s raw capacity (bytes): %I64u\n",out_str,total_raw_cap);
        }
        else if(!strcmp(command,"formatted-capacity")) {
             printf("%s format capacity (bytes): %I64u\n",out_str,total_format_cap);
        }
        else if(!strcmp(command,"spare-capacity")) {
            printf("%s spare capacity (bytes): %I64u\n",out_str,total_spare_cap);
        }
	#else
        if(!strcmp(command,"raw-capacity")) {
            printf("%s raw capacity(bytes): %llu\n",out_str,total_raw_cap);
        }
        else if(!strcmp(command,"formatted-capacity")) {
            printf("%s format capacity (bytes): %llu\n",out_str,total_format_cap);
        }
        else if(!strcmp(command,"spare-capacity")) {
            printf("%s spare capacity (bytes): %llu\n",out_str,total_spare_cap);
        }
	#endif
	na_elem_free(in);
	na_elem_free(out);
	na_server_close(s);
	na_shutdown();
	return 0;
}

//function to calculate the provisioning capacity
int calcProvisioningCapacity(int argc, char *argv[],na_server_t* s)
{
	char*           command = NULL;
	char            out_str[] = "total";
	int             index = 5;
	na_elem_t *in = NULL;
	na_elem_t *out = NULL;
	na_elem_t*      aggrs = NULL;
	na_elem_t*      aggr  = NULL;
	na_elem_iter_t	aiter;
	uint64_t total_prov_cap = 0;

	command = argv[4];

	in = na_elem_new("aggr-list-info");

	//check for aggregate option
	if(argc > 5) {
		na_child_add_string(in, "aggregate",argv[index]);
		out_str[0] = '\0';
	}
	out = na_server_invoke_elem(s,in);
	if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n", na_results_errno(out),
		na_results_reason(out));
		na_elem_free(in);
        na_elem_free(out);
		return -3;
	}
	aggrs = na_elem_child(out, "aggregates");
		if (aggrs  == NULL) {
			na_elem_free(in);
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return -3;
		}
	for (aiter = na_child_iterator(aggrs);
		(aggr = na_iterator_next(&aiter)) != NULL;  ) {
		total_prov_cap+= na_child_get_uint64(aggr, "size-available",0);
	}
	#ifdef WIN32
		printf("%s capacity usable for provisioning (bytes): %I64u\n",out_str,total_prov_cap);
	#else
		printf("%s capacity usable for provisioning (bytes): %llu\n",out_str,total_prov_cap);
	#endif

	na_elem_free(in);
	na_elem_free(out);
	na_server_close(s);
	na_shutdown();
	return 0;
}

//function to calculate the allocated capacity
int calcAllocatedCapacity(int argc, char *argv[],na_server_t* s)
{

	char*           command = NULL;
	char            out_str[] = "total";
	int             index = 5;
	na_elem_t *in = NULL;
	na_elem_t *out = NULL;
	na_elem_t*      aggrs = NULL;
	na_elem_t*      aggr  = NULL;
	na_elem_iter_t	aiter;
	uint64_t total_alloc_cap = 0;

	command = argv[4];

	in = na_elem_new("aggr-space-list-info");

	//check for aggregate option
	if(argc > 5) {
		na_child_add_string(in, "aggregate",argv[index]);
		out_str[0] = '\0';
	}
	out = na_server_invoke_elem(s,in);
	if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n", na_results_errno(out),
		na_results_reason(out));
		na_elem_free(in);
		na_elem_free(out);
		return -3;
	}
	aggrs = na_elem_child(out, "aggregates");
		if (aggrs  == NULL) {
			na_elem_free(in);
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return -3;
		}
	for (aiter = na_child_iterator(aggrs);
		(aggr = na_iterator_next(&aiter)) != NULL;  ) {
		total_alloc_cap+= na_child_get_uint64(aggr, "size-volume-allocated",0);
	}
	#ifdef WIN32
		printf("%s capacity allocated (bytes): %I64u\n",out_str,total_alloc_cap);
	#else
		printf("%s capacity allocated (bytes): %llu\n",out_str,total_alloc_cap);
	#endif

	na_server_close(s);
	na_shutdown();
	na_elem_free(in);
	na_elem_free(out);
	return 0;
}

//This function will get the size-available for the given volume
uint64_t getAvailVolSize(char *vol_name,na_server_t* s)
{
	char*           command = NULL;
	int             index = 5;
	na_elem_t *in = NULL;
	na_elem_t *out = NULL;
	na_elem_t*      volumes  = NULL;
	na_elem_t*      vol  = NULL;
	uint64_t total_avail_size = 0;

	in = na_elem_new("volume-list-info");
	na_child_add_string(in, "volume",vol_name);

	out = na_server_invoke_elem(s,in);
	if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n", na_results_errno(out),
		na_results_reason(out));
		na_elem_free(in);
		na_elem_free(out);
		return 0;
	}
	volumes = na_elem_child(out, "volumes");
	if (volumes == NULL) {
		na_elem_free(in);
		na_elem_free(out);
		return 0;
	}
	vol = na_elem_child(volumes,"volume-info");
	total_avail_size = na_child_get_uint64(vol, "size-available",0);
	return total_avail_size;
 }

// function to calculate the available user data capacity
int calcAvailUserDataCapacity(int argc, char *argv[],na_server_t* s)
{
	char*           command = NULL;
	char*           vol_name = NULL;
	char            out_str[] = "total";
	int             index = 5;
	na_elem_t *in = NULL;
	na_elem_t *out = NULL;
	na_elem_t*      volumes = NULL;
	na_elem_t*      vol  = NULL;
	na_elem_iter_t	viter;
	na_elem_t*      aggrs  = NULL;
	na_elem_t*      aggr  = NULL;
	uint64_t total_avail_udcap = 0;

	command = argv[4];


	//check for volume or aggregate option
	if(argc > 5) {
		if(argc < 7) {
		printUsage();
		return -1;
	}
	if(!safestrcmp(argv[index],"-v")) {
		in = na_elem_new("volume-list-info");
		na_child_add_string(in, "volume",argv[++index]);
	}
	else if(!safestrcmp(argv[index],"-a")) {
		in = na_elem_new("aggr-list-info");
		na_child_add_string(in, "aggregate",argv[++index]);
	}
	else {
		printUsage();
		return -1;
	}
	out_str[0] = '\0';
	}
	else {
		in = na_elem_new("volume-list-info");
	}

	out = na_server_invoke_elem(s,in);
	if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n", na_results_errno(out),
		na_results_reason(out));
		na_elem_free(in);
		na_elem_free(out);
		return -3;
	}
	if(!safestrcmp(argv[5],"-a")) {
		aggrs = na_elem_child(out, "aggregates");
		if (aggrs == NULL) {
			na_elem_free(in);
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return -3;
		}
		aggr = na_elem_child(aggrs,"aggr-info");
		if(aggr != NULL) {
			volumes = na_elem_child(aggr,"volumes");
			if(volumes != NULL) {
				for (viter = na_child_iterator(volumes);
				  (vol = na_iterator_next(&viter)) != NULL;  ) {
					vol_name = (char *) na_child_get_string(vol, "name");
					total_avail_udcap+=getAvailVolSize(vol_name,s);
				}
			}
		}
	}
	else {
		volumes = na_elem_child(out, "volumes");
		if (volumes == NULL) {
			na_elem_free(in);
			na_elem_free(out);
			na_server_close(s);
			na_shutdown();
			return -3;
		}
		for (viter = na_child_iterator(volumes);
			(vol = na_iterator_next(&viter)) != NULL;  ) {
			total_avail_udcap+= na_child_get_uint64(vol, "size-available",0);
		}
	}
	
	#ifdef WIN32
		printf("%s available user data capacity (bytes): %I64u\n",out_str,total_avail_udcap);
	#else
		printf("%s available user data capacity (bytes): %llu\n",out_str,total_avail_udcap);
	#endif

	na_elem_free(in);
	na_elem_free(out);
	na_server_close(s);
	na_shutdown();
	return 0;
}

//This function will get the used-space for the given disk
uint64_t getDiskUsedSpace(char* disk_name,int type,na_server_t* s)
{
    na_elem_t *in = NULL;
	na_elem_t *out = NULL;
    na_elem_t *disk = NULL;
    na_elem_t *disk_details = NULL;

    uint64_t used_space = 0;

    char* raid_type = NULL;

    in = na_elem_new("disk-list-info");
    na_child_add_string(in, "disk",disk_name);

	out = na_server_invoke_elem(s,in);
    if (na_results_status(out) != NA_OK) {
	    printf("Error %d: %s\n", na_results_errno(out),
		na_results_reason(out));
        na_elem_free(in);
        na_elem_free(out);
	    return 0;
	}
    disk_details = na_elem_child(out, "disk-details");
	if (disk_details  == NULL) {
        na_elem_free(in);
        na_elem_free(out);
	   	return 0;
	}
    disk = na_elem_child(disk_details, "disk-detail-info");
    if (disk  == NULL) {
        na_elem_free(in);
        na_elem_free(out);
	   	return 0;
	}
    raid_type = (char *)na_child_get_string(disk, "raid-type");

    if(type == RAID_OVERHEAD) {
        if (!safestrcmp(raid_type,"parity") || !safestrcmp(raid_type,"dparity")) {
            used_space = na_child_get_uint64(disk, "used-space",0);
        }
    }
    else if(type == WAFL_OVERHEAD) {
        if (!safestrcmp(raid_type,"data")) {
            used_space = na_child_get_uint64(disk, "used-space",0);
        }
    }
    else if(type == SYNC_MIRROR) {
        used_space = na_child_get_uint64(disk, "used-space",0);
    }
    na_elem_free(in);
    na_elem_free(out);

    return used_space;
}

//function to calculate either RAID or WAFL overlead
int calc_RAID_WAFL_Overhead(int argc, char *argv[],na_server_t* s)
{
	char*           command = NULL;
	char*           disk_name = NULL;
	char            out_str[] = "total";
	int             index = 5;
	char* raid_state = NULL;
	int operation        = 0;
	int numPlexes = 0;
	na_elem_t *in = NULL;
	na_elem_t *out = NULL;
	na_elem_t*      aggrs = NULL;
	na_elem_t*      aggr  = NULL;
	na_elem_iter_t	aiter;
	na_elem_t*      rgroups = NULL;
	na_elem_t*      rgroup  = NULL;
	na_elem_iter_t	riter;
	na_elem_t*      disks = NULL;
	na_elem_t*		disk = NULL;
	na_elem_iter_t	diter;
	na_elem_t*      plexes = NULL;
	na_elem_t*      plex = NULL;
	na_elem_iter_t	piter;
	uint64_t total_raid_oh = 0;
	uint64_t total_wafl_oh = 0;
	
	command = argv[4];

	//calculate raid-overhead ?
	if(!strcmp(command,"raid-overhead")) {
		operation = RAID_OVERHEAD;
	}
	if(!strcmp(command,"wafl-overhead")) {
		operation = WAFL_OVERHEAD;
	}

	in = na_elem_new("aggr-list-info");

	if(argc > 5) {
		na_child_add_string(in, "aggregate",argv[index]);
		out_str[0] = '\0';
	}
	na_child_add_string(in, "verbose","true");
	out = na_server_invoke_elem(s,in);
	if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n", na_results_errno(out),
		na_results_reason(out));
		na_elem_free(in);
		na_elem_free(out);
		return -3;
	}
	aggrs = na_elem_child(out, "aggregates");
	if (aggrs  == NULL) {
    	na_elem_free(in);
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
		return -3;
	}
	for (aiter = na_child_iterator(aggrs);
		(aggr = na_iterator_next(&aiter)) != NULL;  ) {
		plexes = na_elem_child(aggr,"plexes");
		if(plexes != NULL) {
			numPlexes = 0;
			for (piter = na_child_iterator(plexes);
				(plex = na_iterator_next(&piter)) != NULL;  ) {
				numPlexes++;
				rgroups = na_elem_child(plex,"raid-groups");
				if(rgroups != NULL) {
					for (riter = na_child_iterator(rgroups);
						(rgroup = na_iterator_next(&riter)) != NULL;  ) {
						disks = na_elem_child(rgroup,"disks");
						if(disks != NULL) {
							for (diter = na_child_iterator(disks);
								(disk = na_iterator_next(&diter)) != NULL;  ) {
								disk_name = (char *)na_child_get_string(disk, "name");
								if(operation == RAID_OVERHEAD) {
									if(numPlexes == 1) {
										total_raid_oh+= getDiskUsedSpace(disk_name,RAID_OVERHEAD,s);
									}
									else {
										//if numPlexes=2, then the disks belongs to sync mirror
										total_raid_oh+= getDiskUsedSpace(disk_name,SYNC_MIRROR,s);
									}
								}
								if(operation == WAFL_OVERHEAD) {
									total_wafl_oh+= getDiskUsedSpace(disk_name,WAFL_OVERHEAD,s);
								}
							}
						}
					}
				}
			}
		}
	}
    if(operation == RAID_OVERHEAD) {
        #ifdef WIN32
            printf("%s RAID overhead (bytes): %I64u\n",out_str,total_raid_oh);
        #else
            printf("%s RAID overhead (bytes): %llu\n",out_str,total_raid_oh);
        #endif
    }
    if(operation == WAFL_OVERHEAD) {
        #ifdef WIN32
            printf("%s WAFL overhead(bytes):%I64u\n",out_str,total_wafl_oh/10);
        #else
            printf("%s WAFL overhead(bytes):%llu\n",out_str,total_wafl_oh/10);
        #endif
    }
	na_elem_free(in);
	na_elem_free(out);
	na_server_close(s);
	na_shutdown();
	return 0;
}

int main(int argc, char* argv[])
{
	na_server_t*    s = NULL;
	char            err[256];
	char*           filername = argv[1];
	char*           user = argv[2];
	char*           passwd = argv[3];

	if (argc < 5) {
		printUsage();
		return -1;
	}

	if (!na_startup(err, sizeof(err))) {
		fprintf(stderr, "Error in na_startup: %s\n", err);
		return -2;
	}

	// Initialize connection to server, and
	// request version 1.1 of the API set.
	s = na_server_open(filername, 1, 1);

	// Set connection style (HTTP)
	na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
	na_server_adminuser(s, user, passwd);

	if(!strcmp(argv[4],"raw-capacity") ||
        !strcmp(argv[4],"formatted-capacity") ||
        !strcmp(argv[4],"spare-capacity")) {
		calc_raw_fmt_spare_Capacity(argc,argv,s);
    }
	else if(!strcmp(argv[4],"raid-overhead") ||
		!strcmp(argv[4],"wafl-overhead")) {
		calc_RAID_WAFL_Overhead(argc,argv,s);
	}
	else if(!strcmp(argv[4],"allocated-capacity")) {
		calcAllocatedCapacity(argc,argv,s);
	}
	else if(!strcmp(argv[4],"provisioning-capacity")) {
		calcProvisioningCapacity(argc,argv,s);
	}
	else if(!strcmp(argv[4],"avail-user-data-capacity")) {
		calcAvailUserDataCapacity(argc,argv,s);
    }
    else {
		printUsage();
    }
	return 0;
}
