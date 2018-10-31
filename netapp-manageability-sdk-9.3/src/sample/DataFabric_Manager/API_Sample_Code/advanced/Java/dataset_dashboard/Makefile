JAVAC=javac
JAVA=java

CLASSPATH = ../../../../../../../lib/java/classes/manageontap-9.3.jar:../../../../../../java/classes

all :
	$(JAVAC) -deprecation -classpath .:$(CLASSPATH) dataset_health.java dataset_metrics.java

clean :
	rm -fr *.class

dataset_health :
	$(JAVA) -classpath .:$(CLASSPATH) dataset_health sweetpea root tryme 

dataset_metrics :
	$(JAVA) -classpath .:$(CLASSPATH) dataset_metrics sweetpea root tryme
