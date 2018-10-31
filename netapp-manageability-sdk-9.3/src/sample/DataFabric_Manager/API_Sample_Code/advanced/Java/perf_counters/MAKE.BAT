@rem This makefile assumes that your PATH contains 
@rem the bin directory which has java and javac.
@rem
@rem You may have to adjust the value of CL to
@rem find the manageontap-9.3.jar file.

javac -classpath ../../../../../../../lib/java/classes/manageontap-9.3.jar;../../../../../../java/classes -deprecation perfAggrLatency.java  perfCpuUtil.java  perfDiskLatency.java  perfVolLatency.java

