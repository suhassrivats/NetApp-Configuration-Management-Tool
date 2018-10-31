/*
 * $Id:$
 *
 * system_mode.java
 * Copyright (c) 2011 NetApp, Inc.
 * All rights reserved.
 *
 * This sample code prints the mode of the Storage system
 * (7-Mode or Cluster-Mode)
 *
 */
import netapp.manage.*;

public class system_mode {
    public static void main(String[] args) {
        NaElement xi;
        NaElement xo;
        NaServer s;

        if (args.length < 3) {
            System.err.println("Usage: system_mode <storage-system> <user> <password>");
            System.exit(1);
        }
        try {
            s = new NaServer(args[0], 1, 0);
            s.setAdminUser(args[1], args[2]);

            xi = new NaElement("system-get-version");
            xo = s.invokeElem(xi);
            String isClustered = xo.getChildContent("is-clustered");
            if(isClustered != null && isClustered.equals("true")) {
                System.out.print("The Storage System " + args[0] + " is in \"Cluster-Mode\"\n");
            } else {
                System.out.println("The Storage System " + args[0] + " is in \"7-Mode\"\n");
            }
            s.close();
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}
