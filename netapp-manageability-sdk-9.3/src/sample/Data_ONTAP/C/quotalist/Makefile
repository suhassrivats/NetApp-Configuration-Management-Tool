##############################################################
#
# $Id:$
#
# Makefile for Quotalist
#
# 
# Copyright 2007 Network Appliance, Inc. All rights     
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

all: quotalist 

quotalist: quotalist.c 
	 gcc $(CFLAGS) -o quotalist quotalist.c $(INCLOPTS) $(LINKOPTS)

clean:
	rm -f quotalist 
	
