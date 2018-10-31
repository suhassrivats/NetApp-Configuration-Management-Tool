JAVAC=javac
JAVA=java

CLASSPATH = ../../../../../../../lib/java/classes/manageontap-9.3.jar:../../../../../../java/classes

all :
	$(JAVAC) -deprecation -classpath $(CLASSPATH) dfm_schedule.java

clean :
	rm -fr *.class

test :
	$(JAVA) -classpath .:$(CLASSPATH) dfm_schedule sweetpea root tryme
