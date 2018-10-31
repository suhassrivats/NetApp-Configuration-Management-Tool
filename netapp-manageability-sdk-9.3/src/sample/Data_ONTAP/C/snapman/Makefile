##############################################################
#
# $ID$
#
# Makefile for snapman
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

all: snapman

OBJ = snapman.o ../util/na_snapshot.o ../util/na_server.o ../util/ontapiver.o

snapman: $(OBJ)
	@echo "Linking snapman ..."
	@$(CC) $(CFLAGS) -o snapman $(OBJ) $(LINKOPTS)

clean:
	@rm -f ../util/*.o
	@rm -f *.o
	@rm -f snapman
	
%.o: %.c
	@echo "Compiling $(<) ..."
	gcc $(CFLAGS) $(INCLOPTS) $(<) -c -o $(@)
#	@$(CC) $(CFLAGS) $(INCLOPTS) $(<) -c -o $(@)
