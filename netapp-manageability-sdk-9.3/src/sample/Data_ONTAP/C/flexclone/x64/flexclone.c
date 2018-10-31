//============================================================//
//                                                            //
//                                                            //
// flexclone.c                                                //
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
// Usage:                                                     //
//   This program is an example for flexclone feature,        //
//   It can create a clone for a flexible volume, It can      //
//   estimate the sixe, split it and can show the status.     //
//                                                            //
//============================================================//
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "netapp_api.h"

na_server_t*    s = NULL;

void printUsage()
{
		printf("Usage: flexclone <filer> <user> <password> <command>");
		printf(" <clone_volname> [<parent>]\n");
		printf(" <filer> - the name/ipaddress of the filer\n");
		printf(" <user>,<password> - User and password for remote");
		printf(" authentication\n");
		printf(" <command>-command to be executed. The possible value are:\n");
		printf("create - to create a new clone\n");
		printf("estimate - to estimate the size before spliting the clone\n");
		printf("split - to split the clone \n");
		printf("status - give the status of the clone\n");
		printf("<clone_volname> - desired name of the clone volume \n");
		printf("<parent> - name of the parent volume to create the clone.\n");
		printf("This option is only valid for \"create\" command\n");
}


/*
 * Function: createFlexClone
 * Description: Function to demostrate "vol-clone-create" api
 *			 to create a new flexclone.
 * Parameters: 
 *		clonename  - name of the clone
 *		parentclone - parent of the new clone
 * Return: 0 if successful otherwise a negative value
 */	
int createFlexClone( char* clonename, char* parentvol )
{
	na_elem_t* out = 
		na_server_invoke(s, "volume-clone-create","parent-volume"
			,parentvol,"volume",clonename,NULL);
	if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n",na_results_errno(out),na_results_reason(out));
		return -1;        
	}
	else {
		printf(" Creation of clone volume '%s' has completed\n");
	}

	/*
	 * free the resources used by the result of the call
	 */
	na_elem_free(out);

	return 0;	
}

/* 
 * Function: estimateCloneSplit
 * Description: Function to demostrate "volume-clone-split-estimate" api
 *			 to estimate the size for flexclone split
 * Parameters: 
 * 		clonename  - name of the clone
 * 		parentclone - parent of the new clone
 * Return: 0 if successful otherwise a negative value
 */
int estimateCloneSplit(char* clonename)
{
	na_elem_t* out = 
		na_server_invoke(s, "volume-clone-split-estimate", "volume"
				,clonename,NULL);
	if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n",na_results_errno(out),na_results_reason(out));
		return -2;        
	}
	else {
		na_elem_t* clone_split_estimate = NULL;
		na_elem_t* clone_split_estimate_info = NULL;
		unsigned long  blk_estimate = 0;
		unsigned long space_req_in_mb = 0;

		clone_split_estimate = na_elem_child(out, "clone-split-estimate");

		if(clone_split_estimate != NULL) {
			clone_split_estimate_info =	na_elem_child(clone_split_estimate, "clone-split-estimate-info");
			if(clone_split_estimate_info != NULL) {
				blk_estimate = na_child_get_int(clone_split_estimate_info,"estimate-blocks", 0);
			}
		}
		/*
		 * block estimate is given in no of 4kb blocks required 
		 */
		 space_req_in_mb = (unsigned long)((blk_estimate * 4)/1024);
		printf("An estimated %lu MB available storage is required in the aggregate to split clone volume '%s' from its parent.\n",space_req_in_mb,clonename);	
	}

	/*
	 * free the resources used by the result of the call
	 */
	na_elem_free(out);
	return 0;
}

/*
 * Function: startCloneSplit
 * Description: Function to demostrate using "volume-clone-split-start" 
 *			 api to split a flexclone
 * Parameters: 
 *		clonename  - name of the clone
 * Return: 0 if successful otherwise a negative value
 */
int startCloneSplit(char* clonename)
{
	na_elem_t* out = 
		na_server_invoke(s,"volume-clone-split-start","volume",clonename,NULL);
	if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n",na_results_errno(out),na_results_reason(out));
		return -3;        
	}
	else {
		printf("Starting volume clone split on volume '%s'.\n",clonename);
		printf("Use 'status' command to monitor progress\n");
	}

	/*	
	 * free the resources used by the result of the call
	 */
	na_elem_free(out);
	return 0;
}

/*
 * Function: cloneSplitStatus
 * Description: Function to demostrate using "volume-clone-split-status" 
 *			 api to query the progress of the flexclone split
 * Parameters: 
 * 		clonename  - name of the clone
 * Return: 0 if successful otherwise a negative value
 */
