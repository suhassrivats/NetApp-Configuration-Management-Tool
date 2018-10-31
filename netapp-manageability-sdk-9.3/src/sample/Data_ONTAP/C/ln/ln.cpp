//============================================================//
//															  //
// ln.cpp : symbolic links for Windows on Netapp Filers 6.3   //
//          and later.										  //
//															  //
// See Usage printout for invocation						  //
//															  //
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

#define UNICODE

#define WIN32_LEAN_AND_MEAN 
#include <stdio.h>
#include <tchar.h>
#include <stdlib.h>
#include <windows.h>
#include <winsock2.h>
#include "pipeops.h"

#define VER "v0.1"

/* TODO:
 * UNC path only accepts Netbios names, no DNS names, no IP addresses. 
 */


//
// getUNC: Take UNC path to symlink, extract machinename and return 
// NETAPPSVC pipename.
//
LPTSTR getUNC(WCHAR *filerpath)
{
	static WCHAR buffer[512];

	memset(buffer, 0, 512*sizeof(WCHAR));
	wcscpy(buffer, filerpath);
	*(wcschr(buffer+2, '\\')) = 0;

	wcscat(buffer, L"\\PIPE\\NETAPPSVC");
	return (LPTSTR) buffer;
}

int wmain(int argc, WCHAR* argv[])
{
	HANDLE				hPipe = NULL; 
	CHAR				chBuf[MAX_UPATH]; 
	BOOL				fSuccess; 
	DWORD				cbRead; 
	SymlinkCreateSVC	naMsgSymLink;
	ReadlinkSVC			naMsgReadLink;
	ReadlinkSVC_R*		naMsgResp;

	//
	// copy WCHAR arg to char buf, sigh
	//
	if (argc > 2) {
		CHAR*		bufptr = chBuf;
		WCHAR*		argptr = argv[1];		

		while(*bufptr++ = (char)*argptr++)
			;
	}

	switch (argc) {
	case 2:
		//
		// Read a symlink
		//
		naMsgReadLink.hdr.operation = NETAPP_SVC_READLINK;
		wcscpy(naMsgReadLink.hdr.path, argv[1]);

		fSuccess = CallNamedPipe(
			getUNC(argv[1]),        // pipe name 
			&naMsgReadLink,         // message to server 
			sizeof(naMsgReadLink),	// message length 
			chBuf,					// buffer to receive reply 
			sizeof(chBuf),          // size of read buffer 
			&cbRead,				// number of bytes read 
			5000);					// waits for 5 seconds 
		 
		if (! fSuccess) {
			printf("Reading symlink %s failed.\n", argv[0]);
			exit(1);
		} 
		else {
			naMsgResp = (ReadlinkSVC_R *) chBuf;
			printf("%s\n", naMsgResp->destbuf) ;
		}
		break;
	case 3:
		//
		// Create a symlink
		//
		naMsgSymLink.hdr.operation = NETAPP_SVC_SYMLINK;
		wcscpy(naMsgSymLink.hdr.path, argv[2]);
		strcpy(naMsgSymLink.destbuf, chBuf);

		fSuccess = CallNamedPipe(
			getUNC(argv[2]),		// pipe name 
			&naMsgSymLink,			// message to server 
			sizeof(naMsgSymLink),	// message length 
			chBuf,					// buffer to receive reply 
			sizeof(chBuf),			// size of read buffer 
			&cbRead,				// number of bytes read 
			5000);					// waits for 5 seconds 
 
		if (! fSuccess) {
		   printf("Creation of symlink %s failed.\n", argv[2]);
		   exit(1);
		} 
		break;
	default:
		fprintf(stderr,
		// "01234567890123456789012345678901234567890123456789012345678901234567890123456789
		   "ln: tool for listing and creating symbolic links on Netapp filers\n" 
		   "         (c) 2002-2003 Network Appliance, Inc. %s\n" 
		   "Usage:   ln destination linkname   - create symlink which points to destination\n" \
		   "         ln linkname               - show destination of linkname\n\n" 
		   "Notes:   linkname must always be a complete UNC path, \n" 
		   "         destination is a unix-style filer pathname.  You may need to use the \n"
		   "             'cifs chares' command to find out where the desired destination \n"
		   "              path is rooted.\n" 
		   "Example: ln /vol/vol0/home/abc \\\\filer1\\home\\user1\\link\n" 
		   "             creates a symlink called link on filer1 which points to \n"
		   "             /vol/vol0/home/abc.   \n\n",
		   VER );
		exit (2);
   }
   
   return 0;
}
