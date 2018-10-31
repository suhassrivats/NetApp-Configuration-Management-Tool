/*
 * $Id:$
 *
 * snapmirror.java
 * Copyright (c) 2001-2007 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample for using the netapp.manage.* classes and ONTAPI
 * API to list Option Information 
 * Usage: 
 * snapmirror <filer> <user> <password> <operation> [<value1>] [<value2>] 
 *			[<value3>] [<value4>] [<value5>]
 * <filer>		-- Name/IP address of the filer 
 * <user>		-- User name						  
 * <password>	-- Password 									  
 * <operation>	 -- getStatus/getVolStatus/initialize/release/on/off
 * <value1>	-- This depends on the operation
 * <value2> 	-- This depends on the operation
 * <value3> 	-- This depends on the operation
 * <value4> 	-- This depends on the operation
 * <value5> 	-- This depends on the operation
 */

import java.util.*;
import netapp.manage.*;

public class snapmirror {
    public static void main(String[] args) {
        NaElement xi;
        NaElement xo;
        NaServer s;
        String op;

        if (args.length < 3) {
            System.out.print("Usage : snapmirror <filername> <username> "
                    + "<passwd> <operation> [<value1>] [<value2>] [<value3>] "
                    + "[<value4>] [<value5>]");
            System.exit(1);
        }
        try {
            // Initialize connection to server, and
            // request version 1.3 of the API set
            //
            s = new NaServer(args[0], 1, 3);
            s.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            s.setAdminUser(args[1], args[2]);

            if (args.length > 3) {
                op = args[3];

                //
                // Get snapmirror status
                //
                if (0 == op.compareTo("getStatus")) {
                    xi = new NaElement("snapmirror-get-status");

                    if (args.length > 4) {
                        xi.addNewChild("location", args[4]);
                    }

                    xo = s.invokeElem(xi);
                    System.out.println("------------------------------------");

                    System.out.print("Is snapmirror available: ");
                    System.out.println(xo.getChildContent("is-available"));

                    System.out.println("------------------------------------");

                    List status = xo.getChildByName("snapmirror-status")
                            .getChildren();

                    Iterator statusIter = status.iterator();

                    while (statusIter.hasNext()) {
                        NaElement statusInfo = (NaElement) statusIter.next();

                        System.out.print("Base snapshot:");
                        System.out.println(statusInfo
                                .getChildContent("base-snapshot"));

                        System.out.print("Contents:");
                        System.out.println(statusInfo
                                .getChildContent("contents"));

                        System.out.print("Current transfer error:");
                        System.out.println(statusInfo
                                .getChildContent("current-transfer-error"));

                        System.out.print("Current transfer type:");
                        System.out.println(statusInfo
                                .getChildContent("current-transfer-type"));

                        System.out.print("Destination location:");
                        System.out.println(statusInfo
                                .getChildContent("destination-location"));

                        System.out.print("Lag time:");
                        System.out.println(statusInfo
                                .getChildContent("lag-time"));

                        System.out.print("Last transfer duration:");
                        System.out.println(statusInfo
                                .getChildContent("last-transfer-duration"));

                        System.out.print("Last transfer from:");
                        System.out.println(statusInfo
                                .getChildContent("last-transfer-from"));

                        System.out.print("Last transfer size:");
                        System.out.println(statusInfo
                                .getChildContent("last-transfer-size"));

                        System.out.print("Last transfer type:");
                        System.out.println(statusInfo
                                .getChildContent("last-transfer-type"));

                        System.out.print("Mirror timestamp:");
                        System.out.println(statusInfo
                                .getChildContent("mirror-timestamp"));

                        System.out.print("Source location:");
                        System.out.println(statusInfo
                                .getChildContent("source-location"));

                        System.out.print("State:");
                        System.out.println(statusInfo.getChildContent("state"));

                        System.out.print("Status:");
                        System.out
                                .println(statusInfo.getChildContent("status"));

                        System.out.print("Transfer progress:");
                        System.out.println(statusInfo
                                .getChildContent("transfer-progress"));

                        System.out.print("contents:");
                        System.out.println(statusInfo
                                .getChildContent("contents"));

                        System.out.println("--------------------------------");
                    }
                }

                //
                // Get snapmirror volume status information
                //

                else if (0 == op.compareTo("getVolStatus")) {
                    xi = new NaElement("snapmirror-get-volume-status");
                    if (args.length > 4) {
                        xi.addNewChild("volume", args[4]);
                    } else {
                        System.out
                                .println("Input parameter volume is required");
                        s.close();
                        System.exit(1);
                    }

                    xo = s.invokeElem(xi);
                    System.out.println("------------------------------------");

                    System.out.print("Is destination: ");
                    System.out.println(xo.getChildContent("is-destination"));

                    System.out.print("Is source: ");
                    System.out.println(xo.getChildContent("is-source"));

                    System.out.print("Is destination: ");
                    System.out.println(xo.getChildContent("is-destination"));

                    System.out.print("Is transfer broken: ");
                    System.out
                            .println(xo.getChildContent("is-transfer-broken"));

                    System.out.print("Is transfer in progress: ");
                    System.out.println(xo
                            .getChildContent("is-transfer-in-progress"));

                    System.out.println("------------------------------------");
                }

                //
                // Snapmirror initialize
                //

                else if (0 == op.compareTo("initialize")) {
                    xi = new NaElement("snapmirror-initialize");
                    if (args.length > 4) {
                        xi.addNewChild("destination-location", args[4]);
                    } else {
                        System.out
                                .println("Please provide Destination location");
                        s.close();
                        System.exit(1);
                    }

                    if (args.length > 5)
                        xi.addNewChild("destination-snapshot", args[5]);
                    if (args.length > 6)
                        xi.addNewChild("max-transfer-rate", args[6]);
                    if (args.length > 7)
                        xi.addNewChild("source-location", args[7]);
                    if (args.length > 8)
                        xi.addNewChild("source-snapshot", args[8]);

                    xo = s.invokeElem(xi);
                    System.out.println("Snapmirror initialization successful");
                }

                //
                // Snapmirror disable
                //

                else if (0 == op.compareTo("off")) {
                    xi = new NaElement("snapmirror-off");

                    xo = s.invokeElem(xi);
                    System.out.println("Snapmirror data transfers disabled "
                            + "and Snapmirror scheduler turned off");
                }

                //
                // Snapmirror enable
                //

                else if (0 == op.compareTo("on")) {
                    xi = new NaElement("snapmirror-on");

                    xo = s.invokeElem(xi);
                    System.out.println("Snapmirror data transfer enabled and"
                            + " Snapmirror scheduler turned on");
                }

                //
                // Snapmirror release
                //

                else if (0 == op.compareTo("release")) {
                    xi = new NaElement("snapmirror-release");
                    if (args.length > 5) {
                        xi.addNewChild("destination-location", args[4]);
                        xi.addNewChild("source-location", args[5]);
                    } else {
                        System.out
                                .println("Please provide destination location"
                                        + " and source location values");
                        s.close();
                        System.exit(1);
                    }

                    xo = s.invokeElem(xi);
                    System.out.println("SnapMirror informed that a direct "
                            + "mirror is no longer going to make requests");
                }

                else {
                    System.out.println("Invalid Operation");
                    System.exit(1);
                }

                s.close();

                System.exit(0);
            }
        }

        catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}
