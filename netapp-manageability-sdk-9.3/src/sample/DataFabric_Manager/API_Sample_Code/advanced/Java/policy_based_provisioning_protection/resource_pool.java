/*
 * $Id:$
 *
 * resource_pool.java
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * Sample code to demonstrate how to:
 *        - list/create/delete a resource pool
 *        - list/add/delete members from a resource pool
 *
 *
 * This Sample code is supported from DataFabric Manager 3.8
 * onwards.
 * However few of the functionalities of the sample code may
 * work on older versions of DataFabric Manager.
 */
import java.util.*;
import netapp.manage.*;

public class resource_pool {

    private static void usage() {
        System.out.println("Usage:\n resource_pool <dfmserver> <user> "
                + "<password> list [ResPoolName]");
        System.out.println(" resource_pool <dfmserver> <user> <password> "
                + "create ResPoolName [ResourceTag]");
        System.out.println(" resource_pool <dfmserver> <user> <password> "
                + "destroy ResPoolName");
        System.out.println(" resource_pool <dfmserver> <user> <password> "
                + "member list ResPoolName");
        System.out.println(" resource_pool <dfmserver> <user> <password> "
                + "member [add|del] ResPoolName MemberName\n");
        System.out.println(" <dfm-server>   -- Name/IP Address of the "
                + "DFM server");
        System.out.println(" <user>         -- DFM server User name");
        System.out.println(" <password>     -- DFM server User Password");
        System.out.println(" <ResPoolName>  -- Resourcepool name, mandatory "
                + "for create & destroy options");
        System.out.println(" <MemberName>   -- Member to be added/removed "
                + "from a resourcepool, mandatory for add  & del options");
        System.exit(1);
    }

