/*
 * $Id:$
 *
 * multistore.java
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * Sample code to demonstrate how to:
 *        - create/destroy/setup a multistore
 *
 *
 * This Sample code is supported from DataFabric Manager 3.8
 * onwards.
 * However few of the functionalities of the sample code may
 * work on older versions of DataFabric Manager.
 */

import java.util.*;
import netapp.manage.*;

public class multistore {

    private static void usage() {
        System.out.println("Usage:\n multistore <dfmserver> <user> "
                + "<password> create <vfiler> <ip> <protocol> <rpool>");
        System.out.println(" multistore <dfmserver> <user> <password> "
                + "destroy <vfiler>");
        System.out.println(" multistore <dfmserver> <user> <password> "
                + "setup <vfiler> <if> <ip> <nm> [-c]\n");
        System.out.println(" <dfmserver>  -- Name/IP Address of the "
                + "DFM server");
        System.out.println(" <user>       -- DFM server User name");
        System.out.println(" <password>   -- DFM server User Password");
        System.out.println(" <vfiler>     -- Vfiler name to be created "
                + "or setup");
        System.out.println(" <ip>         -- IP Address to be assigned "
                + "to the vfiler ");
        System.out.println(" <protocol>   -- nas - for NFS & CIFS");
        System.out.println("                 san - for iSCSI");
        System.out.println("                 all - for both NFS & CIFS");
        System.out.println(" <rpool>      -- Resource pool in which vfiler "
                + "will be created");
        System.out.println(" <if>         -- interface on the vfiler to be "
                + "used, for e.g e0a, e0b");
        System.out.println(" <nm>         -- netmask on the vfiler to be "
                + "used, for e.g 255.255.255.0");
        System.out.println(" -c           -- specify this flag to run cifs "
                + "setup for nas & all protocols");
        System.exit(1);
    }

    public static void main(String[] args) {
        NaElement xi;
        NaElement xo;
        NaServer s;

        if (args.length < 4) {
            usage();
        }
        try {
            // Initialize connection to server, and
            // request version 1.0 of the API set
            //
            s = new NaServer(args[0], 1, 0);
            s.setServerType(NaServer.SERVER_TYPE_DFM);
            s.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            s.setAdminUser(args[1], args[2]);

            // Create a new Multistore
            if (args[3].equals("create")) {
                if (args.length < 8)
                    usage();

                String vfiler_name = args[4];
                String ip = args[5];
                String protocols = args[6];
                String rpool = args[7];

                xi = new NaElement("vfiler-create");
                xi.addNewChild("name", vfiler_name);
                xi.addNewChild("ip-address", ip);
                xi.addNewChild("resource-name-or-id", rpool);

                NaElement allproto = new NaElement("allowed-protocols");

                // Pre-set protocols to be allowed on the multistore
                if (protocols.equals("all")) {
                    allproto.addNewChild("protocols", "nfs");
                    allproto.addNewChild("protocols", "cifs");
                    allproto.addNewChild("protocols", "iscsi");
                } else if (protocols.equals("nas")) {
                    allproto.addNewChild("protocols", "nfs");
                    allproto.addNewChild("protocols", "cifs");
                } else if (protocols.equals("san")) {
                    allproto.addNewChild("protocols", "iscsi");
                } else {
                    System.out.println("Protocols allowed are: nfs, cifs, all");
                    System.exit(1);
                }
                xi.addChildElem(allproto);

                xo = s.invokeElem(xi);

                System.out.println("VFiler '" + vfiler_name + "' created on "
                        + xo.getChildContent("filer-name") + ":"
                        + xo.getChildContent("root-volume-name"));
            }
            // Setup a newly created Multistore
            else if (args[3].equals("setup")) {
                if (args.length < 8)
                    usage();

                String vfiler_name = args[4];
                String intf = args[5];
                String ip = args[6];
                String netmask = args[7];

                xi = new NaElement("vfiler-setup");
                xi.addNewChild("vfiler-name-or-id", vfiler_name);

                if (args.length == 9 && args[8].equals("-c"))
                    xi.addNewChild("run-cifs-setup", "true");

                // Configure ip settings for multistore.
                NaElement ipbind = new NaElement("ip-bindings");
                NaElement ipbindinfo = new NaElement("ip-binding-info");
                ipbindinfo.addNewChild("interface", intf);
                ipbindinfo.addNewChild("ip-address", ip);
                ipbindinfo.addNewChild("netmask", netmask);

                ipbind.addChildElem(ipbindinfo);
                xi.addChildElem(ipbind);

                xo = s.invokeElem(xi);

                System.out.println("VFiler " + vfiler_name + "' setup!");
            }
            // Destroy a multistore
            else if (args[3].equals("destroy")) {
                if (args.length < 5)
                    usage();

                String vfiler_name = args[4];

                xi = new NaElement("vfiler-destroy");
                xi.addNewChild("vfiler-name-or-id", vfiler_name);
                xo = s.invokeElem(xi);
                System.out.println("\nVFiler " + vfiler_name + " destroyed!");
            } else {
                usage();
            }
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}