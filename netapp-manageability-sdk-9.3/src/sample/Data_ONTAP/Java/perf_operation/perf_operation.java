/*
 * $Id: //depot/prod/zephyr/belair/src/sample/java/perf_operation/perf_operation.java#1 $
 *
 * perf_operation.java
 * Copyright (c) 2001-2007 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample for usage of following nfs group API:
 *			perf-object-list-info   			
 *			perf-object-counter-list-info		
 *			perf-object-instance-list-info
 * 			perf-object-get-instances-iter-*
 *
 * Usage:							 
 * perf_operation <filer> <user> <password> <operation> <value1> <value2>     
 *				     
 * <filer>      -- Name/IP address of the filer		   
 * <user>       -- User name				      
 * <password>   -- Password				       
 * <operation>  -- 
 *		object-list - Get the list of perforance objects in the system
 *		instance-list - Get the list of instances for a given performance object			
 *		counter-list - Get the list of counters available for a given performance object	
 * 		get-counter-values - get the values of the counters for all the instance of a performance object
 *
 */

import java.io.IOException;
import java.util.*;
import netapp.manage.*;

public class perf_operation {

    public static void print_usage() {
        System.out
                .println("\nUsage : perf_operation <filer> <user> <passwd> <operation> \n");
        System.out.print("<filer>	-- ");
        System.out.println("Name/IP address of the filer");
        System.out.println("<user>	-- User Name");
        System.out.println("<passwd>	-- Password");
        System.out.println("<operation>	--");
        System.out
                .println("\tobject-list - Get the list of perforance objects in the system");
        System.out
                .println("\tinstance-list - Get the list of instances for a given performance object");
        System.out
                .println("\tcounter-list - Get the list of counters available for a given performance object");
        System.out
                .println("\tget-counter-values - get the values of the counters for all the instances of a performance object");
        System.exit(1);
    }

    public static void main(String[] args) {
        NaElement xi;
        NaElement xo;
        NaServer s;
        String operation;

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
             * To invoke perf-object-list-info API Usage: perf_operation <filer>
             * <user> <password> object-list
             */
            if (operation.equals("object-list")) {

                xi = new NaElement("perf-object-list-info");
                xo = s.invokeElem(xi);
                List objList = xo.getChildByName("objects").getChildren();
                Iterator objIter = objList.iterator();

                while (objIter.hasNext()) {

                    NaElement objInfo = (NaElement) objIter.next();
                    System.out.print("Object Name = "
                            + objInfo.getChildContent("name") + "\t");
                    System.out.print("privilege level = "
                            + objInfo.getChildContent("privilege-level"));
                    System.out.println("\n");
                }

            }

            /*
             * To invoke perf-object-instance-list-info API Usage:
             * perf_operation <filer> <user> <password> instance-list
             * <objectname>
             */
            else if (operation.equals("instance-list")) {

                if (args.length < 5) {
                    System.out.println("Usage:");
                    System.out
                            .println("perf_operation <filer> <user> <password> <instance-list> <objectname>");
                    System.exit(1);
                }

                xi = new NaElement("perf-object-instance-list-info");
                xi.addNewChild("objectname", args[4]);
                xo = s.invokeElem(xi);

                List instList = xo.getChildByName("instances").getChildren();
                Iterator instIter = instList.iterator();

                while (instIter.hasNext()) {

                    NaElement instInfo = (NaElement) instIter.next();
                    System.out.println("Instance Name = "
                            + instInfo.getChildContent("name"));
                }
            }

            /*
             * To invoke perf-object-counter-list-info API Usage: perf_operation
             * <filer> <user> <password> counter-list <objectname>
             */
            else if (operation.equals("counter-list")) {

                if (args.length < 5) {
                    System.out.println("Usage:");
                    System.out
                            .println("perf_operation <filer> <user> <password> <counter-list> <objectname>");
                    System.exit(1);
                }

                xi = new NaElement("perf-object-counter-list-info");
                xi.addNewChild("objectname", args[4]);
                xo = s.invokeElem(xi);

                List counterList = xo.getChildByName("counters").getChildren();
                Iterator counterIter = counterList.iterator();

                while (counterIter.hasNext()) {

                    NaElement counterInfo = (NaElement) counterIter.next();
                    System.out.print("Counter Name = "
                            + counterInfo.getChildContent("name") + "\t\t\t\t");

                    if (counterInfo.getChildContent("base-counter") != null) {
                        System.out.print("Base Counter = "
                                + counterInfo.getChildContent("base-counter")
                                + "\t");
                    } else {
                        System.out.print("Base Counter = none\t\t\t");
                    }

                    System.out.print("Privilege Level = "
                            + counterInfo.getChildContent("privilege-level")
                            + "\t\t");

                    if (counterInfo.getChildContent("unit") != null) {
                        System.out.print("Unit = "
                                + counterInfo.getChildContent("unit") + "\t");
                    } else {
                        System.out.print("Unit = none\t");
                    }

                    System.out.print("\n");
                }

            }

            /*
             * To invoke perf-object-get-instances-iter-* API Usage:
             * perf_operation <filer> <user> <password> <get-counter-values>
             * <objectname> <counter1> <counter2> <counter3>......
             */
            else if (operation.equals("get-counter-values")) {

                int total_records = 0;
                int max_records = 10;
                int num_records = 0;
                String iter_tag = null;

                if (args.length < 5) {
                    System.out.println("Usage:");
                    System.out
                            .println("perf_operation <filer> <user> <password> <get-counter-values> <objectname> [<counter1> <counter2> ...]");
                    System.exit(1);
                }

                xi = new NaElement("perf-object-get-instances-iter-start");

                xi.addNewChild("objectname", args[4]);

                NaElement counters = new NaElement("counters");

                /*
                 * Now store rest of the counter names as child element of
                 * counters
                 * 
                 * Here it has been hard coded as 5 because first counter is
                 * specified at 6th position from cmd prompt
                 */
                int num_counter = 5;

                while (num_counter < (args.length)) {
                    counters.addNewChild("counter", args[num_counter]);
                    num_counter++;
                }

                /*
                 * If no counters are specified then all the counters are
                 * fetched
                 */
                if (num_counter > 5) {
                    xi.addChildElem(counters);
                }

                xo = s.invokeElem(xi);
                total_records = xo.getChildIntValue("records", -1);
                iter_tag = xo.getChildContent("tag");

                do {

                    xi = new NaElement("perf-object-get-instances-iter-next");
                    xi.addNewChild("tag", iter_tag);
                    xi.addNewChild("maximum", String.valueOf(max_records));
                    xo = s.invokeElem(xi);
                    num_records = xo.getChildIntValue("records", 0);

                    if (num_records != 0) {
                        List instList = xo.getChildByName("instances")
                                .getChildren();
                        Iterator instIter = instList.iterator();

                        while (instIter.hasNext()) {

                            NaElement instData = (NaElement) instIter.next();
                            System.out.println("Instance = "
                                    + instData.getChildContent("name"));
                            List counterList = instData.getChildByName(
                                    "counters").getChildren();
                            Iterator counterIter = counterList.iterator();
                            while (counterIter.hasNext()) {

                                NaElement counterData = (NaElement) counterIter
                                        .next();
                                System.out.print("counter name ="
                                        + counterData.getChildContent("name"));
                                System.out.print("\t counter value ="
                                        + counterData.getChildContent("value"));
                                System.out.println("\n");
                            }

                        }
                    }

                } while (num_records != 0);

                xi = new NaElement("perf-object-get-instances-iter-end");
                xi.addNewChild("tag", iter_tag);
                xo = s.invokeElem(xi);
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
