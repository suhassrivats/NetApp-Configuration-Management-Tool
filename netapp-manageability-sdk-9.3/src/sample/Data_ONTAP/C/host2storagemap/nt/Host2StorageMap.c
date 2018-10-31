//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// Host2StorageMap.c										                      //
//                                                            //
// This application is used to get the CIFS or LUN map        //
// information for the given local drive 	                    //
//                                                            //
//                                                            //
// Copyright 2003 Network Appliance, Inc. All rights		      //
// reserved. Specifications subject to change without notice. // 
//                                                            //
// This SDK sample code is provided AS IS, with no support or //
// warranties of any kind, including but not limited to       //
// warranties of merchantability or fitness of any kind,      //
// expressed or implied.  This code is subject to the license //
// agreement that accompanies the SDK.                        //
//                                                            //  
//                                                            //
// Usage host2storagemap <drive-name>                         //
//                                                            //
// tab size = 2												                        //
//                                                            //
//															                              //
//============================================================//


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netapp_api.h>
#include "windows.h"
#include "scsiutil.h"


//============================================================//


//get the CIFS share information for the local device name
int getNetworkShareInfo(const char *localDevice, char *remoteServer,char *remoteShare);



/********************************************************************
 Name:         getNetworkShareInfo 
 Description:  get the CIFS share information for the local device name
 Parameters:
      IN:      local device name 
      OUT:     remote server and remote share
 Return value: 1 iff able to get the share Info, else 0
 ********************************************************************/

int getNetworkShareInfo(const char *localDevice, char *remoteServer,char *remoteShare)
{
	
	
	DWORD retValue;

	char remotePath[100];
	char errString[100];
  char *ptr = NULL;
	DWORD remoteLen = 100;
	int index = 0;
	int shareName = 0;
	int l1 = 0;
	int l2 = 0;
	
	//try to get the remote path for the local device
	//get UNC Path for Mapped Drive
	retValue = WNetGetConnection(localDevice, remotePath, &remoteLen); 

	if(retValue != 0)
	{
		if(!FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,NULL, retValue, 0,(LPTSTR)&errString, 100,NULL) == 0)
		{ 
			ptr = (char *)strchr(errString,'\r');
			if(ptr != NULL)
			{
				*ptr = '\0';
			}
		}
		printf("Error: %s\n",errString);
		return 0;
	}

	
	remoteServer[0] = '\0';

	//the remotePath will be of \\<server-name>\<share-name>
	//extract the server-name and share-name from remote path

	while(remotePath[index] != '\0')
	{
		if(shareName == 1)
		{
			remoteShare[l2++] = remotePath[index++];
			continue;
		}
					
		if(remotePath[index] == '\\')
		{
			l1++;
			index++;
		}
		else
		{
			remoteServer[l2++] = remotePath[index++];
		}
		
		if(l1 == 3)
		{
			remoteServer[l2] = '\0';
			l2 = 0;
			shareName = 1;
		}
	}
	remoteShare[l2] = '\0';	
	return 1;	
}

/********************************************************************
 Name:         main 
 Description:  Program entry point to get the CIFS or LUN mapping info
 Parameters:
      IN:      drive-name
      OUT:     return status
 ********************************************************************/

int main(int argc, char* argv[])
{

	char *driveName;
	char remoteServer[100];
	char remoteShare[100];
    char *ptr = NULL;
	int driveType;
	   


	na_server_t*	s =	NULL;
	na_elem_t*		out = NULL;
	na_elem_t*		outputElem = NULL;
	na_elem_t*		ss = NULL;
	na_elem_iter_t	iter;
	
	char  err[256];
	char*	deviceName = argv[1];
	char user[20]; 
	char passwd[20];
	char opt;
  char cifstag[256];
	char recordStr[10];
	int records;


	if(argc != 2)
	{
		fprintf(stderr,"\nUsage: Host2StorageMap <drive-name>\n");
		fprintf(stderr, "<drive-name> -- local drive name\n\n");
    fprintf(stderr,"Example: Host2StorageMap E:\n");
		return -1;
	}

  /* make sure the drive name is in the format X: */
	
	driveName = argv[1];
    
	driveType = GetDriveType(driveName);

	//check whether its a remote device 
	if(driveType == DRIVE_REMOTE)
	{
        //get the remote server and remote share for the given device
		if(getNetworkShareInfo(deviceName,remoteServer,remoteShare) == 0)
		{
			return -2;
		}
    
        //try to get the CIFS mount-point information
        printf("drive %s is mapped to share \"%s\" on server %s\n",deviceName,remoteShare,remoteServer);
		printf("do you want to get the mount-point information for the share ? [y/n] ");
		scanf("%c",&opt);

        //select yes only if the CIFS share belongs to a filer
		if(opt == 'n' || opt == 'N')
		{
			return -2;
		}

        //enter the uname & passwd of the filer
		printf("enter the username of the server:");
		scanf("%s",user);
		printf("enter the password:");
		scanf("%s",passwd);

		if (!na_startup(err, sizeof(err))) {
            fprintf(stderr, "Error in na_startup: %s\n", err);
			return -2;
		}
		
		s = na_server_open(remoteServer, 1, 1); 
		
		na_server_style(s, NA_STYLE_LOGIN_PASSWORD);
		na_server_adminuser(s, user, passwd);

        ptr = strchr(remoteShare,'\\');
        if(ptr != NULL)
        {
          remoteShare[ptr - remoteShare] = '\0';
        }

		out = na_server_invoke(s, "cifs-share-list-iter-start","share-name", remoteShare,NULL);
					
		
		if (na_results_status(out) != NA_OK) {
			printf("Error %d: %s\n", na_results_errno(out),
			na_results_reason(out));
		}
		else {
			strcpy(cifstag,na_child_get_string(out, "tag"));
			records = na_child_get_int(out,"records",0);
			na_elem_free(out);

			itoa(records,recordStr,10);
			
			out = na_server_invoke(s, "cifs-share-list-iter-next","maximum", recordStr,"tag",cifstag,NULL);
					
						
			if (na_results_status(out) != NA_OK) {
				printf("Error %d: %s\n", na_results_errno(out),
				na_results_reason(out));
				return -2;
			}
			else { 			
				outputElem = na_elem_child(out, "cifs-shares");
        
				if (outputElem == NULL) {
                    out = na_server_invoke(s, "cifs-share-list-iter-end","tag",cifstag,NULL);
					na_elem_free(out);
					na_server_close(s);
					na_shutdown();
					return -2;
				}

                printf("\nLocal drive:%s\n",deviceName);
                printf("Filer:%s\n",remoteServer);
      
				for (iter = na_child_iterator(outputElem);
					(ss = na_iterator_next(&iter)) != NULL;  ) {				
				
					if ((na_child_get_string(ss, "share-name"))!= NULL) {
						printf("share-name: %s\n",na_child_get_string(ss, "share-name"));
					}

					if ((na_child_get_string(ss, "mount-point"))!= NULL) {					
						printf("mount-point: %s\n",na_child_get_string(ss, "mount-point"));
					}
				}
                out = na_server_invoke(s, "cifs-share-list-iter-end","tag",cifstag,NULL);
			}
		}
				
		printf("\n");
		na_elem_free(out);
		na_server_close(s);
		na_shutdown();
	}
    //check iff the given drive is a fixed drive (usually local/scsi device)
	else if(driveType == DRIVE_FIXED)
	{
		getLunMapInfo(driveName);
	}
	else
	{
		printf("not a valid drive\n");
		return -1;
	}

	return 0;

}