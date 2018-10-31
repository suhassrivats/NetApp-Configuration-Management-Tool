/*
 * $Id: //depot/prod/zephyr/belair/src/sample/java/vfiler_tunnel/vfiler_tunnel.java#1 $
 *
 * vfiler_tunnel.java
 * Copyright (c) 2001-2007 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample for using the netapp.manage.* classes to
 * any ONTAPI API
 */
import netapp.manage.*;

public class vfiler_tunnel {

    public static void usage() {
        System.out
                .println("\nUsage:vfiler-tunnel {options} <vfiler-name> <filer> <user> "
                        + "<password> <ONTAPI-name> [key value] ...");
        System.out.println("\nOptions:");
        System.out.println("\n -s Use SSL\n");
        System.exit(1);
    }

    public static void main(String[] args) {
        NaElement xi;
        NaElement xo;
        NaServer s;
        int index;
        String options;
        int dos1 = 0;

        if (args.length < 5) {
            usage();
        }

        index = args[0].indexOf('-');
        if (index == 0 && args[0].charAt(index) == '-') {
            options = args[0].substring(index + 1);
            if (options.equals("s") && args.length > 5) {
                dos1 = 1;
            } else {
                usage();
            }
        }

        try {
            if (dos1 == 1) {

                // Initialize connection to server, and
                // request version 1.7 of the API set for vfiler-tunneling
                //
                s = new NaServer(args[2], 1, 7);
                s.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
                s.setAdminUser(args[3], args[4]);
                s.setTransportType(NaServer.TRANSPORT_TYPE_HTTPS);
                s.setPort(443);
                s.setServerType(NaServer.SERVER_TYPE_FILER);
                s.setVfilerTunneling(args[1]);

                // Invoke any ONTAPI API with arguments
                // in (key,value) pair
                // args[0]=option,args[1]=vfiler-name,args[2]=vfiler,
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
                // request version 1.7 of the API set for vfiler-tunneling
                //
                s = new NaServer(args[1], 1, 7);
                s.setStyle(NaServer.STYLE_LOGIN_PASSWORD);
                s.setAdminUser(args[2], args[3]);
                s.setVfilerTunneling(args[0]);

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
