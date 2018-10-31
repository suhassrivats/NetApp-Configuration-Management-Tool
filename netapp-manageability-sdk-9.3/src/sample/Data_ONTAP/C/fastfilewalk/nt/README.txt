Fast file walking from Win32 for Data ONTAP
-------------------------------------------

While the sample fast file walking code for Solaris and NT is different (it was 
written by different developers and uses different threading libraries), the 
spirit of the two remains much the same. Here, directories are placed on a queue
 as they're encountered. Threads repeatedly dequeue a directory name, walk it, 
and process files they encounter. If any of the files are directories, they're 
placed on the queue for processing by the next thread available.

This code assumes fairly normal directory structures, i.e. enough directories to
 keep all the threads busy. Very flat directory structures, or directories with 
millions of files in them, will mandate a slightly different approach, which is 
left as an exercise for the reader. 

Informal tests at Netapp on a 2GHz P4 with a 10/100BT LAN connection show that 
performance gains tail off at about five threads. This is probably due to 
saturation of the pipe; the filer was clocking about 2000 CIFS ops per second.
