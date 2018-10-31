##############################################################
#
#
# Makefile for vollist
#
# Copyright 2011 NetApp, Inc. All rights reserved. 
# Specifications subject to change without notice.
#
##############################################################

include ../../../../Makefile.common

all: vollist

vollist: vollist.c 
	 gcc $(CFLAGS) -o vollist vollist.c $(INCLOPTS) $(LINKOPTS)

clean:
	rm -f vollist
	
