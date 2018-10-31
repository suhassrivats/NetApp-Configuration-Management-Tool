@echo off
setlocal EnableDelayedExpansion

IF "%1"=="FROM_VSSTUDIO" (
    IF NOT EXIST "DfmService.dll" (
      echo Stub dll DfmService.dll Not found. You need to run MAKE.BAT file from Visual Studio 2005 Command Prompt to generate stub dll..
    )
    goto END
)
IF NOT DEFINED VSINSTALLDIR (
       @echo VSINSTALLDIR not defined. You need to run this file from Visual Studio 2005 Command Prompt.. 
       goto END
)

set STUB_PATH=.
set STUB_FILE=DfmService.cs
set STUB_DLL=DfmService.dll

set DFM_VER=5.6D1
set WSDL_FILE_NAME=dfm-%DFM_VER%.wsdl
set WSDL_PATH=..\..\..\..\..\wsdl
set WSDL_DOC_PATH=..\..\..\..\..\doc\DataFabric_Manager
set WSDL_FILE=%WSDL_PATH%\%WSDL_FILE_NAME%

IF NOT EXIST "%WSDL_FILE%" (
    REM Look in doc path  
    IF NOT EXIST "%WSDL_DOC_PATH%\%WSDL_FILE_NAME%" (
        @echo %WSDL_FILE% file not found.
        goto END
    )
    set WSDL_FILE=%WSDL_DOC_PATH%\%WSDL_FILE_NAME%
)

@echo Generating stub file from !WSDL_FILE! file into %STUB_PATH%\%STUB_FILE% ..
wsdl.exe /l:CS /out:%STUB_PATH%\%STUBS_FILE% %WSDL_FILE%
@echo Done generating stub file.
@echo .
@echo Compiling stub dll into %STUB_PATH%\%STUB_DLL%
csc.exe /t:library /out:%STUB_PATH%\%STUB_DLL% %STUB_PATH%\%STUB_FILE%
@echo Done generating stub dll.

: END
