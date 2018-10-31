#ifndef _VDISKINTF_
#define _VDISKINTF_

typedef struct VDISK_STAT_ {
	ISTRING WCHAR* vdiskpath;
	ISTRING WCHAR* serialno;
	ISTRING WCHAR* attrval;
} VDISK_STAT;

typedef struct VDISK_LIST_ {
	ULONG num_vdisk;
	SIZEIS(num_vdisk) VDISK_STAT* vstat;
} VDISK_LIST;

typedef struct VDISK_DATA_1_BYTE_ {
	unsigned char onebyte;
} VDISK_DATA_1_BYTE;

typedef struct VDISK_DATA_ {
	ULONG length;
	SIZEIS(length) VDISK_DATA_1_BYTE* databyte;
} VDISK_DATA;

#endif
