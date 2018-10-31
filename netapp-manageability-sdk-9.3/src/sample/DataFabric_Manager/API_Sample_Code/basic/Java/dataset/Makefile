JAVAC=javac
JAVA=java

CLASSPATH = ../../../../../../../lib/java/classes/manageontap-9.3.jar:../../../../../../java/classes

all :
	$(JAVAC) -deprecation -classpath $(CLASSPATH) dataset.java

clean :
	rm -fr *.class

test :
	$(JAVA) -classpath .:$(CLASSPATH) dataset sweetpea root tryme
