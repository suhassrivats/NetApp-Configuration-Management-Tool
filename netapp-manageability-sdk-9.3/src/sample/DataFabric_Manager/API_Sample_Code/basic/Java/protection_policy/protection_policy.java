/*
 * $Id:$
 *
 * protection_policy.java
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * This program will help managing the protection policies
 * you can Create, delete and list protection policies
 *
 *
 * This Sample code is supported from DataFabric Manager 3.6R2
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

public class protection_policy {
    private static NaServer server;
    private static String[] Arg;

    public static void USAGE() {
        System.out
                .println(""
                        + "Usage:\n"
                        + "protection_policy <dfmserver> <user> <password> list [ <policy> ]\n"
                        + "\n"
                        + "protection_policy <dfmserver> <user> <password> delete <policy>\n"
                        + "\n"
                        + "protection_policy <dfmserver> <user> <password> create <policy> <pol-new>\n"
                        + "\n"
                        + "<operation> -- create or delete or list\n"
                        + "\n"
                        + "<dfmserver> -- Name/IP Address of the DFM server\n"
                        + "<user>      -- DFM server User name\n"
                        + "<password>  -- DFM server User Password\n"
                        + "<policy>    -- Exisiting policy name\n"
                        + "<pol-new>   -- Protection policy to be created"
                        + "\n"
                        + "\n"
                        + "Note: In the create operation the a copy of protection policy will be made and"
                        + "\n" + "name changed from <pol-temp> to <pol-new>\n");
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
                || (dfmop.equals("create") && arglen != 6))
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
        String policyTemplate = Arg[4];
        String policyName = Arg[5];

        try {
            // Copy section
            // Making a copy of the policy in the format copy of <policy name>
            NaElement input = new NaElement("dp-policy-copy");
            input.addNewChild("template-dp-policy-name-or-id", policyTemplate);
            input.addNewChild("dp-policy-name", "copy of " + policyTemplate);
            server.invokeElem(input);

            // Modify section
            // creating edit section
            input = new NaElement("dp-policy-edit-begin");
            input.addNewChild("dp-policy-name-or-id", "copy of "
                    + policyTemplate);
            NaElement output = server.invokeElem(input);

            String lockId = output.getChildContent("edit-lock-id");

            // modifying the policy name
            // creating a dp-policy-modify element and adding child elements
            input = new NaElement("dp-policy-modify");
            input.addNewChild("edit-lock-id", lockId);

            // getting the policy content deailts of the original policy
            NaElement origPolicyContent = getPolicyContent();

            // Creating a new dp-policy-content element and adding name and desc
            NaElement policyContent = new NaElement("dp-policy-content");
            policyContent.addNewChild("name", policyName);
            policyContent.addNewChild("description", "Added by sample code");

            // appending the original connections and nodes children
            policyContent.addChildElem(origPolicyContent
                    .getChildByName("dp-policy-connections"));
            policyContent.addChildElem(origPolicyContent
                    .getChildByName("dp-policy-nodes"));

            // Attaching the new policy content child to modify element
            input.addChildElem(policyContent);

            try {
                // invoking the api && printing the xml ouput
                output = server.invokeElem(input);

                input = new NaElement("dp-policy-edit-commit");
                input.addNewChild("edit-lock-id", lockId);
                output = server.invokeElem(input);
            } catch (Exception e) {
                System.err.println(e.toString());
                input = new NaElement("dp-policy-edit-rollback");
                input.addNewChild("edit-lock-id", lockId);
                server.invokeElem(input);
                System.exit(1);
            }

            System.out.println("\nPolicy creation "
                    + result(output.getAttr("status")));
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static NaElement getPolicyContent() {
        NaElement policyContent = null;
        try {
            // creating a dp policy start element
            NaElement input = new NaElement("dp-policy-list-iter-start");
            input.addNewChild("dp-policy-name-or-id", Arg[4]);

            // invoke the api && capturing the records && tag values
            NaElement output = server.invokeElem(input);

            // Extracting the record && tag values && printing them
            String tag = output.getChildContent("tag");

            // Extracting records one at a time
            input = new NaElement("dp-policy-list-iter-next");
            input.addNewChild("maximum", "1");
            input.addNewChild("tag", tag);
            NaElement record = server.invokeElem(input);

            // Navigating to the dp-policy-infos child element
            NaElement policyInfos = record.getChildByName("dp-policy-infos");

            // Navigating to the dp-policy-info child element
            NaElement policyInfo = policyInfos.getChildByName("dp-policy-info");

            // Navigating to the dp-policy-content child element
            policyContent = policyInfo.getChildByName("dp-policy-content");

            // invoking the iter-end zapi
            input = new NaElement("dp-policy-list-iter-end");
            input.addNewChild("tag", tag);

            server.invokeElem(input);

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
        // Returning the original policy content
        return (policyContent);
    }

    public static void list() {
        String policyName = null;

        try {
            // creating a dp policy start element
            NaElement input = new NaElement("dp-policy-list-iter-start");
            if (Arg.length > 4) {
                policyName = Arg[4];
                input.addNewChild("dp-policy-name-or-id", policyName);
            }

            // invoke the api && capturing the records && tag values
            NaElement output = server.invokeElem(input);

            // Extracting the record && tag values && printing them
            String records = output.getChildContent("records");

            if (records.equals("0"))
                System.out.println("\nNo policies to display");

            String tag = output.getChildContent("tag");

            // Extracting records one at a time
            input = new NaElement("dp-policy-list-iter-next");
            input.addNewChild("maximum", records);
            input.addNewChild("tag", tag);
            NaElement record = server.invokeElem(input);

            // Navigating to the dp-policy-infos child element
            NaElement stat = record.getChildByName("dp-policy-infos");

            // Navigating to the dp-policy-info child element
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

                // extracting the policy name and printing it
                // Navigating to the dp-policy-content child element
                NaElement policyContent = info
                        .getChildByName("dp-policy-content");

                // Removing non modifiable policies
                if (policyContent.getChildContent("name").indexOf("NM") < 0) {

                    System.out.println("-------------------------------------");
                    value = policyContent.getChildContent("name");
                    System.out.println("Policy Name : " + value);

                    value = info.getChildContent("id");
                    System.out.println("Id : " + value);

                    value = policyContent.getChildContent("description");
                    System.out.println("Description : " + value);

                    System.out.println("-------------------------------------");

                    // printing detials if only one policy is selected for
                    // listing
                    if (policyName != null) {

                        // printing connection info
                        NaElement dpc = policyContent
                                .getChildByName("dp-policy-connections");
                        NaElement dpci = dpc
                                .getChildByName("dp-policy-connection-info");

                        value = dpci.getChildContent("backup-schedule-name");
                        System.out.print("\nBackup Schedule Name : ");
                        if (value != null)
                            System.out.print(value);

                        value = dpci.getChildContent("backup-schedule-id");
                        System.out.print("\nBackup Schedule Id   : ");
                        if (value != null)
                            System.out.println(value);

                        value = dpci.getChildContent("id");
                        System.out.println("Connection Id        : " + value);

                        value = dpci.getChildContent("type");
                        System.out.println("Connection Type      : " + value);

                        value = dpci.getChildContent("lag-warning-threshold");
                        System.out.println("Lag Warning Threshold:" + value);

                        value = dpci.getChildContent("lag-error-threshold");
                        System.out.println("Lag Error Threshold  : " + value);

                        value = dpci.getChildContent("from-node-name");
                        System.out.println("From Node Name       : " + value);

                        value = dpci.getChildContent("from-node-id");
                        System.out.println("From Node Id         : " + value);

                        value = dpci.getChildContent("to-node-name");
                        System.out.println("To Node Name         : " + value);

                        value = dpci.getChildContent("to-node-id");
                        System.out.println("To Node Id           :" + value);
                    }
                }
            }

            // invoking the iter-end zapi
            input = new NaElement("dp-policy-list-iter-end");
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
            NaElement input = new NaElement("dp-policy-edit-begin");
            input.addNewChild("dp-policy-name-or-id", policyName);
            NaElement output = server.invokeElem(input);

            String lockId = output.getChildContent("edit-lock-id");

            // Deleting the policy name
            // creating a dp-policy-destroy element and adding edit-lock
            input = new NaElement("dp-policy-destroy");
            input.addNewChild("edit-lock-id", lockId);
            output = server.invokeElem(input);

            try {
                input = new NaElement("dp-policy-edit-commit");
                input.addNewChild("edit-lock-id", lockId);
                output = server.invokeElem(input);
            } catch (Exception e) {
                System.err.println(e.toString());
                input = new NaElement("dp-policy-edit-rollback");
                input.addNewChild("edit-lock-id", lockId);
                server.invokeElem(input);
                System.exit(1);
            }

            System.out.println("\nPolicy deletion "
                    + result(output.getAttr("status")));

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}
