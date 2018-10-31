/*
 *
 * vollist.java
 *
 * Copyright (c) 2011 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * Sample code to list the volumes available in the cluster.
 *
 * This Sample code is supported from Cluster-Mode
 * Data ONTAP 8.1 onwards.
 *
 */

import java.io.IOException;
import java.util.List;
import java.util.Iterator;

import netapp.manage.*;

public class vollist {
    static NaServer server;
    static String user;
    static String passwd;
    static String ipaddr;
    static String args[];

    public static void printUsageAndExit() {
        System.out.println("\nUsage: \n");
        System.out.println("vollist <cluster/vserver> <user> <passwd> [-v <vserver-name>]");
        System.out.println("<cluster>             -- IP address of the cluster");
        System.out.println("<vserver>             -- IP address of the vserver");
        System.out.println("<user>                -- User name");
        System.out.println("<passwd>              -- Password");
        System.out.println("<vserver-name>        -- Name of the vserver \n");
        System.out.println("Note: ");
        System.out.println(" -v switch is required when you want to tunnel the command to a vserver using cluster interface \n");
        System.exit(-1);
    }

    public static void listVolumes() throws NaProtocolException,
            NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in, out;
        String tag = "";
        String vserverName, volName, aggrName, volType, volState, size, availSize;

        while (tag != null) {
            if (args.length > 3) {
                if (args.length < 5 || !args[3].equals("-v")) {
                    printUsageAndExit();
                }
                server.setVserver(args[4]);
            }
            in = new NaElement("volume-get-iter");
            if (!tag.equals("")) {
                in.addNewChild("tag", tag);
            }
            out = server.invokeElem(in);
            if (out.getChildIntValue("num-records", 0) == 0) {
                System.out.println("No volume(s) information available\n");
                return;
            }
            tag = out.getChildContent("next-tag");
            List volList = out.getChildByName("attributes-list").getChildren();
            Iterator volIter = volList.iterator();
            System.out.println("----------------------------------------------------");
            while(volIter.hasNext()) {
                NaElement volInfo =(NaElement)volIter.next();
                vserverName = volName = aggrName = volType = volState = size = availSize = "";
                NaElement volIdAttrs = volInfo.getChildByName("volume-id-attributes");
                if (volIdAttrs != null) {
                    vserverName = volIdAttrs.getChildContent("owning-vserver-name");
                    volName = volIdAttrs.getChildContent("name");
                    aggrName = volIdAttrs.getChildContent("containing-aggregate-name");
                    volType = volIdAttrs.getChildContent("type");
                }
                System.out.println("Vserver Name            : " + (vserverName != null ? vserverName : ""));
                System.out.println("Volume Name             : " + (volName != null ? volName : ""));
                System.out.println("Aggregate Name          : " + (aggrName != null ? aggrName : ""));
                System.out.println("Volume type             : " + (volType != null ? volType : ""));
                NaElement volStateAttrs = volInfo.getChildByName("volume-state-attributes");
                if (volStateAttrs != null) {
                    volState = volStateAttrs.getChildContent("state");
                }
                System.out.println("Volume state            : " + (volState != null ? volState : ""));
                NaElement volSizeAttrs = volInfo.getChildByName("volume-space-attributes");
                if (volSizeAttrs != null) {
                    size = volSizeAttrs.getChildContent("size");
                    availSize = volSizeAttrs.getChildContent("size-available");
                }
                System.out.println("Size (bytes)            : " + (size != null ? size : ""));
                System.out.println("Available Size (bytes)  : " + (availSize != null ? availSize : ""));
                System.out.println("----------------------------------------------------");
            }
        }
    }

    public static void main(String[] vargs) {
        int index = 0;
        args = vargs;

        if (args.length < 3) {
            printUsageAndExit();
        }
        try {
            server = new NaServer(args[index++], 1, 15);
            server.setAdminUser(args[index++], args[index++]);
            listVolumes();
        } catch (Exception e) {
          System.err.println(e.toString());
        }
   }
}
