/*
 * $Id: //depot/prod/zephyr/belair/src/sample/java/vfiler/vfiler.java#2 $
 *
 * vfiler.java
 * Copyright (c) 2001-2007 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample for using the netapp.manage.* classes to
 * any ONTAPI API
 */
import java.util.*;
import netapp.manage.*;

public class vfiler {

    private static NaServer s;

    private static void printUsage() {
        System.out.println("Usage: vfiler <filer> <user>"
                + " <password> <operation> [<value1>] [<value2>]..");
        System.out.println(" <filer> - the name/ipaddress of the filer");
        System.out.println(" <user>,<password> - User and password for "
                + "remote authentication");
        System.out.println(" <operation> -  The possible value are:");
        System.out.println(" create - to create a new vfiler");
        System.out.println(" destroy - to destroy a vfiler");
        System.out.println(" list - to list the vfiler(s)");
        System.out.println(" status - give the status of the vfiler");
        System.out.println(" start - to start the vfiler");
        System.out.println(" stop - to stop the vfiler");
        System.out.println(" <value1>	-- This depends on the operation");
        System.out.println(" <value2> 	-- This depends on the operation");
    }

    private static int createVfiler(String[] args) {

        NaElement vfiler;
        NaElement xo;
        NaElement ip_addrs;
        NaElement stg_units;
        int parseIP = 1;
        int index = 4;

        try {

            if ((args.length < 9) || (args[5].equals("-ip") != true)) {
                System.out
                        .println("Usage: vfiler <filer> <user>  <password>"
                                + " <create> <vfiler-name> -ip <ip-address1> [<ip-address2>..]"
                                + " -su <storage-unit1> [<storage-unit2]..]");
                return 0;
            }
            vfiler = new NaElement("vfiler-create");
            ip_addrs = new NaElement("ip-addresses");
            stg_units = new NaElement("storage-units");

            vfiler.addChildElem(ip_addrs);
            vfiler.addChildElem(stg_units);

            vfiler.addNewChild("vfiler", args[index]);

            while (++index < args.length) {
                if (args[index].equals("-su") == true) {
                    parseIP = 0;
                    continue;
                }
                if (args[index].equals("-ip") == true) {
                    parseIP = 1;
                    continue;
                }
                if (parseIP == 1) {
                    ip_addrs.addNewChild("ip-address", args[index]);
                } else {
                    stg_units.addNewChild("storage-unit", args[index]);
                }
            }
            xo = s.invokeElem(vfiler);
            System.out.println("vfiler created successfully!");
        } catch (NaAPIFailedException e) {
            System.err.println(e.toString());
            return -1;
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println(e.getMessage());
            return -1;
        }
        return 0;
    }

    private static int listVfilers(String[] args) {

        NaElement xi;
        NaElement xo;

        try {

            xi = new NaElement("vfiler-list-info");

            if (args.length >= 5) {
                xi.addNewChild("vfiler", args[4]);
            }
            xo = s.invokeElem(xi);

            List vfilers = xo.getChildByName("vfilers").getChildren();
            for (Iterator i = vfilers.iterator(); i.hasNext();) {
                NaElement vfiler = (NaElement) i.next();
                System.out.println("\nVFILER:");
                System.out.println("   name:" + vfiler.getChildContent("name"));
                if (vfiler.getChildContent("ipspace") != null) {
                    System.out.println("   ipspace:"
                            + vfiler.getChildContent("ipspace"));
                }
                System.out.println("   uuid:" + vfiler.getChildContent("uuid"));

                List vfnets = vfiler.getChildByName("vfnets").getChildren();
                for (Iterator j = vfnets.iterator(); j.hasNext();) {
                    NaElement vfnet = (NaElement) j.next();
                    System.out.println(" network resources:");
                    System.out.println("   ipaddress:"
                            + vfnet.getChildContent("ipaddress"));
                    System.out.println("   interface:"
                            + vfnet.getChildContent("interface"));
                }

                List vfstores = vfiler.getChildByName("vfstores").getChildren();
                System.out.println(" storage resources:");
                for (Iterator k = vfstores.iterator(); k.hasNext();) {
                    NaElement vfstore = (NaElement) k.next();
                    System.out.println("   path:"
                            + vfstore.getChildContent("path"));
                    System.out.println("   status:"
                            + vfstore.getChildContent("status"));
                    System.out.println("   is-etc:"
                            + vfstore.getChildContent("is-etc") + "\n");
                }
            }

        } catch (NaAPIFailedException e) {
            System.err.println(e.toString());
            return -1;
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println(e.getMessage());
            return -1;
        }
        return 0;
    }

    public static void main(String[] args) {

        int index;
        String options;
        int dos1 = 0;

        if (args.length < 4) {
            printUsage();
            return;
        }

        try {
            // Initialize connection to server, and
            // request version 1.3 of the API set for vfiler-tunneling
            //
            s = new NaServer(args[0], 1, 3);
            s.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            s.setAdminUser(args[1], args[2]);

            if (args[3].equals("create") == true) {
                createVfiler(args);
            } else if (args[3].equals("status") == true
                    || args[3].equals("start") == true
                    || args[3].equals("stop") == true
                    || args[3].equals("destroy") == true) {

                NaElement vfiler;
                NaElement xo;

                if (args.length < 5) {
                    System.out.println("This operation requires <vfiler-name>");
                    return;
                }

                if (args[3].equals("status") == true) {
                    vfiler = new NaElement("vfiler-get-status");
                } else if (args[3].equals("start") == true) {
                    vfiler = new NaElement("vfiler-start");
                } else if (args[3].equals("stop") == true) {
                    vfiler = new NaElement("vfiler-stop");
                } else {
                    vfiler = new NaElement("vfiler-destroy");
                }
                vfiler.addNewChild("vfiler", args[4]);
                xo = s.invokeElem(vfiler);

                if (args[3].equals("status") == true) {
                    System.out
                            .println("status:" + xo.getChildContent("status"));
                } else {
                    System.out.println("Operation successful");
                }
            } else if (args[3].equals("list") == true) {
                listVfilers(args);
            } else {
                printUsage();
            }
        } catch (NaAPIFailedException e) {
            System.err.println(e.toString());
        } catch (Exception e) {
            System.err.println(e.toString());
        }
    }
}
