##############################################################
#
# $ID$
#
# Makefile for perf_operation.c
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

all: clean perf_operation

perf_operation: perf_operation.c
	 gcc $(CFLAGS) -o perf_operation perf_operation.c $(INCLOPTS) $(LINKOPTS)

clean:
	rm -f perf_operation
