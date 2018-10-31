@echo off
setlocal

IF NOT DEFINED CXF_HOME (
   @echo CXF_HOME not defined. Set CXF_HOME to the path where apache-cxf is installed.
   goto END
)
IF NOT DEFINED JAVA_HOME (
   @echo JAVA_HOME not defined. Set JAVA_HOME to the path where JDK/JRE is installed.
   goto END
)
IF NOT EXIST "%CXF_HOME%\lib\cxf-manifest.jar"  (
    @echo "%CXF_HOME%\lib\cxf-manifest.jar" file not found.
    goto END
)

set STUBS_PATH=..
set CXF_JAR=%CXF_HOME%\lib\cxf-manifest.jar
set TRUSTSTORE=

IF NOT EXIST "%STUBS_PATH%\com\netapp\management" (
    @echo Stubs directory %STUBS_PATH%\com\netapp\management not found.
    goto END
)
IF "%1"=="HelloDfm" (
    IF NOT DEFINED DFM_KEYSTORE (
        echo DFM_KEYSTORE not defined. This is required for HTTPS. Set DFM_KEYSTORE to the path and file name of the Java key store where the server certificate is stored.
        echo.
    ) ELSE (
        set TRUSTSTORE=-Djavax.net.ssl.trustStore="%DFM_KEYSTORE%"
    )
    goto READ_ARGS
) ELSE IF "%1"=="Vfiler" (
    goto READ_ARGS
) ELSE (
    @echo "Usage: TEST HelloDfm | Vfiler"
    goto END
)

:READ_ARGS
shift
set ARGS=%ARGS% %0
IF NOT "%1"=="" goto READ_ARGS

: CMD
@echo "%JAVA_HOME%\bin\java" -cp ".;%STUBS_PATH%;%CXF_JAR%" -Djava.util.logging.config.file="%CXF_HOME%\etc\logging.properties" %TRUSTSTORE% %ARGS%
"%JAVA_HOME%\bin\java" -cp ".;%STUBS_PATH%;%CXF_JAR%" -Djava.util.logging.config.file="%CXF_HOME%\etc\logging.properties" %TRUSTSTORE% %ARGS%

: END