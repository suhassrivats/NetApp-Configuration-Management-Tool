//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// SCSIUtil.h       										                      //
//                                                            //
// This header file defines all constants and types for       //
// accessing the SCSI bus adapters                            // 
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
//                                                            //
//                                                            //
//============================================================//




#include <windows.h>
#include <winioctl.h>
#include <initguid.h>
#include <stddef.h>

#ifndef _NTDDSCSIH_
#define _NTDDSCSIH_


typedef struct _SCSI_ADDRESS {
    ULONG Length;
    UCHAR PortNumber;
    UCHAR PathId;
    UCHAR TargetId;
    UCHAR Lun;
}SCSI_ADDRESS, *PSCSI_ADDRESS;

//
// Define the SCSI pass through direct structure.
//

typedef struct _SCSI_PASS_THROUGH_DIRECT {
    USHORT Length;
    UCHAR ScsiStatus;
    UCHAR PathId;
    UCHAR TargetId;
    UCHAR Lun;
    UCHAR CdbLength;
    UCHAR SenseInfoLength;
    UCHAR DataIn;
    ULONG DataTransferLength;
    ULONG TimeOutValue;
    PVOID DataBuffer;
    ULONG SenseInfoOffset;
    UCHAR Cdb[16];
}SCSI_PASS_THROUGH_DIRECT, *PSCSI_PASS_THROUGH_DIRECT;

  typedef struct _SCSI_PASS_THROUGH_DIRECT_BUFFER
  {
      SCSI_PASS_THROUGH_DIRECT s;
      char senseBuffer[64];
  } SCSI_PASS_THROUGH_DIRECT_BUFFER;




#define IOCTL_SCSI_BASE         FILE_DEVICE_CONTROLLER
#define IOCTL_SCSI_GET_ADDRESS  CTL_CODE(IOCTL_SCSI_BASE, 0x0406, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_SCSI_PASS_THROUGH_DIRECT  CTL_CODE(IOCTL_SCSI_BASE, 0x0405, METHOD_BUFFERED, FILE_READ_ACCESS | FILE_WRITE_ACCESS)


#define SCSI_IOCTL_DATA_OUT          0
#define SCSI_IOCTL_DATA_IN           1
#define SCSI_IOCTL_DATA_UNSPECIFIED  2

#endif


HANDLE openDeviceHandle(const char* deviceName);
BOOL getScsiAddress(const char* device,SCSI_ADDRESS *addr,int sizeOfAddr);
BOOL performSCSIPassThrough(const char* deviceName,unsigned char  *dataBuffer,int dataBufferSize,
				               unsigned char  *CDB,int cdbLength,PHANDLE deviceHandle);
void getIPAddresses(unsigned char *buffer,char ipAddresses[][16],int *numIPs);
BOOL getLunMapInfo(const char* deviceName);
HANDLE getPhysicalDriveHandle(SCSI_ADDRESS scsiAddress);
int compareAddresses(char *physicalDrive, SCSI_ADDRESS scsiAddress);

/* helper functions to get the lun map information */
void getVendorInformation(unsigned char *buffer,unsigned char *vendorInfo);
void getProtocolInfo(unsigned char *buffer,unsigned char *protocol);
void getLunPathInfo(unsigned char *buffer,unsigned char *lunPath);
