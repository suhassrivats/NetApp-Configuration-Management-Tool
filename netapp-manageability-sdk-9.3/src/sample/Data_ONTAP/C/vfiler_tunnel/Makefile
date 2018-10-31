##############################################################
#
# $ID$
#
# Makefile for vfiler_tunnel
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

all: vfiler_tunnel

vfiler_tunnel: vfiler_tunnel.c 
	gcc $(CFLAGS) -o vfiler_tunnel vfiler_tunnel.c $(INCLOPTS) $(LINKOPTS)

clean:
	rm -f vfiler_tunnel
	
