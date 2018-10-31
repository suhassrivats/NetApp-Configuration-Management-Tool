##############################################################
#
# $ID$
#
# Makefile for dfm_proxy
#
# Copyright (c) 2009 NetApp, Inc. All rights reserved.
# Specifications subject to change without notice.
#                                                            
##############################################################

include ../../../../../Makefile.common

all:dfm_proxy

dfm_proxy: dfm_proxy.c
	gcc $(CFLAGS) -o dfm_proxy dfm_proxy.c $(INCLOPTS) $(LINKOPTS)

clean:
	rm -f dfm_proxy
	
