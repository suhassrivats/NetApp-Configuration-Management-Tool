//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// SCSIUtil.cpp      										                      //
//                                                            //
// This utility file contains all the SCSI related functions  //
// which is used for getting the LUN map information          //
//                                                            //
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
// tab size = 2												                        //
//                                                            //
//															                              //
//============================================================//

#include "SCSIUtil.h"
#include <stdio.h>

/********************************************************************
 Name:            getVendorInformation
 Description:     get the vendor information from the SCSI buffer
 Parameters:
      IN:         SCSI buffer
      OUT:        vendor info
 Return value:    none
********************************************************************/
void getVendorInformation(unsigned char *buffer,unsigned char *vendorInfo)
{
  /* byte 8-15 contains the vendor specific information */
	memset(vendorInfo,0,10);
  memcpy(vendorInfo,buffer+8,8);
}

/********************************************************************
 Name:            getProtocolInfo
 Description:     get the protocol information from the SCSI buffer
 Parameters:
      IN:         SCSI buffer
      OUT:        protocol info
 Return value:    none
********************************************************************/

void getProtocolInfo(unsigned char *buffer,unsigned char *protocol)
{

  /* protocol specific information mainly in byte 58-59 */
  if(buffer[58] == 0x9 && buffer[59] == 0x60)
  {
    strcpy(protocol,"iSCSI");
  }
  else if(buffer[58] == 0x00 && buffer[59] == 0x00)
  {
    strcpy(protocol,"FCP");
  }
  else
  {
    strcpy(protocol,"UNKNOWN");
  }
}

/********************************************************************
 Name:            getIPAddresses
 Description:     get the ip Addresses of the filer from the SCSI buffer
 Parameters:
      IN:         SCSI buffer
      OUT:        filer IP addresses
 Return value:    none
********************************************************************/

void getIPAddresses(unsigned char *buffer, char ipAddresses[][16],int *numIPs)
{
	
	char ipAddress[16];
	int i;
	int count = 0;
  /* byte 16-19 contains the no. of ip addresses of the filer */
	count = buffer[19] + buffer[18]*256 + buffer[17]*512 + buffer[16]*1024;
	*numIPs = count;
	
	/* byte 20-23 contains the first ip address of the filer */
  for( i = 0 ; i < count; i++)
	{
		sprintf(ipAddress,"%d.%d.%d.%d",buffer[20+i*4],buffer[21+i*4],buffer[22+i*4],buffer[23+i*4]);
		memcpy(ipAddresses[i],ipAddress,strlen(ipAddress));
	}
}



/********************************************************************
 Name:            getLunPathInfo
 Description:     get the lun path information from the SCSI buffer
 Parameters:
      IN:         SCSI buffer
      OUT:        lun path info
 Return value:    none
********************************************************************/

void getLunPathInfo(unsigned char *buffer,unsigned char *lunPath)
{

  int i ;
  int size = 0;
  int flag = 0;
  int l = 0;

  
  /* byte 2-3 contains the volume length(N+1) */
  /* byte 4-N contains the volume string */ 
  
  size = buffer[2]*256 + buffer[3]-1;

  for(i = 4; i <= size;i++)
  {
    if(buffer[i] == '/')
    {
      flag = 1;
    }
    if(flag == 1)
    {
     lunPath[l++] = buffer[i];
    }
  }
  lunPath[l] ='\0';
  
}

/********************************************************************
 Name:            openDeviceHandle
 Description:     returns the handle of the given SCSI device
 Parameters:
      IN:         device name
      OUT:        device handle
 Return value:    device handle
********************************************************************/

HANDLE openDeviceHandle(const char* deviceName)
{
  return(CreateFile(deviceName,GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0,NULL));
}


/********************************************************************
 Name:            getScsiAddress
 Description:     get the SCSI address for the given SCSI device
 Parameters:
      IN:         device name
      OUT:        SCSI address
 Return value:    TRUE iff success, else FALSE
********************************************************************/

BOOL getScsiAddress(const char* device,SCSI_ADDRESS *addr,int sizeOfAddr)
{

  DWORD returned = 0;
  int status = 0;
  
  HANDLE handle = openDeviceHandle(device);
  
  if (handle == (HANDLE)-1)
  {
    return(FALSE);
  }

  status = DeviceIoControl(handle,
                           IOCTL_SCSI_GET_ADDRESS,
                           NULL,
                           0,
                           (char *)addr,
                           sizeOfAddr,
                           &returned,
                           FALSE);

  CloseHandle(handle);

  return ((status != 0) ? TRUE : FALSE);
}


