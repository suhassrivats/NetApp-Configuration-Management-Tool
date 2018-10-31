JAVAC=javac
JAVA=java

CLASSPATH = ../../../../../../../lib/java/classes/manageontap-9.3.jar:../../../../../../java/classes

all :
	$(JAVAC) -deprecation -classpath $(CLASSPATH) perfAggrLatency.java perfCpuUtil.java  perfDiskLatency.java  perfVolLatency.java

clean :
	rm -fr *.class

aggr:
	$(JAVA) -classpath .:$(CLASSPATH) perfAggrLatency 

cpu:
	$(JAVA) -classpath .:$(CLASSPATH) perfCpuUtil

disk:
	$(JAVA) -classpath .:$(CLASSPATH) perfDiskLatency

vol:
	$(JAVA) -classpath .:$(CLASSPATH) perfVolLatency