    public static void main(String[] args) {
        NaElement xi, xin;
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
            // Option to list all resourcepools
            if (args[3].equals("list")) {
                // Begin iteration sequence
                xi = new NaElement("resourcepool-list-info-iter-start");

                if (args.length == 5) {
                    String rname = args[4];
                    xi.addNewChild("object-name-or-id", rname);

                }
                xo = s.invokeElem(xi);
                String xotag = xo.getChildContent("tag");
                // Retrieve the records
                xin = new NaElement("resourcepool-list-info-iter-next");
                xin.addNewChild("maximum", xo.getChildContent("records"));
                xin.addNewChild("tag", xotag);
                xo = s.invokeElem(xin);

                System.out.println("\nRESOURCEPOOLS:\n");
                System.out.println("========================================="
                        + "==========================\n");
                // Check if record is empty, which means no resourcepools
                if (xo.getChildByName("resourcepools") == null) {
                    System.out.println("Error: No Resourcepools!\n");
                    System.exit(1);
                }

                // Traverse through the records and print details
                if ((xo.getChildByName("resourcepools")).hasChildren()) {
                    List rpInfos = (xo.getChildByName("resourcepools"))
                            .getChildren();

                    for (Iterator i = rpInfos.iterator(); i.hasNext();) {
                        NaElement rpi = (NaElement) i.next();
                        System.out.println("Name\t\t:"
                                + rpi.getChildContent("resourcepool-name"));
                        System.out.println("Status\t\t:"
                                + rpi.getChildContent("resourcepool-status"));
                        System.out
                                .println("No. of Members\t:"
                                        + rpi.getChildContent("resourcepool-member-count"));
                        System.out.println("Tag\t\t:"
                                + rpi.getChildContent("resource-tag"));
                        System.out.println("================================"
                                + "===================================\n");
                    }
                } else {
                    System.out.println("No Resourcepools!\n");
                }
                xin = new NaElement("resourcepool-list-info-iter-end");
                xin.addNewChild("tag", xotag);
                xo = s.invokeElem(xin);
            }
            // Create a new resoucepool
            else if (args[3].equals("create")) {

                if (args.length < 5)
                    usage();

                String rTag = null, rpName = args[4];

                if (args.length == 6)
                    rTag = args[5];
                xi = new NaElement("resourcepool-create");
                NaElement rp = new NaElement("resourcepool");

                NaElement rpInfo = new NaElement("resourcepool-info");
                rpInfo.addNewChild("resourcepool-name", rpName);
                if (rTag != null)
                    rpInfo.addNewChild("resource-tag", rTag);

                rp.addChildElem(rpInfo);
                xi.addChildElem(rp);
                // Call to create a new empty resourcepool
                xo = s.invokeElem(xi);

                System.out.println("\nResourcepool " + rpName
                        + " created with ID : "
                        + xo.getChildContent("resourcepool-id"));

                // Add member into the resourcepool. Arguments passed after
                // rpool name. This is a hidden feature.
                int count = args.length;
                for (int i = 6; i < count; i++) {
                    String memName = args[i];
                    xi = new NaElement("resourcepool-add-member");
                    xi.addNewChild("resourcepool-name-or-id", rpName);
                    xi.addNewChild("member-name-or-id", memName);
                    xi.addNewChild("resource-tag", rTag);

                    xo = s.invokeElem(xi);
                    System.out.println("\nAdded member " + memName
                            + " to Resourcepool " + rpName);
                }

            }
            // Option to destroy a resourcepool
            else if (args[3].equals("destroy")) {
                if (args.length < 5)
                    usage();

                String rpName = args[4];

                xi = new NaElement("resourcepool-destroy");
                xi.addNewChild("resourcepool-name-or-id", rpName);

                xo = s.invokeElem(xi);
                System.out
                        .println("\nResourcepool " + rpName + " destroyed!\n");
            }
            // Member operations on a rpool - list/add/remove
            else if (args[3].equals("member")) {
                if (args.length < 6)
                    usage();

                String subCommand = args[4];
                String rpName = args[5];

                if (subCommand.equals("list")) {
                    if (args.length < 6)
                        usage();
                    xi = new NaElement(
                            "resourcepool-member-list-info-iter-start");
                    xi.addNewChild("resourcepool-name-or-id", rpName);

                    xo = s.invokeElem(xi);

                    xi = new NaElement(
                            "resourcepool-member-list-info-iter-next");
                    xi.addNewChild("tag", xo.getChildContent("tag"));
                    xi.addNewChild("maximum", xo.getChildContent("records"));

                    xo = s.invokeElem(xi);

                    System.out.println("\nRESOURCE POOL: " + rpName + "\n");
                    System.out.println("==================================="
                            + "================================\n");

                    if (xo.getChildByName("resourcepool-members") == null) {
                        System.out.println("Error: Resourcepool empty!\n");
                        System.exit(1);
                    }

                    if ((xo.getChildByName("resourcepool-members"))
                            .hasChildren()) {
                        List rpInfos = (xo
                                .getChildByName("resourcepool-members"))
                                .getChildren();

                        for (Iterator i = rpInfos.iterator(); i.hasNext();) {
                            NaElement rpi = (NaElement) i.next();
                            System.out.println("Name\t:"
                                    + rpi.getChildContent("member-name"));
                            System.out.println("Status\t:"
                                    + rpi.getChildContent("member-status"));
                            System.out.println("Type\t:"
                                    + rpi.getChildContent("member-type"));
                            System.out.println("Tag\t:"
                                    + rpi.getChildContent("resource-tag"));
                            System.out
                                    .println("=========================="
                                            + "=========================================\n");
                        }
                    } else {
                        System.out.println("No such Resourcepool " + rpName
                                + "!\n");
                    }
                } else if (subCommand.equals("add")) {
                    if (args.length < 7)
                        usage();
                    String memName = args[6];

                    xi = new NaElement("resourcepool-add-member");
                    xi.addNewChild("resourcepool-name-or-id", rpName);
                    xi.addNewChild("member-name-or-id", memName);
                    if (args.length == 8) {
                        String rTag = args[7];
                        xi.addNewChild("resource-tag", rTag);
                    }
                    xo = s.invokeElem(xi);

                    System.out.println("Added member " + memName
                            + " to Resourcepool " + rpName + "\n");
                } else if (subCommand.equals("del")) {
                    if (args.length < 7)
                        usage();

                    String memName = args[6];

                    xi = new NaElement("resourcepool-remove-member");
                    xi.addNewChild("resourcepool-name-or-id", rpName);
                    xi.addNewChild("member-name-or-id", memName);

                    xo = s.invokeElem(xi);

                    System.out.println("Member " + memName
                            + " deleted from Resourcepool " + rpName + "\n");
                } else {
                    System.out.println("Invalid Options selected");
                    usage();
                }
            } else {
                usage();
            }
            s.close();
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}
