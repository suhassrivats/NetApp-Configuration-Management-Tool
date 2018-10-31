/**
 * $Id:$
 *
 * perfVolLatency.java
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

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Iterator;
import java.util.List;

import netapp.manage.NaAPIFailedException;
import netapp.manage.NaElement;
import netapp.manage.NaServer;

public class perfVolLatency {
    public static void print_help() {
        System.out.println("\nCommand:");
        System.out.println("java perfVolLatency <dfm> <user> <password> "
                + "<aggr_name>");
        System.out.println("<dfm>       -- DFM Server name");
        System.out.println("<user>      -- User name");
        System.out.println("<password>  -- Password");
        System.out.println("<aggr-name> -- Name of the aggregate in format "
                + "storage:aggrName");
        System.out.println("-----------------------------------------------"
                + "---------------------\n");
        System.out.println("This sample code prints average latency of all "
                + "the volumes ");
        System.out.println("present in the given aggregate. This data can be"
                + "used to ");
        System.out.println("generate distribution chart for volume average"
                + "latency. ");
        System.out.println("To generate the graph, redirect output of this"
                + "sample code to");
        System.out.println("an Excel sheet.");

        System.exit(1);
    }

    /**
     * getVolLatency : Calculates the volume latency for all the volumes in the
     * aggregate specified.
     * 
     * @param server
     *            DFM server that is contacted to retrieve the information
     * @param aggr
     *            Parent aggregate, latency of volumes under this aggregate are
     *            calculated
     * @return This method outputs the values by itself, no return values
     */

    public static void getVolLatency(NaServer server, String aggr) {
        NaServer connectedServer = server;
        String targetAggr = aggr;
        NaElement perfApiInput, instanceInfo, counterInfo, perfObjectCounter;
        NaElement perfApiOutput;
        String volumeName;
        String localTime;

        /*
         * Construct the API to be called here. (perf-get-counter-data)
         * Specified : the duration for api to execute, number of samples and
         * the method of collecting data.
         */

        perfApiInput = new NaElement("perf-get-counter-data");
        perfApiInput.addNewChild("duration", "6000");
        perfApiInput.addNewChild("number-samples", "50");
        perfApiInput.addNewChild("time-consolidation-method", "average");

        instanceInfo = new NaElement("instance-counter-info");
        instanceInfo.addNewChild("object-name-or-id", targetAggr);

        counterInfo = new NaElement("counter-info");

        perfObjectCounter = new NaElement("perf-object-counter");
        perfObjectCounter.addNewChild("object-type", "volume");
        perfObjectCounter.addNewChild("counter-name", "avg_latency");

        counterInfo.addChildElem(perfObjectCounter);
        instanceInfo.addChildElem(counterInfo);
        perfApiInput.addChildElem(instanceInfo);

        try {
            perfApiOutput = connectedServer.invokeElem(perfApiInput);

            NaElement iterValue;
            boolean generateTimeArray = true;
            ArrayList timeArray = new ArrayList();
            ArrayList dataArray = new ArrayList();
            int nSamples = 0;
            int i = 0;
            String[] counterArray;

            List instances = perfApiOutput.getChildByName("perf-instances")
                    .getChildren();

            Iterator instanceIter = instances.iterator();

            /*
             * Populate the counter data for volume latency.
             */
            System.out.print("Time");
            while (instanceIter.hasNext()) {

                iterValue = (NaElement) instanceIter.next();
                System.out.print("\t");

                if (iterValue.getChildByName("instance-name") != null) {
                    volumeName = iterValue.getChildContent("instance-name");
                    System.out.print(volumeName);
                }

                if (iterValue.getChildByName("counters") != null) {
                    List counters1 = iterValue.getChildByName("counters")
                            .getChildren();
                    Iterator counterIter1 = counters1.iterator();

                    while (counterIter1.hasNext()) {

                        NaElement counter1 = (NaElement) counterIter1.next();
                        String counterData = counter1
                                .getChildContent("counter-data");
                        if (counterData == null || counterData.length() == 0)
                            break;
                        nSamples += counterData.split(",").length;
                        counterArray = counterData.split(",");

                        for (i = 0; i < counterArray.length; i++) {
                            String[] counterDataArray = new String[counterArray[i]
                                    .split(":").length];

                            counterDataArray = counterArray[i].split(":");

                            if (generateTimeArray == true) {
                                localTime = new SimpleDateFormat(
                                        "dd/MM/yyyy HH:mm:ss")
                                        .format(new Date(
                                                Long.parseLong(counterDataArray[0]) * 1000));

                                timeArray.add(localTime);

                            }
                            dataArray.add(new Double(Double
                                    .parseDouble(counterDataArray[1])));
                        }

                        generateTimeArray = false;

                    }
                }

            }

            int a, k;

            String[] timeSamples = new String[timeArray.size()];
            timeArray.toArray(timeSamples);
            Double[] dataSamples = new Double[dataArray.size()];
            dataArray.toArray(dataSamples);

            /*
             * Print data for volume latencies.
             */

            System.out.println("");
            for (a = 0; a < timeSamples.length; a++) {
                System.out.print(timeSamples[a] + "\t");
                for (k = a; k < dataSamples.length; k = k + timeSamples.length) {
                    System.out.print(dataSamples[k].toString() + "\t");
                }
                System.out.println("");
            }

        } catch (NaAPIFailedException exception) {
            exception.printStackTrace();
            System.exit(1);
        } catch (Exception exception) {
            exception.printStackTrace();
            System.exit(1);
        }
    }

    /**
     * @param args
     */
    public static void main(String[] args) {

        NaServer server;

        if (args.length < 4) {
            print_help();
        }

        String aggr = new String(args[3]);

        try {
            server = new NaServer(args[0], 1, 0);
            server.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            server.setAdminUser(args[1], args[2]);
            server.setServerType(NaServer.SERVER_TYPE_DFM);
            server.setPort(8088);

            getVolLatency(server, aggr);

        } catch (Exception exception) {
            exception.printStackTrace();
            System.exit(1);
        }
    }

}
