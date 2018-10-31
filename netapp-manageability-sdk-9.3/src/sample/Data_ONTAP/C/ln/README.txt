The Netapp Data ONTAP. named pipe interface
-------------------------------------------

The pipe interface is an older CIFS-specific interface that is used by some 
utility programs such as SecureShare Access. to manage Unix file permissions on 
the filer. It also allows reading and setting of symlinks as of version 6.3 of 
the OS. The sample program ln.exe allows individual users to set symlinks in 
directories that they have permission to write to. It does not allow them to set
widelinks, as that operation requires a write to the /etc/symlinks.translations 
file by an administrator.

The full definition of the interface is in %sdk-home%\include\pipeops.h. This 
file must be included by every program written to this interface.