/********************************************************************
 Name:            performSCSIPassThrough
 Description:     performs a SCSI pass through command to the SCSI device
 Parameters:
      IN:         device name,buffer,buffer size,CDB,CDB length
      OUT:        
 Return value:    TRUE iff succeeded in sending the command, else FALSE
********************************************************************/

BOOL performSCSIPassThrough(const char* deviceName,
				               unsigned char  *dataBuffer,
				               int dataBufferSize,
				               unsigned char  *CDB,
				               int cdbLength,
                       PHANDLE deviceHandle
                       )
{
  
  int i = 0;
  int ioctlResult;
  int commandStatus;
  DWORD bytesReturned = 0;

  unsigned char  path = 0;
	unsigned char  target = 0;
	unsigned char  lun = 0;
  
  char newDevice[100];

 	SCSI_ADDRESS address;
	int size = sizeof(SCSI_ADDRESS);
  BOOL gotAddress = FALSE;

    
   /* pass through buffer */
  SCSI_PASS_THROUGH_DIRECT_BUFFER scsiPassThrough;

  /* first get the scsi address for the given device */
  gotAddress = getScsiAddress(deviceName,&address,size);

  /* got scsi address ? */
  if (gotAddress)
  {
	  const char newDeviceFmt[] = "\\\\.\\SCSI%d:";
	  char tempDevice[sizeof(newDeviceFmt) + 4 * (20 - 2)];
	  sprintf(tempDevice, newDeviceFmt, address.PortNumber);
    strcpy(newDevice,tempDevice);
	  path = address.PathId;
	  target = address.TargetId;
	  lun = address.Lun;
	}

  else
  {
	   /* printf("unable to get the scsi address for the given device\n"); */
     return FALSE;
  }
  	
  

  /* initialize the scsi pass through parameters */
  scsiPassThrough.s.Length = sizeof(scsiPassThrough.s);
  scsiPassThrough.s.ScsiStatus = 0;
  scsiPassThrough.s.PathId = path;
  scsiPassThrough.s.TargetId = target;
  scsiPassThrough.s.Lun = lun;
  scsiPassThrough.s.CdbLength = cdbLength;
  scsiPassThrough.s.SenseInfoLength = sizeof(scsiPassThrough.senseBuffer);
  scsiPassThrough.s.DataIn = SCSI_IOCTL_DATA_IN;
  scsiPassThrough.s.DataTransferLength = dataBufferSize;
  scsiPassThrough.s.TimeOutValue = 30;
  scsiPassThrough.s.DataBuffer = dataBuffer;
  scsiPassThrough.s.SenseInfoOffset = offsetof(SCSI_PASS_THROUGH_DIRECT_BUFFER, senseBuffer);

  for( i = 0 ; i < cdbLength; i++)
  {
    scsiPassThrough.s.Cdb[i] = CDB[i];
  }
  
  
  // intialize the data Buffers
  memset(dataBuffer, 0, dataBufferSize);
  memset(scsiPassThrough.senseBuffer, 0, sizeof(scsiPassThrough.senseBuffer));

     
  //get the device handle
  if(*deviceHandle == NULL)
  {
    *deviceHandle = openDeviceHandle(newDevice);
  }


  if ((int) *deviceHandle > 0)
  {
    
    commandStatus = TRUE;
    
  
    //perform the DeviceIOCTL call
    ioctlResult = DeviceIoControl(*deviceHandle,
                                  IOCTL_SCSI_PASS_THROUGH_DIRECT,
                                  &scsiPassThrough,
                                  sizeof(scsiPassThrough),
                                  &scsiPassThrough,
                                  sizeof(scsiPassThrough),
                                  &bytesReturned,
                                  NULL);
    
    
    
    
    if (ioctlResult != 0)
    {
      if (scsiPassThrough.s.ScsiStatus > 0)
      {
        commandStatus = FALSE;
      }
      else
      {
        commandStatus = TRUE;
      }
    }
    else
    {
	    CloseHandle(*deviceHandle);
      *deviceHandle = NULL;
                      
      *deviceHandle = getPhysicalDriveHandle(address);
      

      if(*deviceHandle !=  NULL)
      {
        //perform the DeviceIOCTL call
        ioctlResult = DeviceIoControl(*deviceHandle,
                                  IOCTL_SCSI_PASS_THROUGH_DIRECT,
                                  &scsiPassThrough,
                                  sizeof(scsiPassThrough),
                                  &scsiPassThrough,
                                  sizeof(scsiPassThrough),
                                  &bytesReturned,
                                  NULL);
    
      }
      if (ioctlResult != 0)
      {
        if (scsiPassThrough.s.ScsiStatus > 0)
        {
          commandStatus = FALSE;
        }
        else
        {
          commandStatus = TRUE;
        }
      }
      else
      {
        commandStatus = FALSE;
      }
      
    }
  }
  /* unable to get the device handle */
  else
  {
	printf("unable to get the device handle\n");
	commandStatus = FALSE;
  }

  return (commandStatus);
  
}


