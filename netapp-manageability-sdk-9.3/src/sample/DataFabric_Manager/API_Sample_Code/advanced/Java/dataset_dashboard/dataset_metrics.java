/*
 * $Id:$
 *
 * dataset_metrics.java
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * Sample code to demonstrate how to get the storage information
 * of each dataset. This provides total space, used space and
 * available space information of each node in a dataset.
 * It also provides space breakout and dedupe space savings
 * information of each dataset member.
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
import java.text.DecimalFormat;
import java.io.StringReader;
import java.util.List;
import java.util.Iterator;
import java.util.Map;
import java.util.HashMap;

public class dataset_metrics {
    private static NaServer server;

    /**
     * This function will print the various space usage options of the dataset.
     */
    public static void usage() {
        System.out.print("\nUsage:\n dataset_metrics <dfm-server> <user> "
                + "<password> -n | ");
        System.out.println(" <-m <dataset-name> > | <-s <dataset-name>> | "
                + "<-d <dataset-name>>\n\n");
        System.out.println("  dfm-server  -- Name/IP Address of the DFM "
                + "Server");
        System.out.println("  user        -- DFM Server user name");
        System.out.println("  password    -- DFM Server password");
        System.out.println("  -n          -- list node level space "
                + "information of all the datasets");
        System.out.println("  -m          -- list member and node "
                + "level space information of the dataset");
        System.out.println("  -s          -- list space breakout information "
                + "of the dataset");
        System.out.println("  -d          -- list dedupe space saving "
                + "information of the dataset\n");
        System.exit(1);
    }

    public static void main(String[] args) {
        // check for valid no. of arguments
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
            if (args[argsIndex].equals("-n"))
                dsSpaceInfo("Node", null);
            else if (args[argsIndex].equals("-m") && args.length > 4)
                dsSpaceInfo("Storage", args[argsIndex + 1]);
            else if (args[argsIndex].equals("-s") && args.length > 4)
                dsDetailSpaceInfo("Space Breakout", args[argsIndex + 1]);
            else if (args[argsIndex].equals("-d") && args.length > 4)
                dsDetailSpaceInfo("Dedupe", args[argsIndex + 1]);
            else
                usage();
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    /**
     * This function will print the node space information in a formatted way
     */
    public static void prettyPrint1(String node, String total, String used,
            String avail) {
        String output = "| " + node;
        int len = node.length();
        int c = 0;
        for (c = len; c < 15; c++)
            output += " ";
        output += "| " + total;

        len = total.length();
        for (c = len; c < 15; c++)
            output += " ";

        output += "| " + used;
        len = used.length();
        for (c = len; c < 15; c++)
            output += " ";

        output += "| " + avail;
        len = avail.length();
        for (c = len; c < 15; c++)
            output += " ";

        output += "        |";
        System.out.println(output);
    }

    /**
     * This function will print the dataset member information in a formatted
     * way
     */
    public static void prettyPrint2(String memberName, String nodeName,
            String spaceStatus, String total, String used, String avail) {
        String output = "| " + memberName;
        int len = memberName.length();
        int c = 0;
        for (c = len + 1; c < 75; c++)
            output += " ";
        output += "|";
        System.out.println(output);

        output = "|        | " + nodeName;

        len = nodeName.length();
        for (c = len; c < 10; c++)
            output += " ";

        output += "| " + spaceStatus;
        len = spaceStatus.length();
        for (c = len + 1; c < 10; c++)
            output += " ";

        if (spaceStatus.equals("Not Available")) {
            for (c = 0; c < 40; c++)
                output += " ";
            output += "|";
            System.out.println(output);
            System.out.println("|                                        "
                    + "                                   |");
            return;
        }

        output += "| " + total;
        len = total.length();
        for (c = len; c < 12; c++)
            output += " ";

        output += " | " + used;
        len = used.length();
        for (c = len; c < 12; c++)
            output += " ";

        output += " | " + avail;
        len = avail.length();
        for (c = len; c < 12; c++)
            output += " ";

        output += "|";
        System.out.println(output);
        System.out.println("|                                             "
                + "                              |");
    }

    /**
     * This function will convert the given bytes into KB or MB or GB format
     */
    public static String getUnits(long val) {
        double temp = 0;
        DecimalFormat f = new DecimalFormat("#####.##");
        String units = "";

        if (val < 1048576) {
            temp = val * 0.0009765;
            units = f.format(temp) + " (KB)";
        } else if (val >= 1048576 && val < 1073741824) {
            temp = val * 0.0000009536;
            units = f.format(temp) + " (MB)";
        } else {
            temp = val * 0.0000000009313;
            units = f.format(temp) + " (GB)";
        }
        return units;
    }

    /**
     * This function will retrieve the node level and member level space
     * information of the dataset
     */
    public static void dsSpaceInfo(String option, String dataset) {
        try {
            // create the API request for retrieving all datasets.
            // This requires invoking dataset-list-info-iter-start and then
            // dataset-list-info-iter-next APIs
            NaElement input = new NaElement("dataset-list-info-iter-start");

            // check whether we provided dataset name. If so add it to the
            // child of input
            if (dataset != null)
                input.addNewChild("object-name-or-id", dataset);

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

            if (option.equals("Storage")) {
                System.out.println("\nDataset name : " + dataset);
                System.out.println("\n\n Member level details: ");
                System.out.println("|--------------------------------------"
                        + "-------------------------------------|");
                System.out.println("| Storage                              "
                        + "                                     |");
                System.out.println("|        | Node      | status   | "
                        + "Total space  | Used space   | Avail space |");
                System.out.println("|--------------------------------------"
                        + "-------------------------------------|");
            } // if(option.equals("Storage")) {

            // Iterate through each dataset record
            while (dsIter.hasNext()) {
                NaElement dsInfo = (NaElement) dsIter.next();
                String dsName = dsInfo.getChildContent("dataset-name");
                String dsID = dsInfo.getChildContent("dataset-id");
                Map primaryNode = new HashMap();
                Map backupNode = new HashMap();
                Map mirrorNode = new HashMap();
                Map firstMirrorNode = new HashMap();
                Map secondMirrorNode = new HashMap();
                Map drBackupNode = new HashMap();
                Map drMirrorNode = new HashMap();

                // Frame the dataset member list info API request to return
                // the space information
                NaElement dsMember = new NaElement(
                        "dataset-member-list-info-iter-start");
                dsMember.addNewChild("dataset-name-or-id", dsID);
                dsMember.addNewChild("include-indirect", "true");
                dsMember.addNewChild("include-space-info", "true");
                dsMember.addNewChild("suppress-status-refresh", "true");
                dsMember.addNewChild("include-exports-info", "true");

                // Invoke the dataset-member-list-info-iter-next API request
                output = server.invokeElem(dsMember);
                // Extract the record and tag values for iter-next API
                String memberRecords = output.getChildContent("records");
                String memberTag = output.getChildContent("tag");
                dsMember = new NaElement("dataset-member-list-info-iter-next");
                dsMember.addNewChild("maximum", memberRecords);
                dsMember.addNewChild("tag", memberTag);

                // Invoke the dataset-member-list-info-iter-next API request
                output = server.invokeElem(dsMember);
                // get the list of dataset members which are contained under
                // dataset-members element
                List dsMemberList = null;
                // no members ?
                if (output.getChildByName("dataset-members") == null) {
                    dsMember = new NaElement(
                            "dataset-member-list-info-iter-end");
                    dsMember.addNewChild("tag", memberTag);
                    // Invoke the dataset-member-list-info-iter-end API request
                    output = server.invokeElem(dsMember);
                    continue;
                }
                dsMemberList = output.getChildByName("dataset-members")
                        .getChildren();
                Iterator dsMemberIter = dsMemberList.iterator();

                if (option.equals("Node"))
                    System.out.println("\n Dataset name: " + dsName);

                // iterate through each dataset member
                while (dsMemberIter.hasNext()) {
                    NaElement dsMemberInfo = (NaElement) dsMemberIter.next();
                    String memberName = dsMemberInfo
                            .getChildContent("member-name");
                    String memberID = dsMemberInfo.getChildContent("member-id");
                    String memberType = dsMemberInfo
                            .getChildContent("member-type");
                    String memberNodeName = dsMemberInfo
                            .getChildContent("dp-node-name");
                    NaElement spaceInfo = dsMemberInfo
                            .getChildByName("space-info");
                    String spaceStatus = "Not Available";
                    long dataAvail = 0;
                    long totalData = 0;
                    long dataUsed = 0;

                    if (memberNodeName.equals("Primary data"))
                        memberNodeName = "Primary";
                    if (memberNodeName.equals(""))
                        memberNodeName = "Primary";
                    // don't consider root storage
                    if (memberName.endsWith("-"))
                        spaceStatus = null;
                    // get the space info for non volume member
                    // like qtree or lun
                    else if (!memberType.equals("volume") && spaceInfo != null) {
                        spaceStatus = spaceInfo.getChildContent("space-status");
                        dataAvail = spaceInfo.getChildLongValue(
                                "available-space", 0);
                        totalData = spaceInfo.getChildLongValue("total-space",
                                0);
                        dataUsed = spaceInfo.getChildLongValue("used-space", 0);
                    } // if(!memberType.equals("volume") && spaceInfo != null) {
                      // get the space info for volume member type
                    else if (memberType.equals("volume")) {
                        if (spaceInfo != null)
                            spaceStatus = spaceInfo
                                    .getChildContent("space-status");
                        NaElement volumeInput = new NaElement(
                                "volume-list-info-iter-start");
                        volumeInput.addNewChild("object-name-or-id", memberID);
                        // invoke the volume-list-info-iter-start API
                        NaElement volumeOutput = server.invokeElem(volumeInput);
                        String volumeRecords = volumeOutput
                                .getChildContent("records");
                        String volumeTag = volumeOutput.getChildContent("tag");
                        volumeInput = new NaElement(
                                "volume-list-info-iter-next");
                        volumeInput.addNewChild("maximum", volumeRecords);
                        volumeInput.addNewChild("tag", volumeTag);
                        // invoke the volume-list-info-iter-next API
                        volumeOutput = server.invokeElem(volumeInput);
                        List volList = null;
                        // no volumes ?
                        if (volumeOutput.getChildByName("volumes") == null) {
                            volumeInput = new NaElement(
                                    "volume-list-info-iter-end");
                            volumeInput.addNewChild("tag", volumeTag);
                            volumeOutput = server.invokeElem(volumeInput);
                            continue;
                        }
                        volList = volumeOutput.getChildByName("volumes")
                                .getChildren();
                        Iterator volIter = volList.iterator();
                        // iterate through each volume member, there will be
                        // only one volume returned
                        while (volIter.hasNext()) {
                            NaElement volInfo = (NaElement) volIter.next();
                            NaElement volSize = volInfo
                                    .getChildByName("volume-size");
                            dataUsed = volSize.getChildLongValue("afs-used", 0);
                            dataAvail = volSize.getChildLongValue("afs-avail",
                                    0);
                            totalData = volSize.getChildLongValue("afs-total",
                                    0);
                        } // while(dsMemberIter.hasNext()) {
                        volumeInput = new NaElement("volume-list-info-iter-end");
                        volumeInput.addNewChild("tag", volumeTag);
                        volumeOutput = server.invokeElem(volumeInput);
                    } // if(memberType.equals("volume")) {
                    if (spaceStatus != null) {
                        String hashVal = memberType + "#" + spaceStatus + "#"
                                + totalData + "#" + dataUsed + "#" + dataAvail;

                        if (memberNodeName.equals("Primary"))
                            primaryNode.put(memberName, hashVal);
                        else if (memberNodeName.equals("Backup"))
                            backupNode.put(memberName, hashVal);
                        else if (memberNodeName.equals("Mirror"))
                            mirrorNode.put(memberName, hashVal);
                        else if (memberNodeName.equals("First Mirror"))
                            firstMirrorNode.put(memberName, hashVal);
                        else if (memberNodeName.equals("Second Mirror"))
                            secondMirrorNode.put(memberName, hashVal);
                        else if (memberNodeName.equals("DR Mirror"))
                            drMirrorNode.put(memberName, hashVal);
                        else if (memberNodeName.equals("DR Backup"))
                            drBackupNode.put(memberName, hashVal);
                    } // if(spaceStatus != null) {
                    if (option.equals("Storage") && spaceStatus != null) {
                        prettyPrint2(memberName, memberNodeName, spaceStatus,
                                getUnits(totalData), getUnits(dataUsed),
                                getUnits(dataAvail));
                    } // if(option.equals("Storage") {
                } // while(dsMemberIter.hasNext()) {
                if (option.equals("Storage")) {
                    System.out.println("|---------------------------------"
                            + "------------------------------------------|");
                    System.out.println("\n Node level details:");
                }
                calcNodeSpaceInfo(primaryNode, backupNode, mirrorNode,
                        firstMirrorNode, secondMirrorNode, drBackupNode,
                        drMirrorNode);
            } // while(dsIter.hasNext()){
              // done listing the datasets. Now invoke the iter-end API.
            input = new NaElement("dataset-list-info-iter-end");
            input.addNewChild("tag", tag);
            server.invokeElem(input);
        } catch (NaAPIFailedException e) {
            System.err.println(e.toString());
            e.printStackTrace();
            System.exit(1);
        } catch (Exception e) {
            System.err.println(e.toString());
            e.printStackTrace();
            System.exit(1);
        }
    }

    /**
     * This function will calculate the total space information of a given node
     * in the dataset
     */
    public static long[] getNodeSpaceInfo(Map node) {
        long total = 0;
        long used = 0;
        long avail = 0;
        long[] size = new long[3];

        if (node.isEmpty())
            return null;

        for (Iterator i = node.keySet().iterator(); i.hasNext();) {
            String attrName = (String) i.next();
            String attrValue = (String) node.get(attrName);
            String[] nodeInfo = attrValue.split("#");
            // check if qreee or lun is already in a volume member of a dataset
            if (!nodeInfo[0].equals("volume")) {
                int pos = attrName.lastIndexOf('/');
                String volName = attrName.substring(0, pos);
                if (node.get(volName) == null) {
                    total += Long.parseLong(nodeInfo[2]);
                    used += Long.parseLong(nodeInfo[3]);
                    avail += Long.parseLong(nodeInfo[4]);
                }
            } else {
                total += Long.parseLong(nodeInfo[2]);
                used += Long.parseLong(nodeInfo[3]);
                avail += Long.parseLong(nodeInfo[4]);
            }
        }
        size[0] = total;
        size[1] = used;
        size[2] = avail;
        return size;
    }

    /**
     * This function will calculate the space information of each node in a
     * dataset
     */
    public static void calcNodeSpaceInfo(Map primaryNode, Map backupNode,
            Map mirrorNode, Map firstMirrorNode, Map secondMirrorNode,
            Map drBackupNode, Map drMirrorNode) {
        long[] size;

        System.out.println("|--------------------------------------------"
                + "-------------------------------|");
        System.out.println("| Node type      | Total space    | Used space"
                + "     | Avail space            |");
        System.out.println("|---------------------------------------------"
                + "------------------------------|");

        if ((size = getNodeSpaceInfo(primaryNode)) != null)
            prettyPrint1("Primary", getUnits(size[0]), getUnits(size[1]),
                    getUnits(size[2]));
        if ((size = getNodeSpaceInfo(backupNode)) != null)
            prettyPrint1("Backup", getUnits(size[0]), getUnits(size[1]),
                    getUnits(size[2]));
        if ((size = getNodeSpaceInfo(mirrorNode)) != null)
            prettyPrint1("mirror", getUnits(size[0]), getUnits(size[1]),
                    getUnits(size[2]));
        if ((size = getNodeSpaceInfo(firstMirrorNode)) != null)
            prettyPrint1("First Mirror", getUnits(size[0]), getUnits(size[1]),
                    getUnits(size[2]));
        if ((size = getNodeSpaceInfo(secondMirrorNode)) != null)
            prettyPrint1("Second Mirror", getUnits(size[0]), getUnits(size[1]),
                    getUnits(size[2]));
        if ((size = getNodeSpaceInfo(drBackupNode)) != null)
            prettyPrint1("DR Backup", getUnits(size[0]), getUnits(size[1]),
                    getUnits(size[2]));
        if ((size = getNodeSpaceInfo(drMirrorNode)) != null)
            prettyPrint1("DR Mirror", getUnits(size[0]), getUnits(size[1]),
                    getUnits(size[2]));
        System.out.println("|----------------------------------------------"
                + "-----------------------------|");
    }

    /**
     * This function will get the detail space information of the given dataset.
     */
    public static void dsDetailSpaceInfo(String option, String dataset) {
        try {
            // create the API request for retrieving all datasets.
            // This requires invoking dataset-list-info-iter-start and then
            // dataset-list-info-iter-next APIs
            NaElement input = new NaElement("dataset-list-info-iter-start");

            // add dataset name to the child of input
            input.addNewChild("object-name-or-id", dataset);

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

            // get the list of datasets which are contained under
            // datasets element
            List dsList = output.getChildByName("datasets").getChildren();
            Iterator dsIter = dsList.iterator();

            System.out.println("\nDataset name : " + dataset);

            // Iterate through each dataset record
            while (dsIter.hasNext()) {
                NaElement dsInfo = (NaElement) dsIter.next();
                String dsName = dsInfo.getChildContent("dataset-name");
                String dsID = dsInfo.getChildContent("dataset-id");

                // Frame the dataset member list info API request to
                // return the space information
                NaElement dsMember = new NaElement(
                        "dataset-member-list-info-iter-start");
                dsMember.addNewChild("dataset-name-or-id", dsID);
                dsMember.addNewChild("include-indirect", "true");
                dsMember.addNewChild("include-space-info", "true");
                dsMember.addNewChild("suppress-status-refresh", "true");
                dsMember.addNewChild("include-exports-info", "true");

                // Invoke the dataset-member-list-info-iter-next API request
                output = server.invokeElem(dsMember);
                // Extract the record and tag values for iter-next API
                String memberRecords = output.getChildContent("records");
                String memberTag = output.getChildContent("tag");
                dsMember = new NaElement("dataset-member-list-info-iter-next");
                dsMember.addNewChild("maximum", memberRecords);
                dsMember.addNewChild("tag", memberTag);

                // Invoke the dataset-member-list-info-iter-next API request
                output = server.invokeElem(dsMember);
                // get the list of dataset members which are contained under
                // dataset-members element
                List dsMemberList = null;
                // no members ?
                if (output.getChildByName("dataset-members") == null) {
                    dsMember = new NaElement(
                            "dataset-member-list-info-iter-end");
                    dsMember.addNewChild("tag", memberTag);
                    // Invoke the dataset-member-list-info-iter-end API request
                    output = server.invokeElem(dsMember);
                    continue;
                }
                dsMemberList = output.getChildByName("dataset-members")
                        .getChildren();
                Iterator dsMemberIter = dsMemberList.iterator();

                // iterate through each dataset member
                while (dsMemberIter.hasNext()) {
                    NaElement dsMemberInfo = (NaElement) dsMemberIter.next();
                    String memberName = dsMemberInfo
                            .getChildContent("member-name");
                    String memberID = dsMemberInfo.getChildContent("member-id");
                    String memberType = dsMemberInfo
                            .getChildContent("member-type");
                    String memberNodeName = dsMemberInfo
                            .getChildContent("dp-node-name");
                    NaElement spaceInfo = dsMemberInfo
                            .getChildByName("space-info");
                    String spaceStatus = "Not Available";
                    long dataAvail = 0;
                    long totalData = 0;
                    long dataUsed = 0;
                    long snapUsed = 0;
                    long snapAvail = 0;
                    long snapReserve = 0;
                    long snapOverflow = 0;
                    long holeReserve = 0;
                    long overwriteUsed = 0;
                    long overwriteReserve = 0;
                    long overwriteAvail = 0;
                    long dedupeSpaceSavings = 0;
                    int dedupeSpaceSavingsPercentage = 0;
                    String storageType = "nas";
                    String dedupeStatus = "unknown";
                    String curDedupeProgress = "unknown";
                    String dedupeError = null;

                    if (memberNodeName.equals("Primary data"))
                        memberNodeName = "Primary";
                    if (memberNodeName.equals(""))
                        memberNodeName = "Primary";

                    if (spaceInfo == null)
                        spaceStatus = "Not Available";
                    // don't consider root storage
                    if (memberName.endsWith("-"))
                        spaceStatus = null;
                    // get the space info for non volume member type
                    else if (!memberType.equals("volume") && spaceInfo != null) {
                        spaceStatus = spaceInfo.getChildContent("space-status");
                        dataAvail = spaceInfo.getChildLongValue(
                                "available-space", 0);
                        totalData = spaceInfo.getChildLongValue("total-space",
                                0);
                        dataUsed = spaceInfo.getChildLongValue("used-space", 0);
                    } // if(!memberType.equals("volume") && spaceInfo != null) {
                      // get the space info for volume member type
                    else if (memberType.equals("volume")) {
                        if (spaceInfo != null)
                            spaceStatus = spaceInfo
                                    .getChildContent("space-status");
                        NaElement volumeInput = new NaElement(
                                "volume-list-info-iter-start");
                        volumeInput.addNewChild("object-name-or-id", memberID);
                        // invoke the volume-list-info-iter-start API
                        NaElement volumeOutput = server.invokeElem(volumeInput);
                        String volumeRecords = volumeOutput
                                .getChildContent("records");
                        String volumeTag = volumeOutput.getChildContent("tag");
                        volumeInput = new NaElement(
                                "volume-list-info-iter-next");
                        volumeInput.addNewChild("maximum", volumeRecords);
                        volumeInput.addNewChild("tag", volumeTag);
                        // invoke the volume-list-info-iter-next API
                        volumeOutput = server.invokeElem(volumeInput);
                        List volList = null;
                        // no volumes ?
                        if (volumeOutput.getChildByName("volumes") == null) {
                            volumeInput = new NaElement(
                                    "volume-list-info-iter-end");
                            volumeInput.addNewChild("tag", volumeTag);
                            volumeOutput = server.invokeElem(volumeInput);
                            continue;
                        }
                        volList = volumeOutput.getChildByName("volumes")
                                .getChildren();
                        Iterator volIter = volList.iterator();
                        // iterate through each volume member, there will
                        // be only one volume returned
                        while (volIter.hasNext()) {
                            NaElement volInfo = (NaElement) volIter.next();
                            NaElement volSize = volInfo
                                    .getChildByName("volume-size");
                            dataUsed = volSize.getChildLongValue("afs-used", 0);
                            dataAvail = volSize.getChildLongValue("afs-avail",
                                    0);
                            totalData = volSize.getChildLongValue("afs-total",
                                    0);
                            snapUsed = volSize.getChildLongValue(
                                    "snapshot-reserve-used", 0);
                            snapReserve = volSize.getChildLongValue(
                                    "snapshot-reserve-total", 0);
                            snapAvail = volSize.getChildLongValue(
                                    "snapshot-reserve-avail", 0);
                            overwriteReserve = volSize.getChildLongValue(
                                    "overwrite-reserve-total", 0);
                            overwriteUsed = volSize.getChildLongValue(
                                    "overwrite-reserve-used", 0);
                            overwriteAvail = volSize.getChildLongValue(
                                    "overwrite-reserve-avail", 0);
                            overwriteReserve = volSize.getChildLongValue(
                                    "overwrite-reserve-total", 0);
                            holeReserve = volSize.getChildLongValue(
                                    "hole-reserve", 0);
                            if (option.equals("Dedupe")) {
                                NaElement dedupeInfo = volInfo
                                        .getChildByName("volume-dedupe-info");
                                if (dedupeInfo == null)
                                    dedupeError = "Dedupe information not available";
                                else if (dedupeInfo != null
                                        && dedupeInfo.getChildContent(
                                                "is-dedupe-enabled").equals(
                                                "false"))
                                    dedupeError = "Dedupe is not enabled on this volume";
                                else {
                                    dedupeSpaceSavings = dedupeInfo
                                            .getChildLongValue(
                                                    "dedupe-space-savings", 0);
                                    dedupeSpaceSavingsPercentage = dedupeInfo
                                            .getChildIntValue("dedupe-space-"
                                                    + "savings-percentage", 0);
                                    dedupeStatus = dedupeInfo
                                            .getChildContent("dedupe-status");
                                    curDedupeProgress = dedupeInfo
                                            .getChildContent("dedupe-progress");
                                }
                            }
                        } // while(volIter.hasNext()) {
                        volumeInput = new NaElement("volume-list-info-iter-end");
                        volumeInput.addNewChild("tag", volumeTag);
                        volumeOutput = server.invokeElem(volumeInput);
                        storageType = getProvPolicyType(dsInfo
                                .getChildContent("provisioning-policy-id"));
                        if (holeReserve > 0)
                            storageType = "san";
                        if (option.equals("Dedupe")) {

                            calcDedupeSpaceInfo(memberName, memberType,
                                    spaceStatus, storageType, dataUsed,
                                    totalData, dataAvail, snapUsed,
                                    snapReserve, snapAvail, overwriteUsed,
                                    overwriteReserve, overwriteAvail,
                                    holeReserve, dedupeSpaceSavings,
                                    dedupeSpaceSavingsPercentage, dedupeStatus,
                                    curDedupeProgress, dedupeError);
                        } // if(option.equals("Dedupe")) {
                    } // if(memberType.equals("volume")) {
                    if (spaceStatus != null && option.equals("Space Breakout"))
                        calcSpaceBreakout(memberName, memberType, spaceStatus,
                                storageType, dataUsed, totalData, dataAvail,
                                snapUsed, snapReserve, snapAvail,
                                overwriteUsed, overwriteReserve,
                                overwriteAvail, holeReserve);
                } // while(dsMemberIter.hasNext()) {
            } // while(dsIter.hasNext()){
              // done listing the datasets. Now invoke the iter-end API.
            input = new NaElement("dataset-list-info-iter-end");
            input.addNewChild("tag", tag);
            server.invokeElem(input);
        } catch (NaAPIFailedException e) {
            System.err.println(e.toString());
            e.printStackTrace();
            System.exit(1);
        } catch (Exception e) {
            System.err.println(e.toString());
            e.printStackTrace();
            System.exit(1);
        }
    }

    /**
     * This function will return the provision policy type for the given policy
     * ID
     */
    public static String getProvPolicyType(String provPolicyID) {
        String policyType = "nas";
        if (provPolicyID == null)
            return policyType;
        try {
            NaElement provPolicyInput = new NaElement(
                    "provisioning-policy-list-iter-start");
            provPolicyInput.addNewChild("provisioning-policy-name-or-id",
                    provPolicyID);
            NaElement provPolicyOutput = server.invokeElem(provPolicyInput);
            String records = provPolicyOutput.getChildContent("records");
            String tag = provPolicyOutput.getChildContent("tag");

            provPolicyInput = new NaElement(
                    "provisioning-policy-list-iter-next");
            provPolicyInput.addNewChild("maximum", records);
            provPolicyInput.addNewChild("tag", tag);
            provPolicyOutput = server.invokeElem(provPolicyInput);

            List polList = null;
            if (provPolicyOutput.getChildByName("provisioning-policies") != null)
                polList = provPolicyOutput.getChildByName(
                        "provisioning-policies").getChildren();
            Iterator polIter = polList.iterator();
            while (polIter.hasNext()) {
                NaElement polInfo = (NaElement) polIter.next();
                policyType = polInfo
                        .getChildContent("provisioning-policy-type");
            }
            provPolicyInput = new NaElement("provisioning-policy-list-iter-end");
            provPolicyInput.addNewChild("tag", tag);
            provPolicyOutput = server.invokeElem(provPolicyInput);
        } catch (NaAPIFailedException e) {
            System.err.println(e.toString());
            e.printStackTrace();
            System.exit(1);
        } catch (Exception e) {
            System.err.println(e.toString());
            e.printStackTrace();
            System.exit(1);
        }
        return policyType;
    }

    /**
     * This function will calculate the space breakout information for the given
     * dataset member.
     */
    public static void calcSpaceBreakout(String memberName, String memberType,
            String spaceStatus, String storageType, long dataUsed,
            long totalData, long dataAvail, long snapUsed, long snapReserve,
            long snapAvail, long overwriteUsed, long overwriteReserve,
            long overwriteAvail, long holeReserve) {
        long snapOverflow = 0;
        long totalDataSize = 0;
        long totalVolSize = 0;

        System.out.println("\nStorage               : " + memberName);
        System.out.println("Storage type          : " + memberType);
        System.out.println("Space status          : " + spaceStatus);
        if (spaceStatus.equals("Not Available")) {
            return;
        }
        if (!memberType.equals("volume")) {

            if (!memberType.equals("lun_path")) {
                System.out.println("Qtree Used  space     : "
                        + getUnits(dataUsed));
                System.out.println("Qtree Avail space     : "
                        + getUnits(dataAvail));
            } else {
                System.out.println("LUN Total space       : "
                        + getUnits(totalData));
            }
            return;
        }
        if (storageType.equals("nas")) {
            if (snapUsed > snapReserve) {
                snapOverflow = snapUsed - snapReserve;
                dataUsed -= snapOverflow;
                snapUsed = snapReserve;
                snapAvail = 0;
            }
            System.out.println("\nData     :");
            System.out.println("Used space                         : "
                    + getUnits(dataUsed));
            System.out.println("Free space                         : "
                    + getUnits(dataAvail));
            System.out.println("Snap overflow                      : "
                    + getUnits(snapOverflow));
            totalDataSize = dataUsed + dataAvail + snapOverflow;
            totalVolSize = totalDataSize;
            System.out.println("                                   "
                    + "--------------------");
            System.out.println("Total data space                   : "
                    + getUnits(totalDataSize) + "\n");
            System.out.println("Snapshot :");
            System.out.println("Used snapshot space                : "
                    + getUnits(snapUsed));
            System.out.println("Free snapshot space                : "
                    + getUnits(snapAvail));
            totalVolSize += snapReserve;
            System.out.println("                                   "
                    + "--------------------");
            System.out.println("Snapshot reserve                   : "
                    + getUnits(snapReserve) + "\n");
            System.out.println("\nVolume   :");
            System.out.println("Total volume size                  : "
                    + getUnits(totalVolSize));
        } else {
            long usedLunSpace = 0;
            long availLunSpace = holeReserve;
            if (overwriteUsed > 0) {
                dataUsed -= (overwriteUsed + overwriteAvail);
            } else if (overwriteUsed == 0) {
                dataUsed -= overwriteReserve;
            }
            usedLunSpace = dataUsed - availLunSpace;
            if (snapUsed > snapReserve) {
                snapOverflow = snapUsed - snapReserve;
                usedLunSpace -= snapOverflow;
            }
            System.out.println("\nData     :");
            System.out.println("LUN Used space                         : "
                    + getUnits(usedLunSpace));
            System.out.println("LUN Free space                         : "
                    + getUnits(availLunSpace));
            System.out.println("Data in overwrite reserve              : "
                    + getUnits(overwriteUsed));
            totalDataSize = usedLunSpace + availLunSpace + overwriteUsed;
            System.out.println("                                       "
                    + "----------------");
            System.out.println("Total data space                       : "
                    + getUnits(totalDataSize) + "\n");
        }
    }

    /**
     * This function will calculate the dedupe space saving information for the
     * given dataset member.
     */
    public static void calcDedupeSpaceInfo(String memberName,
            String memberType, String spaceStatus, String storageType,
            long dataUsed, long totalData, long dataAvail, long snapUsed,
            long snapReserve, long snapAvail, long overwriteUsed,
            long overwriteReserve, long overwriteAvail, long holeReserve,
            long dedupeSpaceSavings, int dedupeSpaceSavingsPercentage,
            String dedupeStatus, String currDedupeProgress, String dedupeError) {

        long snapOverflow = 0;
        long total = 0;
        long dataUsedWithoutDedupe = 0;
        long dataUsedWithDedupe = 0;

        System.out.println("\nStorage               : " + memberName);
        System.out.println("Storage type          : " + memberType);
        System.out.println("Space status          : " + spaceStatus);

        if (!memberType.equals("volume")) {
            return;
        }
        if (dedupeError != null) {
            System.out.println(dedupeError);
            return;
        }
        System.out.println("Dedupe status                      : "
                + dedupeStatus);
        System.out.println("Current Dedupe progress            : "
                + currDedupeProgress);

        if (storageType.equals("nas")) {
            if (snapUsed > snapReserve) {
                snapOverflow = snapUsed - snapReserve;
                dataUsed -= snapOverflow;
                snapUsed = snapReserve;
                snapAvail = 0;
            }
            dataUsedWithoutDedupe = dataUsed + dedupeSpaceSavings;
            dataUsedWithDedupe = dataUsed;
            System.out.println("\nDedupe space savings :");
            System.out.println("Dedupe space saved                 : "
                    + getUnits(dedupeSpaceSavings));
            System.out.println("Dedupe space savings percentage    : "
                    + dedupeSpaceSavingsPercentage + " (%)");
            System.out.println("Used space without dedupe          : "
                    + getUnits(dataUsedWithoutDedupe));
            System.out.println("Used space with dedupe             : "
                    + getUnits(dataUsedWithDedupe));
        } else {
            long usedLunSpace = 0;
            long availLunSpace = holeReserve;
            long lundataUsedWithoutDedupe = 0;
            long lundataUsedWithDedupe = 0;
            if (overwriteUsed > 0) {
                dataUsed -= (overwriteUsed + overwriteAvail);
            } else if (overwriteUsed == 0) {
                dataUsed -= overwriteReserve;
            }
            usedLunSpace = dataUsed - availLunSpace;
            if (snapUsed > snapReserve) {
                snapOverflow = snapUsed - snapReserve;
                usedLunSpace -= snapOverflow;
            }
            lundataUsedWithoutDedupe = usedLunSpace + dedupeSpaceSavings;
            lundataUsedWithDedupe = usedLunSpace;
            System.out.println("\nDedupe space savings :");
            System.out.println("Dedupe space saved                 : "
                    + getUnits(dedupeSpaceSavings));
            System.out.println("Dedupe space savings percentage    : "
                    + dedupeSpaceSavingsPercentage + " (%)");
            System.out.println("LUN used space without dedupe      : "
                    + getUnits(lundataUsedWithoutDedupe));
            System.out.println("LUN used space with dedupe         : "
                    + getUnits(lundataUsedWithDedupe));
        }
    }
}
