/*
 * $Id: //depot/prod/zephyr/belair/src/sample/java/systemcli/systemcli.java#1 $
 *
 * Copyright (c) 2001-2006 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample of using the netapp.manage.* classes to
 * invoke the system-cli API.
 */

import java.io.IOException;
import java.net.UnknownHostException;
import java.util.List;
import java.util.Iterator;
import netapp.manage.*;

public class systemcli {

    public static void main(String[] args) {

        if (args.length < 3) {
            System.err.println("Usage: systemcli {filer} {login} {password}");
            System.exit(1);
        }
        String filer = args[0];
        String login = args[1];
        String password = args[2];

        NaServer s;

        try {
            s = new NaServer(filer, 1, 1);
        } catch (UnknownHostException e) {
            System.out.println("Unknown host: " + filer);
            System.exit(1);
            return;
        }

        s.setAdminUser(login, password);
        System.out.println();

        String volumeName = "vol0";

        try {
            NaElement xi, xo, argsarray;

            /*
             * Call the system-cli API, and pass it whatever arguments were
             * passed in on the command-line to this java program (after the
             * filer/login/password).
             */
            xi = new NaElement("system-cli");
            argsarray = new NaElement("args");
            int i;
            for (i = 3; i < args.length; i++) {
                argsarray.addNewChild("arg", args[i]);
            }

            xi.addChildElem(argsarray);

            xo = s.invokeElem(xi);

            System.out
                    .println("cli-output=" + xo.getChildContent("cli-output"));

        } catch (NaAuthenticationException e) {
            System.err.println("Bad login/password");
        } catch (NaAPIFailedException e) {
            System.err.println("API failed (" + e.getReason() + ")");
        } catch (IOException e) {
            e.printStackTrace();
        } catch (NaProtocolException e) {
            e.printStackTrace();
        } finally {
            s.close();
        }
    }
}
