##############################################################
#
# $ID$
#
# Makefile for san_mgmt
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
	
all: san_mgmt

san_mgmt: san_mgmt.c 
	 gcc $(CFLAGS) -o san_mgmt san_mgmt.c $(INCLOPTS) $(LINKOPTS)

clean:
	rm -f san_mgmt
	
