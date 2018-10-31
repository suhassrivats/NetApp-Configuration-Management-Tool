/*
 * $Id:$
 *
 * policy.java
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * Sample code to demonstrate how to:
 *        - list/delete protection policies
 *        - list/create/delete a new provisionoing policy
 *
 *
 * This Sample code is supported from DataFabric Manager 3.8
 * onwards.
 * However few of the functionalities of the sample code may
 * work on older versions of DataFabric Manager.
 */
import java.util.*;
import netapp.manage.*;

public class policy {

    private static void usage() {
        System.out.println("\nUsage:\n policy <dfmserver> <user> <password> "
                + "list {-v [<prov-name>] | -t [<prot-name>]}");
        System.out.println(" policy <dfmserver> <user> <password> destroy "
                + "<prov-name>");
        System.out.println(" policy <dfmserver> <user> <password> create "
                + "<prov-name> <type> <rtag>\n");
        System.out.println(" <dfmserver>   -- Name/IP Address of the DFM "
                + "server");
        System.out.println(" <user>        -- DFM server User name");
        System.out.println(" <password>    -- DFM server User Password");
        System.out.println(" <prov-name>   -- provisioning policy");
        System.out.println(" <prot-name>   -- protection policy name");
        System.out.println(" <policy name> -- policy name, can be either "
                + "provisioning or protection policy");
        System.out.println(" <type>        -- provisioning policy type, "
                + "san or nas");
        System.out.println(" <rtag>        -- resource tag for policy\n");
        System.out.println(" Creates policy with default options :");
        System.out.println("	NAS - User-quota=1G; Group-quota=1G, "
                + "Thin-prov=True; Snapshot-reserve=False");
        System.out.println("	SAN - Storage-Container=Volume; "
                + "Thin-prov=True.\n");
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

            if (args[3].equals("list")) {
                if (args.length < 5) {
                    usage();
                }
                String subCommand = args[4];
                // List all provisioning policies
                if (subCommand.equals("-v")) {
                    xi = new NaElement("provisioning-policy-list-iter-start");
                    if (args.length == 6)
                        xi.addNewChild("provisioning-policy-name-or-id",
                                args[5]);

                    xo = s.invokeElem(xi);

                    String xotag = xo.getChildContent("tag");
                    xi = new NaElement("provisioning-policy-list-iter-next");
                    xi.addNewChild("tag", xotag);
                    xi.addNewChild("maximum", xo.getChildContent("records"));

                    xo = s.invokeElem(xi);

                    System.out.println("\nProvisioning Policies:");
                    System.out.println("====================================="
                            + "==============================");

                    if (xo.getChildByName("provisioning-policies") == null) {
                        System.out.println("Error: No Provisioning Policies!");
                        System.exit(1);
                    }
                    if (xo.getChildByName("provisioning-policies")
                            .hasChildren()) {
                        List ppInfos = xo.getChildByName(
                                "provisioning-policies").getChildren();
                        for (Iterator i = ppInfos.iterator(); i.hasNext();) {
                            NaElement ppi = (NaElement) i.next();
                            System.out
                                    .println("Policy Name\t:"
                                            + ppi.getChildContent("provisioning-policy-name"));
                            System.out
                                    .println("Policy Type\t:"
                                            + ppi.getChildContent("provisioning-policy-type"));
                            System.out.println("Resource Tag\t:"
                                    + ppi.getChildContent("resource-tag"));

                            if ((ppi.getChildContent("provisioning-policy-type"))
                                    .equals("nas")) {
                                System.out.println("NAS container Settings:");
                                System.out
                                        .println("\t\tDefault User Quota  : "
                                                + (ppi.getChildByName("nas-container-settings"))
                                                        .getChildContent("default-user-quota"));
                                System.out
                                        .println("\t\tDefault Group Quota : "
                                                + (ppi.getChildByName("nas-container-settings"))
                                                        .getChildContent("default-group-quota"));
                                System.out
                                        .println("\t\tSnapshot Reserve    : "
                                                + (ppi.getChildByName("nas-container-settings"))
                                                        .getChildContent("snapshot-reserve"));
                                System.out
                                        .println("\t\tThin Provision      : "
                                                + (ppi.getChildByName("nas-container-settings"))
                                                        .getChildContent("thin-provision"));
                            } else if ((ppi
                                    .getChildContent("provisioning-policy-type"))
                                    .equals("san")) {
                                System.out.println("SAN container Settings:");
                                System.out
                                        .println("\t\tStorage Container Type "
                                                + ": "
                                                + (ppi.getChildByName("san-container-settings"))
                                                        .getChildContent("storage-container-type"));

                                System.out
                                        .println("\t\tThin Provision : "
                                                + (ppi.getChildByName("san-container-settings"))
                                                        .getChildContent("thin-provision"));

                                System.out
                                        .println("\t\tThin Prov Config : "
                                                + (ppi.getChildByName("san-container-settings"))
                                                        .getChildContent("thin-provisioning-"
                                                                + "configuration"));
                            }
                            System.out.println("=============================="
                                    + "=====================================");
                        }
                    } else {
                        System.out.println("No Provisioning Policies!");
                    }

                    xi = new NaElement("provisioning-policy-list-iter-end");
                    xi.addNewChild("tag", xotag);
                    xo = s.invokeElem(xi);
                }
                // List all protection policies
                else if (subCommand.equals("-t")) {
                    xi = new NaElement("dp-policy-list-iter-start");
                    if (args.length == 6)
                        xi.addNewChild("dp-policy-name-or-id", args[5]);

                    xo = s.invokeElem(xi);

                    xi = new NaElement("dp-policy-list-iter-next");
                    String xotag = xo.getChildContent("tag");
                    xi.addNewChild("tag", xotag);
                    xi.addNewChild("maximum", xo.getChildContent("records"));

                    xo = s.invokeElem(xi);

                    System.out.println("\nProtection Policies:");
                    System.out.println("====================================="
                            + "==============================");

                    if (xo.getChildByName("dp-policy-infos") == null) {
                        System.out.println("Error: No Protection Policies!");
                        System.exit(1);
                    }
                    if (xo.getChildByName("dp-policy-infos").hasChildren()) {
                        List dpInfos = xo.getChildByName("dp-policy-infos")
                                .getChildren();
                        for (Iterator i = dpInfos.iterator(); i.hasNext();) {
                            NaElement ppi = (NaElement) i.next();
                            NaElement dpContent = ppi
                                    .getChildByName("dp-policy-content");
                            System.out.println("Policy Name\t: "
                                    + dpContent.getChildContent("name"));

                            List dpCons = dpContent.getChildByName(
                                    "dp-policy-connections").getChildren();

                            for (Iterator j = dpCons.iterator(); j.hasNext();) {
                                NaElement dpi = (NaElement) j.next();
                                if (dpi != null) {
                                    System.out.println("Connection Type\t: "
                                            + dpi.getChildContent("type"));
                                    System.out
                                            .println("Source Node\t: "
                                                    + dpi.getChildContent("from-node-name"));
                                    System.out
                                            .println("To Node\t\t: "
                                                    + dpi.getChildContent("to-node-name"));
                                }
                            }
                            System.out.println("=============================="
                                    + "=====================================");
                        }
                    } else {
                        System.out.println("No Protection Policies!");
                    }

                    xi = new NaElement("dp-policy-list-iter-end");
                    xi.addNewChild("tag", xotag);
                    xo = s.invokeElem(xi);
                } else {
                    System.out.println("Invalid options...");
                    usage();
                }
            } else if (args[3].equals("create")) {
                if (args.length < 7)
                    usage();
                // Create provisioning policies
                String ppname = args[4];
                String pptype = args[5];
                String rtag = args[6];

                xi = new NaElement("provisioning-policy-create");
                NaElement ppi = new NaElement("provisioning-policy-info");
                ppi.addNewChild("provisioning-policy-name", ppname);
                ppi.addNewChild("provisioning-policy-type", pptype);
                ppi.addNewChild("resource-tag", rtag);
                xi.addChildElem(ppi);

                // Set default options for nas & san settings
                if (pptype.equals("nas")) {
                    NaElement nas = new NaElement("nas-container-settings");
                    nas.addNewChild("default-user-quota", "1000000000");
                    nas.addNewChild("default-group-quota", "1000000000");
                    nas.addNewChild("thin-provision", "true");
                    nas.addNewChild("snapshot-reserve", "false");
                    ppi.addChildElem(nas);
                } else if (pptype.equals("san")) {
                    NaElement san = new NaElement("san-container-settings");
                    san.addNewChild("storage-container-type", "volume");
                    san.addNewChild("thin-provision", "true");
                    ppi.addChildElem(san);
                }

                xo = s.invokeElem(xi);

                System.out.println("New Provisioning Policy " + ppname
                        + " created with ID : "
                        + xo.getChildContent("provisioning-policy-id"));
            } else if (args[3].equals("destroy")) {
                if (args.length < 5)
                    usage();
                // Delete a provisioning policy
                String pname = args[4];
                xi = new NaElement("provisioning-policy-destroy");
                xi.addNewChild("provisioning-policy-name-or-id", pname);
                xo = s.invokeElem(xi);
                System.out.println("Provisioning Policy " + pname
                        + " destroyed!");
            } else {
                System.out.println("Invalid options...");
                usage();
            }
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}