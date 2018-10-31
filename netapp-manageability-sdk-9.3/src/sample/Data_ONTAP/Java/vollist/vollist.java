/*
 * $Id:$
 *
 * vollist.java
 * Copyright (c) 2001-2007 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample for using the netapp.manage.* classes and ONTAPI
 * API to list Volume Information  
 */
import java.util.*;
import netapp.manage.*;

public class vollist {
    public static void main(String[] args) {
        NaElement xi;
        NaElement xo;
        NaServer s;

        if (args.length < 3) {
            System.out
                    .println("Usage : vollist <filername> <username> <passwd> [<volume>]");
            System.exit(1);
        }
        try {
            // Initialize connection to server, and
            // request version 1.3 of the API set
            //
            s = new NaServer(args[0], 1, 3);
            s.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            s.setAdminUser(args[1], args[2]);

            // Invoke Vol list Info ONTAPI API
            if (args.length == 4) {
                xi = new NaElement("volume-list-info");
                xi.addNewChild("volume", args[3]);
            } else {
                xi = new NaElement("volume-list-info");
            }
            xo = s.invokeElem(xi);
            //
            // Get the list of children from element(Here 'xo') and iterate
            // through each of the child element to fetch their values
            //
            List volList = xo.getChildByName("volumes").getChildren();
            Iterator volIter = volList.iterator();
            while (volIter.hasNext()) {
                NaElement volInfo = (NaElement) volIter.next();
                System.out.println("---------------------------------");
                System.out.print("Volume Name:");
                System.out.println(volInfo.getChildContent("name"));
                System.out.print("Volume State:");
                System.out.println(volInfo.getChildContent("state"));
                System.out.print("Disk Count:");
                System.out.println(volInfo.getChildIntValue("disk-count", -1));
                System.out.print("Total Files:");
                System.out.println(volInfo.getChildIntValue("files-total", -1));
                System.out.print("No of files used:");
                System.out.println(volInfo.getChildIntValue("files-used", -1));
            }
            s.close();
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}
