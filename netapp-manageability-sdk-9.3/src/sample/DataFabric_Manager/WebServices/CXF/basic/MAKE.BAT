@echo off
setlocal EnableDelayedExpansion

IF NOT DEFINED CXF_HOME (
   @echo CXF_HOME not defined. Set CXF_HOME to the path where apache-cxf is installed.
   goto END
)
IF NOT DEFINED JAVA_HOME (
   @echo JAVA_HOME not defined. Set JAVA_HOME to the path where JDK is installed.
   goto END
)
IF NOT EXIST "%CXF_HOME%\lib\cxf-manifest.jar"  (
    @echo "%CXF_HOME%\lib\cxf-manifest.jar" file not found.
    goto END
)

set CXF_JAR=%CXF_HOME%\lib\cxf-manifest.jar
set STUBS_PATH=..
set GENERATE_STUBS=TRUE

set DFM_VER=5.2
set WSDL_FILE_NAME=dfm-%DFM_VER%.wsdl
set WSDL_PATH=..\..\..\..\..\wsdl
set WSDL_DOC_PATH=..\..\..\..\..\doc\DataFabric_Manager
set WSDL_FILE=%WSDL_PATH%\%WSDL_FILE_NAME%

IF EXIST "%STUBS_PATH%\com" (
    IF NOT "%~1" == "-r" (
        set GENERATE_STUBS=FALSE
    )
)

IF %GENERATE_STUBS%==TRUE  (
    IF NOT EXIST "%WSDL_FILE%" (
          REM Look in doc path  
        IF NOT EXIST "%WSDL_DOC_PATH%\%WSDL_FILE_NAME%" (
            @echo %WSDL_FILE% file not found.
            goto END
        )
        set WSDL_FILE=%WSDL_DOC_PATH%\%WSDL_FILE_NAME%
    )
    IF EXIST "%STUBS_PATH%\com" (
        rmdir/s/q "%STUBS_PATH%\com"
    )
    @echo Generating and compiling stubs from !WSDL_FILE! file into %STUBS_PATH%\com\netapp\management ..
    "%JAVA_HOME%\bin\java" -Xmx256M -cp "%CXF_JAR%;%CLASSPATH%" -Djava.util.logging.config.file="%CXF_HOME%\etc\logging.properties" org.apache.cxf.tools.wsdlto.WSDLToJava  -compile -d %STUBS_PATH% !WSDL_FILE!
    @echo Done compiling stubs.
) ELSE (
    @echo Stubs directory %STUBS_PATH%\com exists. Skipping re-generating and compiling stubs. Use -r option to re-generate stubs.
)

@echo Compiling HelloDfm.java Vfiler.java ..
"%JAVA_HOME%\bin\javac" -cp "%STUBS_PATH%;%CXF_JAR%" HelloDfm.java Vfiler.java
@echo Done.

: END
