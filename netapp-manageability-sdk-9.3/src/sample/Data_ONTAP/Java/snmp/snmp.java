/*
 * $Id:$
 *
 * snmp.java
 * Copyright (c) 2001-2007 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample for using SNMP ONTAPI API to do following operations:
 *              Add new SNMP community
 *              Delete specific SNMP community
 *              Delete all SNMP communities
 *              Disable SNMP interface
 *              SNMP get for specific OID
 *              SNMP Status
 *              Disable Traps
 *
 * Usage:
 *  snmp <filer> <user> <password> <operation> [<value1>] [<value2>]
 * <filer>      -- Name/IP address of the filer
 * <user>       -- User name
 * <password>   -- Password
 * <operation>  -- addCommunity/deleteCommunity/deleteCommunityAll
 *                 snmpDisable/snmpget/
 *                 snmpStatus/trapEnable
 * <value1>     -- This depends on the operation
 * <value2>     -- This depends on the operation
 */

import java.io.IOException;
import java.util.*;
import netapp.manage.*;

public class snmp {
    public static void usage() {
        System.out.println("\nUsage : snmp <filer> <user> <passwd> "
                + "<operation> [<volume1>] [<volume2>]\n");
        System.out.print("<filer>		-- ");
        System.out.println("Name/IP address of the filer");
        System.out.println("<user>		-- User Name");
        System.out.println("<passwd>	-- Password");
        System.out.print("<operation>	--");
        System.out.println(" addCommunity/deleteCommunity/"
                + "deleteCommunityAll/snmpDisable/snmpGet/");
        System.out.println("\t\t   snmpStatus/snmpTrapEnable");
        System.out.println("<value1>	-- This depends on operation");
        System.out.println("<value2>	-- This depends on operation");
        System.exit(1);
    }

    public static void main(String[] args) {
        NaElement xi;
        NaElement xo;
        NaServer s;
        String operation;

        if (args.length < 4) {
            usage();
        }
        try {
            // Initialize connection to server, and
            // request version 1.3 of the API set
            //
            s = new NaServer(args[0], 1, 3);

            // Set connection style(HTTP)
            //
            s.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            s.setAdminUser(args[1], args[2]);
            operation = args[3];

            // Add new SNMP community
            // Usage:
            // snmp <filer> <user> <password> addCommunity
            // <access-control(ro/rw)> <community>
            if (operation.equals("addCommunity")) {
                if (args.length < 6) {
                    System.out.println("Usage :");
                    System.out
                            .println("snmp <filer> <user> <passwd> "
                                    + "addCommunity <access-control(ro/rw)> <community>");
                    System.exit(1);
                }

                xi = new NaElement("snmp-community-add");
                xi.addNewChild("access-control", args[4]);
                xi.addNewChild("community", args[5]);
                xo = s.invokeElem(xi);
                System.out.println("Community added successfully");
            }

            //
            // Delete specific SNMP community
            // Usage:
            // snmp <filer> <user> <password> deleteCommunity
            // <access-control(ro/rw)> <community>
            //
            else if (operation.equals("deleteCommunity")) {
                if (args.length < 6) {
                    System.out.println("Usage :");
                    System.out
                            .println("snmp <filer> <user> <passwd> "
                                    + "deleteCommunity <access-control(ro/rw) <community>");
                    System.exit(1);
                }

                xi = new NaElement("snmp-community-delete");
                xi.addNewChild("access-control", args[4]);
                xi.addNewChild("community", args[5]);
                xo = s.invokeElem(xi);
                System.out.println("Community deleted successfully");
            }

            //
            // Delete all SNMP communities
            // Usage:
            // snmp <filer> <user> <password> deleteCommunityAll
            else if (operation.equals("deleteCommunityAll")) {
                xi = new NaElement("snmp-community-delete-all");
                xo = s.invokeElem(xi);
                System.out.println("Deleted all Communities successfully");
            }

            //
            // Disable SNMP interface
            // Usage:
            // snmp <filer> <user> <password> snmpDisable
            else if (operation.equals("snmpDisable")) {
                xi = new NaElement("snmp-disable");
                xo = s.invokeElem(xi);
                System.out.println("Disabled SNMP interface");
            }

            //
            // SNMP GET operation on specific Object Identifier.
            // Only numeric OID's(ex: .1.3.6.1.4.1.789.1.1.1.0)
            // are allowed.
            // Usage: snmp <filer> <user> <password> snmpget
            // <ObjectIdentifier>
            //
            else if (operation.equals("snmpGet")) {
                if (args.length < 5) {
                    System.out.println("Usage :");
                    System.out.println("snmp <filer> <user> "
                            + "<passwd> snmpGet " + "<objectIdentifier>");

                    System.exit(1);
                }

                xi = new NaElement("snmp-get");
                xi.addNewChild("object-id", args[4]);
                xo = s.invokeElem(xi);
                System.out.print("Value of SNMP Object:\n");
                if (!(xo.getChildContent("value")).equals(null))
                    System.out.println("Value: " + xo.getChildContent("value"));
            }

            //
            // SNMP status
            // Usage: snmp <filer> <user> <password> snmpStatus
            //
            else if (operation.equals("snmpStatus")) {
                xi = new NaElement("snmp-status");
                xo = s.invokeElem(xi);
                NaElement communities;
                communities = xo.getChildByName("communities");
                List communityList = communities.getChildren();
                Iterator communityIter = communityList.iterator();
                System.out.println("\nCommunities");
                while (communityIter.hasNext()) {
                    NaElement communityInfo = (NaElement) communityIter.next();
                    System.out.println("---------------------");
                    System.out.print("Access Control:");
                    System.out.println(communityInfo
                            .getChildContent("access-control"));
                    System.out.print("Community Name:");
                    System.out.println(communityInfo
                            .getChildContent("community"));
                }
                System.out.println("\n\n---------------------");
                System.out.print("Contact :");
                System.out.println(xo.getChildContent("contact"));
                System.out.print("Is trap enabled :");
                System.out.println(xo.getChildContent("is-trap-enabled"));
                System.out.print("Location :");
                System.out.println(xo.getChildContent("location"));
                NaElement trapHosts;
                trapHosts = xo.getChildByName("traphosts");
                List trapHostList = trapHosts.getChildren();
                Iterator trapHostIter = trapHostList.iterator();
                System.out.println("\nTraphosts");
                while (trapHostIter.hasNext()) {
                    NaElement trapHostInfo = (NaElement) trapHostIter.next();
                    System.out.println("---------------------");
                    System.out.print("Host Name:");
                    System.out.println(trapHostInfo
                            .getChildContent("host-name"));
                    System.out.print("Ip Address:");
                    System.out.println(trapHostInfo
                            .getChildContent("ip-address"));
                }
            }
            //
            // Enable Trap
            // Usage: snmp <filer> <user> <password> trapEnable
            else if (operation.equals("snmpTrapEnable")) {
                xi = new NaElement("snmp-trap-enable");
                xo = s.invokeElem(xi);
                System.out.println("Enabled Interface\n");
            } else {
                s.close();
                usage();
            }
            s.close();
        } catch (NaAuthenticationException e) {
            System.err.println("Bad login/password");
        } catch (NaAPIFailedException e) {
            System.err.println("API failed (" + e.getReason() + ")");
        } catch (IOException e) {
            e.printStackTrace();
        } catch (NaProtocolException e) {
            e.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
