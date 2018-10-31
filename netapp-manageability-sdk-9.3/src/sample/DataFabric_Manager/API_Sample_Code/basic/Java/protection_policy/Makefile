JAVAC=javac
JAVA=java

CLASSPATH = ../../../../../../../lib/java/classes/manageontap-9.3.jar:../../../../../../java/classes

all :
	$(JAVAC) -deprecation -classpath $(CLASSPATH) protection_policy.java

clean :
	rm -fr *.class

test :
	$(JAVA) -classpath .:$(CLASSPATH) protection_policy sweetpea root tryme
