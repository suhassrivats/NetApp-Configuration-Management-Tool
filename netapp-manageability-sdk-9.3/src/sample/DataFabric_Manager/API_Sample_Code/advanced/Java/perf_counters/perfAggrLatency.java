/**
 * $Id:$
 *
 * perfAggrLatency.java
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
import java.text.DecimalFormat;

import netapp.manage.NaAPIFailedException;
import netapp.manage.NaElement;
import netapp.manage.NaServer;

public class perfAggrLatency {
    public static void print_help() {
        System.out.println("\nCommand:");
        System.out.println("java perfAggrLatency <dfm> <user> <password>"
                + " <aggr_name>");
        System.out.println("<dfm>       -- DFM Server name");
        System.out.println("<user>      -- User name");
        System.out.println("<password>  -- Password");
        System.out.println("<aggr-name> -- Name of the aggregate in format"
                + " storage:aggrName");
        System.out.println("-----------------------------------------------"
                + "---------------------\n");
        System.out.println("This sample code provides information on read"
                + " latency, write latency");
        System.out.println("and average latency of an aggregate.");
        System.out.println("This data can be used to charts to represent"
                + " data in graphical format.");
        System.out.println("To generate the graph, redirect output of this"
                + " sample code to");
        System.out.println("an Excel sheet.");

        System.exit(1);
    }

    /**
     * getAggrLatency : Calculates the aggregate latency for all the volumes in
     * the aggregate specified.
     * 
     * @param server
     *            DFM server that is contacted to retrieve the information
     * @param aggr
     *            Parent aggregate, latency of volumes under this aggregate are
     *            calculated
     * @return This method outputs the values by itself, no return values
     */

    public static void getAggrLatency(NaServer server, String aggr) {
        NaServer connectedServer = server;
        String targetAggr = aggr;
        NaElement perfApiInput, instanceInfo, counterInfo;
        NaElement perfObjectCounter1, perfObjectCounter2, perfObjectCounter3;
        NaElement perfApiOutput;
        String localTime;
        int sample = 50;
        /*
         * Construct the API to be called here. (perf-get-counter-data)
         * Specified : the duration for api to execute, number of samples and
         * the method of collecting data.
         */

        perfApiInput = new NaElement("perf-get-counter-data");
        perfApiInput.addNewChild("duration", "6000");
        perfApiInput.addNewChild("number-samples", Integer.toString(sample));
        perfApiInput.addNewChild("time-consolidation-method", "average");

        instanceInfo = new NaElement("instance-counter-info");
        instanceInfo.addNewChild("object-name-or-id", targetAggr);

        counterInfo = new NaElement("counter-info");

        perfObjectCounter1 = new NaElement("perf-object-counter");
        perfObjectCounter1.addNewChild("object-type", "volume");
        perfObjectCounter1.addNewChild("counter-name", "read_latency");

        perfObjectCounter2 = new NaElement("perf-object-counter");
        perfObjectCounter2.addNewChild("object-type", "volume");
        perfObjectCounter2.addNewChild("counter-name", "write_latency");

        perfObjectCounter3 = new NaElement("perf-object-counter");
        perfObjectCounter3.addNewChild("object-type", "volume");
        perfObjectCounter3.addNewChild("counter-name", "avg_latency");

        counterInfo.addChildElem(perfObjectCounter1);
        counterInfo.addChildElem(perfObjectCounter2);
        counterInfo.addChildElem(perfObjectCounter3);
        instanceInfo.addChildElem(counterInfo);
        perfApiInput.addChildElem(instanceInfo);

        try {
            perfApiOutput = connectedServer.invokeElem(perfApiInput);

            NaElement iterValue;
            boolean generateTimeArray = true;
            ArrayList timeArray = new ArrayList();
            double[] readDataArray = new double[sample];
            double[] writeDataArray = new double[sample];
            double[] avgDataArray = new double[sample];
            int timeIter, readIter, writeIter, avgIter;

            List instances = perfApiOutput.getChildByName("perf-instances")
                    .getChildren();

            Iterator instanceIter = instances.iterator();

            /*
             * Populate the counter data for aggregate latency.
             */

            while (instanceIter.hasNext()) {

                String counterName;
                readIter = 0;
                writeIter = 0;
                avgIter = 0;
                iterValue = (NaElement) instanceIter.next();

                if (iterValue.getChildByName("counters") != null) {
                    List counters1 = iterValue.getChildByName("counters")
                            .getChildren();
                    Iterator counterIter1 = counters1.iterator();

                    while (counterIter1.hasNext()) {

                        NaElement counter1 = (NaElement) counterIter1.next();
                        String counterData = counter1
                                .getChildContent("counter-data");
                        counterName = counter1.getChildContent("counter-name");

                        String[] counterArray;
                        int iter = 0;
                        counterArray = counterData.split(",");
                        if (counterName.equals("read_latency")) {
                            for (iter = 0; iter < counterArray.length; iter++) {
                                String[] counterDataArray;
                                counterDataArray = counterArray[iter]
                                        .split(":");

                                if (generateTimeArray == true) {
                                    localTime = new SimpleDateFormat(
                                            "dd/MM/yyyy HH:mm:ss")
                                            .format(new Date(
                                                    Long.parseLong(counterDataArray[0]) * 1000));
                                    timeArray.add(localTime);
                                }
                                readDataArray[readIter] += Double
                                        .parseDouble(counterDataArray[1]);
                                readIter++;
                            }
                            generateTimeArray = false;
                        } else if (counterName.equals("write_latency")) {
                            for (iter = 0; iter < counterArray.length; iter++) {
                                String[] counterDataArray;
                                counterDataArray = counterArray[iter]
                                        .split(":");

                                if (generateTimeArray == true) {
                                    localTime = new SimpleDateFormat(
                                            "dd/MM/yyyy HH:mm:ss")
                                            .format(new Date(
                                                    Long.parseLong(counterDataArray[0]) * 1000));
                                    timeArray.add(localTime);
                                }
                                writeDataArray[writeIter] += Double
                                        .parseDouble(counterDataArray[1]);
                                writeIter++;
                            }
                            generateTimeArray = false;
                        } else if (counterName.equals("avg_latency")) {
                            for (iter = 0; iter < counterArray.length; iter++) {
                                String[] counterDataArray;
                                counterDataArray = counterArray[iter]
                                        .split(":");

                                if (generateTimeArray == true) {
                                    localTime = new SimpleDateFormat(
                                            "dd/MM/yyyy HH:mm:ss")
                                            .format(new Date(
                                                    Long.parseLong(counterDataArray[0]) * 1000));
                                    timeArray.add(localTime);
                                }
                                avgDataArray[avgIter] += Double
                                        .parseDouble(counterDataArray[1]);
                                avgIter++;
                            }
                            generateTimeArray = false;
                        }
                    }
                }
            }
            /*
             * Print data for aggregate latencies.
             */

            System.out.println("Time\tRead Latency\tWrite Latency\tAverage"
                    + " Latency");
            int total = timeArray.size();
            DecimalFormat f = new DecimalFormat("#####.####");

            for (timeIter = 0; timeIter < total; timeIter++) {
                System.out.println(timeArray.get(timeIter) + "\t"
                        + f.format(readDataArray[timeIter] / total) + "\t"
                        + f.format(writeDataArray[timeIter] / total) + "\t"
                        + f.format(avgDataArray[timeIter] / total));
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

            getAggrLatency(server, aggr);

        } catch (Exception exception) {
            exception.printStackTrace();
            System.exit(1);
        }
    }

}
