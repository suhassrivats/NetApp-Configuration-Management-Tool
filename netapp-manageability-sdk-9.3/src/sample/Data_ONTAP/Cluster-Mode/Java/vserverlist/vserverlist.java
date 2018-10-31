/*
 *
 * vserverlist.java
 *
 * Copyright (c) 2011 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * Sample code to list the vservers available in the cluster.
 * This sample code demonstrates the usage of new iterative 
 * vserver-get-iter API.
 *
 * This Sample code is supported from Cluster-Mode 
 * Data ONTAP 8.1 onwards.
 *
 */

import java.io.IOException;
import java.util.List;
import java.util.Iterator;

import netapp.manage.*;

public class vserverlist {
    static NaServer server;
    static String user;
    static String passwd;
    static String ipaddr;
    static String args[];

    public static void printUsageAndExit() {
        System.out.println("\nUsage: \n");
        System.out.println("vserverlist <cluster/vserver> <user> <passwd> [-v <vserver-name>]");
        System.out.println("<cluster>             -- IP address of the cluster");
        System.out.println("<vserver>             -- IP address of the vserver");
        System.out.println("<user>                -- User name");
        System.out.println("<passwd>              -- Password");
        System.out.println("<vserver-name>        -- Name of the vserver \n");
        System.out.println("Note: ");
        System.out.println(" -v switch is required when you want to tunnel the command to a vserver using cluster interface");
        System.exit(-1);
    }

    public static void listVservers() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in, out;
        String rootVol, rootVolAggr, secStyle, state;
        String tag = "";

        while (tag != null) {
            in = new NaElement("vserver-get-iter");
            if (args.length > 3) {
                if (args.length < 5 || !args[3].equals("-v")) {
                    printUsageAndExit();
                }
                server.setVserver(args[4]);
            }
            if (!tag.equals("")) {
                in.addNewChild("tag", tag);
            }
            out = server.invokeElem(in);
            if (out.getChildIntValue("num-records", 0) == 0) {
                System.out.println("No vserver(s) information available\n");
                return;
            }
            tag = out.getChildContent("next-tag");
            List vserverList = out.getChildByName("attributes-list").getChildren();
            Iterator vserverIter = vserverList.iterator();
            System.out.println("----------------------------------------------------");
            while(vserverIter.hasNext()) {
                NaElement vserverInfo =(NaElement)vserverIter.next();
                System.out.println("Name                    : " + vserverInfo.getChildContent("vserver-name"));
                System.out.println("Type                    : " + vserverInfo.getChildContent("vserver-type"));
                rootVolAggr = vserverInfo.getChildContent("root-volume-aggregate");
                rootVol = vserverInfo.getChildContent("root-volume");
                secStyle = vserverInfo.getChildContent("root-volume-security-style");
                state = vserverInfo.getChildContent("state");
                System.out.println("Root volume aggregate   : " + (rootVolAggr != null ? rootVolAggr : ""));
                System.out.println("Root volume             : " + (rootVol != null ? rootVol : ""));
                System.out.println("Root volume sec style   : " + (secStyle != null ? secStyle : ""));
                System.out.println("UUID                    : " + vserverInfo.getChildContent("uuid"));
                System.out.println("State                   : " + (state != null ? state : ""));
                NaElement allowedProtocols = null;
                System.out.print("Allowed protocols       : ");
                if ((allowedProtocols = vserverInfo.getChildByName("allowed-protocols")) != null) {
                    List allowedProtocolsList = allowedProtocols.getChildren();
                    Iterator allowedProtocolsIter = allowedProtocolsList.iterator();
                    while(allowedProtocolsIter.hasNext()){
                        NaElement protocol = (NaElement) allowedProtocolsIter.next();
                        System.out.print(protocol.getContent() + " ");
                    }
                }
                System.out.print("\nName server switch      : ");
                NaElement nameServerSwitch = null;
                if ((nameServerSwitch = vserverInfo.getChildByName("name-server-switch")) != null) {
                    List nsSwitchList = nameServerSwitch.getChildren();
                    Iterator nsSwitchIter = nsSwitchList.iterator();
                    while(nsSwitchIter.hasNext()){
                        NaElement nsSwitch = (NaElement) nsSwitchIter.next();
                        System.out.print(nsSwitch.getContent() + " ");
                    }
                }
                System.out.println("\n----------------------------------------------------");
            }
        }
    }

    public static void main(String[] vargs) {
        int index = 0;
        String command;
        args = vargs;

        if (args.length < 3) {
            printUsageAndExit();
        }
        try {
            server = new NaServer(args[index++], 1, 15);
            server.setAdminUser(args[index++], args[index++]);
            listVservers();
        } catch (Exception e) {
          System.err.println(e.toString());
        }
   }
}
