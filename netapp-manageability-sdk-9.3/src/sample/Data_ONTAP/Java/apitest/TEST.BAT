@rem This makefile assumes that your PATH contains 
@rem the bin directory which has java and javac.

@rem You may have to adjust the value of CL to
@rem find the manageontap-9.3.jar file.

@rem change the name of the filer and root account info
@rem to suit your test environment

@ECHO OFF
echo.
echo "If You wish to invoke the API using RPC mechanism, run as following:"
echo "Example:-  java -Djava.library.path=../../../../../lib/nt -classpath .;../../../../../lib/java/classes/manageontap-9.3.jar;../../../../java/classes apitest -r sweetpea root tryme system-get-info  "
echo.
echo.
echo "If You wish to invoke the API without using RPC mechanism, run as following:"
echo "Example:-  java -classpath .;../../../../../lib/java/classes/manageontap-9.3.jar;../../../../java/classes apitest sweetpea root tryme system-get-info  "


