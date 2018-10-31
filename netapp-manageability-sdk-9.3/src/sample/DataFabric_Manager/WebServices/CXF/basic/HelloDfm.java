/*
 * $Id:$
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 */

import java.util.Map;

import javax.xml.ws.BindingProvider;
import javax.xml.ws.soap.SOAPFaultException;
import org.apache.cxf.configuration.jsse.TLSClientParameters;
import org.apache.cxf.frontend.ClientProxy;
import org.apache.cxf.transport.http.HTTPConduit;
import javax.net.ssl.TrustManager;
import java.security.cert.*;
import javax.net.ssl.*;

import com.netapp.management.v1.*;

/**
 * This class will print the version number of the DFM Server
 *
 * This Sample code is supported from DataFabric Manager 4.0 onwards.
 */
public final class HelloDfm {

    /**
    * The default HTTP and HTTPS port numbers for the DFM server.
    */
    private static final int DEFAULT_DFM_HTTP_PORT = 8088;
    private static final int DEFAULT_DFM_HTTPS_PORT = 8488;

    /**
     * Client interface to the DFM server
     */
    private static DfmInterface dfmInterface;

    public static void main(String args[]) throws Exception {

        if (args.length < 3) {
            printUsageAndExit();
        }

        String dfmServer = args[0];
        String dfmUser = args[1];
        String dfmPwd = args[2];
        boolean useHttps = false;
        boolean ignoreCert = false;
        
        if (args.length > 3) {
            if (!args[3].equals("-s")) {
                printUsageAndExit();
            }
            useHttps = true;
            if(args.length > 4) {
                if(args[4].equals("-i")) {
                    ignoreCert = true;
                }
                else {
                    printUsageAndExit();
                }
            }
        }

        dfmInterface = createDfmInterface(dfmServer, dfmUser, dfmPwd, useHttps, ignoreCert);

        dfmAbout();
    }

    /**
     * Creates the client proxy that you can use to invoke DFM APIs.
     */
    private static DfmInterface createDfmInterface(String dfmServer, String dfmUser, String dfmPwd, boolean useHttps, boolean ignoreCert) {
        String protocol = "http";
        int portno = DEFAULT_DFM_HTTP_PORT;
        
        if (useHttps) {
            protocol = "https";
            portno = DEFAULT_DFM_HTTPS_PORT;
        }

        String url = protocol + "://" + dfmServer + ":" + portno + "/apis/soap/v1";

        DfmService ss = new DfmService();
        DfmInterface dfmInterface = ss.getDfmPort();

        BindingProvider provider = (BindingProvider) dfmInterface;
        Map<String, Object> reqContext = provider.getRequestContext();
        reqContext.put(BindingProvider.USERNAME_PROPERTY, dfmUser);
        reqContext.put(BindingProvider.PASSWORD_PROPERTY, dfmPwd);
        reqContext.put(BindingProvider.ENDPOINT_ADDRESS_PROPERTY, url);

        if (useHttps && ignoreCert) {
            HTTPConduit httpConduit = (HTTPConduit) ClientProxy.getClient(dfmInterface).getConduit();
            TLSClientParameters tlsParams = new TLSClientParameters();

            // Create a trust manager that will trust all the certificates supplied by the server.
            TrustManager[] trustAllCerts = new TrustManager[] { 
                    new X509TrustManager() {
                        public X509Certificate[] getAcceptedIssuers() {
                            return null;
                        }
                        public void checkClientTrusted(java.security.cert.X509Certificate[] certs, String authType) {
                        }
                        public void checkServerTrusted(java.security.cert.X509Certificate[] certs, String authType) {
                        }
                    } 
            };
            // Trust the servers host name against that certificate.
            tlsParams.setDisableCNCheck(true);
            tlsParams.setTrustManagers(trustAllCerts);
            httpConduit.setTlsClientParameters(tlsParams); 
        }
        return dfmInterface;
    }

    /**
     * Calls the DfmAbout API and prints the results.
     */
    private static void dfmAbout() {
        try {
            // Creating a dfmAbout instance
            DfmAbout dfmAboutParam = new DfmAbout();
            // Invoking the dfm about API and capturing the output datastructure
            DfmAboutResult dfmAboutRes = dfmInterface.dfmAbout(dfmAboutParam);
            // Extracting and printing the version info from dfmAboutRes output
            // structure returned by the API
            System.out.println("\nHello world!  DFM Server version is: " + dfmAboutRes.getVersion());
            
        } catch (SOAPFaultException se) {
            // printing error string if any. the string has the error code and
            // the error description
            System.err.println(se.getFault().getFaultString());
        }
    }

    private static void printUsageAndExit() {
        System.out.println("Usage: HelloDfm <dfmserver> <user> <passwd> [ -s [ -i ] ]\n");
        System.out.println("  -s          Use HTTPS");
        System.out.println("  -i          Ignore server certificate validation for HTTPS\n");
        System.exit(1);
    }

}
