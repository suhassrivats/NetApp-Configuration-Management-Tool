/*
 * $Id:$
 *
 * vserver_tunnel.java
 * Copyright (c) 2011 NetApp, Inc.
 * All rights reserved.
 *
 * Sample code for vserver tunneling.
 * Any given API is executed on the specified Vserver
 * through the Cluster interface.
 */

import netapp.manage.*;

public class vserver_tunnel {

    public static void usage() {
        System.out
                .println("\nUsage:\n vserver-tunnel [-s] <vserver-name> <storage-system> <user> "
                        + "<password> <ONTAPI-name> [key value] ...");
        System.out.println(" -s : Use SSL\n");
        System.exit(1);
    }

    public static void main(String[] args) {
        NaElement xi;
        NaElement xo;
        NaServer s;
        int index;
        String options;
        int dossl = 0;

        if (args.length < 5) {
            usage();
        }

        index = args[0].indexOf('-');
        if (index == 0 && args[0].charAt(index) == '-') {
            options = args[0].substring(index + 1);
            if (options.equals("s") && args.length > 5) {
                dossl = 1;
            } else {
                usage();
            }
        }

        try {
            if (dossl == 1) {

                // Initialize connection to server, and
                // request version 1.15 of the API set for vserver-tunneling
                //
                s = new NaServer(args[2], 1, 15);
                s.setAdminUser(args[3], args[4]);
                s.setTransportType(NaServer.TRANSPORT_TYPE_HTTPS);
                s.setPort(443);
                s.setVserver(args[1]);

                // Invoke any ONTAPI API with arguments
                // in (key,value) pair
                // args[0]=option,args[1]=vserver-name,args[2]=vserver,
                // args[3]=user,args[4] = passwd, args[5]=Ontapi API,
                // args[6] onwards arguments in (key,value)
                // pair
                //
                xi = new NaElement(args[5]);

                try {
                    if (args.length > 6) {
                        for (int index1 = 6; index1 < args.length; index1++) {
                            xi.addNewChild(args[index1], args[index1 + 1]);
                            index1++;
                        }
                    }
                } catch (ArrayIndexOutOfBoundsException e) {
                    throw new NaAPIFailedException(-1,
                            "Mismatch in arguments passed "
                                    + "(in (key,value) Pair) to "
                                    + "Ontapi API");
                }
            } else {
                // Initialize connection to server, and
                // request version 1.15 of the API set for vserver-tunneling
                //
                s = new NaServer(args[1], 1, 15);
                s.setAdminUser(args[2], args[3]);
                s.setVserver(args[0]);

                // Invoke any ONTAPI API with arguments
                // in (key,value) pair
                // args[0]=filer,args[1]=user,args[2]=passwd
                // args[3]=Ontapi API,args[4] onward arguments
                // in (key,value) pair
                //
                xi = new NaElement(args[4]);
                try {
                    if (args.length > 5) {
                        for (int index2 = 5; index2 < args.length; index2++) {
                            xi.addNewChild(args[index2], args[index2 + 1]);
                            index2++;
                        }
                    }
                } catch (ArrayIndexOutOfBoundsException e) {
                    throw new NaAPIFailedException(-1,
                            "Mismatch in arguments passed "
                                    + "(in (key,value) Pair) to "
                                    + "Ontapi API");
                }
            }
            xo = s.invokeElem(xi);
            System.out.println(xo.toPrettyString(""));
            s.close();
        } catch (NaAPIFailedException e) {
            System.err.println(e.toString());
            System.exit(1);
        } catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}