int cloneSplitStatus(char* clonename)
{
	int blk_scanned ;
	int blk_updated ;
	int inode_processed ;
	int inode_total ;
	int inode_per_complete ;
	char tmpCloneName[500] = {0};		
	na_elem_t* out =
		na_server_invoke(s,"volume-clone-split-status","volume"
				,clonename,NULL);
	if (na_results_status(out) != NA_OK) {
		printf("Error %d: %s\n",na_results_errno(out),na_results_reason(out));
		return -3;        
	}
	else {
		/*
		 * list the volumes from the result of the call
		 */
		na_elem_t*		clone_split_details = NULL;
		na_elem_t*		cloneStatus = NULL;
		na_elem_iter_t	iter;

		clone_split_details = na_elem_child(out, "clone-split-details");
		if ( clone_split_details != NULL) {

/* Retrieve the clone status parameters:
 *	blocks-scanned:
 *		integer - Number of the clone's blocks that have been scanned 
 *		to date by the split.  
 *	blocks-updated 
 *		integer -  Total number of the clone's blocks that have been 
 *		updated to date by the split. 
 *	inode-percentage-complete 
 *		integer -  Percent of the clone's inodes processed to date by 
 *		the split.  
 *	inodes-processed 
 *		integer - Number of the clone's inodes processed to date by the 
 *		split.
 *	inodes-total 
 *		integer -  Total number of inodes in the clone.  
 *	name 
 *		string -  Name of the clone being split.  
 */
		
			iter=na_child_iterator(clone_split_details);
			cloneStatus=na_iterator_next(&iter);


			if ((na_child_get_string(cloneStatus, "name")) != NULL) {
				strcpy(tmpCloneName, na_child_get_string(cloneStatus,"name"));
			}

			if( strcmp(clonename,tmpCloneName)==0 ) {
				blk_scanned = na_child_get_int(cloneStatus,
					"blocks-scanned",0);
				blk_updated = 
					na_child_get_int(cloneStatus,"blocks-updated",0);
				inode_processed =
					na_child_get_int(cloneStatus,"inodes-processed", 0);
				inode_total =
					na_child_get_int(cloneStatus,"inodes-total", 0);
				inode_per_complete = na_child_get_int(cloneStatus,
					"inode-percentage-complete",0);
		
				printf( "Volume '%s', %d of %d inodes processed (%d).\n%d blocks scanned. %d blocks updated.\n", clonename,inode_processed,inode_total, inode_per_complete,blk_scanned,blk_updated);
			
			}
		}
	}

	/*
	 * free the resources used by the result of the call
	 */
	na_elem_free(out);
	return 0;
}

int main(int argc, char* argv[])
{
	char            err[256];
	char*           filername = argv[1];
	char*           user = argv[2];     
	char*           passwd = argv[3];
	char*			command = argv[4];
	char*			clonename = argv[5];
	int ret = 0;
	/*
	 * Usage validation
	 */
	if (argc < 6 || argc > 7 ||  
		( argc == 7 && strcmp(command,"create")!=0 )) {
		printUsage();
		return -1;
	}
 
	/*
	 * Argument validations
	 */
	if ( !(strcmp(command,"create")==0 || strcmp(command,"estimate")==0 ||
			strcmp(command,"split")==0 || strcmp(command,"status")==0)) {
		printf("%s is not a valid command.\n",command);
		printUsage();
		return -1;
	}

	if ( strcmp(clonename,"") == 0 ||
		( strcmp(command,"create")==0 && strcmp(argv[6],"")==0 ) ) {
		printf("<clone_volname> and <parent> cannot be empty strings\n");
		printUsage();
		return -1;
	}
	/*
	 * One-time initialization of system on client
	 */
	if (!na_startup(err, sizeof(err))) {
		fprintf(stderr, "Error in na_startup: %s\n", err);
		return -2;
	}

	/*
	 * Initialize connection to server, and
	 * request version 1.1 of the API set.
	 */
	s = na_server_open(filername, 1, 1); 

	/*
	 * Set connection style (HTTP)
	 */
	na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
	na_server_adminuser(s, user, passwd);

	/*
	 * Execute the Filer command
	 */
	
	if ( strcmp(command,"create")==0 ) {
		ret = createFlexClone(clonename,argv[6]);
	}
	
	if ( strcmp(command,"estimate")==0 ) {
		ret = estimateCloneSplit(clonename);
	}
	
	if (strcmp(command,"split")==0 ) {
		ret = startCloneSplit(clonename);
	}
	
	if ( strcmp(command,"status")== 0 ) {
		ret = cloneSplitStatus(clonename);
	}

	na_server_close(s);
	na_shutdown();
 
	return ret;
}

