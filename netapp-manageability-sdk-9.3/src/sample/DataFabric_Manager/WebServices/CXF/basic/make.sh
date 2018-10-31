#!/bin/sh

if [ "${CXF_HOME}" = "" ] 
then
   echo CXF_HOME not defined. Set CXF_HOME to the path where apache-cxf is installed.
   exit
fi

if [ "${JAVA_HOME}" = "" ]
then
   echo JAVA_HOME not defined. Set JAVA_HOME to the path where JDK is installed.
   exit
fi

if [ ! -f "${CXF_HOME}/lib/cxf-manifest.jar" ] 
then 
   echo ${CXF_HOME}/lib/cxf-manifest.jar file not found.
   exit
fi

STUBS_PATH=..
GENERATE_STUBS=TRUE

DFM_VER=5.2
WSDL_FILE_NAME=dfm-${DFM_VER}.wsdl
WSDL_PATH=../../../../../wsdl
WSDL_DOC_PATH=../../../../../doc/DataFabric_Manager
WSDL_FILE=${WSDL_PATH}/${WSDL_FILE_NAME}
CXF_JAR=${CXF_HOME}/lib/cxf-manifest.jar

export PATH="${JAVA_HOME}/bin:${PATH}"

if [ -d "${STUBS_PATH}/com" -a "${1}" != "-r" ]
then
    GENERATE_STUBS="FALSE"
fi

if [ "${GENERATE_STUBS}" = "TRUE" ]
then
    if [ ! -f "${WSDL_FILE}" ]
    then
        if [ ! -f "${WSDL_DOC_PATH}/${WSDL_FILE_NAME}" ]
        then
            echo ${WSDL_FILE} file not found.
            exit
        else
            WSDL_FILE=${WSDL_DOC_PATH}/${WSDL_FILE_NAME}
        fi
    fi
    if [ -d "${STUBS_PATH}/com" ]
    then
        rm -fr ${STUBS_PATH}/com
    fi
    echo Generating and compiling stubs from ${WSDL_FILE} file into ${STUBS_PATH}/com/netapp/management ..
    ${JAVA_HOME}/bin/java -Xmx256M -cp "${CXF_JAR}:${CLASSPATH}" -Djava.util.logging.config.file="${CXF_HOME}/etc/logging.properties" org.apache.cxf.tools.wsdlto.WSDLToJava  -compile -d ${STUBS_PATH} ${WSDL_FILE}
    echo Done compiling stubs.
else
    echo Stubs directory ${STUBS_PATH}/com exists. Skipping re-generating and compiling stubs. Use -r option to re-generate stubs.
fi

echo Compiling HelloDfm.java Vfiler.java ..
${JAVA_HOME}/bin/javac -cp "${STUBS_PATH}:${CXF_JAR}" HelloDfm.java Vfiler.java

echo Done.