/********************************************************************
 Name:            getLunMapInfo
 Description:     entry point to get the LUN map info for the given device
 Parameters:
      IN:         device name
      OUT:        
 Return value:    TRUE iff succeeded in getting the LUN map info, else FALSE
********************************************************************/

BOOL getLunMapInfo(const char* deviceName)
{

  /* CDB declarations for standard inquiry,filer ip addresses and lun path */
  unsigned char  inquiryCDB[6] = {0x12, 0, 0, 0, 63, 0};
  unsigned char  ipAddressCDB[6] = {0x12, 1, 0xc0, 0, 100, 0};
  unsigned char  lunPathCDB[10] = { 0xC0,0x00,0x00,0x0a,0x98,0x0A,0X10,0x00,100,0};

  /* CDB length declarations */
  int inquiryCDBLength = 6;
  int ipAddressCDBLength = 6;
  int lunPathCDBLength = 10;


  int deviceAdded = FALSE;
  const int maxRetries = 3;
  BOOL status = 0;
  int retry = 0;
  int i = 0;
  
    
  unsigned char path = 0; 
  unsigned char  target = 0;
  unsigned char  lun = 0;

  int bufferSize = 4096;
  unsigned char dataBuffer[4096];
  char newDeviceName[20];

  //scsi information
  unsigned char vendorInfo[10];
  unsigned char protocol[10];
  unsigned char lunPath[100];
  unsigned char ipAddresses[10][16];
  int numIPs = 0;
  HANDLE deviceHandle = NULL;

  char *physicalDrive = malloc(1024);
  int usePhysicalDrvAddress = 0;

  sprintf(newDeviceName,"\\\\.\\%s",deviceName);


  // first check whether this is a SCSI device by doing a Standard Inquiry
  do
  {
  	status = performSCSIPassThrough(newDeviceName,
		  				                  (unsigned char*) &dataBuffer,
							                  bufferSize,
							                  inquiryCDB,
							                  inquiryCDBLength,
                                &deviceHandle
										            );
	  retry++;
	} 
	while ((status == FALSE) && (retry < maxRetries));

  /* may not be a scsi device */
  if(status == FALSE)
  {
    printf("unable to get device information\n");
    CloseHandle(deviceHandle);
    return FALSE;
  }

	/* Its a SCSI device. Now get the vendor information */
	memset(vendorInfo,0,10);
	getVendorInformation(dataBuffer,vendorInfo);

  /* check iff its a NetApp device */
  if(strnicmp((char *)vendorInfo,"NETAPP",6))
	{
    printf("Not a NetApp device\n");
    CloseHandle(deviceHandle);
	  return 0;
	}

  printf("\nDrive:%s\n",deviceName);

  /* get the protocol FCP/iSCSI information */
  memset(protocol,0,10);
	getProtocolInfo(dataBuffer,protocol);

  printf("Protocol:%s\n",protocol);


  
  //now send a scsi pass through command to get the filer ip addresses
	retry = 0;

	do
	{
	  status = performSCSIPassThrough(newDeviceName,
		  				                      (unsigned char  *) &dataBuffer,
											              bufferSize,
							                      ipAddressCDB,
							                      ipAddressCDBLength,
                                    &deviceHandle
										                );
	  retry++;
	} 
	while ((status == FALSE) && (retry < maxRetries));
	

  if(status == FALSE)
  {
    printf("unable to get Filer IPAddress(s)\n");
    CloseHandle(deviceHandle);
    return 0;
  }

	memset(ipAddresses,0,10*16);	
	getIPAddresses(dataBuffer,ipAddresses,&numIPs);

  printf("Filer IPAddress(s):");
  for(i = 0 ; i < numIPs; i++)
  {
    if(i > 0)
    {
      printf(",");
    }
	  printf("%s",ipAddresses[i]);
  }
  printf("\n");
    

  //now send a scsi pass through command to get the lun path info
	retry = 0;
	do
	{
	  status = performSCSIPassThrough(newDeviceName,
		  				                    (unsigned char*) &dataBuffer,
							                    bufferSize,
							                    lunPathCDB,
							                    lunPathCDBLength,
                                  &deviceHandle
                                  );
		retry++;
	} 
	while ((status == FALSE) && (retry < maxRetries));
	

  if(status == FALSE)
  {
    printf("unable to get lun path information\n");
    CloseHandle(deviceHandle);
    return 0;
  }

	memset(lunPath,0,100); 
  getLunPathInfo(dataBuffer,lunPath);

  printf("LUN path:%s\n\n",lunPath);
	
  CloseHandle(deviceHandle);

  return status;
 }


