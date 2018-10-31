/*
 *
 * vserver.java
 *
 * Copyright (c) 2011 NetApp, Inc. All rights reserved.
 * Specifications subject to change without notice.
 *
 * This advanced sample code is used for vserver management in Cluster ONTAP. 
 * You can create or list vservers, add aggregates, create new volumes, 
 * configure LIFs, NFS service, nis domain and export rule for a vserver 
 * that are all required to export a vserver volume on a host for data 
 * access. 
 * You can even create new roles and users, and assign the roles to 
 * the new users for privileged access on vserver operations.
 * 
 * This Sample code is supported from Cluster-Mode  Data ONTAP 8.1 onwards.
 *
 */

import java.io.IOException;
import java.util.List;
import java.util.Iterator;

import netapp.manage.*;

public class vserver {
    static NaServer server;
    static String user;
    static String passwd;
    static String ipaddr;
    static String args[];

    public static void printUsageAndExit() {
        System.out.println("\nUsage: \n");
        System.out.println("vserver <cluster/vserver> <user> <passwd> show [-v <vserver-name>]");
        System.out.println("vserver <cluster> <user> <passwd> create <vserver-name> <root-vol-aggr> <root-vol> [<ns-switch1> <ns-switch2> ..]");
        System.out.println("vserver <cluster> <user> <passwd> start <vserver-name>");
        System.out.println("vserver <cluster> <user> <passwd> stop <vserver-name> \n");

        System.out.println("vserver <cluster> <user> <passwd> aggr-show");
        System.out.println("vserver <cluster> <user> <passwd> aggr-add <vserver-name> <aggr-name1> [<aggr-name2> ..] \n");

        System.out.println("vserver <cluster/vserver> <user> <passwd> vol-create [-v <vserver-name>] <aggr-name> <vol-name> <size>");
        System.out.println("vserver <cluster/vserver> <user> <passwd> vol-show [-v <vserver-name>]\n");

        System.out.println("vserver <cluster> <user> <passwd> node-show \n");

        System.out.println("vserver <cluster> <user> <passwd> lif-create <vserver-name> <lif-name> <ip-addr> <netmask> <gateway> <home-node> <home-port>");
        System.out.println("vserver <cluster/vserver> <user> <passwd> lif-show [-v <vserver-name>] \n");

        System.out.println("vserver <cluster/vserver> <user> <passwd> nfs-configure [-v <vserver-name>]");
        System.out.println("vserver <cluster/vserver> <user> <passwd> nfs-enable [-v <vserver-name>]");
        System.out.println("vserver <cluster/vserver> <user> <passwd> nfs-disable [-v <vserver-name>]");
        System.out.println("vserver <cluster/vserver> <user> <passwd> nfs-show [-v <vserver-name>] \n");

        System.out.println("vserver <cluster/vserver> <user> <passwd> nis-create [-v <vserver-name>] <nis-domain> <is-active-domain> <nis-server-ip>");
        System.out.println("vserver <cluster/vserver> <user> <passwd> nis-show [-v <vserver-name>] \n");

        System.out.println("vserver <cluster/vserver> <user> <passwd> export-rule-create [-v <vserver-name>]");
        System.out.println("vserver <cluster/vserver> <user> <passwd> export-rule-show [-v <vserver-name>] \n");

        System.out.println("vserver <cluster> <user> <passwd> role-create <role-name> [<cmd-dir-name1> <cmd-dir-name2> ..] ");
        System.out.println("vserver <cluster> <user> <passwd> role-show [<vserver-name>]");
        System.out.println("vserver <cluster> <user> <passwd> user-create <user-name> <password> <role-name>");
        System.out.println("vserver <cluster> <user> <passwd> user-show [<vserver-name>]\n");

        System.out.println("<cluster>             -- IP address of the cluster");
        System.out.println("<vserver>             -- IP address of the vserver");
        System.out.println("<user>                -- User name");
        System.out.println("<passwd>              -- Password");
        System.out.println("<vserver-name>        -- Name of the vserver");
        System.out.println("<root-vol-aggr>       -- Aggregate on which the root volume will be created");
        System.out.println("<root-vol>            -- New root volume of the vserver");
        System.out.println("<vol-name>            -- Name of the volume to create");
        System.out.println("<aggr-name>           -- Name of the aggregate to add");
        System.out.println("<ns-switch>           -- Name Server switch configuration details for the vserver. Possible values: 'nis', 'file', 'ldap'");
        System.out.println("<size>                -- The initial size (in bytes) of the new flexible volume");
        System.out.println("<is-active-domain>    -- Specifies whether the NIS domain configuration is active or inactive");
        System.out.println("<cmd-dir-name>        -- The command or command directory to which the role has an access");
        System.out.println("Note: ");
        System.out.println(" -v switch is required when you want to tunnel the command to a vserver using cluster interface.");
        System.out.println(" You need not specify <vserver-name> when you target the command to a vserver interface.");
        System.out.println(" 'role-create' option creates a new role with default access for vserver get, start, stop and volume get operations.");
        System.out.println(" 'create' option creates a new vserver with default ns-switch value as 'file' and security-style as 'unix'. \n");
        System.exit(-1);
    }

