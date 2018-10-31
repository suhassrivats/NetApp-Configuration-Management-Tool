/*
 * $Id:$
 *
 * dataset.java
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * Sample code to demonstrate how to:
 *        - list/create/delete a dataset
 *        - list/add/delete a member in a dataset
 *        - attach resourcepools, provisioning policy,
 *          protection policy and multistore to a dataset
 *        - provision storage from a dataset
 *
 *
 * This Sample code is supported from DataFabric Manager 3.8
 * onwards.
 * However few of the functionalities of the sample code may
 * work on older versions of DataFabric Manager.
 */

import java.util.*;
import netapp.manage.*;

public class dataset {
    private static void usage() {
        System.out.println("Usage: \n dataset <dfmserver> <user> "
                + "<passwd> list [<name>]");
        System.out.println(" dataset <dfmserver> <user> <passwd> "
                + "create <name> [<vfiler> <prov_pol> <prot-pol>]");
        System.out.println(" dataset <dfmserver> <user> <passwd> "
                + "destroy <name>");
        System.out
                .println(" dataset <dfmserver> <user> <passwd> "
                        + "update <name> <prov_pol> <prot_pol> <pri_rp> <sec_rp> [<ter_rp>]");
        System.out.println(" dataset <dfmserver> <user> <passwd> "
                + "member list <name>");
        System.out.println(" dataset <dfmserver> <user> <passwd> "
                + "member add <name> <mem_add>");
        System.out.println(" dataset <dfmserver> <user> <passwd> "
                + "member del <name> <mem_del>");
        System.out.println(" dataset <dfmserver> <user> <passwd> "
                + "provision <name> <mem_prov_name> <size> [<snap-size>]\n");
        System.out.println(" <dfmserver>     -- Name/IP Address of the "
                + "DFM server");
        System.out.println(" <user>          -- DFM server User name");
        System.out.println(" <passwd>        -- DFM server User Password");
        System.out.println(" <name>          -- Name of the dataset");
        System.out.println(" <vfiler>        -- Attach newly provisioned "
                + "member to this vfiler");
        System.out.println(" <prov_pol>      -- name or id of an exisitng "
                + "nas provisioning policy");
        System.out.println(" <prot-pol>      -- name or id of an exisitng "
                + "protection policy");
        System.out.println(" <mem_prov_name> -- member name to be provisioned");
        System.out.println(" <size>          -- size of the new member to be "
                + "provisioned in bytes");
        System.out.println(" <snap-size>     -- maximum size in bytes "
                + "allocated to snapshots in SAN envs");
        System.out.println(" <mem_add>       -- member to be added");
        System.out.println(" <mem_del>       -- member to be removed");
        System.out.println(" <pri_rp>        -- Primary resource pool");
        System.out.println(" <sec_rp>        -- Secondary resource pool");
        System.out.println(" <ter_rp>        -- Tertiary resource pool\n");
        System.out
                .println("       If the protection policy is 'Mirror', "
                        + "specify only pri_rp and sec_rp.\n"
                        + "If protection policy is 'Back up, then Mirror', specify pri_rp, "
                        + "sec_rp and ter_rp");
        System.exit(1);
    }

