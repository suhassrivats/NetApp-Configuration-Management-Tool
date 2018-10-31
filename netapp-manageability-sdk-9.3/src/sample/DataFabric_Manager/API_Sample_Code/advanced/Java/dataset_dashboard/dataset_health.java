/*
 * $Id:$
 *
 * dataset_health.java
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * Sample code for providing health status of all the datasets
 * in the system. This is provided using a dashboard which
 * provides information about total protected and
 * unprotected datasets, dataset protection status,
 * space status, conformance status, resource status, etc.
 *
 *
 * This Sample code is supported from DataFabric Manager 3.8
 * onwards.
 * However few of the functionalities of the sample code may
 * work on older versions of DataFabric Manager.
 */

import netapp.manage.*;
import java.io.*;
import java.lang.*;
import java.io.StringReader;
import java.util.List;
import java.util.Iterator;
import java.util.Map;
import java.util.HashMap;

public class dataset_health {
    private static NaServer server;

    public static void usage() {
        System.out.print("\nUsage:\n dataset_health <dfm-server> <user> "
                + "<password>");
        System.out.println(" | <[-d] | [-p] | [-D] | [-l [<dataset-name>]>"
                + "\n\n");
        System.out.println("  dfm-server        -- Name/IP Address of the "
                + "DFM server \n");
        System.out.println("  user              -- DFM Server user name \n");
        System.out.println("  password          -- DFM Server password \n");
        System.out.println("  -d                -- Display the dataset health"
                + " dashboard \n");
        System.out.println("  -l                -- List all datasets and its"
                + " status information \n");
        System.out.println("  -p                -- List Protected and "
                + "Unprotected datasets \n");
        System.out.println("  -D                -- List DR configured "
                + "datasets \n\n");
        System.exit(1);
    }

