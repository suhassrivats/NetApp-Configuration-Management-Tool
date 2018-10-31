//============================================================//
//                                                            //
//                                                            //
//                                                            //
// host2storagemap.c                                          //
//         This file provides functions to get the volume or  // 
//         LUN  mapping information for the given mount-point //
//         on the host.                                       //
//                                                            //
// Copyright 2005 Network Appliance, Inc. All rights          //
// reserved. Specifications subject to change without notice. //
//                                                            //
// This SDK sample code is provided AS IS, with no support or //
// warranties of any kind, including but not limited to       //
// warranties of merchantability or fitness of any kind,      //
// expressed or implied.  This code is subject to the license //
// agreement that accompanies the SDK.                        //
//                                                            //
// Usage host2storagemap <mount-point>                        //
//                                                            //
//============================================================//

#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <scsi/sg.h>
#include <mntent.h>
#include <dirent.h>
#include <scsi/scsi.h>

#define INQ_REPLY_LEN 100


/*
This function is the entry point to get the Vol/Lun mapping information for 
the given mount-point
*/
int getMappingInfo(const char* mntPoint);

/*
 This function is the entry point to get the Lun mapping information
 for the given scsi device
*/
int getLUNInfo(char *devName);

/*
This function will get the Lun mapping information for the given sg device.
 It prints protocol,filer IP addresses,Lun path and its device filename.
*/
int getLunInfoFromScsi(char *sgDevName,char *sdDevName);

/* This function will actually contain the system calls to get the data 
from the filer for the given scsi device using scsi command
 */
int getDataFromScsi(char *devName,char* cmdBlk, int cmdLen, char *buffer);


/*
This function will get the scsi address (c#t#b#d#)for the given 
character/block device
 */
int getScsiAddress(char *deviceName,int *controller,int *bus,int *target,int *lun);

/*
This function will get the character(sg) device for the given 
 block(sd) device
 */
int getsgDevice(char *deviceName,int controller,int bus,int target,int lun);


/********************************************************************
 Name:            getMappingInfo
 Description:     entry point to get the vol/LUN mapping information
                  This function will scan the /etc/mtab file
                  and figure out whether the given mount-point
                  is an nfs or a scsi device
 Parameters:
      in:        mount-point 
      out:       none 
 Return value:   1 iff able to get the mapping information
*********************************************************************/

int getMappingInfo(const char* mntPoint)
{

  struct mntent *pMountEntry;
  FILE *mountTab = NULL;
  char mnt_fsname[100];
  char mnt_dir[50];
  char mnt_type[10];
  char* ptr1 = NULL;
  char* ptr2 = NULL;
  int l = 0;
  int found = 0;
  char devName[50];
  char protocol[10];
  char server[100];
  char volPath[100];

  devName[0] = '\0';
  protocol[0] = '\0';
  server[0] = '\0';
  volPath[0] = '\0';

  mountTab = setmntent("/etc/mtab", "r");

  if(mountTab == NULL)
  {
    printf("unable to open mount table\n");
    return 0;
  }
  printf("\n-----------------------------------------------------------------------\n");
  printf(" Protocol   Server               Vol/Lun Path          Device filename \n");
  printf("-----------------------------------------------------------------------\n\n");

  /* iterate through the mount table and look for the given mount-point */
  while((pMountEntry = getmntent(mountTab)) != NULL)
  {
    strcpy(mnt_fsname,(char *)pMountEntry->mnt_fsname);
    strcpy(mnt_dir,(char *)pMountEntry->mnt_dir);
    strcpy(mnt_type,(char *)pMountEntry->mnt_type);


    if(strcmp(mntPoint,mnt_dir) == 0)
    {
        /* chech is this is an nfs mount-point */
        if(strcmp(mnt_type,"nfs") == 0)
        {
          l = strlen(mnt_fsname);
          ptr1 = mnt_fsname;
          ptr2 = (char *)strchr(mnt_fsname,':');
          if(ptr2 != NULL)
          {
            memcpy(server,ptr1,ptr2-ptr1);
            server[ptr2-ptr1] = '\0';
            memcpy(volPath,ptr2+1,l-(ptr2-ptr1));
            volPath[l-(ptr2-ptr1)+1] = '\0';
          }
          strcpy(devName,mnt_fsname);
          strcpy(protocol,"nfs");
          found = 1;
         printf(" %-10s %-20s %s\n",protocol,server,volPath);
        }
        /* check if this a scsi block device */
        else if(strncmp(mnt_fsname,"/dev/sd",7) == 0)
        {
         strcpy(devName,mnt_fsname);
         getLUNInfo(devName);
         found = 1;
        }
    }
  }
  fclose(mountTab);

  printf("-----------------------------------------------------------------------\n");
  if(found == 0)
  {
    printf("unable to find mount-point\n");
  }
  return 0;
}

