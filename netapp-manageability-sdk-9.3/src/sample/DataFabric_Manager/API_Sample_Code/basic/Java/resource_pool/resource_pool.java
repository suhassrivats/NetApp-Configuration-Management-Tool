/*
 * $Id:$
 *
 * resource_pool.java
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * This program will help managing the resource pool
 * you you can create,list and delete resource pools
 * add,list and remove members
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

public class resource_pool {
    private static NaServer server;
    private static String[] Arg;

    public static void USAGE() {
        System.out
                .println(""
                        + "Usage:\n"
                        + "resource_pool <dfmserver> <user> <password> list [ <rpool> ]\n"
                        + "\n"
                        + "resource_pool <dfmserver> <user> <password> delete <rpool>\n"
                        + "\n"
                        + "resource_pool <dfmserver> <user> <password> create <rpool>  [ -t <rtag> ]\n"
                        + "[-f <rp-full-thresh>] [-n <rp-nearly-full-thresh>]\n"
                        + "\n"
                        + "resource_pool <dfmserver> <user> <password> member-add <a-mem-rpool>\n"
                        + "<member> [ -m mem-rtag ]\n"
                        + "\n"
                        + "resource_pool <dfmserver> <user> <password> member-list <mem-rpool>\n"
                        + "[ <member> ]\n"
                        + "\n"
                        + "resource_pool <dfmserver> <user> <password> member-remove <mem-rpool>\n"
                        + "<member>\n"
                        + "\n"
                        + "\n"
                        + "<operation>             -- create or delete or list or member-add or\n"
                        + "                           member-list or member-remove\n"
                        + "\n"
                        + "<dfmserver>             -- Name/IP Address of the DFM server\n"
                        + "<user>                  -- DFM server User name\n"
                        + "<password>              -- DFM server User Password\n"
                        + "<rpool>                 -- Resource pool name\n"
                        + "<rtag>                  -- resource tag to be attached to a resourcepool\n"
                        + "<rp-full-thresh>        -- fullness threshold percentage to generate a\n"
                        + "                           \"resource pool full\" event.Range: [0..1000]\n"
                        + "<rp-nearly-full-thresh> -- fullness threshold percentage to generate a\n"
                        + "                           \"resource pool nearly full\" event.Range: "
                        + "[0..1000]\n"
                        + "<a-mem-rpool>           -- resourcepool to which the member will be added\n"
                        + "<mem-rpool>             -- resourcepool containing the member\n"
                        + "<member>                -- name or Id of the member (host or aggregate)\n"
                        + "<mem-rtag>              -- resource tag to be attached to member\n");

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
                || (dfmop.equals("member-add") && arglen < 6))
            USAGE();

        // checking if the operation selected is valid
        if ((!dfmop.equals("list")) && (!dfmop.equals("create"))
                && (!dfmop.equals("delete")) && (!dfmop.equals("member-list"))
                && (!dfmop.equals("member-add"))
                && (!dfmop.equals("member-remove")))
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
        String fullThresh = null;
        String nearlyFullThresh = null;
        String resourceTag = null;

        // Getting the pool name
        String poolName = Arg[4];

        // parsing optional parameters
        int i = 5;
        while (i < Arg.length) {
            if (Arg[i].equals("-t")) {
                resourceTag = Arg[++i];
                ++i;
            } else if (Arg[i].equals("-f")) {
                fullThresh = Arg[++i];
                ++i;
            } else if (Arg[i].equals("-n")) {
                nearlyFullThresh = Arg[++i];
                ++i;
            } else {
                USAGE();
            }
        }

        try {
            // creating the input for api execution
            // creating a resourcepool-create element and adding child elements
            NaElement input = new NaElement("resourcepool-create");
            NaElement rpool = new NaElement("resourcepool");
            NaElement pool = new NaElement("resourcepool-info");
            pool.addNewChild("resourcepool-name", poolName);
            if (resourceTag != null)
                pool.addNewChild("resource-tag", resourceTag);
            if (fullThresh != null)
                pool.addNewChild("resourcepool-full-threshold", fullThresh);
            if (nearlyFullThresh != null)
                pool.addNewChild("resourcepool-nearly-full-threshold",
                        nearlyFullThresh);

            rpool.addChildElem(pool);
            input.addChildElem(rpool);

            // invoking the api && printing the xml ouput
            NaElement output = server.invokeElem(input);

            System.out.println("\nPool creation "
                    + result(output.getAttr("status")));
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void list() {
        String poolName = null;

        try {
            // creating a resource pool start element
            NaElement input = new NaElement("resourcepool-list-info-iter-start");
            if (Arg.length > 4) {
                poolName = Arg[4];
                input.addNewChild("object-name-or-id", poolName);
            }

            // invoke the api && capturing the records && tag values
            NaElement output = server.invokeElem(input);

            // Extracting the record && tag values && printing them
            String records = output.getChildContent("records");

            if (records.equals("0"))
                System.out.println("\nNo resourcepools to display");

            String tag = output.getChildContent("tag");

            // Extracting records one at a time
            input = new NaElement("resourcepool-list-info-iter-next");
            input.addNewChild("maximum", records);
            input.addNewChild("tag", tag);
            NaElement record = server.invokeElem(input);

            // Navigating to the resourcepools child element
            NaElement stat = record.getChildByName("resourcepools");

            // Navigating to the resourcepool-info child element
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
                // extracting the resource-pool name and printing it
                value = info.getChildContent("resourcepool-name");
                System.out.println("Resourcepool Name : " + value);

                value = info.getChildContent("resourcepool-id");
                System.out.println("Resourcepool Id : " + value);

                value = info.getChildContent("resourcepool-description");
                System.out.println("Resourcepool Description : " + value);

                System.out.println("-----------------------------------------");

                // printing detials if only one resource-pool is selected
                if (poolName != null) {

                    value = info.getChildContent("resourcepool-status");
                    System.out.println("\nResourcepool Status               "
                            + "       : " + value);

                    value = info.getChildContent("resourcepool-perf-status");
                    System.out.println("Resourcepool Perf Status            "
                            + "     : " + value);

                    value = info.getChildContent("resource-tag");
                    System.out.print("Resource Tag                          "
                            + "   : ");
                    if (value != null)
                        System.out.print(value);

                    value = info.getChildContent("resourcepool-member-count");
                    System.out.println("\nResourcepool Member Count         "
                            + "       : " + value);

                    value = info.getChildContent("resourcepool-full-threshold");
                    System.out.print("Resourcepool Full Threshold           "
                            + "   : ");
                    if (value != null)
                        System.out.print(value + "%");

                    value = info
                            .getChildContent("resourcepool-nearly-full-threshold");
                    System.out.print("\nResourcepool Nearly Full Threshold  "
                            + "     : ");
                    if (value != null)
                        System.out.print(value + "%");

                    value = info
                            .getChildContent("aggregate-nearly-overcommitted-threshold");
                    System.out.println("\nAggregate Nearly Overcommitted "
                            + "Threshold : " + value + "%");

                    value = info
                            .getChildContent("aggregate-overcommitted-threshold");
                    System.out.println("Aggregate Overcommitted Threshold   "
                            + "     : " + value + "%");
                }
            }

            // invoking the iter-end zapi
            input = new NaElement("resourcepool-list-info-iter-end");
            input.addNewChild("tag", tag);
            server.invokeElem(input);

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void delete() {
        String poolName = Arg[4];

        try {
            // invoking the api && printing the xml ouput
            NaElement input = new NaElement("resourcepool-destroy");
            input.addNewChild("resourcepool-name-or-id", poolName);
            NaElement output = server.invokeElem(input);

            System.out.println("\nPool deletion "
                    + result(output.getAttr("status")));

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void memberAdd() {
        String memberResourceTag = null;

        // Getting the resource pool and member name
        String poolName = Arg[4];
        String memberName = Arg[5];

        // parsing optional parameters
        int i = 6;
        while (i < Arg.length) {
            if (Arg[i].equals("-m")) {
                memberResourceTag = Arg[++i];
                ++i;
            } else {
                USAGE();
            }
        }

        try {
            // creating the input for api execution
            // creating a resourcepool-add-member element and adding child
            NaElement input = new NaElement("resourcepool-add-member");
            input.addNewChild("resourcepool-name-or-id", poolName);
            input.addNewChild("member-name-or-id", memberName);
            if (memberResourceTag != null)
                input.addNewChild("resource-tag", memberResourceTag);

            // invoking the api && printing the xml ouput
            NaElement output = server.invokeElem(input);

            System.out.println("\nMember addition "
                    + result(output.getAttr("status")));
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void memberList() {
        String memberName = null;
        String poolName = Arg[4];

        try {
            // creating a resourcepool member start element
            NaElement input = new NaElement(
                    "resourcepool-member-list-info-iter-start");
            input.addNewChild("resourcepool-name-or-id", poolName);
            if (Arg.length > 5) {
                memberName = Arg[5];
                input.addNewChild("resourcepool-member-name-or-id", memberName);
            }

            // invoke the api && capturing the records && tag values
            NaElement output = server.invokeElem(input);

            System.out.println("---------------------------------------------");
            // Extracting the record && tag values && printing them
            String records = output.getChildContent("records");
            if (memberName == null)
                System.out.println("Records: " + records + "\n");

            String tag = output.getChildContent("tag");

            if (records.equals("0"))
                System.out.println("\nNo members to display");

            System.out.println("---------------------------------------------");

            // Extracting records one at a time
            input = new NaElement("resourcepool-member-list-info-iter-next");
            input.addNewChild("maximum", records);
            input.addNewChild("tag", tag);
            NaElement record = server.invokeElem(input);

            // Navigating to the resourcepool-members child element
            NaElement stat = record.getChildByName("resourcepool-members");

            // Navigating to the resourcepool-info child element
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

                // extracting the member name and printing it
                String name = info.getChildContent("member-name");
                String id = info.getChildContent("member-id");
                if (memberName == null
                        || (memberName != null && (name.equals(memberName) || id
                                .equals(memberName)))) {
                    System.out.println("Member Name : " + name);
                    System.out.println("Member Id : " + id);
                    System.out.println("-------------------------------------");
                } else {
                    throw new NaException("Member " + memberName
                            + " name not found");
                }

                // printing detials if only one member is selected for listing
                if (memberName != null
                        && (name.equals(memberName) || id.equals(memberName))) {

                    value = info.getChildContent("member-type");
                    System.out.println("\nMember Type            : " + value);

                    value = info.getChildContent("member-status");
                    System.out.println("Member Status          : " + value);

                    value = info.getChildContent("member-perf-status");
                    System.out.println("Member Perf Status     : " + value);

                    value = info.getChildContent("resource-tag");
                    System.out.print("Resource Tag           : ");
                    if (value != null)
                        System.out.print(value);

                    value = info.getChildContent("member-count");
                    System.out.print("\nMember Member Count    : ");
                    if (value != null)
                        System.out.print(value);

                    value = info.getChildContent("member-used-space");
                    System.out.println("\nMember Used Space      : " + value
                            + " bytes");

                    value = info.getChildContent("member-committed-space");
                    System.out.println("Member Committed Space : " + value
                            + " bytes");

                    value = info.getChildContent("member-size");
                    System.out.println("Member Size            : " + value
                            + " bytes");
                }
            }

            // invoking the iter-end zapi
            input = new NaElement("resourcepool-member-list-info-iter-end");
            input.addNewChild("tag", tag);
            server.invokeElem(input);

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void memberRemove() {
        String poolName = Arg[4];
        String memberName = Arg[5];

        try {
            // invoking the api && printing the xml ouput
            NaElement input = new NaElement("resourcepool-remove-member");
            input.addNewChild("resourcepool-name-or-id", poolName);
            input.addNewChild("member-name-or-id", memberName);
            NaElement output = server.invokeElem(input);

            System.out.println("\nMember deletion "
                    + result(output.getAttr("status")));

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}