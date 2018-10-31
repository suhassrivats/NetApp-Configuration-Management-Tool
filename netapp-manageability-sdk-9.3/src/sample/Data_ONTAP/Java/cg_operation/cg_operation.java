/*
 * $Id:$
 *
 * cg_operation.java
 * Copyright (c) 2001-2007 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample for usage of following consistency group API:
 *			cg-start
 *			cg-commit
 *
 * Usage:							 
 * cg_operation <filer> <user> <password> <operation> <value1>    
 *				      [<value2>] [<volumes>]    
 * <filer>      -- Name/IP address of the filer		   
 * <user>       -- User name				      
 * <password>   -- Password				       
 * <operation>  -- cg-start/cg-commit			     
 * <value1>     -- This depends on the operation		  
 * <value2>     -- This depends on the operation		  
 * <volumes>    -- This depends on the operation		  
 *
 */

import java.io.IOException;
import netapp.manage.*;

public class cg_operation {
    public static void usage() {
        System.out
                .println("\nUsage : cg_operation <filer> <user> "
                        + "<passwd> <operation> <value1> [<value2>] "
                        + "[<volumes>]\n");
        System.out.print("<filer>		-- ");
        System.out.println("Name/IP address of the filer");
        System.out.println("<user>		-- User Name");
        System.out.println("<passwd>	-- Password");
        System.out.print("<operation>	--");
        System.out.println("cg-start/cg-commit");
        System.out.println("<value1>	--This depends on operation");
        System.out.println("<value2>	--This depends on operation");
        System.out.println("<volumes>	--List of Volumes.This depends"
                + " on operation\n");
        System.exit(1);
    }

    public static void main(String[] args) {
        NaElement xi;
        NaElement xo;
        NaServer s;
        String operation;
        NaElement vols;
        int volume_counter;
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
             * To start cg-start operation Usage: cg_operation <filer> <user>
             * <password> cg-start <snapshot> <timeout> <volumes>
             */
            if (operation.equals("cg-start")) {
                if (args.length < 7) {
                    System.out.println("Usage :");
                    System.out.println("cg_operation<filer> "
                            + "<user> <passwd> cg-start "
                            + "<snapshot> <timeout> " + "<volumes>");

                    System.exit(1);
                }

                xi = new NaElement("cg-start");
                xi.addNewChild("snapshot", args[4]);
                xi.addNewChild("timeout", args[5]);

                vols = new NaElement("volumes");
                /*
                 * Now store rest of the volumes as a child element of vols
                 * 
                 * Here it has been hard coded as 7 because first volume is
                 * specified at 7th position from cmd prompt
                 */
                volume_counter = 7;
                while (volume_counter != (args.length + 1)) {
                    vols.addNewChild("volume-name", args[volume_counter - 1]);
                    volume_counter++;
                }
                xi.addChildElem(vols);

                /* Printing the INPUT XML */
                System.out.println("Input XML:");
                System.out.println(xi.toPrettyString(""));

                xo = s.invokeElem(xi);

                /* Printing the OUTPUT XML */
                System.out.println("Output XML:");
                System.out.println(xo.toPrettyString(""));

                System.out.println("Consistency group operation"
                        + " started successfuly\n");
            }

            /*
             * To start cg-commit operation Usage: cg_operation <filer> <user>
             * <password> cg-commit <cg-id>
             */
            if (operation.equals("cg-commit")) {
                if (args.length < 5) {
                    System.out.println("Usage :");
                    System.out.println("snmp <filer> <user> "
                            + "<passwd> cg-commit <cg-id> ");
                    System.exit(1);
                }

                xi = new NaElement("cg-commit");

                xc = new NaElement("cg-id", args[4]);
                xi.addChildElem(xc);

                /* Printing the INPUT XML */
                System.out.println("Input XML:");
                System.out.println(xi.toPrettyString(""));

                xo = s.invokeElem(xi);
                System.out.println("Consistency group operation "
                        + "commited successfuly\n ");
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
