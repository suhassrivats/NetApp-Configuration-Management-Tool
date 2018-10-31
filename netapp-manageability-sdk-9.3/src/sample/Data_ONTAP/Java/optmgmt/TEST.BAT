@rem This makefile assumes that your PATH contains 
@rem the bin directory which has java and javac.

@rem You may have to adjust the value of CL to
@rem find the manageontap-9.3.jar file.

@rem change the name of the filer and root account info
@rem to suit your test environment

java -classpath .;../../../../../lib/java/classes/manageontap-9.3.jar;../../../../java/classes optmgmt ijaz root tryme

