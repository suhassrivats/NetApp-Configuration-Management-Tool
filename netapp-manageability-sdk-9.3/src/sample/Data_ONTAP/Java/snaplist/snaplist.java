/*
 * $Id: //depot/prod/zephyr/belair/src/sample/java/Sample1/snaplist.java#1 $
 *
 * Copyright (c) 2001-2003 Network Appliance, Inc.
 * All rights reserved.
 *
 * Sample of using the netapp.manage.* classes to
 * make use of the ONTAPI interface.
 */

import java.io.IOException;
import java.net.UnknownHostException;
import java.util.List;
import java.util.Iterator;
import netapp.manage.*;

public class snaplist {

    public static void main(String[] args) {

        if (args.length < 3) {
            System.err.println("Usage: snaplist {filer} {login} {password}");
            System.exit(1);
        }
        String filer = args[0];
        String login = args[1];
        String password = args[2];

        NaServer s;

        try {
            s = new NaServer(filer, 1, 0);
        } catch (UnknownHostException e) {
            System.out.println("Unknown host: " + filer);
            System.exit(1);
            return;
        }

        s.setAdminUser(login, password);
        System.out.println();

        String volumeName = "vol0";

        try {
            NaElement xi, xo;

            /*
             * Part 1 - a simple API with no arguments.
             */
            xi = new NaElement("system-get-version");
            xo = s.invokeElem(xi);

            System.out.println("VERSION=" + xo.getChildContent("version"));

            /*
             * Part 2 - an API with arguments, and an output array.
             */
            xi = new NaElement("snapshot-list-info");
            xi.addNewChild("volume", volumeName);
            xo = s.invokeElem(xi);

            List snapshots = xo.getChildByName("snapshots").getChildren();
            for (Iterator i = snapshots.iterator(); i.hasNext();) {
                NaElement snapshot = (NaElement) i.next();
                System.out.println("SNAPSHOT:");
                System.out.println("   name = "
                        + snapshot.getChildContent("name"));
                System.out.println("   total = "
                        + snapshot.getChildContent("total"));
                System.out.println("   busy = "
                        + snapshot.getChildContent("busy"));
            }
        } catch (NaAuthenticationException e) {
            System.err.println("Bad login/password");
        } catch (NaAPIFailedException e) {
            switch (e.getErrno()) {

            case NaErrno.EAPIUNSUPPORTEDVERSION:
                System.err.println("API version unsupported (" + e.getReason()
                        + ")");
                break;

            case NaErrno.EVOLUMEDOESNOTEXIST:
                System.err.println("Volume \"" + volumeName
                        + "\" does not exist (" + e.getReason() + ")");
                break;

            case NaErrno.EVOLUMEMOUNTING:
                System.err.println("Volume \"" + volumeName
                        + "\" is in the process of mounting (" + e.getReason()
                        + ")");
                break;

            case NaErrno.EVOLUMEOFFLINE:
                System.err.println("Volume \"" + volumeName + "\" is offline ("
                        + e.getReason() + ")");
                break;

            default:
                System.err.println("API failed (" + e.getReason() + ")");
                break;
            }
        } catch (IOException e) {
            e.printStackTrace();
        } catch (NaProtocolException e) {
            e.printStackTrace();
        } finally {
            s.close();
        }
    }
}
