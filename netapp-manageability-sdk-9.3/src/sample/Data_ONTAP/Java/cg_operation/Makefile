#
# $ID$
#
# Makefile for cg_operation.java
#
# Copyright 2002-2013 Network Appliance, Inc. All rights     
# reserved. Specifications subject to change without notice. 

# Note:This makefile assumes that your PATH contains 
# the bin directory which has java and javac.
# You may have to adjust the value of CL to
# find the manageontap-9.3.jar file.

JAVAC=javac
JAVA=java

CLASSPATH = ../../../../../lib/java/classes/manageontap-9.3.jar:../../../../java/classes

all :
	$(JAVAC)  -classpath $(CLASSPATH) cg_operation.java

clean :
	rm -fr *.class

test :
	$(JAVA) -classpath .:$(CLASSPATH) cg_operation  sweetpea  root tryme cg-start mysnapshot medium vol1 vol2 
