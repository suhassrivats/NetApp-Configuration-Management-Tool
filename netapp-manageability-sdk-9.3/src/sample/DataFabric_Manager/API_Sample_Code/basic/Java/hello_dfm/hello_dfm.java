/*
 * $Id:$
 *
 * hello_dfm.java
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * This program will print the version number of the DFM Server
 *
 * This Sample code is supported from DataFabric Manager 3.6R2
 * onwards.   
 * However few of the functionalities of the sample code may
 * work on older versions of DataFabric Manager.
 */

import netapp.manage.*;

public class hello_dfm {

    public static void main(String[] args) {

        NaElement requestElem;
        NaElement responseElem;
        NaServer s;

        if (args.length < 3) {
            System.err.println("Usage: hello_dfm dfmserver dfmuser dfmpasswd");
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

            // Invokes ONTAPI API to get the DFM server version
            requestElem = new NaElement("dfm-about");

            responseElem = s.invokeElem(requestElem);
            System.out.print("Hello world!  DFM Server version is: ");
            System.out.println(responseElem.getChildContent("version"));
            s.close();
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}
