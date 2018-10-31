JAVAC=javac
JAVA=java

CLASSPATH = ../../../../../../../lib/java/classes/manageontap-9.3.jar:../../../../../../java/classes

all :
	$(JAVAC) -deprecation -classpath $(CLASSPATH) vfiler.java

clean :
	rm -fr *.class

test :
	$(JAVA) -classpath .:$(CLASSPATH) vfiler sweetpea root tryme