/********************************************************************
 Name:            getLunInfo
 Description:     get the LUN map information for the given SCSI device
 Parameters:
      IN:         sd device
      OUT:        none
 Return value:    1 iff got LUN info successfully, else 0
********************************************************************/

int getLUNInfo(char *devName)
{
  FILE *sgFptr;
  FILE *pipe = NULL;

  char sgDevice[10];
  char lineBuff[100];
  char newDevName[50];
  char cmd[100];
  char *ptr = devName;
  int l = 0;
  int c,b,t,d;

  sgDevice[0] = '\0';

  /* truncate the partition no. from the block device */
  while(*ptr != '\0')
  {
    if(*ptr >= '0' && *ptr <= '9')
    {
      break;
    }
    newDevName[l++] = *ptr++;
  }
  newDevName[l] = '\0';

  /* first try to get the sg device for the given sd device
     using sg_map command */
  sgFptr = fopen("/usr/bin/sg_map","r");

  if(sgFptr != NULL)
  {
    sprintf(cmd,"/usr/bin/sg_map | grep %s",newDevName);
    pipe = popen(cmd,"r");

    if(fgets(lineBuff,sizeof(lineBuff),pipe) != NULL)
    {
      strcpy(sgDevice,lineBuff);
      ptr = strchr(sgDevice,' ' );
      if(ptr != NULL)
      {
        sgDevice[ptr - sgDevice] = '\0';
      }
    }
    pclose(pipe);
    if(getLunInfoFromScsi(sgDevice,newDevName) == 0)
    {
     /* printf("unable to get device information.\n"); */
    }
    else
    {
      return 1;
    }
    return 0;
  }
  /* get the scsi address for the given sd device */
  if(getScsiAddress(devName,&c,&b,&t,&d))
  {
    /* get the matching sg device for the given scsi address */
    if(getsgDevice(sgDevice,c,b,t,d))
    {
      /* get the LUN map for the given sg device */
      if(getLunInfoFromScsi(sgDevice,newDevName) == 1)
      {
      }
      else
      {
        /*printf("unable to get device information\n");*/
      }
    }
    else
    {
      perror("error");
    }
  }
  else
  {
    perror("error");
  }
return 0;
}


/********************************************************************
 Name:         getLunInfoFromScsi 
 Description:  get the LUN information from scsi.
               This function uses the scsi commands to get the LUN
               map information for the given scsi device
 Parameters:
      IN:      device name
      OUT:     none
 Return value: 1 iff able to get the LUN info from scsi, else 0
********************************************************************/

