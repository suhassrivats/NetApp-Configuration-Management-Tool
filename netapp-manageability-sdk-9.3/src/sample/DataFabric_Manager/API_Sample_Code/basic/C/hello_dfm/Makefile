##############################################################
#
# $ID$
#
# Makefile for hello_dfm
#
# Copyright (c) 2009 NetApp, Inc. All rights reserved.
# Specifications subject to change without notice.    
#                                                            
##############################################################

include ../../../../../Makefile.common

all:hello_dfm

hello_dfm: hello_dfm.c
	gcc $(CFLAGS) -o hello_dfm hello_dfm.c $(INCLOPTS) $(LINKOPTS)

clean:
	rm -f hello_dfm
	
