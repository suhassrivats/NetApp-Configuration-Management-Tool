/*
 *
 * nas_provisioning_policy.java
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * This program will help manage nas provisioning policies
 * you can create, delete and list nas provisioning policies
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

public class nas_provisioning_policy {
    private static NaServer server;
    private static String[] Arg;

    public static void USAGE() {
        System.out
                .println(""
                        + "Usage:\n"
                        + "nas_prov_policy <dfmserver> <user> <password> list [ <pol-name> ]\n"
                        + "\n"
                        + "nas_prov_policy <dfmserver> <user> <password> delete <pol-name>\n"
                        + "\n"
                        + "nas_prov_policy <dfmserver> <user> <password> create <pol-name> [ -d ]\n"
                        + "[ -c ] [ -s ] [ -r ] [ -S | -t ] [ -g <gquota> ] [ -u <uquota> ]\n"
                        + "\n"
                        + "<operation>     -- create or delete or list\n"
                        + "\n"
                        + "<dfmserver> -- Name/IP Address of the DFM server\n"
                        + "<user>      -- DFM server User name\n"
                        + "<password>  -- DFM server UserPassword\n"
                        + "<pol-name>  -- provisioning policy name\n"
                        + "[ -d ]      -- To enable dedupe \n"
                        + "[ -c ]      -- To enable resiliency against controller failure\n"
                        + "[ -s ]      -- To enable resiliency against sub-system failure\n"
                        + "[ -r ]      -- To disable snapshot reserve\n"
                        + "[ -S ]      -- To enable space on demand\n"
                        + "[ -t ]      -- To enable thin provisioning\n"
                        + "<gquota>    -- Default group quota setting in kb.  Range: [1..2^44-1]\n"
                        + "<uquota>    -- Default user quota setting in kb. Range: [1..2^44-1]\n"
                        + "\n"
                        + "Note : All options except provisioning policy name are optional and are\n"
                        + "required only by create operation");
        System.exit(1);
    }

    public static void main(String[] args) {

        Arg = args;
        int arglen = Arg.length;
        // Checking for valid number of parameters
        if (arglen < 4)
            USAGE();

        String dfmserver = Arg[0];
        String dfmuser = Arg[1];
        String dfmpw = Arg[2];
        String dfmop = Arg[3];

        // checking for valid number of parameters for the respective operations
        if ((dfmop.equals("list") && arglen < 4)
                || (dfmop.equals("delete") && arglen != 5)
                || (dfmop.equals("create") && arglen < 5))
            USAGE();

        // checking if the operation selected is valid
        if ((!dfmop.equals("list")) && (!dfmop.equals("create"))
                && (!dfmop.equals("delete")))
            USAGE();

        try {
            // Initialize connection to server, and
            // request version 1.0 of the API set
            //
            // Creating a server object and setting appropriate attributes
            server = new NaServer(dfmserver, 1, 0);
            server.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            server.setServerType(NaServer.SERVER_TYPE_DFM);

            server.setAdminUser(dfmuser, dfmpw);

            // Calling the functions based on the operation selected
            if (dfmop.equals("create"))
                create();
            else if (dfmop.equals("list"))
                list();
            else if (dfmop.equals("delete"))
                delete();
            else
                USAGE();
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static String result(String result) {
        // Checking for the string "passed" in the output
        String r = (result.equals("passed")) ? "Successful" : "UnSuccessful";
        return r;
    }

    public static void create() {
        String groupQuota = null;
        String userQuota = null;
        boolean dedupeEnable = false;
        boolean controllerFailure = false;
        boolean subsystemFailure = false;
        boolean snapshotReserve = false;
        boolean spaceOnDemand = false;
        boolean thinProvision = false;

        // Getting the policy name
        String policyName = Arg[4];

        // parsing optional parameters
        int i = 5;
        while (i < Arg.length) {
            if (Arg[i].equals("-g")) {
                groupQuota = Arg[++i];
                ++i;
            } else if (Arg[i].equals("-u")) {
                userQuota = Arg[++i];
                ++i;
            } else if (Arg[i].equals("-d")) {
                dedupeEnable = true;
                ++i;
            } else if (Arg[i].equals("-c")) {
                controllerFailure = true;
                ++i;
            } else if (Arg[i].equals("-s")) {
                subsystemFailure = true;
                ++i;
            } else if (Arg[i].equals("-r")) {
                snapshotReserve = true;
                ++i;
            } else if (Arg[i].equals("-S")) {
                spaceOnDemand = true;
                ++i;
            } else if (Arg[i].equals("-t")) {
                thinProvision = true;
                ++i;
            } else {
                USAGE();
            }
        }

        try {
            // creating the input for api execution
            // creating a create element and adding child elements
            NaElement input = new NaElement("provisioning-policy-create");
            NaElement policy = new NaElement("provisioning-policy-info");
            policy.addNewChild("provisioning-policy-name", policyName);
            policy.addNewChild("provisioning-policy-type", "nas");
            if (dedupeEnable)
                policy.addNewChild("dedupe-enabled", "$dedupe_enable");

            // creating the storage reliability child and adding parameters if
            // input
            if (controllerFailure || subsystemFailure) {
                NaElement storageRelilability = new NaElement(
                        "storage-reliability");
                if (controllerFailure)
                    storageRelilability.addNewChild("controller-failure",
                            "true");
                if (subsystemFailure)
                    storageRelilability.addNewChild("sub-system-failure",
                            "true");

                // appending storage-reliability child to parent and then to
                // policy info
                policy.addChildElem(storageRelilability);
            }

            // creating the nas container settings child and adding parameters
            // if input
            if (groupQuota != null || userQuota != null || snapshotReserve
                    || spaceOnDemand || thinProvision) {
                NaElement nasContainerSettings = new NaElement(
                        "nas-container-settings");
                if (groupQuota != null)
                    nasContainerSettings.addNewChild("default-group-quota",
                            groupQuota);
                if (userQuota != null)
                    nasContainerSettings.addNewChild("default-user-quota",
                            userQuota);
                if (snapshotReserve)
                    nasContainerSettings.addNewChild("snapshot-reserve",
                            "false");
                if (spaceOnDemand)
                    nasContainerSettings.addNewChild("space-on-demand", "true");
                if (thinProvision)
                    nasContainerSettings.addNewChild("thin-provision", "true");

                // appending nas-containter-settings child to policy info
                policy.addChildElem(nasContainerSettings);
            }

            // Adding policy to parent element
            input.addChildElem(policy);

            // invoking the api && printing the xml ouput
            NaElement output = server.invokeElem(input);

            System.out.println("\nPolicy creation "
                    + result(output.getAttr("status")));
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void list() {
        String policyName = null;

        try {
            // creating a start element
            NaElement input = new NaElement(
                    "provisioning-policy-list-iter-start");
            input.addNewChild("provisioning-policy-type", "nas");
            if (Arg.length > 4) {
                policyName = Arg[4];
                input.addNewChild("provisioning-policy-name-or-id", policyName);
            }

            // invoke the api && capturing the records && tag values
            NaElement output = server.invokeElem(input);

            // Extracting the record && tag values && printing them
            String records = output.getChildContent("records");

            if (records.equals("0"))
                System.out.println("\nNo policies to display");

            String tag = output.getChildContent("tag");

            // Extracting records one at a time
            input = new NaElement("provisioning-policy-list-iter-next");
            input.addNewChild("maximum", records);
            input.addNewChild("tag", tag);
            NaElement record = server.invokeElem(input);

            // Navigating to the provisioning-policys child element
            NaElement stat = record.getChildByName("provisioning-policies");

            List infoList = null;

            if (stat != null)
                infoList = stat.getChildren();
            if (infoList == null)
                return;

            // creating a iterator element
            Iterator infoIter = infoList.iterator();

            // Iterating through each record
            while (infoIter.hasNext()) {
                String value;
                NaElement info = (NaElement) infoIter.next();
                NaElement nasContainerSettings = info
                        .getChildByName("nas-container-settings");

                // Checking if the container is nas before printing the details
                if (nasContainerSettings != null) {
                    System.out
                            .println("----------------------------------------------------");
                    // extracting the provisioning policy name and printing it
                    value = info.getChildContent("provisioning-policy-name");
                    System.out.println("Policy Name : " + value);

                    value = info.getChildContent("provisioning-policy-id");
                    System.out.println("Policy Id : " + value);

                    value = info
                            .getChildContent("provisioning-policy-description");
                    System.out.println("Policy Description : " + value);
                    System.out
                            .println("----------------------------------------------------");

                    // printing details if only one policy is selected
                    if (policyName != null) {
                        value = info
                                .getChildContent("provisioning-policy-type");
                        System.out.println("\nPolicy Type        : " + value);

                        value = info.getChildContent("dedupe-enabled");
                        System.out.println("Dedupe Enabled     : " + value);

                        NaElement storageRelilability = info
                                .getChildByName("storage-reliability");

                        value = storageRelilability
                                .getChildContent("disk-failure");
                        System.out.println("Disk Failure       : " + value);

                        value = storageRelilability
                                .getChildContent("sub-system-failure");
                        System.out.println("Subsystem Failure  : " + value);

                        value = storageRelilability
                                .getChildContent("controller-failure");
                        System.out.println("Controller Failure : " + value);

                        value = nasContainerSettings
                                .getChildContent("default-user-quota");
                        System.out.print("Default User Quota : ");
                        if (value != null)
                            System.out.print(value + " kb");

                        value = nasContainerSettings
                                .getChildContent("default-group-quota");
                        System.out.print("\nDefault Group Quota: ");
                        if (value != null)
                            System.out.print(value + " kb");

                        value = nasContainerSettings
                                .getChildContent("snapshot-reserve");
                        System.out.print("\nSnapshot Reserve   : ");
                        if (value != null)
                            System.out.print(value);

                        value = nasContainerSettings
                                .getChildContent("space-on-demand");
                        System.out.print("\nSpace On Demand    : ");
                        if (value != null)
                            System.out.print(value);

                        value = nasContainerSettings
                                .getChildContent("thin-provision");
                        System.out.print("\nThin Provision     : ");
                        if (value != null)
                            System.out.println(value);

                    }
                }
                if (nasContainerSettings == null && policyName != null) {
                    System.out.println("\nsan type of provisioning policy"
                            + " is not supported for listing");
                }
            }

            // invoking the iter-end zapi
            input = new NaElement("provisioning-policy-list-iter-end");
            input.addNewChild("tag", tag);
            server.invokeElem(input);

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void delete() {
        String policyName = Arg[4];

        try {
            // invoking the api && printing the xml ouput
            NaElement input = new NaElement("provisioning-policy-destroy");
            input.addNewChild("provisioning-policy-name-or-id", policyName);
            NaElement output = server.invokeElem(input);

            System.out.println("\nPolicy deletion "
                    + result(output.getAttr("status")));

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}
