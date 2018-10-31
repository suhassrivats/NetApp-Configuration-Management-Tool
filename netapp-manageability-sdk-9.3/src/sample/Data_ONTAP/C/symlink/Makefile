##############################################################
#
# $ID$
#
# Makefile for symlink
#
# 
# Copyright 2002-2003 Network Appliance, Inc. All rights     
# reserved. Specifications subject to change without notice.    
#                                                            
# This SDK sample code is provided AS IS, with no support or    
# warranties of any kind, including but not limited to       
# warranties of merchantability or fitness of any kind,      
# expressed or implied.  This code is subject to the license    
# agreement that accompanies the SDK.                        
#                                                            
##############################################################

include ../../../Makefile.common

OBJS = ontapiver.o symlink.o

all: symlink

symlink: ontapiver.h $(OBJS) 
	 gcc $(CFLAGS) -o symlink $(OBJS) $(LINKOPTS)

%o:%c
	 gcc $(CFLAGS) -c $(<) -o $(@) $(INCLOPTS) 

clean:
	rm -f symlink 
	rm -f *.o 
	
