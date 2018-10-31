JAVAC=javac
JAVA=java

CLASSPATH = ../../../../../../../lib/java/classes/manageontap-9.3.jar:../../../../../../java/classes

all :
	$(JAVAC) -deprecation -classpath $(CLASSPATH) dfm_proxy.java

clean :
	rm -fr *.class

test :
	$(JAVA) -classpath .:$(CLASSPATH) dfm_proxy <dfmserver> <dfmuser> <dfmpasswd> <filerip>
