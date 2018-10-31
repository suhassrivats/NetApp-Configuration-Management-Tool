/*
 * $Id:$
 *
 * vfiler.java
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * This program will help managing the vfiler units
 * you can create and delete vFiler units, create,list and delete vFiler 
 * templates.
 *
 *
 * This Sample code is supported from DataFabric Manager 3.7.1
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

public class vfiler {
    private static NaServer server;
    private static String[] Arg;

    public static void USAGE() {
        System.out
                .println(""
                        + "Usage:\n"
                        + "vfiler <dfmserver> <user> <password> delete <name>\n"
                        + "\n"
                        + "vfiler <dfmserver> <user> <password> create <name> <rpool> <ip> [ <tname> ]\n"
                        + "\n"
                        + "vfiler <dfmserver> <user> <password> template-list [ <tname> ]\n"
                        + "\n"
                        + "vfiler <dfmserver> <user> <password> template-delete <tname>\n"
                        + "\n"
                        + "vfiler <dfmserver> <user> <password> template-create <a-tname>\n"
                        + "[ -a <cauth> -d <cdomain> ] [ -s <csecurity> ]\n"
                        + "\n"
                        + "<dfmserver> -- Name/IP Address of the DFM server\n"
                        + "<user>      -- DFM server User name\n"
                        + "<password>  -- DFM server User Password\n"
                        + "<rpool>     -- Resource pool in which vFiler is to be created\n"
                        + "<ip>        -- ip address of the new vFiler\n"
                        + "<name>      -- name of the new vFiler to be created\n"
                        + "<tname>     -- Existing Template name\n"
                        + "<a-tname>   -- Template to be created\n"
                        + "<cauth>     -- CIFS authentication mode Possible values: \"active_directory\""
                        + ",\n"
                        + "               \"workgroup\". Default value: \"workgroup\"\n"
                        + "<cdomain>   -- Active Directory domain .This field is applicable only when\n"
                        + "               cifs-auth-type is set to \"active-directory\"\n"
                        + "<csecurity> -- The security style Possible values: \"ntfs\", \"multiprotocol\""
                        + "\n"
                        + "               Default value is: \"multiprotocol\"");

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
        if ((dfmop.equals("delete") && arglen != 5)
                || (dfmop.equals("create") && arglen < 7)
                || (dfmop.equals("template-list") && arglen < 4)
                || (dfmop.equals("template-delete") && arglen != 5)
                || (dfmop.equals("template-create") && arglen < 5))
            USAGE();

        // checking if the operation selected is valid
        if ((!dfmop.equals("list")) && (!dfmop.equals("create"))
                && (!dfmop.equals("delete"))
                && (!dfmop.equals("template-list"))
                && (!dfmop.equals("template-create"))
                && (!dfmop.equals("template-delete")))
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
            else if (dfmop.equals("delete"))
                delete();
            else if (dfmop.equals("template-list"))
                template_list();
            else if (dfmop.equals("template-create"))
                template_create();
            else if (dfmop.equals("template-delete"))
                template_delete();
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
        String templateName = null;

        // Getting the vfiler name, resource pool name and ip
        String vfilerName = Arg[4];
        String poolName = Arg[5];
        String ip = Arg[6];

        if (Arg.length > 7)
            templateName = Arg[7];

        try {
            // creating the input for api execution
            // creating a vfiler-create element and adding child elements
            NaElement input = new NaElement("vfiler-create");
            input.addNewChild("ip-address", ip);
            input.addNewChild("name", vfilerName);
            input.addNewChild("resource-name-or-id", poolName);
            NaElement output = server.invokeElem(input);

            System.out.println("\nvFiler unit creation "
                    + result(output.getAttr("status")));
            System.out.println("\nvFiler unit created on Storage System : "
                    + output.getChildContent("filer-name") + "\nRoot Volume : "
                    + output.getChildContent("root-volume-name"));

            if (templateName != null)
                setup(vfilerName, templateName);

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void setup(String vName, String tName) {
        try {
            // creating the input for api execution
            // creating a vfiler-create element and adding child elements
            NaElement input = new NaElement("vfiler-setup");
            input.addNewChild("vfiler-name-or-id", vName);
            input.addNewChild("vfiler-template-name-or-id", tName);
            NaElement output = server.invokeElem(input);

            System.out.println("\nvFiler unit setup with template " + tName
                    + " " + result(output.getAttr("status")));

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void delete() {
        String vfilerName = Arg[4];

        try {
            // invoking the api && printing the xml ouput
            NaElement input = new NaElement("vfiler-destroy");
            input.addNewChild("vfiler-name-or-id", vfilerName);
            NaElement output = server.invokeElem(input);

            System.out.println("\nvFiler unit deletion "
                    + result(output.getAttr("status")));

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void template_create() {
        String cifsAuth = null;
        String cifsDomain = null;
        String cifsSecurity = null;

        // Getting the template name
        String templateName = Arg[4];

        // parsing optional parameters
        int i = 5;
        while (i < Arg.length) {
            if (Arg[i].equals("-a")) {
                cifsAuth = Arg[++i];
                ++i;
            } else if (Arg[i].equals("-d")) {
                cifsDomain = Arg[++i];
                ++i;
            } else if (Arg[i].equals("-s")) {
                cifsSecurity = Arg[++i];
                ++i;
            } else {
                USAGE();
            }
        }

        try {
            // creating the input for api execution
            // creating a vfiler-template-create element and adding child elem
            NaElement input = new NaElement("vfiler-template-create");
            NaElement temp = new NaElement("vfiler-template");
            NaElement template = new NaElement("vfiler-template-info");
            template.addNewChild("vfiler-template-name", templateName);
            if (cifsAuth != null)
                template.addNewChild("cifs-auth-type", cifsAuth);
            if (cifsDomain != null)
                template.addNewChild("cifs-domain", cifsDomain);
            if (cifsSecurity != null)
                template.addNewChild("cifs-security-style", cifsSecurity);
            temp.addChildElem(template);
            input.addChildElem(temp);

            // invoking the api && printing the xml ouput
            NaElement output = server.invokeElem(input);

            System.out.println("\nvFiler template creation "
                    + result(output.getAttr("status")));
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void template_list() {
        String templateName = null;

        try {
            // creating a template lsit start element
            NaElement input = new NaElement(
                    "vfiler-template-list-info-iter-start");
            if (Arg.length > 4) {
                templateName = Arg[4];
                input.addNewChild("vfiler-template-name-or-id", templateName);
            }

            // invoke the api && capturing the records && tag values
            NaElement output = server.invokeElem(input);

            // Extracting the record && tag values && printing them
            String records = output.getChildContent("records");

            if (records.equals("0"))
                System.out.println("\nNo templates to display");

            String tag = output.getChildContent("tag");

            // Extracting records one at a time
            input = new NaElement("vfiler-template-list-info-iter-next");
            input.addNewChild("maximum", records);
            input.addNewChild("tag", tag);
            NaElement record = server.invokeElem(input);

            // Navigating to the vfiler templates child element
            NaElement stat = record.getChildByName("vfiler-templates");

            // Navigating to the vfiler-info child element
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

                System.out
                        .println("----------------------------------------------------");
                // extracting the template name and printing it
                value = info.getChildContent("vfiler-template-name");
                System.out.println("Template Name : " + value);

                value = info.getChildContent("vfiler-template-id");
                System.out.println("Template Id : " + value);

                value = info.getChildContent("vfiler-template-description");
                System.out.print("Template Description : ");
                if (value != null)
                    System.out.print(value);

                System.out
                        .println("\n----------------------------------------------------");

                // printing detials if only one template is selected for listing
                if (templateName != null) {

                    value = info.getChildContent("cifs-auth-type");
                    System.out.println("\nCIFS Authhentication     : " + value);

                    value = info.getChildContent("cifs-domain");
                    System.out.print("CIFS Domain              : ");
                    if (value != null)
                        System.out.print(value);

                    value = info.getChildContent("cifs-security-style");
                    System.out.println("\nCIFS Security Style      : " + value);

                    value = info.getChildContent("dns-domain");
                    System.out.print("DNS Domain               : ");
                    if (value != null)
                        System.out.print(value);

                    value = info.getChildContent("nis-domain");
                    System.out.print("\nNIS Domain               : ");
                    if (value != null)
                        System.out.println(value);
                }
            }

            // invoking the iter-end zapi
            input = new NaElement("vfiler-template-list-info-iter-end");
            input.addNewChild("tag", tag);
            server.invokeElem(input);

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    public static void template_delete() {
        String templateName = Arg[4];

        try {
            // invoking the api && printing the xml ouput
            NaElement input = new NaElement("vfiler-template-delete");
            input.addNewChild("vfiler-template-name-or-id", templateName);
            NaElement output = server.invokeElem(input);

            System.out.println("\nTemplate deletion "
                    + result(output.getAttr("status")));

        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}
