##############################################################
#
#
# Makefile for vserverlist
#
# Copyright 2011 NetApp, Inc. All rights reserved. 
# Specifications subject to change without notice.
#
##############################################################

include ../../../../Makefile.common

all: vserverlist

vserverlist: vserverlist.c 
	 gcc $(CFLAGS) -o vserverlist vserverlist.c $(INCLOPTS) $(LINKOPTS)

clean:
	rm -f vserverlist
	