    public static void main(String[] args) {

        // check for the valid no. of arguments
        if (args.length < 4)
            usage();

        int argsIndex = 3;
        server = null;

        try {
            // create the server context for DFM Server
            server = new NaServer(args[0], 1, 0);
            server.setServerType(NaServer.SERVER_TYPE_DFM);
            server.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            server.setAdminUser(args[1], args[2]);

            // parse the input arguments
            if (args[argsIndex].equals("-d"))
                displayDashboard();
            else if (args[argsIndex].equals("-p"))
                listDS("ProtectedUnprotected", null);
            else if (args[argsIndex].equals("-D"))
                listDS("DRConfigured", null);
            else if (args[argsIndex].equals("-l"))
                if (args.length > 4)
                    listDS("All", args[argsIndex + 1]);
                else
                    listDS("All", null);
            else
                usage();
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    // This function will print the input string in a formatted way
    public static void prettyPrint(String input) {
        String output = " | " + input;
        int len = input.length();
        int c = 0;
        for (c = len; c < 60; c++)
            output += " ";
        output += " |";
        System.out.println(output);
    }

    // This function will convert the given seconds into a date formatted string
    public static String convertSeconds(long seconds) {
        String date = "";
        int days = (int) seconds / (24 * 60 * 60);
        int remainder = (int) seconds % (24 * 60 * 60);
        int hours = (int) remainder / (60 * 60);
        remainder %= (60 * 60);
        int mins = (int) remainder / 60;
        remainder %= 60;
        int secs = (int) remainder;

        if (days > 0)
            date += days + " Day ";
        if (hours > 0)
            date += hours + " Hr ";
        if (mins > 0)
            date += mins + " Min ";
        if (secs > 0)
            date += secs + " Sec ";
        return date;
    }

    // This function will list information about the datasets.
    // First parameter contains the type of information that needs to
    // be retrieved and second parameter contains the optional dataset name.
    public static void listDS(String option, String dataset) {
        String datasetName = null;
        String isProtected = null;
        String isDRCapable = null;
        String drState = null;
        String drStatus = null;
        String protStatus = null;
        String confStatus = null;
        String resStatus = null;
        String spaceStatus = null;
        try {
            // create athe API request for retrieving all datasets.
            // This requires invoking dataset-list-info-iter-start and then
            // dataset-list-info-iter-next APIs
            NaElement input = new NaElement("dataset-list-info-iter-start");

            // check whether we provide dataset name. If so add it to the
            // child of input
            if (dataset != null)
                input.addNewChild("object-name-or-id", dataset);

            // For listing DR Configured datasets, add is-dr-capable
            // option to TRUE
            if (option.equals("DRConfigured"))
                input.addNewChild("is-dr-capable", "True");

            // Invoke the dataset-list-info-iter-start API request
            NaElement output = server.invokeElem(input);
            // Extract the record and tag values for iter-next API
            String records = output.getChildContent("records");
            String tag = output.getChildContent("tag");
            input = new NaElement("dataset-list-info-iter-next");
            input.addNewChild("maximum", records);
            input.addNewChild("tag", tag);

            // Invoke the dataset-list-info-iter-next API request
            output = server.invokeElem(input);

            // get the list of datasets which are contained under
            // datasets element
            List dsList = output.getChildByName("datasets").getChildren();
            Iterator dsIter = dsList.iterator();
            if (option.equals("ProtectedUnprotected"))
                System.out.println("\n  Protected/Unprotected Datasets:");
            else if (option.equals("DRConfigured"))
                System.out.println("\n  DR Configured Datasets:");
            else if (option.equals("All"))
                System.out.println("\n  Datasets:");
            System.out.println(" |-----------------------------------------"
                    + "---------------------|");
            // Iterate through each dataset record
            while (dsIter.hasNext()) {
                NaElement dsInfo = (NaElement) dsIter.next();
                datasetName = dsInfo.getChildContent("dataset-name");
                if (option.equals("ProtectedUnprotected")) {
                    prettyPrint("Dataset name           : " + datasetName);
                    isProtected = dsInfo.getChildContent("is-protected");
                    if (isProtected.equals("true"))
                        prettyPrint("Protected              : Yes");
                    else
                        prettyPrint("Protected              : No");
                } else if (option.equals("DRConfigured")) {
                    isDRCapable = dsInfo.getChildContent("is-dr-capable");
                    if (isDRCapable.equals("true")) {
                        NaElement dsStatus = dsInfo
                                .getChildByName("dataset-status");
                        drState = dsInfo.getChildContent("dr-state");
                        drStatus = dsStatus.getChildContent("dr-status");
                        prettyPrint("Dataset name          : " + datasetName);
                        prettyPrint("DR State-Status       : " + drState
                                + " - " + drStatus);
                    }
                } else if (option.equals("All")) {
                    prettyPrint("Dataset name          : " + datasetName);
                    NaElement dsStatus = dsInfo
                            .getChildByName("dataset-status");
                    isProtected = dsInfo.getChildContent("is-protected");
                    if (isProtected.equals("true")) {
                        protStatus = dsStatus
                                .getChildContent("protection-status");
                        prettyPrint("Protection status     : " + protStatus);
                    } else
                        prettyPrint("Protection status     : No data "
                                + "protection policy applied");
                    confStatus = dsStatus.getChildContent("conformance-status");
                    prettyPrint("Conformance status    : " + confStatus);
                    resStatus = dsStatus.getChildContent("resource-status");
                    prettyPrint("Resource status       : " + resStatus);
                    spaceStatus = dsStatus.getChildContent("space-status");
                    prettyPrint("Space status          : " + spaceStatus);
                    isDRCapable = dsInfo.getChildContent("is-dr-capable");
                    if (isDRCapable.equals("true")) {
                        drState = dsInfo.getChildContent("dr-state");
                        drStatus = dsStatus.getChildContent("dr-status");
                        prettyPrint("DR State-Status       : " + drState
                                + " - " + drStatus);
                    } else
                        prettyPrint("DR State-Status       : No data"
                                + " protection policy associated");
                }
                prettyPrint("");
            }
            System.out.println(" |-----------------------------------------"
                    + "---------------------|");
            // done listing the datasets. Now invoke the iter-end API.
            input = new NaElement("dataset-list-info-iter-end");
            input.addNewChild("tag", tag);
            server.invokeElem(input);
        } catch (NaAPIFailedException e) {
            System.err.println(e.toString());
            System.exit(1);
        } catch (Exception e) {
            System.err.println(e.toString());
            e.printStackTrace();
            System.exit(1);
        }
    }

    // This function will print the health of all the datasets in a dashboard.
    public static void displayDashboard() {

        String protStatus = null;
        String confStatus = null;
        String resourceStatus = null;
        String datasetName = null;
        NaElement status = null;

        int psProtected = 0;
        int psUninitialized = 0;
        int psSuspended = 0;
        int worstLag = 0;
        int psLagWarning = 0;
        int psLagError = 0;
        int psBaselineFailure = 0;
        int rsEmergency = 0;
        int rsCritical = 0;
        int rsError = 0;
        int rsWarning = 0;
        int rsNormal = 0;
        int ssError = 0;
        int ssWarning = 0;
        int ssNormal = 0;
        int ssUnknown = 0;
        int dsConformant = 0;
        int dsNonConformant = 0;
        int dsTotalProtected = 0;
        int dsTotalUnprotected = 0;
        int dsTotal = 0;
        int drCount = 0;
        String drState = "";
        String drStateStatus = "";
        String drStatus = "";
        try {
            // create an API request for retrieving all datasets.
            // This requires invoking dataset-list-info-iter-start and then
            // dataset-list-info-iter-next APIs
            NaElement input = new NaElement("dataset-list-info-iter-start");
            // Invoke the dataset-list-info-iter-start API request
            NaElement output = server.invokeElem(input);
            // Extract the records and tag values for iter-next API
            String records = output.getChildContent("records");
            String tag = output.getChildContent("tag");
            input = new NaElement("dataset-list-info-iter-next");
            input.addNewChild("maximum", records);
            input.addNewChild("tag", tag);
            // Invoke the dataset-list-info-iter-next API request
            output = server.invokeElem(input);
            // Iterate through each dataset record
            List dsList = output.getChildByName("datasets").getChildren();
            Iterator dsIter = dsList.iterator();
            while (dsIter.hasNext()) {
                NaElement dsInfo = (NaElement) dsIter.next();
                datasetName = dsInfo.getChildContent("dataset-name");
                status = dsInfo.getChildByName("dataset-status");
                protStatus = status.getChildContent("protection-status");
                if (protStatus != null) {
                    if (protStatus.equals("protected"))
                        psProtected++;
                    else if (protStatus.equals("uninitialized")) {
                        confStatus = status
                                .getChildContent("conformance-status");
                        if (confStatus.equals("conforming")) {
                            psUninitialized++;
                        }
                    }// else if(protStatus == "uninitialized") {
                    else if (protStatus.equals("protection_suspended"))
                        psSuspended++;
                    else if (protStatus.equals("lag_warning"))
                        psLagWarning++;
                    else if (protStatus.equals("lag_error"))
                        psLagError++;
                    else if (protStatus.equals("baseline_failure"))
                        psBaselineFailure++;
                }
                confStatus = status.getChildContent("conformance-status");
                if (confStatus.equals("conformant"))
                    dsConformant++;
                else if (confStatus.equals("nonconformant"))
                    dsNonConformant++;
                resourceStatus = status.getChildContent("resource-status");
                if (resourceStatus.equals("emergency"))
                    rsEmergency++;
                else if (resourceStatus.equals("critical"))
                    rsCritical++;
                else if (resourceStatus.equals("error"))
                    rsError++;
                else if (resourceStatus.equals("warning"))
                    rsWarning++;
                else if (resourceStatus.equals("normal"))
                    rsNormal++;
                String spaceStatus = status.getChildContent("space-status");
                if (spaceStatus != null) {
                    if (spaceStatus.equals("error"))
                        ssError++;
                    else if (spaceStatus.equals("warning"))
                        ssWarning++;
                    else if (spaceStatus.equals("ok"))
                        ssNormal++;
                    else if (spaceStatus.equals("unknown"))
                        ssUnknown++;
                }
            } // while(dsIter.hasNext()){
              // Done listing the datasets. Now invoke the iter-end API
            input = new NaElement("dataset-list-info-iter-end");
            input.addNewChild("tag", tag);
            server.invokeElem(input);

            // Now get the protected and unprotected dataset count.
            input = new NaElement("dp-dashboard-get-protected-data-counts");
            output = server.invokeElem(input);
            dsTotalProtected = output.getChildIntValue(
                    "protected-dataset-count", 0);
            dsTotalUnprotected = output.getChildIntValue(
                    "unprotected-dataset-count", 0);
            dsTotal = dsTotalProtected + dsTotalUnprotected;

            // Now get the DR configured datasets.
            input = new NaElement("dp-dashboard-get-dr-dataset-counts");
            output = server.invokeElem(input);
            // Iterate through each DR state status counts
            List drStateList = output.getChildByName("dr-state-status-counts")
                    .getChildren();
            Iterator drStateIter = drStateList.iterator();
            Map drHash = new HashMap();
            while (drStateIter.hasNext()) {
                NaElement drStateInfo = (NaElement) drStateIter.next();
                int count = drStateInfo.getChildIntValue("count", 0);
                drState = drStateInfo.getChildContent("dr-state");
                drStatus = drStateInfo.getChildContent("dr-status");
                if (drStatus.equals("warning"))
                    drStatus = "warnings";
                drStateStatus = drState + " - " + drStatus;
                drHash.put(drStateStatus, Integer.toString(count));
                drCount += count;
            } // while(drStateIter.hasNext()){
            System.out.print("\n\n  Datasets\n");
            System.out.println(" |-------------------------------------"
                    + "-------------------------|");
            prettyPrint("Protected                 : " + dsTotalProtected);
            prettyPrint("Unprotected               : " + dsTotalUnprotected);
            System.out.println(" |--------------------------------------"
                    + "------------------------|");
            System.out.println("              Total datasets : " + dsTotal
                    + "\n\n");

            System.out.println("  Dataset protection status");
            System.out.println(" |--------------------------------------"
                    + "------------------------|");
            prettyPrint("Baseline Failure          : " + psBaselineFailure);
            prettyPrint("Lag Error                 : " + psLagError);
            prettyPrint("Lag Warning               : " + psLagWarning);
            prettyPrint("Protection Suspended      : " + psSuspended);
            prettyPrint("Uninitialized             : " + psUninitialized);
            prettyPrint("Protected                 : " + psProtected);
            System.out.println(" |---------------------------------------"
                    + "-----------------------|\n\n");
            System.out.println("  Dataset Lags");
            System.out.println(" |---------------------------------------"
                    + "-----------------------|");
            input = new NaElement("dp-dashboard-get-lagged-datasets");
            output = server.invokeElem(input);

            // Iterate through each lagged datasets
            List dsLagList = output.getChildByName("dp-datasets").getChildren();
            Iterator dsLagIter = dsLagList.iterator();
            int count = 0;
            while (dsLagIter.hasNext()) {
                NaElement dsLag = (NaElement) dsLagIter.next();
                String name = dsLag.getChildContent("dataset-name");
                worstLag = dsLag.getChildIntValue("worst-lag", 0);
                String time = convertSeconds(worstLag);
                prettyPrint(name + "                  " + time);
                if (++count >= 5) {
                    break;
                }
            } // while(dsLagIter.hasNext()){
            if (count == 0)
                prettyPrint("No data available");
            System.out.println(" |--------------------------------------"
                    + "------------------------|\n\n");
            System.out.println("  Failover readiness");
            System.out.println(" |----------------------------------------"
                    + "----------------------|");

            if (drCount != 0) {
                for (Iterator i = drHash.keySet().iterator(); i.hasNext();) {
                    String attrName = (String) i.next();
                    int attrValue = Integer.parseInt((String) drHash
                            .get(attrName));
                    prettyPrint(attrName + "            : " + attrValue);
                }
            } else
                prettyPrint("Normal");
            System.out.println(" |--------------------------------------"
                    + "------------------------|");
            System.out.println("   Total DR enabled datasets : " + drCount
                    + "\n\n");

            System.out.println("  Dataset conformance status");
            System.out.println(" |---------------------------------------"
                    + "-----------------------|");
            prettyPrint("Conformant                : " + dsConformant);
            prettyPrint("Non Conformant            : " + dsNonConformant);
            System.out.println(" |---------------------------------------"
                    + "-----------------------|\n\n");

            System.out.println("  Dataset resource status ");
            System.out.println(" |---------------------------------------"
                    + "-----------------------|");
            prettyPrint("Emergency                 : " + rsEmergency);
            prettyPrint("Critical                  : " + rsCritical);
            prettyPrint("Error                     : " + rsError);
            prettyPrint("Warning                   : " + rsWarning);
            prettyPrint("Normal                    : " + rsNormal);
            System.out.println(" |---------------------------------------"
                    + "-----------------------|\n\n");
            System.out.println("  Dataset space status ");
            System.out.println(" |---------------------------------------"
                    + "-----------------------|");
            prettyPrint("Error                     : " + ssError);
            prettyPrint("Warning                   : " + ssWarning);
            prettyPrint("Nowmal                    : " + ssNormal);
            prettyPrint("Unknown                   : " + ssUnknown);
            System.out.println(" |---------------------------------------"
                    + "-----------------------|\n\n");
        } catch (NaAPIFailedException e) {
            System.err.println(e.toString());
            System.exit(1);
        } catch (Exception e) {
            System.err.println(e.toString());
            e.printStackTrace();
            System.exit(1);
        }
    }
}
