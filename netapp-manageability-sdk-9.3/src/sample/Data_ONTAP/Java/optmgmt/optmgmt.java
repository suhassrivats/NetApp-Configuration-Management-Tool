/*
 * $Id:$
 *
 * optmgmt.java
 * Copyright (c) 2001-2007 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample for using the netapp.manage.* classes and ONTAPI
 * API to list Option Information 
 * Usage: 
 * optmgmt <filer> <user> <password> [<operation>] [<optionName>] [<value>]
 * <filer>      -- Name/IP address of the filer                   
 * <user>       -- User name                                      
 * <password>   -- Password                                       
 * <operation>  -- get/set                                        
 * <optionName> -- Name of the option on which get/set operation  
 *                needs to be performed                          
 * <value>      -- This is required only for set operation.       
 *                Provide the value that needs to be assigned for
 *                the option                                      
 */

import java.util.*;
import netapp.manage.*;

public class optmgmt {
    public static void main(String[] args) {
        NaElement xi;
        NaElement xo;
        NaServer s;
        String op;

        if (args.length < 3) {
            System.out.print("Usage : optmgmt <filername> "
                    + "<username> <passwd> [operation(get/set)] "
                    + "[<optionName>] [<value>]");
            System.exit(1);
        }
        try {
            // Initialize connection to server, and
            // request version 1.3 of the API set
            //
            s = new NaServer(args[0], 1, 3);
            s.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            s.setAdminUser(args[1], args[2]);

            // Invoke option list Info ONTAPI API
            if (args.length > 3) {
                op = args[3];

                //
                // Get value of a specific option
                //
                if (0 == op.compareTo("get")) {
                    xi = new NaElement("options-get");
                    xi.addNewChild("name", args[4]);

                    xo = s.invokeElem(xi);
                    System.out.println("----------------------------");
                    System.out.print("Option Value:");
                    System.out.println(xo.getChildContent("value"));
                    System.out.print("Cluster Constraint:");
                    System.out
                            .println(xo.getChildContent("cluster-constraint"));
                    System.out.println("----------------------------");

                    s.close();

                    System.exit(0);
                }

                //
                // Set value of a specific option
                else if (0 == op.compareTo("set")) {
                    xi = new NaElement("options-set");
                    xi.addNewChild("name", args[4]);
                    xi.addNewChild("value", args[5]);

                    xo = s.invokeElem(xi);
                    System.out.println("----------------------------");
                    System.out.print("Message:");
                    System.out.println(xo.getChildContent("message"));
                    System.out.print("Cluster Constraint:");
                    System.out
                            .println(xo.getChildContent("cluster-constraint"));
                    System.out.println("----------------------------");

                    s.close();

                    System.exit(0);
                } else {
                    System.out.println("Invalid Operation");
                    System.exit(1);
                }
            }

            //
            // List out all the options
            //
            else {
                xi = new NaElement("options-list-info");

                xo = s.invokeElem(xi);
                //
                // Get the list of children from element(Here
                // 'xo') and iterate through each of the child
                // element to fetch their values
                //
                List optionList = xo.getChildByName("options").getChildren();
                Iterator optionIter = optionList.iterator();
                while (optionIter.hasNext()) {
                    NaElement optionInfo = (NaElement) optionIter.next();
                    System.out.println("----------------------------");
                    System.out.print("Option Name:");
                    System.out.println(optionInfo.getChildContent("name"));
                    System.out.print("Option Value:");
                    System.out.println(optionInfo.getChildContent("value"));
                    System.out.print("Cluster Constraint:");
                    System.out.println(optionInfo
                            .getChildContent("cluster-constraint"));
                }
            }
            s.close();
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}
