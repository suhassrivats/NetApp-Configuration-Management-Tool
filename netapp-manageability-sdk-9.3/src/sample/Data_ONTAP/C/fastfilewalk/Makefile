##############################################################
#
# $ID$
#
# Makefile for fastfilewalk
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

LIBS =  -L ../../../lib/solaris -lpthread
CFLAGS += -O6 -D_POSIX_PTHREAD_SEMANTICS $(LIBS)

ifeq "$(PLATFORM)" "solaris"
all: clean fastfilewalk
else
$(error Fastfilewalk is not supported on "$(PLATFORM)")
endif

ifeq "$(PLATFORM)" "solaris"
fastfilewalk: fastfilewalk.c
	 gcc -o fastfilewalk fastfilewalk.c $(CFLAGS)
endif

ifeq "$(PLATFORM)" "solaris"
clean: 
	rm -f fastfilewalk 	
endif