    public static void main(String[] args) {
        NaElement xi;
        NaElement xo;
        NaServer s = null;
        String editLock = null;

        if (args.length < 4) {
            usage();
        }
        try {
            // Initialize connection to server, and
            // request version 1.0 of the API set
            //
            s = new NaServer(args[0], 1, 0);
            s.setServerType(NaServer.SERVER_TYPE_DFM);
            s.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            s.setAdminUser(args[1], args[2]);

            // List all datasets
            if (args[3].equals("list")) {
                String dsName = null;

                if (args.length > 5) {
                    usage();
                }

                if (args.length == 5)
                    dsName = args[4];

                // Start iteration sequence
                xi = new NaElement("dataset-list-info-iter-start");
                xi.addNewChild("object-name-or-id", dsName);
                xo = s.invokeElem(xi);

                // save tag to use wiht *-iter-end
                String xotag = xo.getChildContent("tag");

                xi = new NaElement("dataset-list-info-iter-next");
                xi.addNewChild("maximum", xo.getChildContent("records"));
                xi.addNewChild("tag", xo.getChildContent("tag"));
                xo = s.invokeElem(xi);

                System.out.println("\nDATASETS:");
                System.out.println("======================================="
                        + "============================");

                if (xo.getChildByName("datasets") == null) {
                    System.out.println("Error: No Datasets!");
                    System.exit(1);
                }

                // Display all necessary details
                if (xo.getChildByName("datasets").hasChildren()) {
                    List rpInfos = xo.getChildByName("datasets").getChildren();
                    for (Iterator i = rpInfos.iterator(); i.hasNext();) {
                        NaElement rpi = (NaElement) i.next();
                        System.out.println("Dataset Name\t: "
                                + rpi.getChildContent("dataset-name"));

                        NaElement dsstatus = rpi
                                .getChildByName("dataset-status");

                        System.out.println("Overall Status\t: "
                                + dsstatus.getChildContent("resource-status"));
                        System.out.println("# of Members\t: "
                                + rpi.getChildContent("member-count"));
                        String value = "-Not Configured-";
                        if (rpi.getChildContent("vfiler-name") != null)
                            value = rpi.getChildContent("vfiler-name");
                        System.out.println("VFiler unit\t: " + value);
                        value = "-Not Configured-";
                        if (rpi.getChildContent("protection-policy-name") != null)
                            value = rpi
                                    .getChildContent("protection-policy-name");
                        System.out.println("Prot. Policy\t: " + value);
                        value = "-Not Configured-";
                        if (rpi.getChildContent("provisioning-policy-name") != null)
                            value = rpi
                                    .getChildContent("provisioning-policy-name");
                        System.out.println("Prov. Policy\t: " + value);
                        System.out.print("Res. pools(Pri)\t: ");

                        if (rpi.getChildByName("resourcepools") == null)
                            System.out.println("No attached Resourcepool!");
                        else {
                            if (rpi.getChildByName("resourcepools")
                                    .hasChildren()) {
                                List dsrpi = rpi
                                        .getChildByName("resourcepools")
                                        .getChildren();
                                for (Iterator j = rpInfos.iterator(); j
                                        .hasNext();) {
                                    NaElement rp = (NaElement) j.next();
                                    if (rp.getChildContent("resourcepool-name") != null)
                                        System.out
                                                .print(rp
                                                        .getChildContent("resourcepool-name")
                                                        + "; ");
                                }
                            }
                        }
                        System.out.println("\n==============================="
                                + "====================================");
                    }
                }
                xi = new NaElement("dataset-list-info-iter-end");
                xi.addNewChild("tag", xotag);
                xo = s.invokeElem(xi);
            }
            // Create a new dataset
            else if (args[3].equals("create")) {
                if (args.length < 5) {
                    usage();
                } else {
                    String dsName = args[4];
                    xi = new NaElement("dataset-create");
                    xi.addNewChild("dataset-name", dsName);

                    // Configure vFiler, Protection or Provisioning
                    // policy based on input
                    if (args.length >= 6) {
                        String vfiler = args[5];
                        xi.addNewChild("vfiler-name-or-id", vfiler);
                    }
                    if (args.length >= 7) {
                        String prov = args[6];
                        xi.addNewChild("provisioning-policy-name-or-id", prov);
                    }
                    if (args.length == 8) {
                        String prot = args[7];
                        xi.addNewChild("protection-policy-name-or-id", prot);
                    }

                    xo = s.invokeElem(xi);
                    System.out.println("Dataset " + dsName
                            + " created with ID "
                            + xo.getChildContent("dataset-id"));
                }
            }
            // Destroy a dataset
            else if (args[3].equals("destroy")) {
                if (args.length < 5) {
                    usage();
                }
                String dsName = null;

                if (args.length != 5) {
                    usage();
                } else
                    dsName = args[4];

                xi = new NaElement("dataset-destroy");
                xi.addNewChild("dataset-name-or-id", dsName);
                xo = s.invokeElem(xi);
                System.out.println("Dataset " + dsName + " destroyed!");
            }
            // Update a newly created dataset with provisioning and protection
            // policy along with resourcepools needed by the protection policy.
            // This step is critical without which no provisioning or protection
            // of dataset members will take place
            else if (args[3].equals("update")) {
                if (args.length < 9) {
                    usage();
                }
                String dsName = args[4];
                String provp = args[5];
                String protp = args[6];
                int resPoolIndex = 7;

                // Obtain lock to edit dataset
                xi = new NaElement("dataset-edit-begin");
                xi.addNewChild("dataset-name-or-id", dsName);

                xo = s.invokeElem(xi);
                editLock = xo.getChildContent("edit-lock-id");

                // Add protection policy
                System.out.println("Adding protection policy...\n");
                xi = new NaElement("dataset-modify");
                xi.addNewChild("edit-lock-id", editLock);
                xi.addNewChild("protection-policy-name-or-id", protp);
                xo = s.invokeElem(xi);

                // Add provisioning policy
                System.out.println("Adding provisioning policy...\n");
                xi = new NaElement("dataset-modify-node");
                xi.addNewChild("edit-lock-id", editLock);
                xi.addNewChild("provisioning-policy-name-or-id", provp);
                xo = s.invokeElem(xi);

                // Gather dp node names for the protection policy
                System.out.println("Gathering Node names from "
                        + "protection policy...\n");
                xi = new NaElement("dp-policy-list-iter-start");
                xi.addNewChild("dp-policy-name-or-id", protp);
                xo = s.invokeElem(xi);

                xi = new NaElement("dp-policy-list-iter-next");
                xi.addNewChild("maximum", xo.getChildContent("records"));
                xi.addNewChild("tag", xo.getChildContent("tag"));
                xo = s.invokeElem(xi);

                NaElement dps = xo.getChildByName("dp-policy-infos");
                if (dps == null) {
                    System.out.println("Error: No Provisioning Policies!\n");
                    System.exit(1);
                }

                NaElement dpInfo = dps.getChildByName("dp-policy-info");
                NaElement dpContent = dpInfo
                        .getChildByName("dp-policy-content");

                // Based on the protection policy attach a resourcepool to
                // above gathered dp node names.
                if (dpContent.getChildByName("dp-policy-nodes").hasChildren()) {
                    List dpNodeInfo = dpContent.getChildByName(
                            "dp-policy-nodes").getChildren();
                    String rpool;
                    if (dpNodeInfo.size() != (args.length - 7)) {
                        System.out.println("Missing resource pool! No. of "
                                + "resource pools required are "
                                + dpNodeInfo.size());
                        System.err.println("INFO: Attempting to roll-back if"
                                + " any edit sessions were open...\n");
                        xi = new NaElement("dataset-edit-rollback");
                        xi.addNewChild("edit-lock-id", editLock);
                        xo = s.invokeElem(xi);
                        System.exit(1);

                    }

                    for (Iterator i = dpNodeInfo.iterator(); i.hasNext();) {
                        NaElement dpni = (NaElement) i.next();
                        rpool = args[resPoolIndex++];
                        String dpNode = dpni.getChildContent("name");
                        System.out.println("Adding Resourcepool " + rpool
                                + " to DP Node Name " + dpNode);
                        xi = new NaElement("dataset-add-resourcepool");
                        xi.addNewChild("edit-lock-id", editLock);
                        xi.addNewChild("dp-node-name", dpNode);
                        xi.addNewChild("resourcepool-name-or-id", rpool);
                        // System.out.println(xi.toPrettyString(""));
                        xo = s.invokeElem(xi);
                    }
                }
                System.out.println("Committing...");
                xi = new NaElement("dataset-edit-commit");
                xi.addNewChild("edit-lock-id", editLock);
                xo = s.invokeElem(xi);
            }
            // Dataset member operations
            else if (args[3].equals("member")) {
                if (args.length < 6) {
                    usage();
                }
                if (args[4].equals("list")) {
                    String dsName = args[5];

                    xi = new NaElement("dataset-member-list-info-iter-start");
                    xi.addNewChild("include-exports-info", "true");
                    xi.addNewChild("include-indirect", "true");
                    xi.addNewChild("include-space-info", "true");
                    xi.addNewChild("dataset-name-or-id", dsName);
                    xo = s.invokeElem(xi);

                    xi = new NaElement("dataset-member-list-info-iter-next");
                    xi.addNewChild("maximum", xo.getChildContent("records"));
                    xi.addNewChild("tag", xo.getChildContent("tag"));
                    xo = s.invokeElem(xi);

                    System.out.println("\nDATASET : " + dsName);
                    System.out.println("====================================="
                            + "==============================");
                    if (xo.getChildIntValue("records", 0) == 0) {
                        System.out.println("Error: No Members in "
                                + "this Dataset!");
                        System.exit(1);
                    }

                    NaElement dms = xo.getChildByName("dataset-members");

                    List dmis = dms.getChildren();
                    for (Iterator i = dmis.iterator(); i.hasNext();) {
                        NaElement dmi = (NaElement) i.next();
                        // Display member details. Display only member
                        // with non-qtree i.e members ending with "-"
                        if (!(dmi.getChildContent("member-name")).endsWith("-")) {
                            System.out.println("Member Name\t\t: "
                                    + dmi.getChildContent("member-name"));
                            System.out.println("Member Status\t\t: "
                                    + dmi.getChildContent("member-status"));
                            System.out.println("DP node name\t\t: "
                                    + dmi.getChildContent("dp-node-name"));
                            String mtype = dmi.getChildContent("member-type");
                            System.out.println("Member Type\t\t: " + mtype);
                            if (mtype.equals("qtree") == false) {
                                NaElement spinfo = dmi
                                        .getChildByName("space-info");
                                System.out
                                        .println("Space used\t\t: "
                                                + (spinfo.getChildLongValue(
                                                        "used-space", 0) / (1024 * 1024))
                                                + "MB");
                                System.out
                                        .println("Space(Avail/Total)\t: "
                                                + (spinfo.getChildLongValue(
                                                        "available-space", 0) / (1024 * 1024))
                                                + "MB / "
                                                + (spinfo.getChildLongValue(
                                                        "total-space", 0) / (1024 * 1024))
                                                + "MB");
                            }

                            System.out
                                    .println("============================"
                                            + "=======================================");
                        }
                    }
                } else if (args[4].equals("add")) {
                    if (args.length < 7) {
                        usage();
                    }
                    String dsName = args[5];

                    xi = new NaElement("dataset-edit-begin");
                    xi.addNewChild("dataset-name-or-id", dsName);
                    xo = s.invokeElem(xi);

                    editLock = xo.getChildContent("edit-lock-id");

                    xi = new NaElement("dataset-add-member");
                    xi.addNewChild("edit-lock-id", editLock);

                    NaElement dmps = new NaElement("dataset-member-parameters");
                    int count = 7;
                    while (count <= args.length) {
                        System.out.println("Adding member " + args[count - 1]
                                + "...");
                        NaElement dmp = new NaElement(
                                "dataset-member-parameter");
                        dmp.addNewChild("object-name-or-id", args[count - 1]);
                        dmps.addChildElem(dmp);
                        count++;
                    }

                    xi.addChildElem(dmps);

                    xo = s.invokeElem(xi);

                    System.out.println("Committing...");
                    xi = new NaElement("dataset-edit-commit");
                    xi.addNewChild("edit-lock-id", editLock);
                    xo = s.invokeElem(xi);

                    System.out.println("Addition of Members to Dataset "
                            + dsName + " Successful!");
                } else if (args[4].equals("del")) {
                    if (args.length < 7) {
                        usage();
                    }
                    String dsName = args[5];
                    int count = 7;

                    xi = new NaElement("dataset-edit-begin");
                    xi.addNewChild("dataset-name-or-id", dsName);
                    xo = s.invokeElem(xi);

                    editLock = xo.getChildContent("edit-lock-id");

                    xi = new NaElement("dataset-remove-member");
                    xi.addNewChild("edit-lock-id", editLock);
                    NaElement dmps = new NaElement("dataset-member-parameters");
                    while (count <= args.length) {
                        System.out.println("Removing member " + args[count - 1]
                                + "...");
                        NaElement dmp = new NaElement(
                                "dataset-member-parameter");
                        dmp.addNewChild("object-name-or-id", args[count - 1]);
                        dmps.addChildElem(dmp);
                        count++;
                    }
                    xi.addChildElem(dmps);
                    xo = s.invokeElem(xi);

                    System.out.println("Committing...");
                    xi = new NaElement("dataset-edit-commit");
                    xi.addNewChild("edit-lock-id", editLock);
                    xo = s.invokeElem(xi);
                    System.out.println("Removal of Members from Dataset "
                            + dsName + " Successful!");
                } else {
                    usage();
                }
            }
            // Provision a member from a dataset
            else if (args[3].equals("provision")) {
                if (args.length < 7) {
                    usage();
                }

                String dsName = args[4];
                String name = args[5];
                String size = args[6];
                String ssspace = null;
                if (args.length == 8)
                    ssspace = args[7];

                // Determine the provisioning policy attached to the dataset.
                // This is needed to pass on the
                // right input to the dataset create based on nas or san policy
                xi = new NaElement("dataset-list-info-iter-start");
                xi.addNewChild("object-name-or-id", dsName);
                xo = s.invokeElem(xi);

                xi = new NaElement("dataset-list-info-iter-next");
                xi.addNewChild("maximum", xo.getChildContent("records"));
                xi.addNewChild("tag", xo.getChildContent("tag"));
                xo = s.invokeElem(xi);

                if (xo.getChildIntValue("records", 0) == 0) {
                    System.out.println("Error: No such Dataset!");
                    System.exit(1);
                }

                NaElement rps = xo.getChildByName("datasets");
                NaElement rpInfos = rps.getChildByName("dataset-info");
                String provpId = rpInfos
                        .getChildContent("provisioning-policy-id");
                System.out.println("Prov Policy\t: "
                        + rpInfos.getChildContent("provisioning-policy-name"));

                xi = new NaElement("provisioning-policy-list-iter-start");
                xi.addNewChild("provisioning-policy-name-or-id", provpId);
                xo = s.invokeElem(xi);

                xi = new NaElement("provisioning-policy-list-iter-next");
                xi.addNewChild("maximum", xo.getChildContent("records"));
                xi.addNewChild("tag", xo.getChildContent("tag"));
                xo = s.invokeElem(xi);

                if (xo.getChildIntValue("records", 0) == 0) {
                    System.out.println("Error: No Provisioning Policies!");
                    System.exit(1);
                }

                NaElement pps = xo.getChildByName("provisioning-policies");
                NaElement ppInfos = pps
                        .getChildByName("provisioning-policy-info");
                String pptype = ppInfos
                        .getChildContent("provisioning-policy-type");

                xi = new NaElement("dataset-edit-begin");
                xi.addNewChild("dataset-name-or-id", dsName);
                xo = s.invokeElem(xi);

                editLock = xo.getChildContent("edit-lock-id");

                xi = new NaElement("dataset-provision-member");
                xi.addNewChild("edit-lock-id", editLock);
                NaElement pmri = new NaElement("provision-member-request-info");
                pmri.addNewChild("name", name);
                pmri.addNewChild("size", size);

                if (pptype.equals("san")) {
                    pmri.addNewChild("maximum-snapshot-space", ssspace);
                }
                xi.addChildElem(pmri);
                System.out.println("Provisioning storage...");
                xo = s.invokeElem(xi);

                System.out.println("Committing...");
                xi = new NaElement("dataset-edit-commit");
                xi.addNewChild("edit-lock-id", editLock);
                xo = s.invokeElem(xi);

                // Save the jobid to poll for its completion
                String jobId = ((xo.getChildByName("job-ids"))
                        .getChildByName("job-info")).getChildContent("job-id");

                System.out.println("Job ID\t\t: " + jobId);
                String jobStatus = "running";
                System.out.print("Job Status\t: " + jobStatus);
                // Continuously poll to see if the job completed
                while (jobStatus.equals("queued")
                        || jobStatus.equals("running")) {
                    xi = new NaElement("dp-job-list-iter-start");
                    xi.addNewChild("job-id", jobId);
                    xo = s.invokeElem(xi);

                    xi = new NaElement("dp-job-list-iter-next");
                    xi.addNewChild("maximum", xo.getChildContent("records"));
                    xi.addNewChild("tag", xo.getChildContent("tag"));
                    xo = s.invokeElem(xi);

                    NaElement dpJobs = xo.getChildByName("jobs");
                    NaElement dpJobInfo = dpJobs.getChildByName("dp-job-info");
                    jobStatus = dpJobInfo.getChildContent("job-state");
                    Thread.sleep(3000);
                    System.out.print(".");
                    if (jobStatus.equals("completed")
                            || jobStatus.equals("aborted")) {
                        System.out.println("\nOverall Status\t: "
                                + dpJobInfo
                                        .getChildContent("job-overall-status"));
                    }
                }

                // Display the job result - success/failure and provisioned
                // member details
                xi = new NaElement("dp-job-progress-event-list-iter-start");
                xi.addNewChild("job-id", jobId);
                xo = s.invokeElem(xi);

                xi = new NaElement("dp-job-progress-event-list-iter-next");
                xi.addNewChild("tag", xo.getChildContent("tag"));
                xi.addNewChild("maximum", xo.getChildContent("records"));
                xo = s.invokeElem(xi);

                NaElement progEvnts = xo.getChildByName("progress-events");
                List progEvntsInfo = progEvnts.getChildren();
                System.out.println("\nProvision Details:");
                System.out.println("==================================="
                        + "=======================");
                for (Iterator i = progEvntsInfo.iterator(); i.hasNext();) {
                    NaElement evnt = (NaElement) i.next();
                    if (evnt.getChildContent("event-type") != null) {
                        System.out.print(evnt.getChildContent("event-type"));
                    }
                    System.out.println("\t: "
                            + evnt.getChildContent("event-message"));
                }
            } else {
                System.out.println("Invalid Option!");
                usage();
            }
        } catch (NaAPIFailedException e) {
            System.err.println("\n" + e.toString());
            System.err.println("INFO: Attempting to roll-back if any "
                    + "edit sessions were open...\n");
            if (editLock != null) {
                try {
                    xi = new NaElement("dataset-edit-rollback");
                    xi.addNewChild("edit-lock-id", editLock);
                    xo = s.invokeElem(xi);
                } catch (Exception ex) {
                    System.err.println("INFO: No edit sessions open");
                }
            } else
                System.out.println("INFO: No edit-lock obtained...");
            System.exit(1);
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}