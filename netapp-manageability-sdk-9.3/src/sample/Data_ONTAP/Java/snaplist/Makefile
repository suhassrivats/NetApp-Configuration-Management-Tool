# This makefile assumes that your PATH contains 
# the bin directory which has java and javac.
#
# You may have to adjust the value of CL to
# find the manageontap-9.3.jar file.

JAVAC=javac
JAVA=java

CLASSPATH = ../../../../../lib/java/classes/manageontap-9.3.jar:../../../../java/classes

all :
	$(JAVAC) -deprecation -classpath $(CLASSPATH) snaplist.java

clean :
	rm -fr *.class

test :
	$(JAVA) -classpath .:$(CLASSPATH) snaplist sweetpea root tryme

