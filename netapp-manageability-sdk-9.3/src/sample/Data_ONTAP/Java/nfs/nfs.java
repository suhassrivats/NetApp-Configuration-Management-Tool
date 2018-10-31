/*
 * $Id: //depot/prod/zephyr/belair/src/sample/java/nfs/nfs.java#1 $
 *
 * nfs.java
 * Copyright (c) 2001-2007 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample for usage of following nfs group API:
 *			nfs-enable
 *			nfs-disable
 *			nfs-status
 * 			nfs-exportfs-list-rules
 *
 * Usage:
 * nfs <filer> <user> <password> <operation> <value1> [<value2>]
 *
 * <filer>      -- Name/IP address of the filer
 * <user>       -- User name
 * <password>   -- Password
 * <operation>  --
 *		enable - Enable nfs
 *		disable - Disable nfs
 *		status - nfs status
 * 		list   - list nfs export rules
 *
 */

import java.io.IOException;
import java.util.*;
import netapp.manage.*;

public class nfs {

    public static void print_usage() {
        System.out
                .println("\nUsage : nfs <filer> <user> <passwd> <operation> \n");
        System.out.print("<filer>	-- ");
        System.out.println("Name/IP address of the filer");
        System.out.println("<user>	-- User Name");
        System.out.println("<passwd>	-- Password");
        System.out.println("<operation>	--");
        System.out.println("\tenable - To enable NFS Service");
        System.out.println("\tdisable - To disable NFS Service");
        System.out.println("\tstatus - To print the status of NFS Service");
        System.out.println("\tlist - To list the NFS export rules");
        System.exit(1);
    }

    public static void main(String[] args) {
        NaElement xi;
        NaElement xo;
        NaServer s;
        String operation;
        NaElement pathnames;
        int path_counter;
        NaElement xc;

        if (args.length < 4) {
            print_usage();
        }
        try {
            /*
             * Initialize connection to server, and request version 1.3 of the
             * API set
             */
            s = new NaServer(args[0], 1, 3);

            /* Set connection style(HTTP) */
            s.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            s.setAdminUser(args[1], args[2]);
            operation = args[3];

            /*
             * To invoke nfs-enable API Usage: nfs <filer> <user> <password>
             * enable
             */
            if (operation.equals("enable")) {

                xi = new NaElement("nfs-enable");
                xo = s.invokeElem(xi);
                System.out.println("enabled successfully!");
            }

            /*
             * To invoke nfs-enable API Usage: nfs <filer> <user> <password>
             * disable
             */
            else if (operation.equals("disable")) {

                xi = new NaElement("nfs-disable");
                xo = s.invokeElem(xi);
                System.out.println("disabled successfully!");
            }

            /*
             * To invoke nfs-status API Usage: nfs <filer> <user> <password>
             * status
             */
            else if (operation.equals("status")) {

                xi = new NaElement("nfs-status");
                xo = s.invokeElem(xi);
                String enabled = xo.getChildContent("is-enabled");
                if (enabled.compareTo("true") == 0) {
                    System.out.println("NFS Server is enabled");
                } else {
                    System.out.println("NFS Server is disabled");
                }
            }

            /*
             * To invoke nfs-exportfs-list-rules API Usage: nfs <filer> <user>
             * <password> list
             */
            else if (operation.equals("list")) {

                xi = new NaElement("nfs-exportfs-list-rules");
                xo = s.invokeElem(xi);

                List retList = xo.getChildByName("rules").getChildren();
                Iterator retIter = retList.iterator();

                while (retIter.hasNext()) {

                    NaElement retInfo = (NaElement) retIter.next();
                    String path_name = retInfo.getChildContent("pathname");
                    String rw_list = new String("rw=");
                    String ro_list = new String("ro=");
                    String root_list = new String("root=");

                    if (retInfo.getChildByName("read-only") != null) {
                        NaElement rule_elem = retInfo
                                .getChildByName("read-only");
                        List hosts = rule_elem.getChildren();
                        Iterator hostIter = hosts.iterator();
                        while (hostIter.hasNext()) {

                            NaElement hostInfo = (NaElement) hostIter.next();
                            if (hostInfo.getChildContent("all-hosts") != null) {
                                String allhost = hostInfo
                                        .getChildContent("all-hosts");
                                if (allhost.compareTo("true") == 0) {
                                    ro_list = ro_list + "all-hosts";
                                    break;
                                }
                            } else if (hostInfo.getChildContent("name") != null) {
                                ro_list = ro_list
                                        + hostInfo.getChildContent("name")
                                        + ":";
                            }

                        }
                    }
                    if (retInfo.getChildByName("read-write") != null) {
                        NaElement rule_elem = retInfo
                                .getChildByName("read-write");
                        List hosts = rule_elem.getChildren();
                        Iterator hostIter = hosts.iterator();
                        while (hostIter.hasNext()) {

                            NaElement hostInfo = (NaElement) hostIter.next();
                            if (hostInfo.getChildContent("all-hosts") != null) {
                                String allhost = hostInfo
                                        .getChildContent("all-hosts");
                                if (allhost.compareTo("true") == 0) {
                                    rw_list = rw_list + "all-hosts";
                                    break;
                                }
                            } else if (hostInfo.getChildContent("name") != null) {
                                rw_list = rw_list
                                        + hostInfo.getChildContent("name")
                                        + ":";
                            }

                        }
                    }
                    if (retInfo.getChildByName("root") != null) {
                        NaElement rule_elem = retInfo.getChildByName("root");
                        List hosts = rule_elem.getChildren();
                        Iterator hostIter = hosts.iterator();
                        while (hostIter.hasNext()) {

                            NaElement hostInfo = (NaElement) hostIter.next();
                            if (hostInfo.getChildContent("all-hosts") != null) {
                                String allhost = hostInfo
                                        .getChildContent("all-hosts");
                                if (allhost.compareTo("true") == 0) {
                                    root_list = root_list + "all-hosts";
                                    break;
                                }
                            } else if (hostInfo.getChildContent("name") != null) {
                                root_list = root_list
                                        + hostInfo.getChildContent("name")
                                        + ":";
                            }

                        }
                    }
                    path_name = path_name + "  ";
                    if (ro_list.compareTo("ro=") != 0) {
                        path_name = path_name + ro_list;
                    }
                    if (rw_list.compareTo("rw=") != 0) {
                        path_name = path_name + "," + rw_list;
                    }
                    if (root_list.compareTo("root=") != 0) {
                        path_name = path_name + "," + root_list;
                    }

                    System.out.println(path_name);
                }

            } else {
                print_usage();
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
