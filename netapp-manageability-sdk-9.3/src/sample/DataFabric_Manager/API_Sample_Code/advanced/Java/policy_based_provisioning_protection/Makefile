JAVAC=javac
JAVA=java

CLASSPATH = ../../../../../../../lib/java/classes/manageontap-9.3.jar:../../../../../../java/classes

all :
	$(JAVAC) -deprecation -classpath .:$(CLASSPATH) dataset.java resource_pool.java multistore.java policy.java

clean :
	rm -fr *.class

dataset :
	$(JAVA) -classpath .:$(CLASSPATH) dataset sweetpea root tryme 

resource_pool :
	$(JAVA) -classpath .:$(CLASSPATH) resource_pool sweetpea root tryme

multistore :
	$(JAVA) -classpath .:$(CLASSPATH) multistore sweetpea root tryme

policy :
	$(JAVA) -classpath .:$(CLASSPATH) policy sweetpea root tryme
