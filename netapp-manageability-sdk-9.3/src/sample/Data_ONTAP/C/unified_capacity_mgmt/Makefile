##############################################################
#
# $ID$
#
# Makefile for unified_capacity_mgmt
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

INCLOPTS += -I ../../../include
LINKOPTS += -L ../../../lib/$(PLATFORM)
	
all: unified_capacity_mgmt

unified_capacity_mgmt: unified_capacity_mgmt.c 
	 gcc $(CFLAGS) -o unified_capacity_mgmt unified_capacity_mgmt.c $(INCLOPTS) $(LINKOPTS)

clean:
	rm -f unified_capacity_mgmt
	
