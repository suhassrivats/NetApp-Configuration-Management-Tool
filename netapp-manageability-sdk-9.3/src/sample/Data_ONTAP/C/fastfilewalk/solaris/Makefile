#*************************************************************
#
# $ID$
#
# Makefile for fastfilewalk
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

include ../../../../Makefile.common

LIBS =  -L ../../../../../lib/solaris -lpthread
CFLAGS += -O6 -D_POSIX_PTHREAD_SEMANTICS $(LIBS)

# make sure we are building only on solaris
ifneq "$(PLATFORM)" "solaris"
$(error Fastfilewalk is not supported on "$(PLATFORM)")
endif


all: clean fastfilewalk

fastfilewalk: fastfilewalk.c
	gcc -o fastfilewalk fastfilewalk.c $(CFLAGS)

clean: 
	rm -f fastfilewalk 
