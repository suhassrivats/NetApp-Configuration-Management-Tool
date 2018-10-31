/*
 * $Id:$
 *
 * dfm_proxy.java
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * Sample code to demonstrate how to use DFM server
 * as a proxy in sending ONTAPI API commands to a filer
 *
 * This Sample code is supported from DataFabric Manager 3.6R2
 * onwards.   
 * However few of the functionalities of the sample code may
 * work on older versions of DataFabric Manager.
 */

import netapp.manage.*;

public class dfm_proxy {

    public static void main(String[] args) {

        NaElement apiRequest;
        NaElement proxyElem;
        NaElement out;
        NaElement dfmResponse;
        NaElement apiResponse;
        NaServer s;

        if (args.length < 4) {
            System.err.println("Usage: dfm_proxy dfmserver dfmuser "
                    + "dfmpasswd filerip");
            System.exit(1);
        }
        try {
            // Initialize connection to server, and
            // request version 1.0 of the API set
            //
            s = new NaServer(args[0], 1, 0);
            s.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            s.setTransportType(NaServer.TRANSPORT_TYPE_HTTP);
            s.setServerType(NaServer.SERVER_TYPE_DFM);
            s.setPort(8088);
            s.setAdminUser(args[1], args[2]);

            // Invokes ONTAPI API to get the ONTAP
            // version number of a filer
            proxyElem = new NaElement("api-proxy");
            proxyElem.addNewChild("target", args[3]);
            apiRequest = new NaElement("request");
            apiRequest.addNewChild("name", "system-get-version");
            proxyElem.addChildElem(apiRequest);

            out = s.invokeElem(proxyElem);
            dfmResponse = out.getChildByName("response");
            if (dfmResponse.getChildContent("status").equals("passed") != true) {
                System.out.println("Error: "
                        + dfmResponse.getChildContent("reason"));
            } else {
                apiResponse = dfmResponse.getChildByName("results");
                System.out.println("Hello world!  DOT version of " + args[3]
                        + "got from DFM-Proxy is "
                        + apiResponse.getChildContent("version"));
            }
            s.close();
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}