int getLunInfoFromScsi(char *sgDevName,char *sdDevName)
{
  int i;
  int numIPs = 0;
  int size = 0;
  int l = 0;
  int flag = 0;
  FILE *fptr = NULL;
  unsigned char inqBuff[100];

  /* scsi standard inquiry command  to get the vendor information*/
  unsigned char inqCmdBlk[6] = {0X12, 0, 0, 0, 100, 0};

  /* scsi VPDP command to get the filer IP addresses */
  unsigned char vpdinqCmdBlk[6] = { 0X12,1,0xC0,0x00,100,0};

  /* 10 byte vendor specific command to get the lun path */
  /* uses 0X10  Virtual Disk Path page */ 
  unsigned char volCmdBlk[10] = { 0xC0,0x00,0x00,0x0a,0x98,0x0A,0X10,0x00,100,0};

  char protocol[10];
  char server[50];
  char lunPath[100];

  protocol[0] = '\0';
  server[0] = '\0';
  lunPath[0] = '\0';

  if(getDataFromScsi(sgDevName,inqCmdBlk, 6, inqBuff))
  {
/*
    printf("vendor information:%c%c%c%c%c%c\n",inqBuff[8],inqBuff[9],inqBuff[10],inqBuff[11],inqBuff[12],inqBuff[13]);
*/
  }
  else
  {
    return 0;
  }

  /* vendor specific information from byte 8-13 */
  /* check iff this is a NETAPP device */
  if(inqBuff[8] != 'N' && inqBuff[9] != 'E' && inqBuff[10] != 'T'
                       && inqBuff[11] != 'A' && inqBuff[12] != 'P' && inqBuff[13] != 'P')
  {
    printf("not a NETAPP device\n");
    return 0;
  }

  /* protocol specific information mainly in byte 58-59 */
  if(inqBuff[58] == 0X09 && inqBuff[59] == 0X60)
  {
    strcpy(protocol,"iSCSI");
  }
  else if(inqBuff[58] == 0X00 && inqBuff[59] == 0X00)
  {
    strcpy(protocol,"FCP");
  }
  else
  {
    strcpy(protocol,"unknown");
  }
 printf(" %-10s ",protocol);

  if(getDataFromScsi(sgDevName,vpdinqCmdBlk, 6, inqBuff))
  {
    /* byte 18-19 contains the no. of ip addresses of the filer */
    /* bypte 20-23 contains the first ip address of the filer */
    numIPs = inqBuff[19];
    if(numIPs != 0)
    {
      for( i = 0;i < numIPs;i++)
      {
        sprintf(server,"%d.%d.%d.%d",inqBuff[20+i*4],inqBuff[21+i*4],inqBuff[22+i*4],inqBuff[23+i*4]);
        if(numIPs == 1)
        {
          printf("%-20s",server);
        }
        else
        {
          if(i > 0)
          {
            printf(",");
          }
          printf("%s",server);
        }
      }
    }
  }
  if(getDataFromScsi(sgDevName,volCmdBlk,10,inqBuff))
  {
    /* byte 2-3 contains the volume length(N+1) */
    /* byte 4-N contains the volume string */ 
    size = inqBuff[2]*256 + inqBuff[3]-1;
    for(i = 4; i <= size;i++)
    {
      if(inqBuff[i] == '/')
      {
        flag = 1;
      }
      if(flag == 1)
      {
       lunPath[l++] = inqBuff[i];
      }
    }
    lunPath[l] ='\0';
    printf(" %-25s ",lunPath);
  }
  printf("%s\n",sdDevName);
  return 1;
}


/********************************************************************
 Name:         getDataFromScsi 
 Description:  This function gets the data from scsi 
 Parameters:    
      IN:      device name, CDB,CDB length
      OUT:     scsi data
 Return value: 1 iff able to get the data from scsi, else 0
********************************************************************/


