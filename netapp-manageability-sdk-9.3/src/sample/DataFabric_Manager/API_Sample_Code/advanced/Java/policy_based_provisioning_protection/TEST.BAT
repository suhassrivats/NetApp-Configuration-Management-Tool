@rem This makefile assumes that your PATH contains
@rem the bin directory which has java and javac.

@rem You may have to adjust the value of CL to
@rem find the manageontap-9.3.jar file.

@rem change the name of the filer and root account info
@rem to suit your test environment

@echo OFF

IF "%~1"=="dataset" (
    GOTO :COMMAND
) ELSE IF "%~1"=="multistore" (
    GOTO :COMMAND
) ELSE IF "%~1"=="policy" (
    GOTO :COMMAND
) ELSE IF "%~1"=="resource_pool" (
    GOTO :COMMAND
) ELSE (
    echo.
    echo Usage :
    echo test dataset
    echo test multistore
    echo test policy
    echo test resource_pool
    GOTO :EOF
)
:COMMAND
    echo java -classpath .;../../../../../../../lib/java/classes/manageontap-9.3.jar;../../../../../../java/classes %~1 sweetpea root tryme
    java -classpath .;../../../../../../../lib/java/classes/manageontap-9.3.jar;../../../../../../java/classes %~1 sweetpea root tryme
