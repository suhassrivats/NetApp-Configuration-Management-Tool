#
# $ID$
#
# Makefile for vserver_tunnel.java
#
# Copyright 2013 NetApp, Inc. All rights reserved.
# Specifications subject to change without notice.
#
# Note:This makefile assumes that your PATH contains
# the bin directory which has java and javac.
# You may have to adjust the value of CLASSPATH to
# find the manageontap-9.3.jar file.

JAVAC=javac
JAVA=java

CLASSPATH = ../../../../../../lib/java/classes/manageontap-9.3.jar:../../../../../java/classes/manageontap-9.3.jar

all :
	$(JAVAC)  -classpath $(CLASSPATH) vserver_tunnel.java

clean :
	rm -fr *.class

test :
	$(JAVA) -classpath .:$(CLASSPATH) vserver_tunnel myvserver sweetpea root tryme system-get-version
