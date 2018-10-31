/*
 * $Id:$
 *
 * snapvault.java
 * Copyright (c) 2001-2007 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample for using the netapp.manage.* classes and ONTAPI
 * API to list Option Information 
 * Usage: 
 * snapvault <filer> <user> <password> <operation> [<value1>] [<value2>] 
 * <filer>		-- Name/IP address of the filer 
 * <user>		-- User name
 * <password>	-- Password 
 * <operation>	 -- scheduleList/snapshotCreate/relationshipStatus
 * <value1>	-- This depends on the operation
 * <value2> 	-- This depends on the operation
 */

import java.util.*;
import netapp.manage.*;

public class snapvault {
    public static void main(String[] args) {
        NaElement xi, yi;
        NaElement xo, yo;
        NaServer s;
        String op;

        if (args.length < 3) {
            System.out.print("Usage : snapvault <filername> <username> "
                    + "<passwd> <operation> [<value1>] [<value2>]");
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
                // List the configured snapshot schedules
                //
                if (0 == op.compareTo("scheduleList")) {
                    xi = new NaElement(
                            "snapvault-primary-snapshot-schedule-list-info");

                    if (args.length > 4) {
                        xi.addNewChild("volume-name", args[4]);
                    }

                    xo = s.invokeElem(xi);

                    List outputElem = xo.getChildByName("snapshot-schedules")
                            .getChildren();

                    Iterator iter = outputElem.iterator();

                    while (iter.hasNext()) {
                        NaElement outPutInfo = (NaElement) iter.next();

                        System.out.print("Retention count:");
                        System.out.println(outPutInfo
                                .getChildContent("retention-count"));

                        System.out.print("Schedule name:");
                        System.out.println(outPutInfo
                                .getChildContent("schedule-name"));

                        System.out.print("Volume name:");
                        System.out.println(outPutInfo
                                .getChildContent("volume-name"));

                        System.out
                                .println("------------------------------------");
                    }
                }

                //
                // Create Snapshot
                //
                else if (0 == op.compareTo("snapshotCreate")) {
                    xi = new NaElement(
                            "snapvault-primary-initiate-snapshot-create");

                    if (args.length > 5) {
                        xi.addNewChild("schedule-name", args[4]);
                        xi.addNewChild("volume-name", args[5]);
                    } else {
                        System.out.println("Schedule name and volume name "
                                + "are required to create snapshot");
                        s.close();
                        System.exit(1);
                    }

                    xo = s.invokeElem(xi);
                }

                else if (0 == op.compareTo("relationshipStatus")) {
                    int records;
                    String tag;

                    xi = new NaElement(
                            "snapvault-secondary-relationship-status-list-iter-start");

                    xo = s.invokeElem(xi);

                    System.out.println("------------------------------------");

                    records = xo.getChildIntValue("records", -1);
                    System.out.println("Records: " + records);

                    tag = xo.getChildContent("tag");

                    System.out.println("Tag: " + tag);

                    System.out.println("------------------------------------");

                    for (int i = 0; i < records; i++) {
                        yi = new NaElement(
                                "snapvault-secondary-relationship-status-list-iter-next");

                        yi.addNewChild("maximum", "1");
                        yi.addNewChild("tag", tag);

                        yo = s.invokeElem(yi);

                        System.out
                                .println("------------------------------------");

                        System.out.print("Records: ");
                        System.out.println(yo.getChildContent("records"));

                        List statusList = yo.getChildByName("status-list")
                                .getChildren();

                        Iterator statusIter = statusList.iterator();

                        while (statusIter.hasNext()) {
                            NaElement statusInfo = (NaElement) statusIter
                                    .next();

                            System.out.print("Destination path:");
                            System.out.println(statusInfo
                                    .getChildContent("destination-path"));

                            System.out.print("Destination system:");
                            System.out.println(statusInfo
                                    .getChildContent("destination-system"));

                            System.out.print("Source path: ");
                            System.out.println(statusInfo
                                    .getChildContent("source-path"));

                            System.out.print("Source system: ");
                            System.out.println(statusInfo
                                    .getChildContent("source-system"));

                            System.out.print("State: ");
                            System.out.println(statusInfo
                                    .getChildContent("state"));

                            System.out.print("Status: ");
                            System.out.println(statusInfo
                                    .getChildContent("status"));
                        }
                    }

                    yi = new NaElement(
                            "snapvault-secondary-relationship-status-list-iter-end");

                    yi.addNewChild("tag", tag);

                    yo = s.invokeElem(yi);

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
