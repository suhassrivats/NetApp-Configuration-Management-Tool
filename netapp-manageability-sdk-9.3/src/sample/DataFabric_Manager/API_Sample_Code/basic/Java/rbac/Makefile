JAVAC=javac
JAVA=java

CLASSPATH = ../../../../../../../lib/java/classes/manageontap-9.3.jar:../../../../../../java/classes

all :
	$(JAVAC) -deprecation -classpath $(CLASSPATH) rbac.java

clean :
	rm -fr *.class

test :
	$(JAVA) -classpath .:$(CLASSPATH) rbac sweetpea root tryme 
