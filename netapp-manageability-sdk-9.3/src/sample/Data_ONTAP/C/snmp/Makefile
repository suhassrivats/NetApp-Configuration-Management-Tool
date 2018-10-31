##############################################################
#
# $Id: //depot/prod/zephyr/Rdarjeeling/src/sample/C/snmp/Makefile#1 $
#
# Makefile for snmp 
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

all: snmp 

snmp: snmp.c 
	 gcc $(CFLAGS) -o snmp snmp.c $(INCLOPTS) $(LINKOPTS)

clean:
	rm -f snmp 
