#
# $ID$
#
# Makefile for apitest.java
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
	$(JAVAC)  -classpath $(CLASSPATH) apitest.java

clean :
	rm -fr *.class

test :
	$(JAVA) -classpath .:$(CLASSPATH)  apitest sweetpea root tryme   
