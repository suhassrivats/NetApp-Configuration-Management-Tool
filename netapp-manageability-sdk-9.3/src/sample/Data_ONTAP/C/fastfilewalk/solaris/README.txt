Fast file walking from Solaris for Data ONTAP
---------------------------------------------

While the sample fast file walking code for Solaris and NT is different (it was 
written by different developers and uses different threading libraries), the 
spirit of the two remains much the same. Directories are placed on a queue as 
they're encountered. Threads repeatedly dequeue a directory name, walk it, and 
process files they encounter. If any of the files are directories, they're 
placed on the queue for processing by the next thread available.

This code assumes fairly normal directory structures, i.e. enough directories to
keep all the threads busy. Very flat directory structures, or directories with 
millions of files in them, will mandate a slightly different approach, which is 
left as an exercise for the reader. 

Informal tests at Netapp on a Sun Ultra Enterprise with a gigabit LAN connection
 to an F880 filer imply that performance gains tail off at about five threads. 
The filer clocked between 8 and 10,000 NFS ops per second at maximum traffic 
levels. Initial runs on small filesystems take much longer, due both to NFS 
caching and to the filer's buffer cache which tends to have all the inodes in 
memory after the first run. On very large filesystems, this won't be the case, 
and thread use needs to be determined dynamically depending on the results of 
earlier runs. A writeup of some early performance studies is here.

The sample code #DEFINEs INLINE and STATIC to be inline and static respectively.
 The difference in performance between this, and simply defining the terms as 
blanks, was undetectable, given the wide swings in results that happen because 
of other factors.
