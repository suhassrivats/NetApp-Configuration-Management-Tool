/*
 * $Id:$
 *
 * quotalist.java
 * Copyright (c) 2001-2007 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample for using the netapp.manage.* classes and ONTAPI
 * API to list Quota Information  
 */
import java.util.*;
import netapp.manage.*;

public class quotalist {
    public static void main(String[] args) {
        NaElement xi;
        NaElement xo;
        NaServer s;

        if (args.length < 3) {
            System.err.println("Usage: quotalist filer user passwd");
            System.exit(1);
        }
        try {
            // Initialize connection to server, and
            // request version 1.3 of the API set
            //
            s = new NaServer(args[0], 1, 3);
            s.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
            s.setAdminUser(args[1], args[2]);

            // Invoke Quota list Info ONTAP API
            xi = new NaElement("quota-list-entries");
            xo = s.invokeElem(xi);
            //
            // Get the list of children from element(Here 'xo') and iterate
            // through each of the child element to fetch their values
            //
            List quotaList = xo.getChildByName("quota-entries").getChildren();
            Iterator quotaIter = quotaList.iterator();
            while (quotaIter.hasNext()) {
                NaElement quotaInfo = (NaElement) quotaIter.next();
                System.out.println("---------------------------------");
                System.out.print("Quota Target:");
                System.out.println(quotaInfo.getChildContent("quota-target"));
                System.out.print("Quota Type:");
                System.out.println(quotaInfo.getChildContent("quota-type"));
                System.out.print("Volume Name:");
                System.out.println(quotaInfo.getChildContent("volume"));
            }
            s.close();
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}
