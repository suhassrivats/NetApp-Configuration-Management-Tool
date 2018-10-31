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
CXF_JAR=${CXF_HOME}/lib/cxf-manifest.jar
TRUSTSTORE=

if [ ! -d "${STUBS_PATH}/com/netapp/management" ]
then
    echo Stubs directory ${STUBS_PATH}/com/netapp/management not found.
    exit
fi

if [ "${1}" != "UsageMetrics" -a  "${1}" != "StorageService" ]
then
    echo "usage: test.sh UsageMetrics | StorageService"
    exit
fi

echo ${JAVA_HOME}/bin/java -cp ".:${STUBS_PATH}:${CXF_JAR}:${CLASSPATH}" -Djava.util.logging.config.file="${CXF_HOME}/etc/logging.properties" "$@"
${JAVA_HOME}/bin/java -cp ".:${STUBS_PATH}:${CXF_JAR}:${CLASSPATH}" -Djava.util.logging.config.file="${CXF_HOME}/etc/logging.properties" "$@"
