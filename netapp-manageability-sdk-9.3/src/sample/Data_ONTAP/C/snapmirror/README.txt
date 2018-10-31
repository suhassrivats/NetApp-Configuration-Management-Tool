snapmirror application
----------------------

This application implements  snapmirror commands.

The general syntax of the snapmirror command is as follows:

sm subcmd [options] [src:vol | src:qtree_path] dest:vol | dest:qtree_path

The supported subcommands and their options are described below:

IDLE: The idle command takes a given snapmirror relationship and polls the 
destination filer in that relationship and waits until that relationship is 
"idle". If the relationship is not idle, it waits, by default, by 60 seconds 
and polls again. The purpose is to have a script wait until a given 
relationship is idle before proceeding.

Usage: sm idle [-v] [t sec] src_filer:src_vol|src_qtree dst_filer:dst_vol|dst_qtree                                                                                                         
-v : Verbose mode. This is mostly for debugging purposes. It includes 
lots of extra print statements to show progress.

-t sec : This changes the default wait time in between polls.

Examples: sm idle filer1:vol1 filer2:vol2

sm idle -t 30 filer1:/vol/vol1/qtree1 filer2:/vol/vol2/qtree1

RESYNC: The resync command initiates a snapmirror resync of a given snapmirror 
relationship.

Usage:

sm resync [-v] [-k kbytes] [-s snapshot] src_filer:src_vol|src_qtree dst_filer:dst_vol|dst_qtree

-v : Verbose mode. Same as idle. 

-k kbytes : This implements the snapmirror throttle option. This is identical to
the -k option on the snapmirror resync command in Data ONTAP. By default there 
is no throttle.

-s snapshot : This allows the user to select the snapshot on which to base 
the resync. This is identical to the -s option on the snapmirror resync 
command in Data ONTAP. By default ONTAP picks the latest snapshot it can find.

BREAK: The break command properly breaks a snapmirror. It first does a quiesce, 
waits for that to complete (it tries every 15 seconds), then issues a break.

Usage: smbreak [-v] dst_filer:dst_vol|dst_qtree

-v : Verbose mode. Same as idle.

UPDATE: The update command implements the snapmirror udpate command.

Usage: sm update [-v] [-k kbytes] [-s snapshot] src_filer:src_vol|src_qtree dst_filer:dst_vol|dst_qtree

-v : Verbose mode. Same as idle.

-k kbytes : This implements the snapmirror throttle option. This is identical 
to the -k option on the snapmirror update command in Data ONTAP. By default 
there is no throttle.

-s snapshot : This allows the user to select the snapshot on which to base 
the resync. This is identical to the -s option on the snapmirror initialize 
command in Data ONTAP. By default ONTAP picks the latest snapshot it can find.

INITIALIZE: The initialize (or just 'init' can be used) command implements 
the snapmirror initialize command.

Usage: sm update [-v] [-k kbytes] [-s snapshot] src_filer:src_vol|src_qtree dst_filer:dst_vol|dst_qtree

-v : Verbose mode. Same as idle. 

-k kbytes : This implements the snapmirror throttle option. This is identical to
the -k option on the snapmirror update command in Data ONTAP. By default there 
is no throttle.

-s snapshot : This allows the user to select the snapshot on which to base 
the resync. This is identical to the -s option on the snapmirror update 
command in Data ONTAP. By default ONTAP picks the latest snapshot it can find.

Notes

The RPC transport layer will not work without the ntapadmin.dll file in the 
DLL search path of the application. We've copied it into the SDK. If you wish 
to use snapmirror outside the SDK, we recommend copying the file 
/bin/nt/ntapadmin.dll to the %systemroot%/system32 directory on your machine.

The RPC transport layer will also not work unless you are an administrator, 
either in the filer's domain, or on the filer itself. You can add yourself as an
admin on the filer by adding your SID (use "wcc -v -s username" to find it out)
to the filer's /etc/lclgroups.cfg file in the administrators category.