int getDataFromScsi(char *devName,char* cmdBlk, int cmdLen, char *buffer)
{
  unsigned char sense_buffer[32];
  sg_io_hdr_t io_hdr;
  int fd;
  int c,b,t,l;

  memset(buffer,0,100);

  fd = open(devName,O_RDWR|O_NONBLOCK);

  if (fd >= 0)
  {

    memset(&io_hdr, 0, sizeof(sg_io_hdr_t));
    io_hdr.interface_id = 'S';
    io_hdr.cmd_len = cmdLen;
     io_hdr.mx_sb_len = sizeof(sense_buffer);
    io_hdr.dxfer_direction = SG_DXFER_FROM_DEV;
    io_hdr.dxfer_len = INQ_REPLY_LEN;
    io_hdr.dxferp = buffer;
    io_hdr.cmdp = cmdBlk;
    io_hdr.sbp = sense_buffer;
    io_hdr.timeout = 20000;

    if (ioctl(fd, SG_IO, &io_hdr) < 0)
    {
      close(fd);
      perror("Inquiry SG_IO ioctl error");
      return 0;
    }
    if (io_hdr.info & SG_INFO_OK_MASK)
    {
        perror("getDataFromScsi");
        close(fd);
        return 0;

   }
    close(fd);
  }
  else
  {
   return 0;
  }
  return 1;
}


/********************************************************************
 Name:         getScsiAddress 
 Description:  get the scsi address for the given sd/sg device
 Parameters:
      IN:      device name
      OUT:     c#t#b#d#
 Return value: 1 iff able to get the scsi address, else 0
********************************************************************/

int getScsiAddress(char *deviceName,
                    int *controller,
                    int *bus,
                    int *target,
                    int *lun
                    )
{
  int gotAddress = 0;
  int fd;
  int idlun[2] = {0, 0};
  int error ;
  int iController;

  fd = open(deviceName, O_NONBLOCK | O_RDONLY);
  if (fd >= 0)
  {
    error = ioctl(fd, SCSI_IOCTL_GET_IDLUN,(char *)(idlun));
    if (error >= 0)

    {

      *target = idlun[0] & 0xff;
      *lun = (idlun[0] >> 8) & 0xff;
      *bus = (idlun[0] >> 16) & 0xff;


      error =  ioctl(fd, SCSI_IOCTL_GET_BUS_NUMBER,(char*)(&iController));
      if (error >= 0)

      {
        *controller = iController;
        gotAddress = 1;
      }
    }
    close(fd);
  }
  else
  {
  }
  return(gotAddress);
}

/********************************************************************
 Name:         getsgDevice 
 Description:  get the sg device for the given scsi address
 Parameters:
      IN:      scsi device address 
      OUT:     sg device 
 Return value: 1 iff able to get the sg device, else 0
********************************************************************/

int getsgDevice(char *deviceName,int controller,int bus,int target,int lun)
{

  DIR *dp = NULL;
  struct dirent *dirp;
  int b,c,t,l;
  char devPath[20];


  deviceName[0] = '\0';

  dp = opendir("/dev/");
  strcpy(devPath,"/dev/");

  if ((dp) != NULL)
  {
    /* iterate through the /dev directory and find the sg device that is
       associated to the given scsi address */
    while ((dirp = readdir(dp)) != NULL)
    {
      if (dirp->d_name[0] == '.')
      {
        continue;
      }
      if(strncmp(dirp->d_name,"sg",2) != 0)
      {
        continue;
      }
      else
      {
        strcpy(devPath,"/dev/");
        strcat(devPath,dirp->d_name);

        if(getScsiAddress(devPath,&c,&b,&t,&l))
        {
          if(controller == c && target == t && bus == b && lun == l)
          {
              strcpy(deviceName,devPath);
              return 1;
          }
      }
    }
  }
  }
  return 0;
}

/********************************************************************
 Name:         main 
 Description:  Program entry point to get the vol/LUN mapping info
 Parameters:
      IN:      mount-point
      OUT:     none
 Return value: -1 on failure
********************************************************************/


  int main(int argc,char *argv[])
  {

    char devName[100];
    char *mntPoint;

    if(argc != 2)
    {
      fprintf(stderr,"\nUsage:\n");
      fprintf(stderr,"host2storagemap <mount-point>\n");
      return -1;
    }

    mntPoint = argv[1];

    getMappingInfo(mntPoint);
    return 1;
  }

