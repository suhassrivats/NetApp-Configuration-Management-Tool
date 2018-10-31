#
# $ID$
#
# Makefile for vserver.java
#
# Copyright 2013 NetApp, Inc. All rights reserved.
# Specifications subject to change without notice.

# Note:This makefile assumes that your PATH contains
# the bin directory which has java and javac.

JAVAC=javac
JAVA=java

CLASSPATH = ../../../../../../lib/java/classes/manageontap-9.3.jar:../../../../../java/classes/manageontap-9.3.jar

all :
	$(JAVAC) -classpath $(CLASSPATH) vserver.java

clean :
	rm -fr *.class

test :
	$(JAVA) -classpath .:$(CLASSPATH) vserver sweetpea root tryme
