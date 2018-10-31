//========================================================================//
//																		  //
// $Id: //depot/prod/zephyr/belair/src/sample/C/fastfilewalk/nt/fastfilewalk.cpp#1 $	//
//                                                                        //
// fastfilewalk.cpp                                                       //
//                                                                        //
// sample threaded directory traversal code for fast                      //
// filesystem walking from Windows applications                           //                                                            //
//                                                                        //
// Copyright 2002-2003 Network Appliance, Inc. All rights                 //
// reserved. Specifications subject to change without notice.             // 
//                                                                        //
// This SDK sample code is provided AS IS, with no support or             //
// warranties of any kind, including but not limited to                   //
// warranties of merchantability or fitness of any kind,                  //
// expressed or implied.  This code is subject to the license             //
// agreement that accompanies the SDK.                                    //
//                                                                        //
// tab size = 4                                                           //
//                                                                        //
//========================================================================//

//234567890123456789012345678901234567890123456789012345678901234567890123456789

//========================================================================//

#include <afx.h>
#include <iostream>
using namespace std; 

void WINAPI ThreadFunc(int	*counter); /* Function prototype */

#define		MAX_THREADS		5		/* No of threads */
#define		N				10		/* Size of the Buffer */

char		Buffer[N][MAX_PATH];	/* Buffer to hold the file names returned WalkFileInfo() */
HANDLE		BufMutex;				/* Mutex to control access to the Buffer */
HANDLE		THandles[MAX_THREADS];	/* Array of thread handles */
int			In;						/* Next empty location in the Buffer */
int			Out;					/* Next location containing an item to be consumed */
int			Count;					/* Number of Available items in the Buffer */
BOOL		Finished = FALSE;		

int			TotalProcessed;			/* Total number of files processed */
int			c[MAX_THREADS];			/* array of counters, one per thread */

 
void
GetOwnershipInfo(char		*fname,
				_int64		FileId,
				_int64		ParentId,
				long		BlockSize,
				char		*pcFileSystemType,
				BOOL		eGotFirstOwner,
				PSID		&pclFatSID,
				long		ulDeviceInfo)
{

	SECURITY_DESCRIPTOR		*sdData;
	DWORD					sizeSd = 4098;
	DWORD					temp = 0;
	BOOL 					byDef;
	BOOL					Success;
	PSID					psid;
	char					eSuccess = 0;
	long					sidlength;
	
	 
	if (!eGotFirstOwner)
	{
		sdData = (SECURITY_DESCRIPTOR *)GlobalAlloc(GPTR,sizeSd);
 		if (sdData == NULL)
			return;

		/* fname contains the full name of the file including absolute path */
		Success = GetFileSecurity(fname,
								OWNER_SECURITY_INFORMATION |
								GROUP_SECURITY_INFORMATION |
								DACL_SECURITY_INFORMATION,
								sdData,
								sizeSd,
								&sizeSd);
		if (Success)
		{
				 

				Success = GetSecurityDescriptorOwner(sdData,(PSID *)&psid,&byDef);	
				if (Success)
				{
					//SetUserId(psid);

					eGotFirstOwner = 1;
					sidlength=GetLengthSid(psid);
					//if (pclFatSID != 0)
					//	delete [] pclFatSID;
					pclFatSID = (PSID) new char[sidlength];
					CopySid (sidlength, pclFatSID, psid);
				}
		}
		GlobalFree(sdData);
	}
	else
	{
		//SetUserId(pclFatSID);
			;
	}
}



void
WalkFileInfo(LPTSTR path1,
			LPTSTR path2,
			BOOL recurse,
			HANDLE SHandle)
{
	WIN32_FIND_DATA		fdata;
    DWORD				temp1 = 0;
	 
 
	if (SHandle == NULL)
    {
		SHandle = FindFirstFile(path1,
								&fdata);
	}
 
	if (SHandle == INVALID_HANDLE_VALUE)
			return;

   	do {
 
		if ((strcmp(fdata.cFileName, ".") == 0) ||
			(strcmp(fdata.cFileName, "..") == 0))
		{
				continue;
		}
	
		
loop:	WaitForSingleObject(BufMutex, INFINITE);
		if (Count == N)
		{
			ReleaseMutex(BufMutex);
			goto loop;
		}

		strcpy(Buffer[In], path2);
		strcat(Buffer[In], "\\");
		strcat(Buffer[In], fdata.cFileName);
		In = (In +1) % N;
		Count++;
		TotalProcessed++;
		ReleaseMutex(BufMutex);

		
		if ((fdata.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0)
		{
			char	tpath1[MAX_PATH];
			char	tpath2[MAX_PATH];

			strcpy(tpath1, path2);
			strcat(tpath1, "\\");
			strcat(tpath1, fdata.cFileName);
			strcpy(tpath2, tpath1);
			strcat(tpath1, "\\*");

			WalkFileInfo(tpath1, tpath2, recurse, NULL);
		}

	} while (FindNextFile(SHandle, &fdata));

	FindClose(SHandle);

}



void WINAPI ThreadFunc(int *counter)
{
	char		fname[MAX_PATH];
	PSID		pclFatSID;
	DWORD		cbName = 100;
    DWORD		cbReferencedDomainName = 100;  


	while(1)
	{
		
 		WaitForSingleObject(BufMutex, INFINITE);
		if (Count == 0)
		{
			ReleaseMutex(BufMutex);
			if (Finished)
				break;
			continue;
		}

		strcpy(fname, Buffer[Out]);
		Out = (Out + 1) % N;
		Count--;
		ReleaseMutex(BufMutex);
		
		GetOwnershipInfo(fname,
				  	0,
					0,
					0,
					"1",
					0,
					pclFatSID,
					0);
					
		(*counter)++;
		 
	}
	
}



void
main (int argc, char** argv)
{
	HANDLE		SHandle = NULL;	
	char		path1[MAX_PATH];
	char		*path2;
	time_t		start;
	time_t		finish;
    double		elapsed_time;
	int			i;
	DWORD		tid;
	int			total = 0;	/* for cross-checking the no of files processed by all the threads */

	path2 = argv[1];
	
	if (path2 == NULL)
	{
		cout << "Usage: getfilesecurity-mt.exe <path>";
		return;
	}
    
	strcpy(path1, path2);
	strcat(path1, "\\*");	

	BufMutex = CreateMutex(NULL, FALSE, "BufMutex");
	if (BufMutex == NULL)
		return;

	In = 0;
	Out = 0;
	Count = 0;
	TotalProcessed = 0;

    for (i =0 ; i < MAX_THREADS; i++)
	{
		c[i] = 0;
		THandles[i] = CreateThread(NULL,
							0,
							(LPTHREAD_START_ROUTINE)ThreadFunc,
							&c[i],
							0,
							&tid);
	}

    time(&start);
   	WalkFileInfo(path1, path2, 1, SHandle);
	time( &finish );
    elapsed_time = difftime( finish, start );
	cout << "\n\nTime taken in seconds: "<< elapsed_time;
	cout << "\nNO OF FILES PROCESSED : "<< TotalProcessed;

	Finished = TRUE;

	/* Wait until all threads are done */
	WaitForMultipleObjects(MAX_THREADS,
							THandles,
							TRUE,
							INFINITE);

	for (i = 0; i < MAX_THREADS; i++)
	{
		total = total + c[i];
		cout << "\nNo of files processed by thread " << i <<" : "<< c[i];
		CloseHandle(THandles[i]);
	}

	cout << "\nNo. of files processed by all the threads: "<< total;

}



 