    public static void showVservers() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in, out;
        String rootVol, rootVolAggr, secStyle, state;
        String tag = "";

        while (tag != null) {
            in = new NaElement("vserver-get-iter");
            if (args.length > 4) {
                if (args.length < 6 || !args[4].equals("-v")) {
                    printUsageAndExit();
                }
                server.setVserver(args[5]);
            }
            if (!tag.equals("")) {
                in.addNewChild("tag", tag);
            }
            out = server.invokeElem(in);
            if (out.getChildIntValue("num-records", 0) == 0) {
                System.out.println("No vserver(s) information available\n");
                return;
            }
            tag = out.getChildContent("next-tag");
            List vserverList = out.getChildByName("attributes-list").getChildren();
            Iterator vserverIter = vserverList.iterator();
            System.out.println("----------------------------------------------------");
            while(vserverIter.hasNext()) {
                NaElement vserverInfo =(NaElement)vserverIter.next();
                System.out.println("Name                    : " + vserverInfo.getChildContent("vserver-name"));
                System.out.println("Type                    : " + vserverInfo.getChildContent("vserver-type"));
                rootVolAggr = vserverInfo.getChildContent("root-volume-aggregate");
                rootVol = vserverInfo.getChildContent("root-volume");
                secStyle = vserverInfo.getChildContent("root-volume-security-style");
                state = vserverInfo.getChildContent("state");
                System.out.println("Root volume aggregate   : " + (rootVolAggr != null ? rootVolAggr : ""));
                System.out.println("Root volume             : " + (rootVol != null ? rootVol : ""));
                System.out.println("Root volume sec style   : " + (secStyle != null ? secStyle : ""));
                System.out.println("UUID                    : " + vserverInfo.getChildContent("uuid"));
                System.out.println("State                   : " + (state != null ? state : ""));
                NaElement aggregates = null;
                System.out.print("Aggregates              : ");
                if ((aggregates = vserverInfo.getChildByName("aggr-list")) != null) {
                    List aggrList = aggregates.getChildren();
                    Iterator aggrIter = aggrList.iterator();
                    while(aggrIter.hasNext()){
                        NaElement aggr = (NaElement) aggrIter.next();
                        System.out.print(aggr.getContent() + " ");
                    }
                }
                NaElement allowedProtocols = null;
                System.out.print("\nAllowed protocols       : ");
                if ((allowedProtocols = vserverInfo.getChildByName("allowed-protocols")) != null) {
                    List allowedProtocolsList = allowedProtocols.getChildren();
                    Iterator allowedProtocolsIter = allowedProtocolsList.iterator();
                    while(allowedProtocolsIter.hasNext()){
                        NaElement protocol = (NaElement) allowedProtocolsIter.next();
                        System.out.print(protocol.getContent() + " ");
                    }
                }
                System.out.print("\nName server switch      : ");
                NaElement nameServerSwitch = null;
                if ((nameServerSwitch = vserverInfo.getChildByName("name-server-switch")) != null) {
                    List nsSwitchList = nameServerSwitch.getChildren();
                    Iterator nsSwitchIter = nsSwitchList.iterator();
                    while(nsSwitchIter.hasNext()){
                        NaElement nsSwitch = (NaElement) nsSwitchIter.next();
                        System.out.print(nsSwitch.getContent() + " ");
                    }
                }
                System.out.println("\n----------------------------------------------------");
            }
        }
    }

    public static void createVserver() throws NaProtocolException, 
            NaAuthenticationException, NaAPIFailedException, IOException {
        int index = 4;
        NaElement in = new NaElement("vserver-create");
        NaElement nameSrvSwitch = new NaElement("name-server-switch");
        in.addNewChild("vserver-name", args[index++]);
        in.addNewChild("root-volume-aggregate", args[index++]);
        in.addNewChild("root-volume", args[index++]);
        if (args.length == 7) {
            nameSrvSwitch.addNewChild("nsswitch", "file");
        }
        else {
            while (index < args.length) {
                nameSrvSwitch.addNewChild("nsswitch", args[index++]);
            }
        }
        in.addChildElem(nameSrvSwitch);
        in.addNewChild("root-volume-security-style", "unix");
        server.invokeElem(in);
        System.out.println("Vserver created successfully!");
    }

    public static void startVserver() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in = new NaElement("vserver-start");
        in.addNewChild("vserver-name", args[4]);
        server.invokeElem(in);
        System.out.println("Vserver started successfully!");
    }

    public static void stopVserver() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in = new NaElement("vserver-stop");
        in.addNewChild("vserver-name", args[4]);
        server.invokeElem(in);
        System.out.println("Vserver stopped successfully!");
    }

    public static void createVolume() throws NaProtocolException, 
        NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in = new NaElement("volume-create");
        int index = 4;
        String volume;

        if (args.length == 9) {
            if (!args[index].equals("-v")) {
                printUsageAndExit();
            }
            index++;
            server.setVserver(args[index++]);
        }
        in.addNewChild("containing-aggr-name", args[index++]);
        volume = args[index++];
        in.addNewChild("volume", volume);
        in.addNewChild("size", args[index++]);
        in.addNewChild("junction-path", "/" + volume);
        server.invokeElem(in);
        System.out.println("Volume created successfully!");
    }

    public static void showVolumes() throws NaProtocolException, 
            NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in, out;
        String tag = "";
        String vserverName, volName, aggrName, volType, volState, size, availSize;

        while (tag != null) {
            if (args.length > 4) {
                if (args.length < 6 || !args[4].equals("-v")) {
                    printUsageAndExit();
                }
                server.setVserver(args[5]);
            }
            in = new NaElement("volume-get-iter");
            if (!tag.equals("")) {
                in.addNewChild("tag", tag);
            }
            out = server.invokeElem(in);
            if (out.getChildIntValue("num-records", 0) == 0) {
                System.out.println("No vserver(s) information available\n");
                return;
            }
            tag = out.getChildContent("next-tag");
            List volList = out.getChildByName("attributes-list").getChildren();
            Iterator volIter = volList.iterator();
            System.out.println("----------------------------------------------------");
            while(volIter.hasNext()) {
                NaElement volInfo =(NaElement)volIter.next();
                vserverName = volName = aggrName = volType = volState = size = availSize = "";
                NaElement volIdAttrs = volInfo.getChildByName("volume-id-attributes");
                if (volIdAttrs != null) {
                    vserverName = volIdAttrs.getChildContent("owning-vserver-name");
                    volName = volIdAttrs.getChildContent("name");
                    aggrName = volIdAttrs.getChildContent("containing-aggregate-name");
                    volType = volIdAttrs.getChildContent("type");
                }
                System.out.println("Vserver Name            : " + (vserverName != null ? vserverName : ""));
                System.out.println("Volume Name             : " + (volName != null ? volName : ""));
                System.out.println("Aggregate Name          : " + (aggrName != null ? aggrName : ""));
                System.out.println("Volume type             : " + (volType != null ? volType : ""));
                NaElement volStateAttrs = volInfo.getChildByName("volume-state-attributes");
                if (volStateAttrs != null) {
                    volState = volStateAttrs.getChildContent("state");
                }
                System.out.println("Volume state            : " + (volState != null ? volState : ""));
                NaElement volSizeAttrs = volInfo.getChildByName("volume-space-attributes");
                if (volSizeAttrs != null) {
                    size = volSizeAttrs.getChildContent("size");
                    availSize = volSizeAttrs.getChildContent("size-available");
                }
                System.out.println("Size (bytes)            : " + (size != null ? size : ""));
                System.out.println("Available Size (bytes)  : " + (availSize != null ? availSize : ""));
                System.out.println("----------------------------------------------------");
            }
        }
    }

    public static String getAdminVserver() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {

                NaElement in = new NaElement("vserver-get-iter");
        NaElement query = new NaElement("query");
        NaElement qinfo = new NaElement("vserver-info");
        qinfo.addNewChild("vserver-type", "admin");
        query.addChildElem(qinfo);

        NaElement desiredAttrs = new NaElement("desired-attributes");
        NaElement dinfo = new NaElement("vserver-info");
        dinfo.addNewChild("vserver-name", "");
        desiredAttrs.addChildElem(dinfo);
        in.addChildElem(query);
        in.addChildElem(desiredAttrs);

        NaElement out = server.invokeElem(in);
        NaElement attr = out.getChildByName("attributes-list");
        NaElement vserverInfo = attr.getChildByName("vserver-info");
        String vserver = vserverInfo.getChildContent("vserver-name");
        return vserver;
    }

    public static void createRole() throws NaProtocolException, 
        NaAuthenticationException, NaAPIFailedException, IOException {
        String vserver = getAdminVserver();
        NaElement in = null;
        String roleName = args[4];
        int index = 0;
        String cmddir, accessLevel = "all";

        // create a role by default for vserver start and stop access
        if (args.length < 6) {
            while (index++ < 4) {
                accessLevel = "all";
                if (index == 1) {
                    cmddir = "vserver show";
                    accessLevel = "readonly";
                 }
                 else if (index == 2) {
                    cmddir = "vserver start";
                 }
                 else if (index == 3)
                    cmddir = "vserver stop";
                else {
                    cmddir = "volume show";
                    accessLevel = "readonly";
                }
                in = new NaElement("security-login-role-create");
                in.addNewChild("vserver", vserver);
                in.addNewChild("role-name", roleName);
                in.addNewChild("command-directory-name", cmddir);
                in.addNewChild("access-level", accessLevel);
                server.invokeElem(in);
            }
        } else {
            index = 5;
            while (index < args.length) {
                in = new NaElement("security-login-role-create");
                in.addNewChild("vserver", vserver);
                in.addNewChild("role-name", roleName);
                in.addNewChild("command-directory-name", args[index++]);
                in.addNewChild("access-level", "all");
                server.invokeElem(in);
            }
        }
        System.out.println("Role created successfully!");
    }

    public static void showRoles() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in, out;
        String tag = "";

        while (tag != null) {
            in = new NaElement("security-login-role-get-iter");
            if (args.length >= 5) {
                NaElement query = new NaElement("query");
                NaElement info = new NaElement("security-login-role-info");
                info.addNewChild("vserver", args[4]);
                query.addChildElem(info);
                in.addChildElem(query);
            }
            if (!tag.equals("")) {
                in.addNewChild("tag", tag);
            }
            out = server.invokeElem(in);
            if (out.getChildIntValue("num-records", 0) == 0) {
                System.out.println("No role(s) information available\n");
                return;
            }
            tag = out.getChildContent("next-tag");
            List roleList = out.getChildByName("attributes-list").getChildren();
            Iterator roleIter = roleList.iterator();
            System.out.println("----------------------------------------------------");
            while(roleIter.hasNext()) {
                NaElement roleInfo =(NaElement)roleIter.next();
                System.out.println("Role Name               : " + roleInfo.getChildContent("role-name"));
                System.out.println("Vserver                 : " + roleInfo.getChildContent("vserver"));
                System.out.println("Command                 : " + roleInfo.getChildContent("command-directory-name"));
                System.out.println("Query                   : " + roleInfo.getChildContent("role-query"));
                System.out.println("Access Level            : " + roleInfo.getChildContent("access-level"));
                System.out.println("----------------------------------------------------");
            }
        }
    }

    public static void createUser() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        int index = 4;

        String vserver = getAdminVserver();
        NaElement in = new NaElement("security-login-create");
        in.addNewChild("application", "ontapi");
        in.addNewChild("authentication-method", "password");
        in.addNewChild("vserver", vserver);
        in.addNewChild("user-name", args[index++]);
        in.addNewChild("password", args[index++]);
        in.addNewChild("role-name", args[index++]);

        server.invokeElem(in);
        System.out.println("User created successfully!");
}

    public static void showUsers() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in, out;

        in = new NaElement("security-login-get-iter");
        if (args.length >= 5) {
            NaElement query = new NaElement("query");
            NaElement info = new NaElement("security-login-account-info");
            info.addNewChild("vserver", args[4]);
            query.addChildElem(info);
            in.addChildElem(query);
        }
        out = server.invokeElem(in);
        if (out.getChildIntValue("num-records", 0) == 0) {
            System.out.println("No user(s) information available\n");
            return;
        }
        List userList = out.getChildByName("attributes-list").getChildren();
        Iterator userIter = userList.iterator();
        System.out.println("----------------------------------------------------");
        while(userIter.hasNext()){
            NaElement accountInfo =(NaElement)userIter.next();
            System.out.println("User Name               : " + accountInfo.getChildContent("user-name"));
            System.out.println("Role Name               : " + accountInfo.getChildContent("role-name"));
            System.out.println("Vserver                 : " + accountInfo.getChildContent("vserver"));
            System.out.println("Account Locked          : " + accountInfo.getChildContent("is-locked"));
            System.out.println("Application             : " + accountInfo.getChildContent("application"));
            System.out.println("Authentication          : " + accountInfo.getChildContent("authentication-method"));
            System.out.println("----------------------------------------------------");
        }
    }

    public static void configureNFS() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in = new NaElement("nfs-service-create");

        if (args.length > 4) {
            if (args.length < 6 || !args[4].equals("-v")) {
                printUsageAndExit();
            }
            server.setVserver(args[5]);
        }
        server.invokeElem(in);
        System.out.println("NFS service created successfully!");
    }

    public static void enableNFS() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in = new NaElement("nfs-enable");

        if (args.length > 4) {
            if (args.length < 6 || !args[4].equals("-v")) {
                printUsageAndExit();
            }
            server.setVserver(args[5]);
        }
        server.invokeElem(in);
        System.out.println("NFS service enabled successfully!");
    }

    public static void disableNFS() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in = new NaElement("nfs-disable");

        if (args.length > 4) {
            if (args.length < 6 || !args[4].equals("-v")) {
                printUsageAndExit();
            }
            server.setVserver(args[5]);
        }
        server.invokeElem(in);
        System.out.println("NFS service disabled successfully!");
    }

    public static void showNFS() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in, out;
        in = new NaElement("nfs-service-get");

        if (args.length > 4) {
            if (args.length < 6 || !args[4].equals("-v")) {
                printUsageAndExit();
            }
            server.setVserver(args[5]);
        }
        out = server.invokeElem(in);
        NaElement attrs = out.getChildByName("attributes");
        if (attrs == null) {
            System.out.println("NFS information in not available\n");
        }
        NaElement nfsInfo = attrs.getChildByName("nfs-info");
        String nfsAccess = "enabled";
        if (nfsInfo.getChildContent("is-nfs-access-enabled").compareToIgnoreCase("false") == 0)
            nfsAccess = "disabled";
        String nfsv3 = "enabled";
        if (nfsInfo.getChildContent("is-nfsv3-enabled").compareToIgnoreCase("false") == 0)
            nfsv3 = "disabled";
        String nfsv4 = "enabled";
        if (nfsInfo.getChildContent("is-nfsv40-enabled").compareToIgnoreCase("false") == 0)
            nfsv4 = "disabled";
        System.out.println("----------------------------------------------------");
        System.out.println("Vserver Name            : " + nfsInfo.getChildContent("vserver"));
        System.out.println("General NFS access      : " + nfsAccess);
        System.out.println("NFS v3                  : " + nfsv3);
        System.out.println("NFS v4.0                : " + nfsv4);
        System.out.println("----------------------------------------------------");
    }

    public static void createLIF() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        int index = 4;
        String vserver, ipAddr, gateway;

        NaElement in = new NaElement("net-interface-create");
        //<cluster> <user> <passwd> lif-create <vserver-name>  <lif-name> <ip-addr> <netmask> <gateway> <home-node> <home-port>");
        vserver = args[index++];
        in.addNewChild("vserver", vserver);
        in.addNewChild("interface-name", args[index++]);
        ipAddr = args[index++];
        in.addNewChild("address", ipAddr);
        in.addNewChild("netmask", args[index++]);
        gateway = args[index++];
        in.addNewChild("home-node", args[index++]);
        in.addNewChild("home-port", args[index++]);
        in.addNewChild( "firewall-policy", "mgmt");
        in.addNewChild("role", "data");
        in.addNewChild("return-record", "true");
        NaElement out = server.invokeElem(in);
 
        NaElement netLifInfo = out.getChildByName("result").getChildByName("net-interface-info");
        String routingGroup = netLifInfo.getChildContent("routing-group-name");
        in = new NaElement("net-routing-group-route-get-iter");
        NaElement query = new NaElement("query");
        NaElement info = new NaElement("routing-group-route-info");
        info.addNewChild("routing-group", routingGroup);
        info.addNewChild("vserver", vserver);
        query.addChildElem(info);
        in.addChildElem(query);
        out = server.invokeElem(in);
        if (out.getChildIntValue("num-records", 0) != 0) {
            System.out.println("LIF created successfully!");
            return;
        }
        in = new NaElement("net-routing-group-route-create");
        in.addNewChild("vserver", vserver);
        String destAddr = "0.0.0.0" + "/" + "0";
        in.addNewChild("destination-address", destAddr);
        in.addNewChild( "gateway-address", gateway);
        in.addNewChild("routing-group", routingGroup);
        server.invokeElem(in);
        System.out.println("LIF created successfully!");
    }

    public static void showLIFs() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in, out;
        String tag = "";

        while (tag != null) {
            if (args.length > 4) {
                if (args.length < 6 || !args[4].equals("-v")) {
                    printUsageAndExit();
                }
                server.setVserver(args[5]);
            }
            in = new NaElement("net-interface-get-iter");
            if (!tag.equals("")) {
                in.addNewChild("tag", tag);
            }
            out = server.invokeElem(in);
            if (out.getChildIntValue("num-records", 0) == 0) {
                System.out.println("No interface information available\n");
                return;
            }
            tag = out.getChildContent("next-tag");
            List lifList = out.getChildByName("attributes-list").getChildren();
            Iterator lifIter = lifList.iterator();
            System.out.println("----------------------------------------------------");
            while(lifIter.hasNext()) {
                NaElement lifInfo =(NaElement)lifIter.next();
                System.out.println("Vserver Name            : " + lifInfo.getChildContent("vserver"));
                System.out.println("Logical Interface Name  : " + lifInfo.getChildContent("interface-name"));
                System.out.println("Address                 : " + lifInfo.getChildContent("address"));
                System.out.println("Netmask                 : " + lifInfo.getChildContent("netmask"));
                System.out.println("Routing Group Name      : " + lifInfo.getChildContent("routing-group-name"));
                System.out.println("Firewall Policy         : " + lifInfo.getChildContent("firewall-policy"));
                System.out.println("Administrative Status   : " + lifInfo.getChildContent("administrative-status"));
                System.out.println("Operational Status      : " + lifInfo.getChildContent("operational-status"));
                System.out.println("Current Node            : " + lifInfo.getChildContent("current-node"));
                System.out.println("Current Port            : " + lifInfo.getChildContent("current-port"));
                System.out.println("Is Home                 : " + lifInfo.getChildContent("is-home"));
                System.out.println("\n----------------------------------------------------");
            }
        }
    }

    public static void showAggregates() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in, out;
        String tag = "";

        while (tag != null) {
            in = new NaElement("aggr-get-iter");
            if (!tag.equals("")) {
                in.addNewChild("tag", tag);
            }
            out = server.invokeElem(in);
            if (out.getChildIntValue("num-records", 0) == 0) {
                System.out.println("No aggregate(s) information available\n");
                return;
            }
            tag = out.getChildContent("next-tag");
            List aggrList = out.getChildByName("attributes-list").getChildren();
            Iterator aggrIter = aggrList.iterator();
            System.out.println("----------------------------------------------------");
            while(aggrIter.hasNext()) {
                NaElement aggrInfo =(NaElement)aggrIter.next();
                System.out.println("Aggregate Name          : " + aggrInfo.getChildContent("aggregate-name"));
                NaElement aggrSizeAttrs = aggrInfo.getChildByName("aggr-space-attributes");
                System.out.println("Size (bytes)            : " + aggrSizeAttrs.getChildContent("size-total"));
                System.out.println("Available Size (bytes)  : " + aggrSizeAttrs.getChildContent("size-available"));
                System.out.println("Used Percentage         : " + aggrSizeAttrs.getChildContent("percent-used-capacity"));
                NaElement aggrRaidAttrs = aggrInfo.getChildByName("aggr-raid-attributes");
                System.out.println("Aggregate State         : " + aggrRaidAttrs.getChildContent("state"));
                System.out.println("----------------------------------------------------");
            }
        }
    }

    public static void addAggregates() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        int index = 4;
        NaElement in = new NaElement("vserver-modify");

        in.addNewChild("vserver-name", args[index++]);
        NaElement aggrList = new NaElement("aggr-list");
        while (index < args.length) {
            aggrList.addNewChild("aggr-name", args[index++]);
        }
        in.addChildElem(aggrList);
        server.invokeElem(in);
        System.out.println("Aggregate(s) added successfully!");
    }

    public static void createNIS() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        int index = 4;
        NaElement in = new NaElement("nis-create");

        if (args[4].equals("-v")) {
            if (args.length < 9) {
                printUsageAndExit();
            }
            index++;
            server.setVserver(args[index++]);
        }
        in.addNewChild("nis-domain", args[index++]);
        in.addNewChild("is-active", args[index++]);
        NaElement nisServers = new NaElement("nis-servers");
        nisServers.addNewChild("ip-address", args[index++]);
        in.addChildElem(nisServers);
         server.invokeElem(in);
        System.out.println("NIS domain created successfully!");
    }

    public static void showNIS() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in, out;
        String tag = "";
 
        while (tag != null) {
            in = new NaElement("nis-get-iter");
            if (args.length > 4) {
                if (args.length < 6 || !args[4].equals("-v")) {
                    printUsageAndExit();
                }
                server.setVserver(args[5]);
            }
            if (!tag.equals("")) {
                in.addNewChild("tag", tag);
            }
            out = server.invokeElem(in);
            if (out.getChildIntValue("num-records", 0) == 0) {
                System.out.println("No nis domain information available\n");
                return;
            }
            tag = out.getChildContent("next-tag");
            List nisDomainList = out.getChildByName("attributes-list").getChildren();
            Iterator nisDomainIter = nisDomainList.iterator();
            System.out.println("----------------------------------------------------");
            while(nisDomainIter.hasNext()) {
                NaElement nisDomainInfo =(NaElement)nisDomainIter.next();
                System.out.println("NIS Domain              : " + nisDomainInfo.getChildContent("nis-domain"));
                System.out.println("Is Active               : " + nisDomainInfo.getChildContent("is-active"));
                System.out.println("Vserver                 : " + nisDomainInfo.getChildContent("vserver"));
                System.out.print("NIS Server(s)           : ");
                NaElement nisServers = nisDomainInfo.getChildByName("nis-servers");
                if (nisServers != null) {
                    List ipaddrList = nisServers.getChildren();
                    Iterator ipaddrIter = ipaddrList.iterator();
                    while(ipaddrIter.hasNext()) {
                        NaElement ipaddr =(NaElement)ipaddrIter.next();
                        System.out.print(ipaddr.getContent() + " ");
                    }
                }
                System.out.println("\n----------------------------------------------------");
            }
        }
    }

    public static void createExportRule() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        if (args.length > 4) {
            if (args.length < 6 || !args[4].equals("-v")) {
                printUsageAndExit();
            }
            server.setVserver(args[5]);
        }
        NaElement in = new NaElement("export-rule-create");
        in.addNewChild("policy-name", "default");
        in.addNewChild("client-match", "0.0.0/0");
        in.addNewChild("rule-index", "1");
        NaElement roRule = new NaElement("ro-rule");
        roRule.addNewChild("security-flavor", "any");
        NaElement rwRule = new NaElement("rw-rule");
        rwRule.addNewChild("security-flavor", "any");
        in.addChildElem(roRule);
        in.addChildElem(rwRule);

        server.invokeElem(in);
        System.out.println("Export rule created successfully!");
    }

    public static void showExportRules() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in, out;
        String tag = "";

        while (tag != null) {
            if (args.length > 4) {
                if (args.length < 6 || !args[4].equals("-v")) {
                    printUsageAndExit();
                }
                server.setVserver(args[5]);
            }
            in = new NaElement("export-rule-get-iter");
            if (!tag.equals("")) {
                in.addNewChild("tag", tag);
            }
            out = server.invokeElem(in);
            if (out.getChildIntValue("num-records", 0) == 0) {
                System.out.println("No export rule(s) information available\n");
                return;
            }
            tag = out.getChildContent("next-tag");
            List exportRuleList = out.getChildByName("attributes-list").getChildren();
            Iterator exportRuleIter = exportRuleList.iterator();
            System.out.println("----------------------------------------------------");
            while(exportRuleIter.hasNext()){
                NaElement exportRuleInfo =(NaElement)exportRuleIter.next();
                System.out.println("Vserver                 : " + exportRuleInfo.getChildContent("vserver-name"));
                System.out.println("Policy Name             : " + exportRuleInfo.getChildContent("policy-name"));
                System.out.println("Rule Index              : " + exportRuleInfo.getChildContent("rule-index"));
                List protocolList = exportRuleInfo.getChildByName("protocol").getChildren();
                Iterator protocolIter = protocolList.iterator();
                System.out.print("Access Protocols        : ");
                while(protocolIter.hasNext()){
                    NaElement protocol =(NaElement)protocolIter.next();
                    System.out.print(protocol.getContent() + " ");
                }
                System.out.println("\nClient Match Spec       : " + exportRuleInfo.getChildContent("client-match"));
                List roRuleList = exportRuleInfo.getChildByName("ro-rule").getChildren();
                Iterator roRuleIter = roRuleList.iterator();
                System.out.print("RO Access Rule          : ");
                while(roRuleIter.hasNext()){
                    NaElement roRule =(NaElement)roRuleIter.next();
                    System.out.print(roRule.getContent() + " ");
                }
                System.out.println("\n----------------------------------------------------");
            }
        }
    }

    public static void showNodes() throws NaProtocolException, 
                NaAuthenticationException, NaAPIFailedException, IOException {
        NaElement in, out;
        String tag = "";

        while (tag != null) {
            in = new NaElement("system-node-get-iter");
            if (!tag.equals("")) {
                in.addNewChild("tag", tag);
            }
            out = server.invokeElem(in);
            if (out.getChildIntValue("num-records", 0) == 0) {
                System.out.println("No node(s) information available\n");
                return;
            }
            tag = out.getChildContent("next-tag");
            List nodeInfoList = out.getChildByName("attributes-list").getChildren();
            Iterator nodeInfoIter = nodeInfoList.iterator();
            System.out.println("----------------------------------------------------");
            while(nodeInfoIter.hasNext()) {
                NaElement nodeInfo =(NaElement)nodeInfoIter.next();
                System.out.println("Node Name               : " + nodeInfo.getChildContent("node"));
                System.out.println("UUID                    : " + nodeInfo.getChildContent("node-uuid"));
                System.out.println("----------------------------------------------------");
            }
        }
    }

    public static void main(String[] vargs) {
        int index = 0;
        String command;
        args = vargs;

        if (args.length < 4) {
            printUsageAndExit();
        }
        try {
            server = new NaServer(args[index++], 1, 15);
            server.setAdminUser(args[index++], args[index++]);
            command  = args[index++];
            if (command.equals("show")) {
                showVservers();
            } else if (command.equals("create") && (args.length >= 7)) {
                createVserver();
            } else if (command.equals("start") && (args.length >= 5)) {
                startVserver();
            } else if (command.equals("stop") && (args.length >= 5)) {
                stopVserver();
            } else if (command.equals("vol-create") && (args.length == 7 || args.length == 9)) {
                createVolume();
            } else if (command.equals("role-create") && (args.length >= 5)) {
                createRole();
            } else if (command.equals("role-show")) {
                showRoles();
            } else if (command.equals("user-create") && (args.length >= 7)) {
                createUser();
            } else if (command.equals("user-show")) {
                showUsers();
            } else if (command.equals("nfs-configure")) {
                configureNFS();
            } else if (command.equals("nfs-enable")) {
                enableNFS();
            } else if (command.equals("nfs-disable")) {
                disableNFS();
            } else if (command.equals("nfs-show")) {
                showNFS();
            } else if (command.equals("vol-show")) {
                showVolumes();
            } else if (command.equals("lif-create") && (args.length >= 11)) {
                createLIF();
            } else if (command.equals("lif-show")) {
                showLIFs();
            } else if (command.equals("aggr-show")) {
                showAggregates();
            } else if (command.equals("aggr-add") && (args.length >= 6)) {
                addAggregates();
            } else if (command.equals("nis-create") && (args.length >= 7)) {
                createNIS();
            } else if (command.equals("nis-show")) {
                showNIS();
            } else if (command.equals("export-rule-create")) {
                createExportRule();
            } else if (command.equals("export-rule-show")) {
                showExportRules();
            } else if (command.equals("node-show")) {
                showNodes();
            } else {
                printUsageAndExit();
            }
        } catch (Exception e) {
          e.printStackTrace();
        }
    }
}