/********************************************************************
 Name:            getPhysicalDrive
 Description:     gets the handle of the PhysicalDrive that matches 
                  with that of the given SCSI address
 Parameters:
      IN:         SCSI Address
      OUT:        
 Return value:    HANDLE of the PhysicalDrive
********************************************************************/

 HANDLE getPhysicalDriveHandle(SCSI_ADDRESS scsiAddress)
 {

   DWORD maxSize = 4096 * 100;
   char *lpTargetPath = (char *)malloc(maxSize * sizeof(char));
   DWORD retVal = 0;
   DWORD err = 0;
   char physicalDrv[1024];
   unsigned int i = 0 ;
   int l = 0;

   retVal = QueryDosDevice(NULL,lpTargetPath,maxSize);

   err = GetLastError();
   
   if (err == ERROR_INSUFFICIENT_BUFFER)
   {
    free(lpTargetPath);
    maxSize = maxSize*10;
    lpTargetPath = (char *)malloc(maxSize * sizeof(char));
   }
   retVal = QueryDosDevice(NULL,lpTargetPath,maxSize);

   l = 0;

  for(i = 0 ; i < retVal;i++)
  {
    if(lpTargetPath[i] == '\0')
    {
      physicalDrv[l] = '\0';
      l = 0;

      if(!strncmp(physicalDrv,"PhysicalDrive",13))
      {
        char newDevice[1024];
        strcpy(newDevice,"\\\\.\\");
        strcat(newDevice,physicalDrv);
        if(compareAddresses(newDevice,scsiAddress))
        {
          free(lpTargetPath);
          return openDeviceHandle(newDevice);
         }
      }
    }
    else
    {
      physicalDrv[l++] = lpTargetPath[i];
     }
  }
  free(lpTargetPath);
  return NULL;
 }

/********************************************************************
 Name:            compareAddresses
 Description:     comares the PhysicalDrive SCSI address with that 
                    of the given SCSI address
 Parameters:
      IN:         PhysicalDrive, SCSI Address
      OUT:        
 Return value:    TRUE iff both SCSI addresses matches, else FALSE
********************************************************************/

 int compareAddresses(char *physicalDrive, SCSI_ADDRESS scsiAddress)
 {

  SCSI_ADDRESS address;
  int size = sizeof(SCSI_ADDRESS);
  BOOL gotAddress = FALSE;

   
   /* first get the scsi address for the given physical drive */
  gotAddress = getScsiAddress(physicalDrive,&address,size);

  /* got scsi address ? */
  if (gotAddress)
  {
   /*
    printf("newDevice:%s %d %d %d %d - %d %d %d %d \n",physicalAddress,address.PortNumber,address.PathId,address.TargetId,address.Lun, \
      scsiAddress.PortNumber,scsiAddress.PathId,scsiAddress.TargetId,scsiAddress.Lun);
    */ 
	  if( address.PortNumber == scsiAddress.PortNumber && address.PathId == scsiAddress.PathId &&
          address.TargetId == scsiAddress.TargetId && address.Lun == scsiAddress.Lun)
    {
        return 1;
    }
   
  }
  return 0;
 }

