/*
 * $Id:$
 *
 * rbac.java
 *
 * Copyright (c) 2009 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * Sample code to demonstrate how to manage  a
 * Role Based Access Control (RBAC). Using this sample code,
 * you can create, delete and list roles, operations, etc.
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

public class rbac {
    private static NaServer server;
    private static String[] Args;

    public static void main(String[] args) {
        // check for the valid no. of arguments
        if (args.length < 4)
            usage();

        int argsIndex = 3;
        String operation = null;
        server = null;

        try {
            // create the server context for DFM Server
            server = new NaServer(args[0], 1, 0);
            server.setServerType(NaServer.SERVER_TYPE_DFM);
            server.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            server.setAdminUser(args[1], args[2]);

            Args = args;
            operation = args[3];

            // Check for the given input operation and call
            // appropriate function.
            if (operation.equals("operation-list"))
                operationList();
            else if (operation.equals("operation-add"))
                operationAdd();
            else if (operation.equals("operation-delete"))
                operationDelete();
            else if (operation.equals("role-add"))
                roleAdd();
            else if (operation.equals("role-delete"))
                roleDelete();
            else if (operation.equals("role-list"))
                roleList();
            else if (operation.equals("role-capability-add"))
                roleCapabilityAdd();
            else if (operation.equals("role-capability-delete"))
                roleCapabilityDelete();
            else if (operation.equals("admin-role-add"))
                adminRoleAdd();
            else if (operation.equals("admin-role-delete"))
                adminRoleDelete();
            else if (operation.equals("admin-role-list"))
                roleAdminList();
            else if (operation.equals("admin-list"))
                adminList();
            else
                usage();
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    // This function will list the roles assigned to an existing administrator.
    public static void roleAdminList() {
        if (Args.length < 5) {
            usage();
        }
        String adminNameID = Args[4];
        String roleID = null;
        String roleName = null;
        try {
            // invoke the rbac-role-admin-info-list api and capture the ouput
            NaElement input = new NaElement("rbac-role-admin-info-list");
            input.addNewChild("admin-name-or-id", adminNameID);
            input.addNewChild("follow-role-inheritance", "TRUE");

            NaElement output = server.invokeElem(input);

            System.out
                    .println("----------------------------------------------------");
            String adminNameID2 = output.getChildContent("admin-name-or-id");
            System.out.println("\nadmin name-id         :" + adminNameID);

            // get the list of roles which is contained in role-list element
            List roleList = null;

            if (output.getChildByName("role-list") != null)
                roleList = output.getChildByName("role-list").getChildren();
            if (roleList == null)
                return;
            Iterator roleIter = roleList.iterator();
            // Iterate through each role record
            while (roleIter.hasNext()) {
                NaElement role = (NaElement) roleIter.next();
                roleID = role.getChildContent("rbac-role-id");
                roleName = role.getChildContent("rbac-role-name");
                System.out.println("\nrole name             : " + roleName);
                System.out.println("role id               : " + roleID);
            }
            System.out
                    .println("----------------------------------------------------");
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    // This function will list all the administrators and their attributes.
    public static void adminList() {
        String adminNameID = "";

        try {
            // create the rbac-admin-list-info-iter-start API request
            NaElement input = new NaElement("rbac-admin-list-info-iter-start");
            if (Args.length == 5) {
                adminNameID = Args[4];
                input.addNewChild("admin-name-or-id", adminNameID);
            }

            // invoke the api and capture the records and tag values for
            // rbac-admin-list-info-iter-next
            NaElement output = server.invokeElem(input);

            String records = output.getChildContent("records");
            String tag = output.getChildContent("tag");

            // invoke the rbac-admin-list-info-iter-next api to return the
            // list of admins
            input = new NaElement("rbac-admin-list-info-iter-next");
            input.addNewChild("maximum", records);
            input.addNewChild("tag", tag);

            output = server.invokeElem(input);

            List adminList = null;
            // capture the list of admins which is contained in admins element
            if (output.getChildByName("admins") != null)
                adminList = output.getChildByName("admins").getChildren();
            Iterator adminIter = adminList.iterator();
            System.out
                    .println("----------------------------------------------------");
            // Iterate through each admin record
            while (adminIter.hasNext()) {
                NaElement admin = (NaElement) adminIter.next();
                String id = admin.getChildContent("admin-id");
                String name = admin.getChildContent("admin-name");
                System.out.println("\nadmin name             : " + name);
                System.out.println("admin id               : " + id);
                String email = admin.getChildContent("email-address");
                if (email != null)
                    System.out.println("email address          : " + email);
            }
            System.out
                    .println("----------------------------------------------------");
            input = new NaElement("rbac-admin-list-info-iter-end");
            input.addNewChild("tag", tag);
            output = server.invokeElem(input);
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    // This function will remove a role from an administrator
    public static void adminRoleDelete() {
        if (Args.length < 6) {
            usage();
        }

        String adminNameID = Args[4];
        String rolenameID = Args[5];

        try {
            // create the input rbac-admin-role-remove API request
            NaElement input = new NaElement("rbac-admin-role-remove");
            input.addNewChild("admin-name-or-id", adminNameID);
            // check for the role name or delete all roles
            input.addNewChild("role-name-or-id", rolenameID);
            // invoke the API request
            NaElement output = server.invokeElem(input);
            System.out.println("admin role(s) deleted successfully! ");
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    // This function will assign an existing role to an existing administrator.
    public static void adminRoleAdd() {

        if (Args.length < 6) {
            usage();
        }

        String adminnameID = Args[4];
        String rolenameID = Args[5];
        String newAdminName = null;
        String newAdminID = null;
        try {
            // create the input rbac-admin-role-add API request
            NaElement input = new NaElement("rbac-admin-role-add");
            input.addNewChild("admin-name-or-id", adminnameID);
            input.addNewChild("role-name-or-id", rolenameID);

            // invoke the API request
            NaElement output = server.invokeElem(input);

            System.out.println("admin role added successfully! ");
            NaElement newAdminNameID = output
                    .getChildByName("admin-name-or-id").getChildByName(
                            "rbac-admin-name-or-id");
            newAdminName = newAdminNameID.getChildContent("admin-name");
            newAdminID = newAdminNameID.getChildContent("admin-id");
            System.out.println("new admin name                    :"
                    + newAdminName);
            System.out.println("new admin id                      :"
                    + newAdminID);
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    // This function will remove one or more capabilities from an existing role.
    public static void roleCapabilityDelete() {
        if (Args.length < 8) {
            usage();
        }
        String roleNameID = Args[4];
        String operation = Args[5];
        String resourceType = Args[6];
        String resourceName = Args[7];

        try {
            // create the input rbac-role-capability-remove API request
            NaElement input = new NaElement("rbac-role-capability-remove");
            input.addNewChild("role-name-or-id", roleNameID);
            // check for the resource type and frame the nested API request
            if (!resourceType.equals("dataset")
                    && !resourceType.equals("filer")) {
                System.out.println("Invalid resource type");
                System.exit(2);
            }
            input.addNewChild("operation", operation);
            NaElement resource = new NaElement("resource");
            NaElement resourceID = new NaElement("resource-identifier");
            input.addChildElem(resource);
            resource.addChildElem(resourceID);
            if (resourceType.equals("dataset")) {
                NaElement dataset = new NaElement("dataset");
                NaElement datasetResource = new NaElement("dataset-resource");
                datasetResource.addNewChild("dataset-name", resourceName);
                dataset.addChildElem(datasetResource);
                resourceID.addChildElem(dataset);
            } else if (resourceType.equals("filer")) {
                NaElement filer = new NaElement("filer");
                NaElement filerResource = new NaElement("filer-resource");
                filerResource.addNewChild("filer-name", resourceName);
                filer.addChildElem(filerResource);
                resourceID.addChildElem(filer);
            }
            // invoke the API
            NaElement output = server.invokeElem(input);
            System.out.println("capability removed successfully! \n");
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    // This function will add a capability to a role.
    public static void roleCapabilityAdd() {

        if (Args.length < 8) {
            usage();
        }

        String rolenameID = Args[4];
        String operation = Args[5];
        String resourceType = Args[6];
        String resourceName = Args[7];

        // check for the proper resource type
        if (!resourceType.equals("dataset") && !resourceType.equals("filer")) {
            System.err.println("Invalid resource type");
            System.exit(2);
        }

        try {
            // create the input rbac-role-capability-add API request
            NaElement input = new NaElement("rbac-role-capability-add");
            input.addNewChild("operation", operation);
            input.addNewChild("role-name-or-id", rolenameID);

            NaElement resource = new NaElement("resource");
            NaElement resourceID = new NaElement("resource-identifier");
            input.addChildElem(resource);
            resource.addChildElem(resourceID);
            // check for the resource type and frame the request
            if (resourceType.equals("dataset")) {
                NaElement dataset = new NaElement("dataset");
                NaElement datasetResource = new NaElement("dataset-resource");
                datasetResource.addNewChild("dataset-name", resourceName);
                dataset.addChildElem(datasetResource);
                resourceID.addChildElem(dataset);
            } else if (resourceType.equals("filer")) {
                NaElement filer = new NaElement("filer");
                NaElement filerResource = new NaElement("filer-resource");
                filerResource.addNewChild("filer-name", resourceName);
                filer.addChildElem(filerResource);
                resourceID.addChildElem(filer);
            }

            // invoke the API
            NaElement output = server.invokeElem(input);
            System.out.println("capability added successfully! ");
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    // This function will add a new role to the RBAC system
    public static void roleAdd() {
        String role;
        String description;

        if (Args.length != 6) {
            usage();
            System.exit(2);
        }
        role = Args[4];
        description = Args[5];

        try {
            // create the input API request for role-add
            NaElement input = new NaElement("rbac-role-add");
            input.addNewChild("role-name", role);
            input.addNewChild("description", description);
            // invoke the api request and get the new role id
            NaElement output = server.invokeElem(input);
            System.out.println("new role-id: "
                    + output.getChildContent("role-id"));
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
        System.out.println("role added successfully!");
    }

    // This function will delete an existing role from the RBAC system
    public static void roleDelete() {
        if (Args.length < 5) {
            usage();
        }
        String role = Args[4];
        try {
            // create the API request to delete role
            NaElement input = new NaElement("rbac-role-delete");
            input.addNewChild("role-name-or-id", role);

            // invoke the API
            NaElement output = server.invokeElem(input);
            System.out.println("\nrole deleted successfully!");
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    // This function will list the operations, capabilities
    // and inherited roles that one or more roles have.
    public static void roleList() {
        String role = null;
        String roleID = null;
        String roleName = null;
        String description = null;
        String inhRoleID = null;
        String inhRoleName = null;
        String operationName = null;
        String operationDesc = null;
        String operationSyn = null;
        String resourceType = null;

        if (Args.length == 5)
            role = Args[4];

        try {
            // create the input rbac-role-info-list API request
            NaElement input = new NaElement("rbac-role-info-list");

            if (role != null)
                input.addNewChild("role-name-or-id", role);

            // invoke the API and capture the role attributes
            NaElement output = server.invokeElem(input);

            // get the list of role attributes which is contained under
            // role-attributes element
            List attrList = output.getChildByName("role-attributes")
                    .getChildren();
            Iterator attrIter = attrList.iterator();

            // iterate through each role attribute
            while (attrIter.hasNext()) {
                NaElement attribute = (NaElement) attrIter.next();
                System.out
                        .println("----------------------------------------------------");
                NaElement rolenameID = attribute.getChildByName(
                        "role-name-and-id")
                        .getChildByName("rbac-role-resource");
                roleID = rolenameID.getChildContent("rbac-role-id");
                roleName = rolenameID.getChildContent("rbac-role-name");
                description = attribute.getChildContent("description");
                System.out.println("role name                         : "
                        + roleName);
                System.out.println("role id                           : "
                        + roleID);
                System.out.println("role description                  : "
                        + description + "\n");

                // iterate through the inherited roles
                List inheritedList = attribute
                        .getChildByName("inherited-roles").getChildren();
                Iterator inheritedIter = inheritedList.iterator();

                while (inheritedIter.hasNext()) {
                    NaElement inheritedRole = (NaElement) inheritedIter.next();
                    System.out.println("inherited role details:\n");
                    inhRoleID = inheritedRole.getChildContent("rbac-role-id");
                    inhRoleName = inheritedRole
                            .getChildContent("rbac-role-name");
                    System.out.println("inherited role name                : "
                            + inhRoleName);
                    System.out.println("inherited role id                  : "
                            + inhRoleID);
                }

                System.out.println("operation details:\n");
                List capList = attribute.getChildByName("capabilities")
                        .getChildren();

                Iterator capIter = capList.iterator();
                // iterate through the role capabilities
                while (capIter.hasNext()) {
                    NaElement capability = (NaElement) capIter.next();
                    NaElement operation = capability
                            .getChildByName("operation").getChildByName(
                                    "rbac-operation");
                    operationName = operation.getChildContent("operation-name");
                    NaElement operationNameDetails = operation.getChildByName(
                            "operation-name-details").getChildByName(
                            "rbac-operation-name-details");
                    operationDesc = operationNameDetails
                            .getChildContent("operation-description");
                    operationSyn = operationNameDetails
                            .getChildContent("operation-synopsis");
                    resourceType = operationNameDetails
                            .getChildContent("resource-type");

                    System.out.println("operation name                    :"
                            + operationName);
                    System.out.println("operation description             :"
                            + operationDesc);
                    System.out.println("operation synopsis                :"
                            + operationSyn);
                    System.out.println("resource type                     :"
                            + resourceType + "\n");
                }
            }
            System.out
                    .println("----------------------------------------------------");
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    // This funcion will add a new operation to the RBAC system.
    public static void operationAdd() {
        if (Args.length < 8) {
            usage();
            System.exit(2);
        }
        String name = Args[4];
        String desc = Args[5];
        String synopsis = Args[6];
        String type = Args[7];

        try {
            // construct the input rbac-operation-add API request
            NaElement input = new NaElement("rbac-operation-add");
            NaElement operation = new NaElement("operation");
            NaElement rbacOperation = new NaElement("rbac-operation");
            rbacOperation.addNewChild("operation-name", name);
            NaElement operationNameDetails = new NaElement(
                    "operation-name-details");
            NaElement rbacOperationNameDetails = new NaElement(
                    "rbac-operation-name-details");
            rbacOperationNameDetails.addNewChild("operation-description", desc);
            rbacOperationNameDetails
                    .addNewChild("operation-synopsis", synopsis);
            rbacOperationNameDetails.addNewChild("resource-type", type);
            input.addChildElem(operation);
            operation.addChildElem(rbacOperation);
            rbacOperation.addChildElem(operationNameDetails);
            operationNameDetails.addChildElem(rbacOperationNameDetails);

            // invoke the API request
            NaElement output = server.invokeElem(input);

            System.out.println("Operation added successfully!");
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    // This function will delete an existing operation.
    public static void operationDelete() {
        if (Args.length < 5) {
            usage();
            System.exit(2);
        }
        String name = Args[4];

        try {
            // create the input rbac-operation-delete API request
            NaElement input = new NaElement("rbac-operation-delete");
            input.addNewChild("operation", name);
            // invoke the API request
            NaElement output = server.invokeElem(input);
            System.out.println("\nOperation deleted successfully!");
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    // This function will list about an existing operation or
    // all operations in the system.
    public static void operationList() {
        String operation = null;
        String name = null;
        String desc = null;
        String type = null;
        String synopsis = null;

        if (Args.length == 5)
            operation = Args[4];

        try {
            // create the input API request
            NaElement input = new NaElement("rbac-operation-info-list");

            if (operation != null)
                input.addNewChild("operation", operation);

            // now invoke the api request and get the operations list
            NaElement output = server.invokeElem(input);

            List oprList = output.getChildByName("operation-list")
                    .getChildren();
            Iterator oprIter = oprList.iterator();

            // iterate through each operation
            System.out
                    .println("\n----------------------------------------------------");
            while (oprIter.hasNext()) {
                NaElement opr = (NaElement) oprIter.next();
                name = opr.getChildContent("operation-name");
                System.out.println("\nName             :" + name);
                List nameDetailList = opr.getChildByName(
                        "operation-name-details").getChildren();
                Iterator detailIter = nameDetailList.iterator();
                while (detailIter.hasNext()) {
                    NaElement detail = (NaElement) detailIter.next();
                    desc = detail.getChildContent("operation-description");
                    type = detail.getChildContent("resource-type");
                    synopsis = detail.getChildContent("operation-synopsis");
                    System.out.println("Description      : " + desc);
                    System.out.println("Synopsis         : " + synopsis);
                    System.out.println("Resource type    : " + type);
                }
            }
            System.out
                    .println("----------------------------------------------------");
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }

    // This function will print the usage string of the sample code.
    public static void usage() {
        System.out
                .println("\nUsage: \n rbac <dfm-server> <user> "
                        + "<password> operation-add  <oper> <oper-desc> <syp> <res-ype>");
        System.out.println(" rbac <dfm-server> <user> <password> "
                + "operation-list [<oper>]");
        System.out.println(" rbac <dfm-server> <user> <password> "
                + "operation-delete <oper>");
        System.out.println(" rbac <dfm-server> <user> <password> "
                + "role-add <role> <role-desc>");
        System.out.println(" rbac <dfm-server> <user> <password> "
                + "role-list [<role>]");
        System.out.println(" rbac <dfm-server> <user> <password> "
                + "role-delete <role>");
        System.out.println(" rbac <dfm-server> <user> <password> "
                + "role-capability-add <role> <oper> <res-type> <res-name> ");
        System.out.println(" rbac <dfm-server> <user> <password> "
                + "role-capability-delete <role> <oper> <res-type> <res-name>");
        System.out.println(" rbac <dfm-server> <user> <password> "
                + "admin-list [<admin>]");
        System.out.println(" rbac <dfm-server> <user> <password> "
                + "admin-role-add <admin> <role>");
        System.out.println(" rbac <dfm-server> <user> <password> "
                + "admin-role-list <admin>");
        System.out.println(" rbac <dfm-server> <user> <password> "
                + "admin-role-delete <admin> <role>\n");
        System.out.println(" <dfm-server>      -- Name/IP Address "
                + "of the DFM Server ");
        System.out.println(" <user>            -- DFM Server user name");
        System.out.println(" <password>        -- DFM Server password \n");
        System.out.println(" <oper>            -- Name of the operation."
                + " For example: \"DFM.SRM.Read\"");
        System.out.println(" <oper-desc>       -- operation description");
        System.out.println(" <role>            -- role name or id");
        System.out.println(" <role-desc>       - role description");
        System.out.println(" <syp>             -- operation synopsis");
        System.out.println(" <res-type>        -- resource type");
        System.out.println(" <res-name>        -- name of the resource");
        System.out.println(" <admin>           -- admin name or id");
        System.out.println(" Possible resource types are: dataset, filer\n");
        System.exit(1);
    }
}
