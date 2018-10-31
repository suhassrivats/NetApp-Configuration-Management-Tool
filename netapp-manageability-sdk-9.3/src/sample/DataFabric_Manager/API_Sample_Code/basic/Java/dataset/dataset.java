/*
 * $Id:$
 *
 * dataset.java
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * This program will help managing the datasets
 * you can create,delete and list datasets
 * add,list,delete and provision members
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

public class dataset {
    private static NaServer server;
    private static String[] Arg;

    public static void USAGE() {
        System.out
                .println(""
                        + "Usage:\n"
                        + "dataset <dfmserver> <user> <password> list [ <dataset name> ]\n"
                        + "\n"
                        + "dataset <dfmserver> <user> <password> delete <dataset name>\n"
                        + "\n"
                        + "dataset <dfmserver> <user> <password> create <dataset name>\n"
                        + "[ -v <prov-pol> ] [ -t <prot-pol> ] [ -r <rpool>]\n"
                        + "\n"
                        + "dataset <dfmserver> <user> <password> member-add <a-mem-dset> <member>\n"
                        + "\n"
                        + "dataset <dfmserver> <user> <password> member-list <mem-dset> [ <member> ]\n"
                        + "\n"
                        + "dataset <dfmserver> <user> <password> member-remove <mem-dset> <member>\n"
                        + "\n"
                        + "dataset <dfmserver> <user> <password> member-provision <p-mem-dset> <member>\n"
                        + "<size> [ <snap-size> | <data-size> ]\n"
                        + "\n"
                        + "<operation>    -- create or delete or list\n"
                        + "\n"
                        + "<dfmserver>    -- Name/IP Address of the DFM server\n"
                        + "<user>         -- DFM server User name\n"
                        + "<password>     -- DFM server User Password\n"
                        + "<dataset name> -- dataset name\n"
                        + "<prov-pol>     -- name or id of an exisitng nas provisioning policy\n"
                        + "<prot-pol>     -- name or id of an exisitng protection policy\n"
                        + "<rpool>        -- name or id of an exisitng resourcepool\n"
                        + "<a-mem-dset>   -- dataset to which the member will be added\n"
                        + "<mem-dset>     -- dataset containing the member\n"
                        + "<p-mem-dset>   -- dataset with resourcepool and provisioning policy attached\n"
                        + "<member>       -- name or Id of the member (volume/LUN or qtree)\n"
                        + "<size>         -- size of the member to be provisioned \n"
                        + "<snap-size>    -- maximum snapshot space required only for provisioning using"
                        + "\n"
                        + "                  \"san\" provision policy"
                        + "<data-size>    -- Maximum storage space space for the dataset member required"
                        + "\n"
                        + "                  only for provisioning using \"nas\" provision policy with "
                        + "nfs\n" + "\n" + "Note : All size in bytes");

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
                || (dfmop.equals("create") && arglen < 5)
                || (dfmop.equals("member-list") && arglen < 5)
                || (dfmop.equals("member-remove") && arglen != 6)
                || (dfmop.equals("member-add") && arglen != 6)
                || (dfmop.equals("member-provision") && arglen < 7))
            USAGE();

        // checking if the operation selected is valid
        if ((!dfmop.equals("list")) && (!dfmop.equals("create"))
                && (!dfmop.equals("delete")) && (!dfmop.equals("member-list"))
                && (!dfmop.equals("member-add"))
                && (!dfmop.equals("member-remove"))
                && (!dfmop.equals("member-provision")))
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
            else if (dfmop.equals("member-list"))
                memberList();
            else if (dfmop.equals("member-add"))
                memberAdd();
            else if (dfmop.equals("member-remove"))
                memberRemove();
            else if (dfmop.equals("member-provision"))
                memberProvision();
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
        String provPolName = null;
        String protPolName = null;
        String resourcePool = null;

        // Getting the dataset name
        String datasetName = Arg[4];

        // parsing optional parameters
        int i = 5;
        while (i < Arg.length) {
            if (Arg[i].equals("-v")) {
                provPolName = Arg[++i];
                ++i;
            } else if (Arg[i].equals("-t")) {
                protPolName = Arg[++i];
                ++i;
            } else if (Arg[i].equals("-r")) {
                resourcePool = Arg[++i];
                ++i;
            } else {
                USAGE();
            }
        }

        try {
            // creating the input for api execution
            // creating a dataset-create element and adding child elements
            NaElement input = new NaElement("dataset-create");
            input.addNewChild("dataset-name", datasetName);
            if (provPolName != null)
                input.addNewChild("provisioning-policy-name-or-id", provPolName);
            if (protPolName != null)
                input.addNewChild("protection-policy-name-or-id", protPolName);

            // invoking the api && printing the xml ouput
            NaElement output = server.invokeElem(input);

            System.out.println("\nDataset creation "
                    + result(output.getAttr("status")));

            if (resourcePool != null)
                addResourcePool(resourcePool);
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void addResourcePool(String rPool) {
        NaElement input;
        NaElement output;

        try {
            // Setting the edit lock for adding resource pool
            input = new NaElement("dataset-edit-begin");
            input.addNewChild("dataset-name-or-id", Arg[4]);
            output = server.invokeElem(input);

            // extracting the edit lock id
            String lockId = output.getChildContent("edit-lock-id");

            try {
                // Invoking add resource pool element
                input = new NaElement("dataset-add-resourcepool");
                input.addNewChild("edit-lock-id", lockId);
                input.addNewChild("resourcepool-name-or-id", rPool);
                output = server.invokeElem(input);

                input = new NaElement("dataset-edit-commit");
                input.addNewChild("edit-lock-id", lockId);
                output = server.invokeElem(input);
            } catch (Exception e) {
                System.err.println(e.toString());
                input = new NaElement("dataset-edit-rollback");
                input.addNewChild("edit-lock-id", lockId);
                server.invokeElem(input);
                System.exit(1);
            }

            System.out.println("\nResourcepool add "
                    + result(output.getAttr("status")));
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void list() {
        String datasetName = null;

        try {
            // creating a dataset list start element
            NaElement input = new NaElement("dataset-list-info-iter-start");
            if (Arg.length > 4) {
                datasetName = Arg[4];
                input.addNewChild("object-name-or-id", datasetName);
            }

            // invoke the api && capturing the records && tag values
            NaElement output = server.invokeElem(input);

            // Extracting the record && tag values && printing them
            String records = output.getChildContent("records");

            if (records.equals("0"))
                System.out.println("\nNo templates to display");

            String tag = output.getChildContent("tag");

            // Extracting records one at a time
            input = new NaElement("dataset-list-info-iter-next");
            input.addNewChild("maximum", records);
            input.addNewChild("tag", tag);
            NaElement record = server.invokeElem(input);

            // Navigating to the datasets child element
            NaElement stat = record.getChildByName("datasets");

            // Navigating to the dataset-info child element
            List infoList = null;

            if (stat != null)
                infoList = stat.getChildren();
            if (infoList == null)
                return;

            Iterator infoIter = infoList.iterator();

            // Iterating through each record
            while (infoIter.hasNext()) {
                String value;
                NaElement info = (NaElement) infoIter.next();

                System.out.println("-----------------------------------------");
                // extracting the dataset name and printing it
                value = info.getChildContent("dataset-name");
                System.out.println("Dataset Name : " + value);

                value = info.getChildContent("dataset-id");
                System.out.println("Dataset Id : " + value);

                value = info.getChildContent("dataset-description");
                System.out.println("Dataset Description : " + value);

                System.out.println("-----------------------------------------");

                // printing detials if only one dataset is selected for listing
                if (datasetName != null) {

                    value = info.getChildContent("dataset-contact");
                    System.out.println("\nDataset Contact          : " + value);

                    value = info.getChildContent("provisioning-policy-id");
                    System.out.print("Provisioning Policy Id   : ");
                    if (value != null)
                        System.out.print(value);

                    value = info.getChildContent("provisioning-policy-name");
                    System.out.print("\nProvisioning Policy Name : ");
                    if (value != null)
                        System.out.print(value);

                    value = info.getChildContent("protection-policy-id");
                    System.out.print("\nProtection Policy Id     : ");
                    if (value != null)
                        System.out.print(value);

                    value = info.getChildContent("protection-policy-name");
                    System.out.print("\nProtection Policy Name   : ");
                    if (value != null)
                        System.out.print(value);

                    value = info.getChildContent("resourcepool-name");
                    System.out.print("\nResource Pool Name       : ");
                    if (value != null)
                        System.out.print(value);

                    NaElement status = info.getChildByName("dataset-status");

                    value = status.getChildContent("resource-status");
                    System.out.println("\nResource Status          : " + value);

                    value = status.getChildContent("conformance-status");
                    System.out.println("Conformance Status       : " + value);

                    value = status.getChildContent("performance-status");
                    System.out.println("Performance Status       : " + value);

                    value = status.getChildContent("protection-status");
                    System.out.print("Protection Status        : ");
                    if (value != null)
                        System.out.print(value);

                    value = status.getChildContent("space-status");
                    System.out.println("\nSpace Status             : " + value);
                }
            }

            // invoking the iter-end zapi
            input = new NaElement("dataset-list-info-iter-end");
            input.addNewChild("tag", tag);
            server.invokeElem(input);

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void delete() {
        String datasetName = Arg[4];

        try {
            // invoking the api && printing the xml ouput
            NaElement input = new NaElement("dataset-destroy");
            input.addNewChild("dataset-name-or-id", datasetName);
            NaElement output = server.invokeElem(input);

            System.out.println("\nDataset deletion "
                    + result(output.getAttr("status")));

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void memberAdd() {
        NaElement input;
        NaElement output;

        // Getting the dataset name and member name
        String datasetName = Arg[4];
        String memberName = Arg[5];

        try {
            // Setting the edit lock for adding member
            input = new NaElement("dataset-edit-begin");
            input.addNewChild("dataset-name-or-id", Arg[4]);
            output = server.invokeElem(input);

            // extracting the edit lock id
            String lockId = output.getChildContent("edit-lock-id");

            try {
                // creating the input for api execution
                // creating a dataset-add-member elem and adding child elements
                input = new NaElement("dataset-add-member");
                input.addNewChild("edit-lock-id", lockId);
                NaElement mem = new NaElement("dataset-member-parameters");
                NaElement param = new NaElement("dataset-member-parameter");
                param.addNewChild("object-name-or-id", memberName);
                mem.addChildElem(param);
                input.addChildElem(mem);
                // invoking the api && printing the xml ouput
                output = server.invokeElem(input);

                input = new NaElement("dataset-edit-commit");
                input.addNewChild("edit-lock-id", lockId);
                output = server.invokeElem(input);
            } catch (Exception e) {
                System.err.println(e.toString());
                input = new NaElement("dataset-edit-rollback");
                input.addNewChild("edit-lock-id", lockId);
                server.invokeElem(input);
                System.exit(1);
            }

            System.out.println("\nMember addition "
                    + result(output.getAttr("status")));
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void memberList() {
        String memberName = null;
        String datasetName = Arg[4];

        try {
            // creating a dataset member list start element
            NaElement input = new NaElement(
                    "dataset-member-list-info-iter-start");
            input.addNewChild("dataset-name-or-id", datasetName);
            if (Arg.length > 5) {
                memberName = Arg[5];
                input.addNewChild("member-name-or-id", memberName);
            }
            input.addNewChild("include-indirect", "true");

            // invoke the api && capturing the records && tag values
            NaElement output = server.invokeElem(input);

            // Extracting the record && tag values && printing them
            String records = output.getChildContent("records");

            if (records.equals("0"))
                System.out.println("\nNo members to display");

            String tag = output.getChildContent("tag");

            // Extracting records one at a time
            input = new NaElement("dataset-member-list-info-iter-next");
            input.addNewChild("maximum", records);
            input.addNewChild("tag", tag);
            NaElement record = server.invokeElem(input);

            // Navigating to the dataset-members child element
            NaElement stat = record.getChildByName("dataset-members");

            // Navigating to the dataset-info child element
            List infoList = null;

            if (stat != null)
                infoList = stat.getChildren();
            if (infoList == null)
                return;

            Iterator infoIter = infoList.iterator();

            // Iterating through each record
            while (infoIter.hasNext()) {
                NaElement info = (NaElement) infoIter.next();

                // extracting the member name and printing it
                String name = info.getChildContent("member-name");
                String id = info.getChildContent("member-id");
                if (!name.endsWith("-")) {
                    System.out
                            .println("-----------------------------------------");
                    System.out.println("Member Name : " + name);
                    System.out.println("Member Id : " + id);
                    System.out
                            .println("-----------------------------------------");

                    // printing detials if only one member is selected for
                    // listing
                    if (memberName != null) {
                        String value;

                        value = info.getChildContent("member-type");
                        System.out.println("\nMember Type            : "
                                + value);

                        value = info.getChildContent("member-status");
                        System.out.println("Member Status          : " + value);

                        value = info.getChildContent("member-perf-status");
                        System.out.println("Member Perf Status     : " + value);

                        value = info.getChildContent("storageset-id");
                        System.out.println("Storageset Id          : " + value);

                        value = info.getChildContent("storageset-name");
                        System.out.println("Storageset Name        : " + value);

                        value = info.getChildContent("dp-node-name");
                        System.out.println("Node Name              : " + value);
                    }
                }
            }

            // invoking the iter-end zapi
            input = new NaElement("dataset-member-list-info-iter-end");
            input.addNewChild("tag", tag);
            server.invokeElem(input);

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void memberRemove() {
        String datasetName = Arg[4];
        String memberName = Arg[5];

        NaElement input;
        NaElement output;

        try {
            // Setting the edit lock for removing member
            input = new NaElement("dataset-edit-begin");
            input.addNewChild("dataset-name-or-id", Arg[4]);
            output = server.invokeElem(input);

            // extracting the edit lock id
            String lockId = output.getChildContent("edit-lock-id");

            try {

                // invoking the api && printing the xml ouput
                input = new NaElement("dataset-remove-member");
                input.addNewChild("edit-lock-id", lockId);
                NaElement mem = new NaElement("dataset-member-parameters");
                NaElement param = new NaElement("dataset-member-parameter");
                param.addNewChild("object-name-or-id", memberName);
                mem.addChildElem(param);
                input.addChildElem(mem);
                // invoking the api && printing the xml ouput
                output = server.invokeElem(input);

                input = new NaElement("dataset-edit-commit");
                input.addNewChild("edit-lock-id", lockId);
                output = server.invokeElem(input);
            } catch (Exception e) {
                System.err.println(e.toString());
                input = new NaElement("dataset-edit-rollback");
                input.addNewChild("edit-lock-id", lockId);
                server.invokeElem(input);
                System.exit(1);
            }

            System.out.println("\nMember remove "
                    + result(output.getAttr("status")));
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void memberProvision() {
        String datasetName = Arg[4];
        String memberName = Arg[5];
        String size = Arg[6];
        String maxSize = null;

        if (Arg.length > 7)
            maxSize = Arg[7];

        NaElement input;
        NaElement output;
        NaElement finalOutput;
        String jobId;

        try {
            // Setting the edit lock for provisioning member
            input = new NaElement("dataset-edit-begin");
            input.addNewChild("dataset-name-or-id", Arg[4]);
            output = server.invokeElem(input);

            // extracting the edit lock id
            String lockId = output.getChildContent("edit-lock-id");

            try {

                // invoking the api && printing the xml ouput
                input = new NaElement("dataset-provision-member");
                input.addNewChild("edit-lock-id", lockId);
                NaElement provMember = new NaElement(
                        "provision-member-request-info");
                provMember.addNewChild("name", memberName);
                provMember.addNewChild("size", size);
                if (maxSize != null) {
                    // for san
                    provMember.addNewChild("maximum-snapshot-space", maxSize);
                    // for nas with nfs
                    provMember.addNewChild("maximum-data-size", maxSize);
                }
                input.addChildElem(provMember);

                // invoking the api && printing the xml ouput
                output = server.invokeElem(input);

                input = new NaElement("dataset-edit-commit");
                input.addNewChild("edit-lock-id", lockId);
                finalOutput = server.invokeElem(input);
                jobId = (finalOutput.getChildByName("job-ids")).getChildByName(
                        "job-info").getChildContent("job-id");
                // tracking the job
                trackJob(jobId);
            } catch (Exception e) {
                System.err.println(e.toString());
                input = new NaElement("dataset-edit-rollback");
                input.addNewChild("edit-lock-id", lockId);
                server.invokeElem(input);
                System.exit(1);
            }

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void trackJob(String jobId) {

        String jobStatus = "running";
        NaElement xi;
        NaElement xo;

        try {
            System.out.println("Job ID\t\t: " + jobId);
            System.out.print("Job Status\t: " + jobStatus);
            // Continuously poll to see if the job completed
            while (jobStatus.equals("queued") || jobStatus.equals("running")
                    || jobStatus.equals("aborting")) {
                xi = new NaElement("dp-job-list-iter-start");
                xi.addNewChild("job-id", jobId);
                xo = server.invokeElem(xi);

                xi = new NaElement("dp-job-list-iter-next");
                xi.addNewChild("maximum", xo.getChildContent("records"));
                xi.addNewChild("tag", xo.getChildContent("tag"));
                xo = server.invokeElem(xi);

                NaElement dpJobs = xo.getChildByName("jobs");
                NaElement dpJobInfo = dpJobs.getChildByName("dp-job-info");
                jobStatus = dpJobInfo.getChildContent("job-state");
                Thread.sleep(3000);
                System.out.print(".");
                if (jobStatus.equals("completed")
                        || jobStatus.equals("aborted")) {
                    System.out.println("\nOverall Status\t: "
                            + dpJobInfo.getChildContent("job-overall-status"));
                }
            }

            // Display the job result - success/failure and
            // provisioned member details
            xi = new NaElement("dp-job-progress-event-list-iter-start");
            xi.addNewChild("job-id", jobId);
            xo = server.invokeElem(xi);

            xi = new NaElement("dp-job-progress-event-list-iter-next");
            xi.addNewChild("tag", xo.getChildContent("tag"));
            xi.addNewChild("maximum", xo.getChildContent("records"));
            xo = server.invokeElem(xi);

            NaElement progEvnts = xo.getChildByName("progress-events");
            List progEvntsInfo = progEvnts.getChildren();
            System.out.print("\nProvision Details:\n");
            System.out.println("==========================================="
                    + "===============");
            for (Iterator i = progEvntsInfo.iterator(); i.hasNext();) {
                NaElement evnt = (NaElement) i.next();
                if (evnt.getChildContent("event-type") != null) {
                    System.out.print(evnt.getChildContent("event-type"));
                }
                System.out.println("\t: "
                        + evnt.getChildContent("event-message") + "\n");
            }
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}