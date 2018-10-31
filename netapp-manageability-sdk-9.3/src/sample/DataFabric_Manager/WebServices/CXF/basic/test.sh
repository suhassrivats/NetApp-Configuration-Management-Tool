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

if [ "${1}" != "HelloDfm" -a  "${1}" != "Vfiler" ]
then
    echo "usage: test.sh HelloDfm | Vfiler"
    exit
fi

if [ "${1}" = "HelloDfm" ]
then
    if [ "${DFM_KEYSTORE}" = "" ] 
    then
        echo DFM_KEYSTORE not defined. This is required for HTTPS. Set DFM_KEYSTORE to the path and file name of the Java key store where the server certificate is stored.
        echo
    else 
        TRUSTSTORE=-Djavax.net.ssl.trustStore=${DFM_KEYSTORE}
    fi
fi

echo ${JAVA_HOME}/bin/java -cp ".:${STUBS_PATH}:${CXF_JAR}:${CLASSPATH}" -Djava.util.logging.config.file="${CXF_HOME}/etc/logging.properties" ${TRUSTSTORE} "$@"
${JAVA_HOME}/bin/java -cp ".:${STUBS_PATH}:${CXF_JAR}:${CLASSPATH}" -Djava.util.logging.config.file="${CXF_HOME}/etc/logging.properties" ${TRUSTSTORE} "$@"
