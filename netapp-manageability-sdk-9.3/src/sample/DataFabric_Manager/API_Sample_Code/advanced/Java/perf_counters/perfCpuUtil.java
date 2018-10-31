/**
 * $Id:$
 *
 * perfCpuUtil.java
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 *
 * This Sample code is supported from DataFabric Manager 3.7.1
 * onwards.
 * However few of the functionalities of the sample code may
 * work on older versions of DataFabric Manager.
 */

import netapp.manage.NaElement;
import netapp.manage.NaServer;
import java.util.ArrayList;
import java.util.Date;
import java.util.Iterator;
import java.util.List;

public class perfCpuUtil {
    private static NaServer server;
    private static String[] Arg;
    private static ArrayList timeArray = new ArrayList();
    private static ArrayList dataArray = new ArrayList();

    public static void print_help() {
        /*
         * Print usage information for cpu util.
         */
        System.out.println("\nCommand:");
        System.out.println("perf_cpu_util.pl <dfm> <user> <password>"
                + " <storage-system>");
        System.out.println("<dfm>            -- DFM Server name");
        System.out.println("<user>           -- User name");
        System.out.println("<password>       -- Password");
        System.out.println("<storage-system> -- Storage system");
        System.out.println("-----------------------------------------"
                + "---------------------------\n");
        System.out.println("This sample code prints CPU utilization"
                + " statistics of a storage ");
        System.out.println("system. The sample code collects CPU "
                + "utilization data for 2 weeks");
        System.out.println("and prints the data in a format, which enables"
                + " comparision of CPU");
        System.out.println("utilization in day, hour format for both the"
                + " weeks");
        System.out.println("Output data of this sample code can be used "
                + "to generate chart.");
        System.out.println("To generate the graph, redirect output of this"
                + " sample code to");
        System.out.println("an Excel sheet.");

        System.exit(1);
    }

    public static void main(String[] args) {

        Arg = args;
        int arglen = Arg.length;
        long startTime1 = (new Date().getTime() / 1000) - 1209600;
        long endTime1 = (new Date().getTime() / 1000) - 604800;
        long startTime2 = (new Date().getTime() / 1000) - 604800;
        long endTime2 = (new Date().getTime() / 1000);

        // Checking for valid number of parameters
        if (arglen != 4)
            print_help();

        String dfmserver = Arg[0];
        String dfmuser = Arg[1];
        String dfmpw = Arg[2];

        try {
            // Initialize connection to server, and
            // request version 1.0 of the API set
            //
            // Creating a server object and setting appropriate attributes
            server = new NaServer(dfmserver, 1, 0);
            server.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            server.setServerType(NaServer.SERVER_TYPE_DFM);

            server.setAdminUser(dfmuser, dfmpw);

            // Collect data for Week1
            NaElement perfOut1 = perWeekData(Long.toString(startTime1),
                    Long.toString(endTime1));

            // Collect data for Week2
            NaElement perfOut2 = perWeekData(Long.toString(startTime2),
                    Long.toString(endTime2));

            // Extracting the time and date
            getTimedataArrayay(perfOut1);
            ArrayList timeArray1 = new ArrayList(timeArray.size());
            ArrayList dataArray1 = new ArrayList(dataArray.size());
            timeArray1.addAll(timeArray);
            dataArray1.addAll(dataArray);
            // clearing arraylist as they are global arraylists
            timeArray.clear();
            dataArray.clear();

            // values will be loaded into global arraylists
            getTimedataArrayay(perfOut2);
            System.out.println("Week1\t\tWeek2\t");
            System.out.println("Time\tCPU Busy\tTime\tCPU Busy");
            int i;
            int j;

            for (i = 0, j = 0; i < timeArray1.size() && j < timeArray.size();) {
                if ((Long.parseLong(timeArray.get(j).toString()) - Long
                        .parseLong(timeArray1.get(i).toString())) > 608400) {
                    System.out.print(new Date(Long.parseLong(timeArray1.get(i)
                            .toString()) * 1000)
                            + "\t"
                            + dataArray1.get(i).toString() + "\t");
                    i++;
                    System.out.println("\t\t");
                } else if ((Long.parseLong(timeArray.get(j).toString()) - Long
                        .parseLong(timeArray1.get(i).toString())) < 601200) {
                    System.out.print("\t\t");
                    System.out.println(new Date(Long.parseLong(timeArray.get(j)
                            .toString()) * 1000)
                            + "\t"
                            + dataArray.get(j).toString());
                    j++;
                } else {
                    System.out.print(new Date(Long.parseLong(timeArray1.get(i)
                            .toString()) * 1000)
                            + "\t"
                            + dataArray1.get(i).toString() + "\t");
                    i++;
                    System.out.println(new Date(Long.parseLong(timeArray.get(j)
                            .toString()) * 1000)
                            + "\t"
                            + dataArray.get(j).toString());
                    j++;
                }
            }
            while (i < timeArray1.size()) {
                System.out.print(new Date(Long.parseLong(timeArray1.get(i)
                        .toString()) * 1000)
                        + "\t"
                        + dataArray1.get(i).toString() + "\t");
                i++;
                System.out.println("\t\t");
            }
            while (j < timeArray.size()) {
                System.out.print("\t\t");
                System.out.println(new Date(Long.parseLong(timeArray.get(j)
                        .toString()) * 1000)
                        + "\t"
                        + dataArray.get(j).toString());
                j++;
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }

    }

    public static NaElement perWeekData(String startTime, String endTime) {
        NaElement perfOut = null;
        try {

            String storageSystem = Arg[3];

            NaElement perfIn = new NaElement("perf-get-counter-data");

            perfIn.addNewChild("start-time", startTime);
            perfIn.addNewChild("end-time", endTime);
            perfIn.addNewChild("sample-rate", "3600");
            perfIn.addNewChild("time-consolidation-method", "average");

            NaElement instanceInfo = new NaElement("instance-counter-info");
            instanceInfo.addNewChild("object-name-or-id", storageSystem);

            NaElement counterInfo = new NaElement("counter-info");
            NaElement perfObjCtr = new NaElement("perf-object-counter");
            perfObjCtr.addNewChild("object-type", "system");
            perfObjCtr.addNewChild("counter-name", "avg_processor_busy");

            counterInfo.addChildElem(perfObjCtr);
            instanceInfo.addChildElem(counterInfo);
            perfIn.addChildElem(instanceInfo);

            perfOut = server.invokeElem(perfIn);

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
        return perfOut;
    }

    public static void getTimedataArrayay(NaElement perfOut) {

        String[] counterArray;
        String[] timeValArray;
        int read;

        NaElement instance = perfOut.getChildByName("perf-instances");

        List instances = null;
        if (instance != null)
            instances = instance.getChildren();
        if (instances == null)
            return;

        Iterator instanceIter = instances.iterator();

        while (instanceIter.hasNext()) {
            NaElement rec = (NaElement) instanceIter.next();
            NaElement counters = rec.getChildByName("counters");

            List perfCntData = null;
            if (counters != null)
                perfCntData = counters.getChildren();
            if (perfCntData == null)
                return;

            Iterator counterIter = perfCntData.iterator();

            while (counterIter.hasNext()) {
                NaElement rec1 = (NaElement) counterIter.next();
                String counterStr = rec1.getChildContent("counter-data");
                counterArray = counterStr.split(",");

                for (read = 0; read < counterArray.length; read++) {
                    timeValArray = counterArray[read].split(":");
                    timeArray.add(timeValArray[0]);
                    dataArray.add(timeValArray[1]);
                }
            }
        }
    }
}