/*
 * $Id: //depot/prod/zephyr/belair/src/sample/java/file_snaplock/file_snaplock.java#1 $
 *
 * file_snaplock.java
 * Copyright (c) 2001-2007 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample for usage of following file-snaplock group API:
 *			file-get-snaplock-retention-time
 *			file-snaplock-retention-time-list-info
 *			file-set-snaplock-retention-time
 * 			file-get-snaplock-retention-time-list-info-max
 *
 * Usage:
 * file_snaplock <filer> <user> <password> <operation> <value1> [<value2>]
 *
 * <filer>      -- Name/IP address of the filer
 * <user>       -- User name
 * <password>   -- Password
 * <operation>  -- file-get-snaplock-retention-time
 *			 file-set-snaplock-retention-time
 *			 file-snaplock-retention-time-list-info
 *			 file-get-snaplock-retention-time-list-info-max
 * <value1>     -- This depends on the operation
 * <value2>     -- This depends on the operation
 *
 */

import java.io.IOException;
import java.util.*;
import netapp.manage.*;

public class file_snaplock {
    public static void usage() {
        System.out.println("\nUsage : file_snaplock <filer> <user> "
                + "<passwd> <operation> <value1> [<value2>] \n");

        System.out.print("<filer>	-- ");
        System.out.println("Name/IP address of the filer");
        System.out.println("<user>	-- User Name");
        System.out.println("<passwd>	-- Password");
        System.out.println("<operation>	--");
        System.out.println("\tfile-get-snaplock-retention-time");
        System.out.println("\tfile-set-snaplock-retention-time");
        System.out.println("\tfile-snaplock-retention-time-list-info");
        System.out.println("\tfile-get-snaplock-retention-time-list-info-max");
        System.out.println("<value1>	--This depends on operation");
        System.out.println("<value2>	--This depends on operation");
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
            usage();
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
             * To invoke file-snaplock-retention-time-list-info operation Usage:
             * file_snaplock <filer> <user> <password>
             * file-snaplock-retention-time-list-info <pathnames>
             */
            if (operation.equals("file-snaplock-retention-time-list-info")) {
                if (args.length < 5) {
                    usage();
                }

                xi = new NaElement("file-snaplock-retention-time-list-info");

                pathnames = new NaElement("pathnames");
                /*
                 * Now store rest of the path names as child element of
                 * pathnames
                 * 
                 * Here it has been hard coded as 5 because first volume is
                 * specified at 5th position from cmd prompt
                 */
                path_counter = 5;
                NaElement pathname_info = new NaElement("pathname-info");
                while (path_counter != (args.length + 1)) {
                    pathname_info.addNewChild("pathname",
                            args[path_counter - 1]);
                    path_counter++;
                }
                pathnames.addChildElem(pathname_info);
                xi.addChildElem(pathnames);

                xo = s.invokeElem(xi);

                /* Printing the OUTPUT XML */

                List retList = xo.getChildByName("file-retention-details")
                        .getChildren();
                Iterator retIter = retList.iterator();
                while (retIter.hasNext()) {
                    NaElement retInfo = (NaElement) retIter.next();
                    System.out.println("---------------------------------");
                    System.out.print("Path Name:");
                    System.out.println(retInfo.getChildContent("pathname"));
                    System.out.print("Retention date:");
                    System.out.println(retInfo
                            .getChildContent("formatted-retention-time"));
                }

            }

            /*
             * To invoke file-get-snaplock-retention-time operation Usage:
             * file_snaplock <filer> <user> <password>
             * file-get-snaplock-retention-time <filepath>
             */
            else if (operation.equals("file-get-snaplock-retention-time")) {
                if (args.length < 5) {
                    usage();
                }

                xi = new NaElement("file-get-snaplock-retention-time");
                xi.addNewChild("path", args[4]);

                xo = s.invokeElem(xi);
                int retTime = xo.getChildIntValue("retention-time", -1);
                System.out.println("Retention Time: " + retTime);
            }

            /*
             * To invoke file-set-snaplock-retention-time operation Usage:
             * file_snaplock <filer> <user> <password>
             * file-set-snaplock-retention-time <filepath> <retention-time>
             */
            else if (operation.equals("file-set-snaplock-retention-time")) {
                if (args.length < 5) {
                    usage();
                }

                xi = new NaElement("file-set-snaplock-retention-time");
                xi.addNewChild("path", args[4]);
                if (args.length == 6)
                    xi.addNewChild("retention-time", args[5]);

                xo = s.invokeElem(xi);

            }

            /*
             * To invoke file-get-snaplock-retention-time-list-info-max
             * operation Usage: file_snaplock <filer> <user> <password>
             * file-get-snaplock-retention-time-list-info-max
             */
            else if (operation
                    .equals("file-get-snaplock-retention-time-list-info-max")) {
                if (args.length < 4) {
                    usage();
                }
                xi = new NaElement(
                        "file-get-snaplock-retention-time-list-info-max");

                xo = s.invokeElem(xi);
                int max_list_entries = xo.getChildIntValue("max-list-entries",
                        -1);
                System.out.println("max list entries=" + max_list_entries);
            } else {
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
