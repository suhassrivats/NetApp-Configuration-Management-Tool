##############################################################
#
# $ID$
#
# Makefile for apitest
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

include ../Makefile.common

INCLOPTS += -I../../../include -I../../../libnetapp -I../../../libadt
LINKOPTS += -L../../../lib/$(PLATFORM) -L../../../../sdk-staging/lib/$(PLATFORM)

all: apitest

apitest: apitest.c 
	 gcc $(CFLAGS) -o apitest apitest.c $(INCLOPTS) $(LINKOPTS)

clean:
	rm -f apitest
	
