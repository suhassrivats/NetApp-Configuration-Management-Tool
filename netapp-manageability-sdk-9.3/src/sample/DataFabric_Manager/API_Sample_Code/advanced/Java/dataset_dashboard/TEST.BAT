@rem This makefile assumes that your PATH contains
@rem the bin directory which has java and javac.

@rem You may have to adjust the value of CL to
@rem find the manageontap-9.3.jar file.

@rem change the name of the filer and root account info
@rem to suit your test environment

@echo OFF

IF "%~1"=="dataset_health" (
    GOTO :COMMAND
) ELSE IF "%~1"=="dataset_metrics" (
    GOTO :COMMAND
) ELSE (
    echo.
    echo Usage :
    echo test dataset_health
    echo test dataset_metrics
    GOTO :EOF
)
:COMMAND
    echo java -classpath .;../../../../../../../lib/java/classes/manageontap-9.3.jar;../../../../../../java/classes %~1 sweetpea root tryme
    java -classpath .;../../../../../../../lib/java/classes/manageontap-9.3.jar;../../../../../../java/classes %~1 sweetpea root tryme
