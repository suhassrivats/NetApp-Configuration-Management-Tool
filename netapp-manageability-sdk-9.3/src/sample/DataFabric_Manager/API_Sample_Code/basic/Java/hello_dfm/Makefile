JAVAC=javac
JAVA=java

CLASSPATH = ../../../../../../../lib/java/classes/manageontap-9.3.jar:../../../../../../java/classes

all :
	$(JAVAC) -deprecation -classpath $(CLASSPATH) hello_dfm.java

clean :
	rm -fr *.class

test :
	$(JAVA) -classpath .:$(CLASSPATH) hello_dfm <dfmserver> <dfmuser> <dfmpasswd>
